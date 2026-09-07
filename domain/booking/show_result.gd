extends RefCounted

var show_id: String = ""
var promotion_id: String = ""
var touring_company_id: String = ""
var market_id: String = ""
var participant_person_ids: Array = []
var featured_person_id: Variant = null
var featured_program_id: Variant = null
var featured_championship_id: Variant = null
var approved_major_outcome: Dictionary = {}
var show_quality: float = 0.0
var crowd_response: float = 0.0
var attendance: int = 0
var gate_minor_units: int = 0
var person_effects: Dictionary = {}
var program_effect: Dictionary = {}
var notable_incidents: Array = []
var causal_factors: Array = []
var travel_pressure: float = 0.0

func to_dict() -> Dictionary:
    return {
        "show_id": show_id,
        "promotion_id": promotion_id,
        "touring_company_id": touring_company_id,
        "market_id": market_id,
        "participant_person_ids": participant_person_ids.duplicate(),
        "featured_person_id": featured_person_id,
        "featured_program_id": featured_program_id,
        "featured_championship_id": featured_championship_id,
        "approved_major_outcome": approved_major_outcome.duplicate(true),
        "show_quality": show_quality,
        "crowd_response": crowd_response,
        "attendance": attendance,
        "gate_minor_units": gate_minor_units,
        "person_effects": person_effects.duplicate(true),
        "program_effect": program_effect.duplicate(true),
        "notable_incidents": notable_incidents.duplicate(true),
        "causal_factors": causal_factors.duplicate(true),
        "travel_pressure": travel_pressure,
    }
