extends RefCounted

const CampaignSession = preload("res://app/session/campaign_session.gd")
const SaveService = preload("res://persistence/services/save_service.gd")

const CAMPAIGN := "res://content/campaigns/great_lakes_1975"
const SEED := 424242
const ROOT := "user://phase_h_lifecycle_saves"
const SAVE_ID := "phase_h_primary"

func run() -> Dictionary:
    var failures: Array[String] = []
    _remove_tree(ProjectSettings.globalize_path(ROOT))
    _test_persistent_start_month_reload(failures)
    _remove_tree(ProjectSettings.globalize_path(ROOT))
    _test_restart_boundary_determinism(failures)
    _remove_tree(ProjectSettings.globalize_path(ROOT))
    _test_failed_checkpoint_retry_and_coalescing(failures)
    _remove_tree(ProjectSettings.globalize_path(ROOT))
    _test_last_good_recovery_and_restore(failures)
    _remove_tree(ProjectSettings.globalize_path(ROOT))
    return {"name": "phase_h_lifecycle_save_recovery", "passed": failures.is_empty(), "failures": failures}

func _test_persistent_start_month_reload(failures: Array[String]) -> void:
    var session: RefCounted = CampaignSession.new()
    var started: Dictionary = session.call("start_or_resume", CAMPAIGN, SAVE_ID, SEED, ROOT, "Phase H Test")
    _expect(bool(started.get("passed", false)), "Phase H persistent session must create its initial transactional checkpoint.", failures)
    _expect(str(started.get("start_mode", "")) == "new_persistent", "A missing save must start as new_persistent rather than a fake resume.", failures)
    if not bool(started.get("passed", false)): return

    var before_turn: int = int((session.call("current_projection") as Dictionary).get("turn_number", -1))
    var advanced: Dictionary = session.call("advance_month")
    _expect(bool(advanced.get("passed", false)), "A persistent Phase H month must resolve through MonthPipeline.", failures)
    _expect(bool(advanced.get("persistence_passed", false)), "A successful persistent month must publish its post-Chronicle checkpoint.", failures)
    var after_state: Dictionary = session.call("state_snapshot")
    var after_chronicle: Dictionary = session.call("chronicle_snapshot")
    _expect(int((session.call("current_projection") as Dictionary).get("turn_number", -1)) == before_turn + 1, "Persistent month resolution must advance exactly one turn.", failures)

    var resumed: RefCounted = CampaignSession.new()
    var resumed_result: Dictionary = resumed.call("start_or_resume", CAMPAIGN, SAVE_ID, SEED, ROOT, "Phase H Test")
    _expect(bool(resumed_result.get("passed", false)) and str(resumed_result.get("start_mode", "")) == "resumed", "Relaunch must load the published primary checkpoint.", failures)
    if bool(resumed_result.get("passed", false)):
        _expect(resumed.call("state_snapshot") == after_state, "Relaunch must preserve authoritative CampaignState exactly.", failures)
        _expect(resumed.call("chronicle_snapshot") == after_chronicle, "Relaunch must preserve Chronicle values and numeric types exactly.", failures)
        _expect(int(resumed.call("pending_count")) == 0, "Uncommitted UI intentions must not masquerade as saved authoritative state.", failures)


func _test_restart_boundary_determinism(failures: Array[String]) -> void:
    var continuous: RefCounted = CampaignSession.new()
    var continuous_start: Dictionary = continuous.call("start", CAMPAIGN, SEED)
    var persisted: RefCounted = CampaignSession.new()
    var persisted_start: Dictionary = persisted.call("start_or_resume", CAMPAIGN, SAVE_ID, SEED, ROOT, "Phase H Determinism")
    if not bool(continuous_start.get("passed", false)) or not bool(persisted_start.get("passed", false)):
        failures.append("Restart determinism fixtures could not start.")
        return
    for month: int in range(6):
        var continuous_result: Dictionary = continuous.call("advance_month")
        var persisted_result: Dictionary = persisted.call("advance_month")
        _expect(bool(continuous_result.get("passed", false)) and bool(persisted_result.get("passed", false)), "Restart determinism fixture month must resolve on both paths.", failures)
        if month == 0:
            var reloaded: RefCounted = CampaignSession.new()
            var reload_result: Dictionary = reloaded.call("start_or_resume", CAMPAIGN, SAVE_ID, SEED, ROOT, "Phase H Determinism")
            _expect(bool(reload_result.get("passed", false)) and str(reload_result.get("start_mode", "")) == "resumed", "Determinism fixture must cross a real persistence/relaunch boundary.", failures)
            persisted = reloaded
    _expect(_snapshot_hash(continuous) == _snapshot_hash(persisted), "Save/relaunch must not alter the deterministic CampaignState + Chronicle fingerprint.", failures)

func _snapshot_hash(session: RefCounted) -> String:
    return JSON.stringify({"state": session.call("state_snapshot"), "chronicle": session.call("chronicle_snapshot")}, "", true, true).sha256_text()

