extends RefCounted

const CampaignSession = preload("res://app/session/campaign_session.gd")
const SaveService = preload("res://persistence/services/save_service.gd")

const CAMPAIGN := "res://content/campaigns/great_lakes_1975"
const SEED := 424242
const ROOT := "user://h2i_persistence_tests"
const SAVE_ID := "h2i_primary"

func run() -> Dictionary:
    var failures: Array[String] = []
    _reset()
    _test_interrupted_publish_promotes_valid_temp(failures)
    _reset()
    _test_partial_temp_never_replaces_primary(failures)
    _reset()
    _test_state_hash_corruption_recovers_last_good(failures)
    _reset()
    _test_chronicle_corruption_recovers_last_good(failures)
    _reset()
    _test_older_good_second_fallback(failures)
    _reset()
    _test_backup_copy_failure_retains_previous(failures)
    _reset()
    _test_unrecoverable_interrupted_artifacts_fail_closed(failures)
    _reset()
    _test_pending_intents_die_with_process(failures)
    _reset()
    return {"name": "h2i_persistence_adversarial", "passed": failures.is_empty(), "failures": failures}

func _new_session() -> RefCounted:
    var session: RefCounted = CampaignSession.new()
    return session

func _start_persistent(label: String = "H2I") -> Dictionary:
    var session: RefCounted = _new_session()
    var result: Dictionary = session.call("start_or_resume", CAMPAIGN, SAVE_ID, SEED, ROOT, label)
    return {"session": session, "result": result}

func _test_interrupted_publish_promotes_valid_temp(failures: Array[String]) -> void:
    var fixture: Dictionary = _start_persistent("Interrupted publish")
    var session: RefCounted = fixture["session"]
    if not _expect_pass(fixture["result"], "interruption fixture start", failures): return
    _expect(bool((session.call("advance_month") as Dictionary).get("passed", false)), "first month must resolve", failures)
    var service: RefCounted = session.get("_save_service")
    service.set("failure_injection_stage", "after_preserve_previous")
    var second: Dictionary = session.call("advance_month")
    _expect(bool(second.get("passed", false)) and not bool(second.get("persistence_passed", true)), "process-death injection must leave a resolved unsaved-in-primary month", failures)
    var expected_state: Dictionary = session.call("state_snapshot")
    var expected_chronicle: Dictionary = session.call("chronicle_snapshot")

    var relaunched: Dictionary = _start_persistent("Interrupted publish")
    _expect_pass(relaunched["result"], "interrupted publish recovery", failures)
    if bool((relaunched["result"] as Dictionary).get("passed", false)):
        var resumed: RefCounted = relaunched["session"]
        _expect(bool((relaunched["result"] as Dictionary).get("recovered", false)), "interrupted publication must be reported as recovery", failures)
        _expect(resumed.call("state_snapshot") == expected_state, "validated newer temp must recover the exact authoritative state", failures)
        _expect(resumed.call("chronicle_snapshot") == expected_chronicle, "validated newer temp must recover the exact Chronicle", failures)

func _test_partial_temp_never_replaces_primary(failures: Array[String]) -> void:
    var fixture: Dictionary = _start_persistent("Partial temp")
    var session: RefCounted = fixture["session"]
    if not _expect_pass(fixture["result"], "partial fixture start", failures): return
    var baseline_state: Dictionary = session.call("state_snapshot")
    var baseline_chronicle: Dictionary = session.call("chronicle_snapshot")
    var service: RefCounted = session.get("_save_service")
    service.set("failure_injection_stage", "after_state_write")
    var attempted: Dictionary = service.call("save", SAVE_ID, "Partial temp", session.get("_state"), session.get("_chronicle"), {})
    _expect(not bool(attempted.get("passed", true)), "partial write injection must fail loudly", failures)

    var relaunched: Dictionary = _start_persistent("Partial temp")
    _expect_pass(relaunched["result"], "partial temp relaunch", failures)
    if bool((relaunched["result"] as Dictionary).get("passed", false)):
        var resumed: RefCounted = relaunched["session"]
        _expect(resumed.call("state_snapshot") == baseline_state, "partial temp must not replace current CampaignState", failures)
        _expect(resumed.call("chronicle_snapshot") == baseline_chronicle, "partial temp must not replace current Chronicle", failures)

