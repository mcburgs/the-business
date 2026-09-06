extends RefCounted

var venue_id: String = ""
var availability_state: String = "available"
var relationship_by_promotion: Dictionary = {}
var active_restriction_ids: Array = []

func to_dict() -> Dictionary:
    return {
        "venue_id": venue_id,
        "availability_state": availability_state,
        "relationship_by_promotion": relationship_by_promotion.duplicate(true),
        "active_restriction_ids": active_restriction_ids.duplicate(true),
    }
