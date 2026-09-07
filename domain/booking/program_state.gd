extends RefCounted

var id: String = ""
var promotion_id: String = ""
var status: String = "active"
var started_on: String = ""
var ended_on: Variant = null
var side_a: Dictionary = {}
var side_b: Dictionary = {}
var purpose_id: String = ""
var phase_id: String = ""
var heat: float = 0.0
var momentum: float = 0.0
var objective_ids: Array = []
var planned_direction_id: Variant = null
var chemistry_truth: Variant = null
var current_hot_state: Variant = null

func to_dict() -> Dictionary:
    return {
        "id": id,
        "promotion_id": promotion_id,
        "status": status,
        "started_on": started_on,
        "ended_on": ended_on,
        "side_a": side_a.duplicate(true),
        "side_b": side_b.duplicate(true),
        "purpose_id": purpose_id,
        "phase_id": phase_id,
        "heat": heat,
        "momentum": momentum,
        "objective_ids": objective_ids.duplicate(true),
        "planned_direction_id": planned_direction_id,
        "chemistry_truth": chemistry_truth,
        "current_hot_state": current_hot_state,
    }
