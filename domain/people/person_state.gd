extends RefCounted

var id: String = ""
var seed_definition_id: Variant = null
var lifecycle: String = "active"
var legal_name: String = ""
var display_name: String = ""
var ring_name: Variant = null
var birth_date: String = ""
var pronoun_set_id: String = ""
var home_region_id: Variant = null
var tag_ids: Array = []
var skills: Dictionary = {}
var traits: Dictionary = {}
var potential: Dictionary = {}
var roles: Array = []
var health: Dictionary = {}
var relationship_ids: Array = []
var audience_by_market: Dictionary = {}
var career: Dictionary = {}
var active_contract_ids: Array = []
var current_hot_state: Variant = null

func to_dict() -> Dictionary:
    return {
        "id": id,
        "seed_definition_id": seed_definition_id,
        "lifecycle": lifecycle,
        "legal_name": legal_name,
        "display_name": display_name,
        "ring_name": ring_name,
        "birth_date": birth_date,
        "pronoun_set_id": pronoun_set_id,
        "home_region_id": home_region_id,
        "tag_ids": tag_ids.duplicate(true),
        "skills": skills.duplicate(true),
        "traits": traits.duplicate(true),
        "potential": potential.duplicate(true),
        "roles": roles.duplicate(true),
        "health": health.duplicate(true),
        "relationship_ids": relationship_ids.duplicate(true),
        "audience_by_market": audience_by_market.duplicate(true),
        "career": career.duplicate(true),
        "active_contract_ids": active_contract_ids.duplicate(true),
        "current_hot_state": current_hot_state,
    }