func _test_state_hash_corruption_recovers_last_good(failures: Array[String]) -> void:
    var fixture: Dictionary = _start_persistent("State corruption")
    var session: RefCounted = fixture["session"]
    if not _expect_pass(fixture["result"], "state corruption fixture start", failures): return
    session.call("advance_month")
    session.call("advance_month")
    var service: RefCounted = session.get("_save_service")
    var expected_last: Dictionary = service.call("load_last_good", SAVE_ID, str(session.get("_state").get("content_fingerprint")))
    if not _expect_pass(expected_last, "last_good before state corruption", failures): return
    var expected_date: String = str(expected_last.get("state").get("current_date"))

    var state_path: String = ProjectSettings.globalize_path(ROOT.path_join(SAVE_ID).path_join("state.json"))
    var data: Dictionary = _read_json_direct(state_path)
    if data.is_empty(): failures.append("state corruption fixture could not read state.json"); return
    var people: Dictionary = data.get("people", {})
    if people.is_empty(): failures.append("state corruption fixture contains no people"); return
    var first_id: Variant = people.keys()[0]
    (people[first_id] as Dictionary)["display_name"] = "Schema-valid disk corruption"
    _write_json_direct(state_path, data)

    var recovered: Dictionary = _start_persistent("State corruption")
    _expect_pass(recovered["result"], "state corruption recovery", failures)
    if bool((recovered["result"] as Dictionary).get("passed", false)):
        _expect(bool((recovered["result"] as Dictionary).get("recovered", false)), "hash mismatch must use explicit recovery", failures)
        _expect(str((recovered["session"] as RefCounted).get("_state").get("current_date")) == expected_date, "state corruption must recover last-good date", failures)

func _test_chronicle_corruption_recovers_last_good(failures: Array[String]) -> void:
    var fixture: Dictionary = _start_persistent("Chronicle corruption")
    var session: RefCounted = fixture["session"]
    if not _expect_pass(fixture["result"], "chronicle corruption fixture start", failures): return
    session.call("advance_month")
    session.call("advance_month")
    var service: RefCounted = session.get("_save_service")
    var expected_last: Dictionary = service.call("load_last_good", SAVE_ID, str(session.get("_state").get("content_fingerprint")))
    if not _expect_pass(expected_last, "last_good before Chronicle corruption", failures): return
    var expected_date: String = str(expected_last.get("state").get("current_date"))

    var chron_path: String = ProjectSettings.globalize_path(ROOT.path_join(SAVE_ID).path_join("chronicle/chronicle.json"))
    var data: Dictionary = _read_json_direct(chron_path)
    var deltas: Array = data.get("deltas", [])
    if deltas.is_empty(): failures.append("Chronicle corruption fixture has no deltas"); return
    deltas.remove_at(deltas.size() - 1)
    data["deltas"] = deltas
    _write_json_direct(chron_path, data)

    var recovered: Dictionary = _start_persistent("Chronicle corruption")
    _expect_pass(recovered["result"], "Chronicle corruption recovery", failures)
    if bool((recovered["result"] as Dictionary).get("passed", false)):
        _expect(bool((recovered["result"] as Dictionary).get("recovered", false)), "Chronicle corruption must use explicit recovery", failures)
        _expect(str((recovered["session"] as RefCounted).get("_state").get("current_date")) == expected_date, "Chronicle corruption must recover last-good date", failures)

func _test_older_good_second_fallback(failures: Array[String]) -> void:
    var fixture: Dictionary = _start_persistent("Backup rotation")
    var session: RefCounted = fixture["session"]
    if not _expect_pass(fixture["result"], "rotation fixture start", failures): return
    for _i: int in range(4):
        var month: Dictionary = session.call("advance_month")
        if not bool(month.get("persistence_passed", false)): failures.append("rotation fixture month failed to persist"); return
    var service: RefCounted = session.get("_save_service")
    _expect(bool(service.call("has_last_good", SAVE_ID)), "rotation must maintain last_good", failures)
    _expect(bool(service.call("has_older_good", SAVE_ID)), "rotation must maintain older_good", failures)
    var expected_older: Dictionary = service.call("load_older_good", SAVE_ID, str(session.get("_state").get("content_fingerprint")))
    if not _expect_pass(expected_older, "older_good before corruption", failures): return
    var expected_date: String = str(expected_older.get("state").get("current_date"))

    _overwrite_invalid_json(ProjectSettings.globalize_path(ROOT.path_join(SAVE_ID).path_join("manifest.json")))
    _overwrite_invalid_json(ProjectSettings.globalize_path(ROOT.path_join(SAVE_ID).path_join("backups/last_good/manifest.json")))
    var recovered: Dictionary = _start_persistent("Backup rotation")
    _expect_pass(recovered["result"], "older_good fallback recovery", failures)
    if bool((recovered["result"] as Dictionary).get("passed", false)):
        _expect(str((recovered["result"] as Dictionary).get("recovery_source", "")) == "older_good", "second fallback must identify older_good", failures)
        _expect(str((recovered["session"] as RefCounted).get("_state").get("current_date")) == expected_date, "older_good fallback must recover exact older date", failures)

