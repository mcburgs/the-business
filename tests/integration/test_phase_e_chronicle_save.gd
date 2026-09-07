extends RefCounted

const PhaseEFixture = preload("res://tests/helpers/phase_e_fixture.gd")
const MonthPipeline = preload("res://app/session/month_pipeline.gd")
const HistoricalProjection = preload("res://domain/chronicle/historical_projection.gd")
const ChronicleQueryService = preload("res://domain/chronicle/chronicle_query_service.gd")
const CampaignStateCodec = preload("res://persistence/codecs/campaign_state_codec.gd")
const ChronicleCodec = preload("res://persistence/codecs/chronicle_codec.gd")
const SaveService = preload("res://persistence/services/save_service.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var state: RefCounted = PhaseEFixture.make_state(424242)
    var chronicle: RefCounted = PhaseEFixture.make_chronicle(6)
    var expected_by_date: Dictionary = {}
    var pipeline: RefCounted = MonthPipeline.new()
    for month_index: int in range(8):
        var turn: RefCounted = pipeline.call("advance_month", state, chronicle, PhaseEFixture.strategy_commands(state, "good", month_index), PhaseEFixture.content_index())
        if not bool(turn.get("passed")):
            failures.append("Phase E history month failed: " + JSON.stringify(turn.get("errors")))
            return _result(failures, chronicle)
        state = turn.get("state")
        chronicle = turn.get("chronicle")
        expected_by_date[str(state.get("current_date"))] = HistoricalProjection.from_campaign_state(state)

    var target_date: String = "2001-05-01"
    var current_before: Dictionary = CampaignStateCodec.new().encode(state)
    var reconstructed: Dictionary = ChronicleQueryService.new().get_projection(chronicle, target_date)
    if not bool(reconstructed.get("passed", false)):
        failures.append("real Phase E month must reconstruct from checkpoint+deltas: " + JSON.stringify(reconstructed.get("errors", [])))
    else:
        if reconstructed.get("projection") != expected_by_date[target_date]: failures.append("reconstructed Phase E projection must equal the recorded historical projection")
        var projection: Dictionary = reconstructed.get("projection", {})
        if not (projection.get("people_audience", {}) as Dictionary).has(PhaseEFixture.STAR_ID): failures.append("Phase E history must retain local wrestler audience state")
        if not (projection.get("programs", {}) as Dictionary).has(PhaseEFixture.PROGRAM_ID): failures.append("Phase E history must retain program state")
        if not (projection.get("touring_companies", {}) as Dictionary).has(PhaseEFixture.COMPANY_ID): failures.append("Phase E history must retain touring route/directive state")
        if not (projection.get("promotions", {}).get(PhaseEFixture.PLAYER_PROMOTION_ID, {}) as Dictionary).has("cash"): failures.append("Phase E history must retain financial position needed for prior-world reconstruction")
    if CampaignStateCodec.new().encode(state) != current_before: failures.append("historical reconstruction must remain read-only and not mutate current CampaignState")
    if (chronicle.get("checkpoints") as Array).size() >= 8: failures.append("Phase E history must remain sparse rather than snapshotting the whole projection every month")

    var expected_state: Dictionary = CampaignStateCodec.new().encode(state)
    var expected_chronicle: Dictionary = ChronicleCodec.new().encode(chronicle)
    var service: RefCounted = SaveService.new()
    service.set("root_path", "user://phase_e_acceptance_saves")
    var save_id: String = "phase_e_roundtrip"
    var saved: Dictionary = service.call("save", save_id, "Phase E Roundtrip", state, chronicle, {"created_utc": "fixture", "updated_utc": "fixture"})
    if not bool(saved.get("passed", false)):
        failures.append("Phase E state+Chronicle save should publish: " + JSON.stringify(saved.get("errors", [])))
    else:
        var loaded: Dictionary = service.call("load_save", save_id, state.get("content_fingerprint"))
        if not bool(loaded.get("passed", false)):
            failures.append("Phase E published save should load: " + JSON.stringify(loaded.get("errors", [])))
        else:
            var loaded_state_encoded: Dictionary = CampaignStateCodec.new().encode(loaded["state"])
            if loaded_state_encoded != expected_state: failures.append("save/load must exactly preserve authoritative Phase E state and RNG checkpoint; first difference=" + JSON.stringify(_first_difference(expected_state, loaded_state_encoded)))
            var loaded_chronicle_encoded: Dictionary = ChronicleCodec.new().encode(loaded["chronicle"])
            if not _semantic_equal(loaded_chronicle_encoded, expected_chronicle): failures.append("save/load must preserve Phase E Chronicle history and head; first difference=" + JSON.stringify(_first_difference(expected_chronicle, loaded_chronicle_encoded)))
            if not (loaded["chronicle"].get("identity_catalog") as Dictionary).has(PhaseEFixture.MARKET_A): failures.append("save/load must preserve stable historical market identity references")

    var ninth: RefCounted = pipeline.call("advance_month", state, chronicle, PhaseEFixture.strategy_commands(state, "good", 8), PhaseEFixture.content_index())
    if bool(ninth.get("passed")):
        service.set("failure_injection_stage", "before_publish")
        var failed_save: Dictionary = service.call("save", save_id, "Phase E Roundtrip", ninth.get("state"), ninth.get("chronicle"), {"updated_utc": "fixture-2"})
        service.set("failure_injection_stage", "")
        if bool(failed_save.get("passed", false)): failures.append("injected Phase E publication failure must fail")
        var after_failure: Dictionary = service.call("load_save", save_id, state.get("content_fingerprint"))
        if not bool(after_failure.get("passed", false)) or str(after_failure["state"].get("current_date")) != str(state.get("current_date")):
            failures.append("failed Phase E publication must preserve last known-good save")
    else:
        failures.append("ninth Phase E month should resolve before failure-injection recovery proof")
    return _result(failures, chronicle)

func _result(failures: Array[String], chronicle: RefCounted) -> Dictionary:
    return {
        "name": "phase_e_chronicle_save",
        "passed": failures.is_empty(),
        "failures": failures,
        "chronicle_counts": chronicle.call("counts") if chronicle != null else {},
        "reconstruction_dependencies": {"booking_system": "unavailable", "show_resolver": "unavailable", "simulation_resolution": "unavailable", "random_service": "unavailable", "old_commands": "not_replayed"},
    }

func _first_difference(left: Variant, right: Variant, path: String = "root") -> Dictionary:
    if typeof(left) != typeof(right):
        return {"path": path, "left": left, "right": right, "left_type": typeof(left), "right_type": typeof(right)}
    if left is Dictionary:
        var left_dict: Dictionary = left
        var right_dict: Dictionary = right
        for key: Variant in left_dict.keys():
            if not right_dict.has(key): return {"path": path + "." + str(key), "left": left_dict[key], "right": "<missing>"}
            var diff: Dictionary = _first_difference(left_dict[key], right_dict[key], path + "." + str(key))
            if not diff.is_empty(): return diff
        for key: Variant in right_dict.keys():
            if not left_dict.has(key): return {"path": path + "." + str(key), "left": "<missing>", "right": right_dict[key]}
        return {}
    if left is Array:
        var left_array: Array = left
        var right_array: Array = right
        if left_array.size() != right_array.size(): return {"path": path + ".size", "left": left_array.size(), "right": right_array.size()}
        for index: int in range(left_array.size()):
            var diff: Dictionary = _first_difference(left_array[index], right_array[index], path + "[" + str(index) + "]")
            if not diff.is_empty(): return diff
        return {}
    if left != right: return {"path": path, "left": left, "right": right}
    return {}

func _semantic_equal(left: Variant, right: Variant) -> bool:
    if (left is int or left is float) and (right is int or right is float): return float(left) == float(right)
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
