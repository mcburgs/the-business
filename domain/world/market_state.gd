extends RefCounted

var market_id: String = ""
var wrestling_interest: float = 0.0
var economic_strength: float = 0.0
var influence_by_promotion: Dictionary = {}
var current_hot_state: Variant = null
var active_effect_ids: Array = []

func to_dict() -> Dictionary:
    return {
        "market_id": market_id,
        "wrestling_interest": wrestling_interest,
        "economic_strength": economic_strength,
        "influence_by_promotion": influence_by_promotion.duplicate(true),
        "current_hot_state": current_hot_state,
        "active_effect_ids": active_effect_ids.duplicate(true),
    }