func _test_backup_copy_failure_retains_previous(failures: Array[String]) -> void:
    var fixture: Dictionary = _start_persistent("Backup copy failure")
    var session: RefCounted = fixture["session"]
    if not _expect_pass(fixture["result"], "backup-copy fixture start", failures): return
    var first: Dictionary = session.call("advance_month")
    if not bool(first.get("persistence_passed", false)): failures.append("backup-copy fixture first month must persist"); return
    var service: RefCounted = session.get("_save_service")
    service.set("failure_injection_stage", "backup_copy_failure")
    var second: Dictionary = session.call("advance_month")
    service.set("failure_injection_stage", "")
    _expect(bool(second.get("passed", false)) and bool(second.get("persistence_passed", false)), "backup-copy failure must not roll back a valid newly published primary", failures)
    var checkpoint: Dictionary = second.get("checkpoint", {})
    _expect(bool(checkpoint.get("backup_retry_retained", false)), "H2I-003: failed backup rotation must retain .previous for retry", failures)
    var base: String = ProjectSettings.globalize_path(ROOT)
    _expect(DirAccess.dir_exists_absolute(base.path_join("." + SAVE_ID + ".previous")), "H2I-003: previous source must physically survive backup-copy failure", failures)
    var expected_state: Dictionary = session.call("state_snapshot")
    var expected_chronicle: Dictionary = session.call("chronicle_snapshot")
    var relaunched: Dictionary = _start_persistent("Backup copy failure")
    _expect_pass(relaunched["result"], "backup-copy recovery", failures)
    if bool((relaunched["result"] as Dictionary).get("passed", false)):
        var resumed: RefCounted = relaunched["session"]
        _expect(resumed.call("state_snapshot") == expected_state and resumed.call("chronicle_snapshot") == expected_chronicle, "backup retry recovery must preserve current primary exactly", failures)
        _expect(not DirAccess.dir_exists_absolute(base.path_join("." + SAVE_ID + ".previous")), "successful recovery must clean the retained previous source", failures)

func _test_unrecoverable_interrupted_artifacts_fail_closed(failures: Array[String]) -> void:
    var fixture: Dictionary = _start_persistent("Fail closed")
    if not _expect_pass(fixture["result"], "fail-closed fixture start", failures): return
    var base: String = ProjectSettings.globalize_path(ROOT)
    var target: String = base.path_join(SAVE_ID)
    var previous: String = base.path_join("." + SAVE_ID + ".previous")
    DirAccess.rename_absolute(target, previous)
    _overwrite_invalid_json(previous.path_join("manifest.json"))
    var temp: String = base.path_join("." + SAVE_ID + ".tmp")
    DirAccess.make_dir_recursive_absolute(temp)
    _overwrite_invalid_json(temp.path_join("manifest.json"))

    var relaunched: Dictionary = _start_persistent("Fail closed")
    _expect(not bool((relaunched["result"] as Dictionary).get("passed", true)), "unrecoverable interrupted artifacts must fail closed", failures)
    _expect(not DirAccess.dir_exists_absolute(target), "fail-closed recovery must not fabricate a new primary", failures)

