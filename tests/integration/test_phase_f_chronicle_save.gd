extends RefCounted

const Fixture = preload("res://tests/helpers/phase_f_fixture.gd")
const MonthPipeline = preload("res://app/session/month_pipeline.gd")
const HistoricalProjection = preload("res://domain/chronicle/historical_projection.gd")
const ChronicleQueryService = preload("res://domain/chronicle/chronicle_query_service.gd")
const CampaignStateCodec = preload("res://persistence/codecs/campaign_state_codec.gd")
const ChronicleCodec = preload("res://persistence/codecs/chronicle_codec.gd")
const SaveService = preload("res://persistence/services/save_service.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var state: RefCounted = Fixture.make_state(13579); var chronicle: RefCounted = Fixture.make_chronicle(6); var pipeline: RefCounted = MonthPipeline.new(); var expected: Dictionary = {}
    for month_index: int in range(12):
        var turn: RefCounted = pipeline.call("advance_month", state, chronicle, [], Fixture.content_index())
        if not bool(turn.get("passed")):
            failures.append("Phase F history month failed: " + JSON.stringify(turn.get("errors"))); return _result(failures, chronicle)
        state = turn.get("state"); chronicle = turn.get("chronicle"); expected[str(state.get("current_date"))] = HistoricalProjection.from_campaign_state(state)
    var current_before: Dictionary = CampaignStateCodec.new().encode(state)
    var target_date: String = "2001-07-01"
    var reconstructed: Dictionary = ChronicleQueryService.new().get_projection(chronicle, target_date)
    _expect(bool(reconstructed.get("passed", false)), "Checkpoint-plus-delta Phase F history must reconstruct.", failures)
    if bool(reconstructed.get("passed", false)):
        var projection: Dictionary = reconstructed.get("projection")
        _expect(projection == expected[target_date], "Reconstructed Phase F projection must exactly equal its recorded historical world.", failures)
        _expect((projection.get("contracts", {}) as Dictionary).size() >= 9, "Historical projection must retain contract identities and lifecycle state.", failures)
        _expect((projection.get("knowledge", {}) as Dictionary).size() == 3, "Historical projection must retain each promotion's accumulated knowledge.", failures)
        _expect((projection.get("promotion_relations", {}) as Dictionary).size() >= 3, "Historical projection must retain diplomacy trust and grievance state.", failures)
        _expect((projection.get("agreements", {}) as Dictionary).size() >= 1, "Historical projection must retain agreements without replaying diplomacy.", failures)
    _expect(CampaignStateCodec.new().encode(state) == current_before, "Historical reconstruction must be read-only against current Phase F state.", failures)
    _expect((chronicle.get("checkpoints") as Array).size() < 12 and (chronicle.get("deltas") as Array).size() > 0, "Chronicle must remain sparse checkpoint-plus-delta history.", failures)

    var expected_state: Dictionary = CampaignStateCodec.new().encode(state); var expected_chronicle: Dictionary = ChronicleCodec.new().encode(chronicle)
    var service: RefCounted = SaveService.new(); service.set("root_path", "user://phase_f_acceptance_saves")
    var saved: Dictionary = service.call("save", "phase_f_roundtrip", "Phase F Roundtrip", state, chronicle, {"created_utc": "fixture", "updated_utc": "fixture"})
    _expect(bool(saved.get("passed", false)), "Phase F state and Chronicle must save transactionally.", failures)
    if bool(saved.get("passed", false)):
        var loaded: Dictionary = service.call("load_save", "phase_f_roundtrip", state.get("content_fingerprint"))
        _expect(bool(loaded.get("passed", false)), "Published Phase F save must load.", failures)
        if bool(loaded.get("passed", false)):
            var loaded_state: Dictionary = CampaignStateCodec.new().encode(loaded.get("state"))
            var loaded_chronicle: Dictionary = ChronicleCodec.new().encode(loaded.get("chronicle"))
            _expect(loaded_state == expected_state, "Save/load must exactly preserve Phase F state, knowledge, contracts, AI state, and RNG checkpoint; first difference=" + JSON.stringify(_first_difference(expected_state, loaded_state)), failures)
            _expect(_semantic_equal(loaded_chronicle, expected_chronicle), "Save/load must preserve Phase F Chronicle meaning and head; first difference=" + JSON.stringify(_first_difference(expected_chronicle, loaded_chronicle)), failures)
    return _result(failures, chronicle)

func _result(failures: Array[String], chronicle: RefCounted) -> Dictionary:
    return {"name": "phase_f_chronicle_save", "passed": failures.is_empty(), "failures": failures, "chronicle_counts": chronicle.call("counts") if chronicle != null else {}, "reconstruction_dependencies": {"ai_planning": "unavailable", "commands": "not_replayed", "random_service": "unavailable", "simulation_resolution": "unavailable"}}

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

func _first_difference(left: Variant, right: Variant, path: String = "root") -> Dictionary:
    if typeof(left) != typeof(right): return {"path": path, "left": left, "right": right, "left_type": typeof(left), "right_type": typeof(right)}
    if left is Dictionary and right is Dictionary:
        for key: Variant in (left as Dictionary).keys():
            if not (right as Dictionary).has(key): return {"path": path + "." + str(key), "left": (left as Dictionary)[key], "right": "<missing>"}
            var child: Dictionary = _first_difference((left as Dictionary)[key], (right as Dictionary)[key], path + "." + str(key)); if not child.is_empty(): return child
        for key: Variant in (right as Dictionary).keys():
            if not (left as Dictionary).has(key): return {"path": path + "." + str(key), "left": "<missing>", "right": (right as Dictionary)[key]}
        return {}
    if left is Array and right is Array:
        if (left as Array).size() != (right as Array).size(): return {"path": path + ".size", "left": (left as Array).size(), "right": (right as Array).size()}
        for index: int in range((left as Array).size()):
            var child: Dictionary = _first_difference((left as Array)[index], (right as Array)[index], path + "[" + str(index) + "]"); if not child.is_empty(): return child
        return {}
    if (left is int or left is float) and (right is int or right is float):
        if float(left) != float(right): return {"path": path, "left": left, "right": right}
    elif left != right: return {"path": path, "left": left, "right": right}
    return {}

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition: failures.append(message)
