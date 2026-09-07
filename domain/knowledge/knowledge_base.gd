extends RefCounted

var owner_promotion_id: String = ""
var observations: Array = []
var familiarity_by_subject: Dictionary = {}

func to_dict() -> Dictionary:
    return {
        "owner_promotion_id": owner_promotion_id,
        "observations": observations.duplicate(true),
        "familiarity_by_subject": familiarity_by_subject.duplicate(true),
    }
