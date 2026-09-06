extends RefCounted

var status: String = "ongoing"
var outcome_id: Variant = null
var details: Dictionary = {}

func to_dict() -> Dictionary:
    return {
        "status": status,
        "outcome_id": outcome_id,
        "details": details.duplicate(true),
    }
