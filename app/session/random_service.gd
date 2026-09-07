extends RefCounted

const RandomState = preload("res://domain/core/random_state.gd")

const PROVIDER_ID: String = "godot.random_number_generator"
const STREAM_POLICY: String = "single_root_v1"

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _seed: int = 0
var _diagnostic_tags: Array[String] = []

func _init(seed_value: int = 0) -> void:
    reset(seed_value)

func reset(seed_value: int) -> void:
    _seed = seed_value
    _rng.seed = seed_value
    _diagnostic_tags.clear()

func restore(state: RefCounted) -> Dictionary:
    if str(state.get("provider_id")) != PROVIDER_ID:
        return {"passed": false, "errors": [{"code": "STATE001", "path": "rng_state.provider_id", "localization_key": "validation.state001", "details": {"provider_id": state.get("provider_id")}}]}
    if str(state.get("stream_policy")) != STREAM_POLICY:
        return {"passed": false, "errors": [{"code": "STATE001", "path": "rng_state.stream_policy", "localization_key": "validation.state001", "details": {"stream_policy": state.get("stream_policy")}}]}
    _seed = int(state.get("seed"))
    _rng.seed = _seed
    _rng.state = int(state.get("internal_state"))
    _diagnostic_tags.clear()
    return {"passed": true, "errors": []}

func draw_float(tag: String = "") -> float:
    _record_tag(tag)
    return _rng.randf()

func draw_int_range(minimum: int, maximum: int, tag: String = "") -> int:
    _record_tag(tag)
    return _rng.randi_range(minimum, maximum)

func capture(captured_turn: int) -> RefCounted:
    var state: RefCounted = RandomState.new()
    state.set("provider_id", PROVIDER_ID)
    state.set("seed", _seed)
    state.set("internal_state", _rng.state)
    state.set("captured_turn", captured_turn)
    state.set("stream_policy", STREAM_POLICY)
    return state

func diagnostic_tags() -> Array[String]:
    return _diagnostic_tags.duplicate()

func _record_tag(tag: String) -> void:
    if not tag.is_empty():
        _diagnostic_tags.append(tag)
