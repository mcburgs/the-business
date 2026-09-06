extends RefCounted

var id: String = ""
var person_a_id: String = ""
var person_b_id: String = ""
var strength: float = 0.0
var trust: float = 0.0
var grievance: float = 0.0
var tag_ids: Array = []

func to_dict() -> Dictionary:
    return {
        "id": id,
        "person_a_id": person_a_id,
        "person_b_id": person_b_id,
        "strength": strength,
        "trust": trust,
        "grievance": grievance,
        "tag_ids": tag_ids.duplicate(true),
    }
