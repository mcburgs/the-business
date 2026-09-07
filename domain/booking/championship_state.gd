extends RefCounted

var id: String = ""
var promotion_id: String = ""
var definition_id: String = ""
var status: String = "active"
var prestige: float = 0.0
var holder_person_ids: Array = []
var recognition_market_ids: Array = []
var recognition_promotion_ids: Array = []
var last_change_event_id: Variant = null

func to_dict() -> Dictionary:
    return {
        "id": id,
        "promotion_id": promotion_id,
        "definition_id": definition_id,
        "status": status,
        "prestige": prestige,
        "holder_person_ids": holder_person_ids.duplicate(true),
        "recognition_market_ids": recognition_market_ids.duplicate(true),
        "recognition_promotion_ids": recognition_promotion_ids.duplicate(true),
        "last_change_event_id": last_change_event_id,
    }
