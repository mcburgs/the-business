extends RefCounted

var id: String = ""
var promotion_id: String = ""
var medium_id: String = ""
var outlet_id: String = ""
var status: String = "active"
var reach_market_ids: Array = []
var start_date: String = ""
var end_date: Variant = null
var schedule_id: String = ""
var cost: Variant = null
var revenue: Variant = null
var exclusivity_id: Variant = null
var production_requirement_ids: Array = []
var restriction_ids: Array = []

func to_dict() -> Dictionary:
    return {
        "id": id,
        "promotion_id": promotion_id,
        "medium_id": medium_id,
        "outlet_id": outlet_id,
        "status": status,
        "reach_market_ids": reach_market_ids.duplicate(true),
        "start_date": start_date,
        "end_date": end_date,
        "schedule_id": schedule_id,
        "cost": cost,
        "revenue": revenue,
        "exclusivity_id": exclusivity_id,
        "production_requirement_ids": production_requirement_ids.duplicate(true),
        "restriction_ids": restriction_ids.duplicate(true),
    }
