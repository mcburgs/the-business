extends RefCounted

const DomainIds = preload("res://domain/core/domain_ids.gd")

const SCHEMA_VERSION: int = 1

static func from_campaign_state(state: RefCounted, date_value: String = "") -> Dictionary:
    var date: String = date_value if not date_value.is_empty() else str(state.get("current_date"))
    var projection: Dictionary = {
        "schema_version": SCHEMA_VERSION,
        "date": date,
        "promotions": {},
        "championships": {},
        "markets": {},
        "agreements": {},
        "media_footprints": {},
        "identity_refs": {},
    }
    var contracts: Dictionary = state.get("contracts")
    for promotion_id: String in DomainIds.sorted_keys(state.get("promotions")):
        var promotion: RefCounted = (state.get("promotions") as Dictionary)[promotion_id]
        var roster: Array[String] = []
        for contract_id: Variant in promotion.get("contract_ids"):
            if contracts.has(str(contract_id)):
                var contract: RefCounted = contracts[str(contract_id)]
                if str(contract.get("status")) == "active": roster.append(str(contract.get("person_id")))
        roster.sort()
        projection["promotions"][promotion_id] = {
            "lifecycle": str(promotion.get("lifecycle")),
            "brand_name": str(promotion.get("brand_name")),
            "owner_person_id": promotion.get("controlling_owner_person_id"),
            "roster_person_ids": roster,
            "prestige": float(promotion.get("prestige")),
            "momentum": float(promotion.get("momentum")),
            "current_hot_state": _copy_variant(promotion.get("current_hot_state")),
        }
        projection["identity_refs"][promotion_id] = {"family": "promotion", "display_name": str(promotion.get("brand_name")), "lifecycle": str(promotion.get("lifecycle"))}
    for person_id: String in DomainIds.sorted_keys(state.get("people")):
        var person: RefCounted = (state.get("people") as Dictionary)[person_id]
        projection["identity_refs"][person_id] = {"family": "person", "display_name": str(person.get("display_name")), "lifecycle": str(person.get("lifecycle"))}
    for championship_id: String in DomainIds.sorted_keys(state.get("championships")):
        var championship: RefCounted = (state.get("championships") as Dictionary)[championship_id]
        projection["championships"][championship_id] = {
            "promotion_id": str(championship.get("promotion_id")),
            "status": str(championship.get("status")),
            "prestige": float(championship.get("prestige")),
            "holder_person_ids": (championship.get("holder_person_ids") as Array).duplicate(),
            "recognition_market_ids": (championship.get("recognition_market_ids") as Array).duplicate(),
        }
        projection["identity_refs"][championship_id] = {"family": "championship", "display_name": str(championship.get("definition_id")), "lifecycle": str(championship.get("status"))}
    for market_id: String in DomainIds.sorted_keys(state.get("markets")):
        var market: RefCounted = (state.get("markets") as Dictionary)[market_id]
        projection["markets"][market_id] = {
            "wrestling_interest": float(market.get("wrestling_interest")),
            "influence_by_promotion": (market.get("influence_by_promotion") as Dictionary).duplicate(true),
            "current_hot_state": _copy_variant(market.get("current_hot_state")),
        }
        projection["identity_refs"][market_id] = {"family": "market", "display_name": market_id, "lifecycle": "active"}
    for agreement_id: String in DomainIds.sorted_keys(state.get("agreements")):
        var agreement: RefCounted = (state.get("agreements") as Dictionary)[agreement_id]
        projection["agreements"][agreement_id] = {
            "status": str(agreement.get("status")),
            "party_promotion_ids": (agreement.get("party_promotion_ids") as Array).duplicate(),
            "clauses": (agreement.get("clauses") as Array).duplicate(true),
        }
        projection["identity_refs"][agreement_id] = {"family": "agreement", "display_name": agreement_id, "lifecycle": str(agreement.get("status"))}
    for deal_id: String in DomainIds.sorted_keys(state.get("media_deals")):
        var deal: RefCounted = (state.get("media_deals") as Dictionary)[deal_id]
        projection["media_footprints"][deal_id] = {
            "promotion_id": str(deal.get("promotion_id")),
            "medium_id": str(deal.get("medium_id")),
            "outlet_id": str(deal.get("outlet_id")),
            "status": str(deal.get("status")),
            "reach_market_ids": (deal.get("reach_market_ids") as Array).duplicate(),
        }
        projection["identity_refs"][deal_id] = {"family": "media_deal", "display_name": deal_id, "lifecycle": str(deal.get("status"))}
    return projection

static func _copy_variant(value: Variant) -> Variant:
    if value is Dictionary: return (value as Dictionary).duplicate(true)
    if value is Array: return (value as Array).duplicate(true)
    return value