func _test_pending_intents_die_with_process(failures: Array[String]) -> void:
    var fixture: Dictionary = _start_persistent("Pending intents")
    var session: RefCounted = fixture["session"]
    if not _expect_pass(fixture["result"], "pending fixture start", failures): return
    var projection: Dictionary = session.call("current_projection")
    var controlled: Dictionary = {}
    for item: Dictionary in projection.get("touring", []):
        if str(item.get("ownership", "")) == "controlled": controlled = item; break
    var markets: Array = projection.get("markets", [])
    if controlled.is_empty() or markets.is_empty(): failures.append("pending fixture lacks controlled company/market"); return
    var queued: Dictionary = session.call("queue_player_command", "command.set_route", {"touring_company_id": str(controlled.get("company_id", "")), "route": [{"market_id": str((markets[-1] as Dictionary).get("market_id", ""))}]})
    _expect(bool(queued.get("accepted", false)) and int(session.call("pending_count")) == 1, "pending intent must queue in memory", failures)
    var relaunched: Dictionary = _start_persistent("Pending intents")
    _expect_pass(relaunched["result"], "pending relaunch", failures)
    if bool((relaunched["result"] as Dictionary).get("passed", false)):
        _expect(int((relaunched["session"] as RefCounted).call("pending_count")) == 0, "uncommitted UI intent must not survive process death", failures)

func _test_repeated_month_save_reload_pressure(failures: Array[String]) -> void:
    var fixture: Dictionary = _start_persistent("Pressure")
    var session: RefCounted = fixture["session"]
    if not _expect_pass(fixture["result"], "pressure fixture start", failures): return
    for month_index: int in range(12):
        var advanced: Dictionary = session.call("advance_month")
        if not bool(advanced.get("passed", false)) or not bool(advanced.get("persistence_passed", false)):
            failures.append("pressure month " + str(month_index) + " failed")
            return
        var state_before: Dictionary = session.call("state_snapshot")
        var chron_before: Dictionary = session.call("chronicle_snapshot")
        var relaunched: Dictionary = _start_persistent("Pressure")
        if not _expect_pass(relaunched["result"], "pressure relaunch " + str(month_index), failures): return
        session = relaunched["session"]
        _expect(session.call("state_snapshot") == state_before, "pressure relaunch must preserve exact state at month " + str(month_index), failures)
        _expect(session.call("chronicle_snapshot") == chron_before, "pressure relaunch must preserve exact Chronicle at month " + str(month_index), failures)
        _expect(int(session.call("pending_count")) == 0, "pressure relaunch must have zero pending commands", failures)
        var dates: Array = (session.call("current_projection") as Dictionary).get("history_dates", [])
        if not dates.is_empty():
            var state_guard: Dictionary = session.call("state_snapshot")
            var chron_guard: Dictionary = session.call("chronicle_snapshot")
            for date_value: Variant in dates:
                session.call("historical_projection", str(date_value))
            _expect(session.call("state_snapshot") == state_guard and session.call("chronicle_snapshot") == chron_guard, "historical pressure must remain read-only", failures)

func _read_json_direct(path: String) -> Dictionary:
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null: return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    return parsed if parsed is Dictionary else {}

func _write_json_direct(path: String, data: Dictionary) -> void:
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file == null: return
    file.store_string(JSON.stringify(data, "  ", true, true) + "\n")
    file.close()

func _overwrite_invalid_json(path: String) -> void:
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file == null: return
    file.store_string("{ not valid json\n")
    file.close()

func _reset() -> void:
    var base: String = ProjectSettings.globalize_path(ROOT)
    # Godot's directory iterator omits dot-prefixed children here, so remove every
    # transactional artifact by its known absolute path before removing the test root.
    for artifact: String in [SAVE_ID, "." + SAVE_ID + ".tmp", "." + SAVE_ID + ".previous", "." + SAVE_ID + ".recovery_old"]:
        _remove_tree(base.path_join(artifact))
    if DirAccess.dir_exists_absolute(base): DirAccess.remove_absolute(base)

func _remove_tree(path: String) -> void:
    if not DirAccess.dir_exists_absolute(path): return
    var directory: DirAccess = DirAccess.open(path)
    if directory == null: return
    directory.list_dir_begin()
    var name: String = directory.get_next()
    while name != "":
        if name != "." and name != "..":
            var child: String = path.path_join(name)
            if directory.current_is_dir(): _remove_tree(child)
            else: DirAccess.remove_absolute(child)
        name = directory.get_next()
    directory.list_dir_end()
    DirAccess.remove_absolute(path)

func _expect_pass(result: Dictionary, label: String, failures: Array[String]) -> bool:
    var passed: bool = bool(result.get("passed", false))
    if not passed: failures.append(label + " failed: " + JSON.stringify(result.get("errors", [])))
    return passed

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition: failures.append(message)
