extends RefCounted

var promotion_id: String = ""
var transition_pending: bool = false

func to_dict() -> Dictionary:
    return {
        "promotion_id": promotion_id,
        "transition_pending": transition_pending,
    }
