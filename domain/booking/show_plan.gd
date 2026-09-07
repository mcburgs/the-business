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
var booking_quality: float = 0.0
var coherence: float = 0.0
var travel_pressure: float = 0.0
var market_context: Dictionary = {}
var causal_factors: Array = []

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
        "booking_quality": booking_quality,
        "coherence": coherence,
        "travel_pressure": travel_pressure,
        "market_context": market_context.duplicate(true),
        "causal_factors": causal_factors.duplicate(true),
    }
