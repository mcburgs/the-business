extends RefCounted

var provider_id: String = "godot.random_number_generator"
var seed: int = 0
var internal_state: int = 0
var captured_turn: int = 0
var stream_policy: String = "single_root_v1"

func to_dict() -> Dictionary:
    return {
        "provider_id": provider_id,
        "seed": seed,
        "internal_state": internal_state,
        "captured_turn": captured_turn,
        "stream_policy": stream_policy,
    }
