extends RefCounted

const PhaseDFixture = preload("res://tests/helpers/phase_d_fixture.gd")
const MonthPipeline = preload("res://app/session/month_pipeline.gd")
const SaveService = preload("res://persistence/services/save_service.gd")
const CampaignStateCodec = preload("res://persistence/codecs/campaign_state_codec.gd")
const ChronicleCodec = preload("res://persistence/codecs/chronicle_codec.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var state: RefCounted = PhaseDFixture.make_state()
    var chronicle: RefCounted = PhaseDFixture.make_chronicle()
    var pipeline: RefCounted = MonthPipeline.new()
    for month_index: int in range(2):
        var turn: RefCounted = pipeline.call("advance_month", state, chronicle, [PhaseDFixture.championship_command(state, month_index)], PhaseDFixture.content_index())
        if not bool(turn.get("passed")):
            failures.append("pre-save month failed: " + JSON.stringify(turn.get("errors")))
            return {"name": "phase_d_save_service", "passed": false, "failures": failures}
        state = turn.get("state")
        chronicle = turn.get("chronicle")
    var expected_state: Dictionary = CampaignStateCodec.new().encode(state)
    var expected_chronicle: Dictionary = ChronicleCodec.new().encode(chronicle)
    var expected_date: String = str(state.get("current_date"))
    var service: RefCounted = SaveService.new()
    service.set("root_path", "user://phase_d_acceptance_saves")
    var save_id: String = "phase_d_roundtrip"
    var first_save: Dictionary = service.call("save", save_id, "Phase D Roundtrip", state, chronicle, {"created_utc": "fixture", "updated_utc": "fixture"})
    if not bool(first_save["passed"]): failures.append("valid state+Chronicle save should publish: " + JSON.stringify(first_save.get("errors")))
    var loaded: Dictionary = service.call("load_save", save_id, state.get("content_fingerprint"))
    if not bool(loaded["passed"]): failures.append("published save should load: " + JSON.stringify(loaded.get("errors")))
    else:
        if CampaignStateCodec.new().encode(loaded["state"]) != expected_state: failures.append("save/load must preserve authoritative current CampaignState including RNG checkpoint")
        if not _semantic_equal(ChronicleCodec.new().encode(loaded["chronicle"]), expected_chronicle): failures.append("save/load must preserve Chronicle meaning and head")
        if not (loaded["chronicle"].get("identity_catalog") as Dictionary).has("person:PER00001"): failures.append("save/load must preserve stable historical identity references")
    var mismatch: Dictionary = service.call("load_save", save_id, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
    if bool(mismatch["passed"]) or not _has_code(mismatch.get("errors", []), "SAVE001"): failures.append("content fingerprint mismatch must fail SAVE001")

    var manifest_path: String = ProjectSettings.globalize_path("user://phase_d_acceptance_saves/" + save_id + "/manifest.json")
    var manifest_file: FileAccess = FileAccess.open(manifest_path, FileAccess.READ)
    var original_manifest_text: String = manifest_file.get_as_text()
    manifest_file.close()
    var parsed: Dictionary = JSON.parse_string(original_manifest_text)
    parsed["save_schema_version"] = 99
    manifest_file = FileAccess.open(manifest_path, FileAccess.WRITE)
    manifest_file.store_string(JSON.stringify(parsed, "  ") + "\n")
    manifest_file.close()
    var newer: Dictionary = service.call("load_save", save_id, state.get("content_fingerprint"))
    if bool(newer["passed"]) or not _has_code(newer.get("errors", []), "SAVE002"): failures.append("unsupported newer save schema must fail SAVE002")
    manifest_file = FileAccess.open(manifest_path, FileAccess.WRITE)
    manifest_file.store_string(original_manifest_text)
    manifest_file.close()

    # Phase F-R compatibility: a historically valid Phase F state/manifest loads through
    # the explicit v1 -> v2 state migration, retiring only the player-seat Person coupling.
    var legacy_manifest_file: FileAccess = FileAccess.open(manifest_path, FileAccess.READ)
    var legacy_manifest: Dictionary = JSON.parse_string(legacy_manifest_file.get_as_text())
    legacy_manifest_file.close()
    legacy_manifest["architecture_version"] = "0.2.0"
    legacy_manifest["game_version"] = "0.0.0-phase-f"
    legacy_manifest_file = FileAccess.open(manifest_path, FileAccess.WRITE)
    legacy_manifest_file.store_string(JSON.stringify(legacy_manifest, "  ") + "\n")
    legacy_manifest_file.close()
    var state_path: String = ProjectSettings.globalize_path("user://phase_d_acceptance_saves/" + save_id + "/state.json")
    var legacy_state_file: FileAccess = FileAccess.open(state_path, FileAccess.READ)
    var legacy_state: Dictionary = JSON.parse_string(legacy_state_file.get_as_text())
    legacy_state_file.close()
    legacy_state["state_schema_version"] = 1
    (legacy_state["ownership_seat"] as Dictionary)["owner_person_id"] = "person:PER00001"
    legacy_state_file = FileAccess.open(state_path, FileAccess.WRITE)
    legacy_state_file.store_string(JSON.stringify(legacy_state, "  ") + "\n")
    legacy_state_file.close()
    var migrated_load: Dictionary = service.call("load_save", save_id, state.get("content_fingerprint"))
    if not bool(migrated_load.get("passed", false)):
        failures.append("Phase F architecture/state save must migrate into F-R: " + JSON.stringify(migrated_load.get("errors", [])))
    else:
        if (migrated_load.get("migrations_applied", []) as Array).size() != 1: failures.append("legacy Phase F load must report the explicit v1->v2 ownership-seat migration")
        var migrated_state: Dictionary = CampaignStateCodec.new().encode(migrated_load["state"])
        if int(migrated_state.get("state_schema_version", -1)) != 2: failures.append("legacy Phase F load must produce state schema v2")
        if (migrated_state.get("ownership_seat", {}) as Dictionary).has("owner_person_id"): failures.append("legacy Phase F load must not retain player Person identity in OwnershipSeatState")
        if (migrated_state.get("promotions", {}).get("promotion:PRO00001", {}) as Dictionary).get("controlling_owner_person_id") != "person:PER00001": failures.append("legacy Phase F migration must preserve NPC/in-world promotion ownership")
    # Restore current files for the remaining last-good/failure-injection assertions.
    manifest_file = FileAccess.open(manifest_path, FileAccess.WRITE)
    manifest_file.store_string(original_manifest_text)
    manifest_file.close()
    var restore_state: Dictionary = service.call("save", save_id, "Phase D Roundtrip", state, chronicle, {"created_utc": "fixture", "updated_utc": "fixture"})
    if not bool(restore_state.get("passed", false)): failures.append("failed to restore current save after legacy migration regression")

    var third_turn: RefCounted = pipeline.call("advance_month", state, chronicle, [PhaseDFixture.championship_command(state, 2)], PhaseDFixture.content_index())
    if not bool(third_turn.get("passed")):
        failures.append("pre-failure-injection month failed")
    else:
        service.set("failure_injection_stage", "before_publish")
        var failed_save: Dictionary = service.call("save", save_id, "Phase D Roundtrip", third_turn.get("state"), third_turn.get("chronicle"), {"updated_utc": "fixture-2"})
        service.set("failure_injection_stage", "")
        if bool(failed_save["passed"]): failures.append("injected save publication failure must fail loudly")
        var after_failure: Dictionary = service.call("load_save", save_id, state.get("content_fingerprint"))
        if not bool(after_failure["passed"]): failures.append("failed publication must preserve last known-good save")
        elif str(after_failure["state"].get("current_date")) != expected_date: failures.append("failed publication must not replace last known-good state")
    return {"name": "phase_d_save_service", "passed": failures.is_empty(), "failures": failures}

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

func _has_code(errors: Array, code: String) -> bool:
    for error: Variant in errors:
        if error is Dictionary and str((error as Dictionary).get("code")) == code: return true
    return false
