extends RefCounted

var id: String = ""
var party_promotion_ids: Array = []
var status: String = "active"
var start_date: String = ""
var end_date: Variant = null
var clause_ids: Array = []
var clauses: Array = []
var trust_effect: float = 0.0
var last_violation_event_id: Variant = null

func to_dict() -> Dictionary:
    return {
        "id": id,
        "party_promotion_ids": party_promotion_ids.duplicate(true),
        "status": status,
        "start_date": start_date,
        "end_date": end_date,
        "clause_ids": clause_ids.duplicate(true),
        "clauses": clauses.duplicate(true),
        "trust_effect": trust_effect,
        "last_violation_event_id": last_violation_event_id,
    }