func _test_failed_checkpoint_retry_and_coalescing(failures: Array[String]) -> void:
    var session: RefCounted = CampaignSession.new()
    var started: Dictionary = session.call("start_or_resume", CAMPAIGN, SAVE_ID, SEED, ROOT, "Phase H Test")
    if not bool(started.get("passed", false)):
        failures.append("Lifecycle retry fixture could not start.")
        return
    var service: RefCounted = session.get("_save_service")
    service.set("failure_injection_stage", "before_publish")
    var advanced: Dictionary = session.call("advance_month")
    _expect(bool(advanced.get("passed", false)), "Injected persistence failure must not retroactively un-resolve a completed authoritative month.", failures)
    _expect(not bool(advanced.get("persistence_passed", true)), "Injected publication failure must be reported as persistence failure.", failures)
    var status: Dictionary = session.call("persistence_status")
    _expect(bool(status.get("checkpoint_requested", false)), "Failed autosave must remain queued for retry.", failures)

    var first_request: Dictionary = session.call("request_checkpoint", "application_background")
    var second_request: Dictionary = session.call("request_checkpoint", "application_background")
    _expect(str(first_request.get("disposition", "")) == "duplicate_suppressed" and str(second_request.get("disposition", "")) == "duplicate_suppressed", "Repeated lifecycle notifications must coalesce onto one pending checkpoint.", failures)

    service.set("failure_injection_stage", "")
    var flushed: Dictionary = session.call("flush_checkpoint")
    _expect(bool(flushed.get("passed", false)) and str(flushed.get("disposition", "")) == "saved", "Lifecycle retry must publish the exact current authoritative checkpoint once storage recovers.", failures)
    _expect(not bool((session.call("persistence_status") as Dictionary).get("checkpoint_requested", true)), "Successful retry must clear pending checkpoint state.", failures)
    var redundant: Dictionary = session.call("request_checkpoint", "application_background")
    _expect(str(redundant.get("disposition", "")) == "already_checkpointed", "Backgrounding an unchanged already-saved state must not rewrite storage pointlessly.", failures)

func _test_last_good_recovery_and_restore(failures: Array[String]) -> void:
    var session: RefCounted = CampaignSession.new()
    var started: Dictionary = session.call("start_or_resume", CAMPAIGN, SAVE_ID, SEED, ROOT, "Phase H Test")
    if not bool(started.get("passed", false)):
        failures.append("Recovery fixture could not start.")
        return
    var first: Dictionary = session.call("advance_month")
    var second: Dictionary = session.call("advance_month")
    _expect(bool(first.get("persistence_passed", false)) and bool(second.get("persistence_passed", false)), "Recovery fixture requires two successful post-month checkpoints.", failures)
    if not bool(second.get("persistence_passed", false)): return

    var service: RefCounted = SaveService.new()
    service.set("root_path", ROOT)
    var fingerprint: String = str((session.call("state_snapshot") as Dictionary).get("content_fingerprint", ""))
    var last_good: Dictionary = service.call("load_last_good", SAVE_ID, fingerprint)
    _expect(bool(last_good.get("passed", false)), "Published save must retain a structurally complete loadable last-good snapshot.", failures)
    if not bool(last_good.get("passed", false)): return
    var expected_recovered_date: String = str(last_good.get("state").get("current_date"))

    var manifest_path: String = ProjectSettings.globalize_path(ROOT.path_join(SAVE_ID).path_join("manifest.json"))
    var manifest_file: FileAccess = FileAccess.open(manifest_path, FileAccess.WRITE)
    if manifest_file == null:
        failures.append("Recovery fixture could not corrupt current manifest.")
        return
    manifest_file.store_string("{ definitely not valid json\n")
    manifest_file.close()

    var recovered_session: RefCounted = CampaignSession.new()
    var recovery: Dictionary = recovered_session.call("start_or_resume", CAMPAIGN, SAVE_ID, SEED, ROOT, "Phase H Test")
    _expect(bool(recovery.get("passed", false)) and bool(recovery.get("recovered", false)), "Invalid current save must recover explicitly from last_good rather than silently starting a new campaign.", failures)
    _expect(str((recovered_session.call("current_projection") as Dictionary).get("date", "")) == expected_recovered_date, "Recovery must adopt the recorded last-good state, not the corrupted current state.", failures)

    var restored_primary: Dictionary = service.call("load_save", SAVE_ID, fingerprint)
    var restored_last_good: Dictionary = service.call("load_last_good", SAVE_ID, fingerprint)
    _expect(bool(restored_primary.get("passed", false)), "Recovery startup must restore a valid primary save transactionally.", failures)
    _expect(bool(restored_last_good.get("passed", false)), "Restoring from recovery must not replace last_good with the corrupted former primary.", failures)
    if bool(restored_primary.get("passed", false)):
        _expect(str(restored_primary.get("state").get("current_date")) == expected_recovered_date, "Restored primary must match the adopted last-good date.", failures)

func _semantic_equal(left: Variant, right: Variant) -> bool:
    if (left is int or left is float) and (right is int or right is float):
        return float(left) == float(right)
    if left is Dictionary and right is Dictionary:
        if (left as Dictionary).size() != (right as Dictionary).size(): return false
        for key: Variant in (left as Dictionary).keys():
            if not (right as Dictionary).has(key) or not _semantic_equal((left as Dictionary)[key], (right as Dictionary)[key]): return false
        return true
    if left is Array and right is Array:
        if (left as Array).size() != (right as Array).size(): return false
        for index: int in range((left as Array).size()):
            if not _semantic_equal((left as Array)[index], (right as Array)[index]): return false
        return true
    return left == right

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

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition: failures.append(message)
