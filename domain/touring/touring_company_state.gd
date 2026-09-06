extends RefCounted

var id: String = ""
var promotion_id: String = ""
var name: String = ""
var person_assignment_ids: Array = []
var carried_championship_ids: Array = []
var route: Array = []
var directives: Array = []
var monthly_budget: Dictionary = {"minor_units": 0, "currency_id": ""}
var fatigue_pressure: float = 0.0
var cohesion: float = 0.0
var current_hot_state: Variant = null
var status: String = "active"

func to_dict() -> Dictionary:
    return {
        "id": id,
        "promotion_id": promotion_id,
        "name": name,
        "person_assignment_ids": person_assignment_ids.duplicate(true),
        "carried_championship_ids": carried_championship_ids.duplicate(true),
        "route": route.duplicate(true),
        "directives": directives.duplicate(true),
        "monthly_budget": monthly_budget.duplicate(true),
        "fatigue_pressure": fatigue_pressure,
        "cohesion": cohesion,
        "current_hot_state": current_hot_state,
        "status": status,
    }
