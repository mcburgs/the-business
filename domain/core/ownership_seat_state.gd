extends RefCounted

var promotion_id: String = ""
var owner_person_id: String = ""
var transition_pending: bool = false

func to_dict() -> Dictionary:
    return {
        "promotion_id": promotion_id,
        "owner_person_id": owner_person_id,
        "transition_pending": transition_pending,
    }
