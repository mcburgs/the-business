extends RefCounted

var id: String = ""
var seed_definition_id: Variant = null
var lifecycle: String = "active"
var brand_name: String = ""
var controlling_owner_person_id: Variant = null
var ownership_model_id: Variant = null
var ownership_shares: Array = []
var cash: Dictionary = {"minor_units": 0, "currency_id": ""}
var prestige: float = 0.0
var locker_room_morale: float = 0.0
var momentum: float = 0.0
var home_market_ids: Array = []
var contract_ids: Array = []
var touring_company_ids: Array = []
var championship_ids: Array = []
var program_ids: Array = []
var media_deal_ids: Array = []
var agreement_ids: Array = []
var strategy_profile_id: Variant = null
var active_effect_ids: Array = []
var current_hot_state: Variant = null

func to_dict() -> Dictionary:
    return {
        "id": id,
        "seed_definition_id": seed_definition_id,
        "lifecycle": lifecycle,
        "brand_name": brand_name,
        "controlling_owner_person_id": controlling_owner_person_id,
        "ownership_model_id": ownership_model_id,
        "ownership_shares": ownership_shares.duplicate(true),
        "cash": cash.duplicate(true),
        "prestige": prestige,
        "locker_room_morale": locker_room_morale,
        "momentum": momentum,
        "home_market_ids": home_market_ids.duplicate(true),
        "contract_ids": contract_ids.duplicate(true),
        "touring_company_ids": touring_company_ids.duplicate(true),
        "championship_ids": championship_ids.duplicate(true),
        "program_ids": program_ids.duplicate(true),
        "media_deal_ids": media_deal_ids.duplicate(true),
        "agreement_ids": agreement_ids.duplicate(true),
        "strategy_profile_id": strategy_profile_id,
        "active_effect_ids": active_effect_ids.duplicate(true),
        "current_hot_state": current_hot_state,
    }
