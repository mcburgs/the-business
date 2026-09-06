extends RefCounted

var region_id: String = ""
var current_hot_state: Variant = null
var active_effect_ids: Array = []

func to_dict() -> Dictionary:
    return {
        "region_id": region_id,
        "current_hot_state": current_hot_state,
        "active_effect_ids": active_effect_ids.duplicate(true),
    }
