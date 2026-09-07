extends RefCounted

var id: String = ""
var person_id: String = ""
var promotion_id: String = ""
var status: String = "active"
var start_date: String = ""
var end_date: Variant = null
var compensation: Dictionary = {}
var exclusivity_id: String = ""
var clause_ids: Array = []
var clause_parameters: Dictionary = {}
var leverage: float = 0.0
var dispute_state_id: Variant = null

func to_dict() -> Dictionary:
    return {
        "id": id,
        "person_id": person_id,
        "promotion_id": promotion_id,
        "status": status,
        "start_date": start_date,
        "end_date": end_date,
        "compensation": compensation.duplicate(true),
        "exclusivity_id": exclusivity_id,
        "clause_ids": clause_ids.duplicate(true),
        "clause_parameters": clause_parameters.duplicate(true),
        "leverage": leverage,
        "dispute_state_id": dispute_state_id,
    }
