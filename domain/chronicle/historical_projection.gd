extends RefCounted

const DomainIds = preload("res://domain/core/domain_ids.gd")

const SCHEMA_VERSION: int = 1

static func from_campaign_state(state: RefCounted, date_value: String = "") -> Dictionary:
    var date: String = date_value if not date_value.is_empty() else str(state.get("current_date"))
    var projection: Dictionary = {
        "schema_version": SCHEMA_VERSION,
        "date": date,
        "ownership_seat": (state.get("ownership_seat") as RefCounted).call("to_dict"),
        "promotions": {},
        "contracts": {},
        "knowledge": {},
        "promotion_relations": (state.get("world_state") as Dictionary).get("promotion_relations_v1", {}).duplicate(true),
        "people_audience": {},
        "touring_companies": {},
        "programs": {},
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
            "cash": (promotion.get("cash") as Dictionary).duplicate(true),
            "financial_stress": float((state.get("world_state") as Dictionary).get("financial_stress_by_promotion", {}).get(promotion_id, 0.0)),
            "current_hot_state": _copy_variant(promotion.get("current_hot_state")),
        }
        projection["identity_refs"][promotion_id] = {"family": "promotion", "display_name": str(promotion.get("brand_name")), "lifecycle": str(promotion.get("lifecycle"))}
    for person_id: String in DomainIds.sorted_keys(state.get("people")):
        var person: RefCounted = (state.get("people") as Dictionary)[person_id]
        projection["people_audience"][person_id] = {
            "audience_by_market": (person.get("audience_by_market") as Dictionary).duplicate(true),
            "current_hot_state": _copy_variant(person.get("current_hot_state")),
        }
        projection["identity_refs"][person_id] = {"family": "person", "display_name": str(person.get("display_name")), "lifecycle": str(person.get("lifecycle"))}
    for contract_id: String in DomainIds.sorted_keys(state.get("contracts")):
        var contract: RefCounted = (state.get("contracts") as Dictionary)[contract_id]
        projection["contracts"][contract_id] = {
            "person_id": str(contract.get("person_id")),
            "promotion_id": str(contract.get("promotion_id")),
            "status": str(contract.get("status")),
            "start_date": str(contract.get("start_date")),
            "end_date": contract.get("end_date"),
            "compensation": (contract.get("compensation") as Dictionary).duplicate(true),
            "exclusivity_id": str(contract.get("exclusivity_id")),
        }
        projection["identity_refs"][contract_id] = {"family": "contract", "display_name": contract_id, "lifecycle": str(contract.get("status"))}
    for owner_id: String in DomainIds.sorted_keys(state.get("knowledge_bases")):
        var knowledge: RefCounted = (state.get("knowledge_bases") as Dictionary)[owner_id]
        projection["knowledge"][owner_id] = {"observations": (knowledge.get("observations") as Array).duplicate(true), "familiarity_by_subject": (knowledge.get("familiarity_by_subject") as Dictionary).duplicate(true)}
    for company_id: String in DomainIds.sorted_keys(state.get("touring_companies")):
        var company: RefCounted = (state.get("touring_companies") as Dictionary)[company_id]
        projection["touring_companies"][company_id] = {
            "promotion_id": str(company.get("promotion_id")),
            "status": str(company.get("status")),
            "person_assignment_ids": (company.get("person_assignment_ids") as Array).duplicate(),
            "carried_championship_ids": (company.get("carried_championship_ids") as Array).duplicate(),
            "route": (company.get("route") as Array).duplicate(true),
            "directives": (company.get("directives") as Array).duplicate(true),
            "monthly_budget": (company.get("monthly_budget") as Dictionary).duplicate(true),
            "fatigue_pressure": float(company.get("fatigue_pressure")),
            "cohesion": float(company.get("cohesion")),
            "current_hot_state": _copy_variant(company.get("current_hot_state")),
        }
        projection["identity_refs"][company_id] = {"family": "touring", "display_name": str(company.get("name")), "lifecycle": str(company.get("status"))}
    for program_id: String in DomainIds.sorted_keys(state.get("programs")):
        var program: RefCounted = (state.get("programs") as Dictionary)[program_id]
        projection["programs"][program_id] = {
            "promotion_id": str(program.get("promotion_id")),
            "status": str(program.get("status")),
            "side_a": (program.get("side_a") as Dictionary).duplicate(true),
            "side_b": (program.get("side_b") as Dictionary).duplicate(true),
            "purpose_id": str(program.get("purpose_id")),
            "phase_id": str(program.get("phase_id")),
            "heat": float(program.get("heat")),
            "momentum": float(program.get("momentum")),
            "objective_ids": (program.get("objective_ids") as Array).duplicate(),
            "planned_direction_id": program.get("planned_direction_id"),
            "current_hot_state": _copy_variant(program.get("current_hot_state")),
        }
        projection["identity_refs"][program_id] = {"family": "program", "display_name": program_id, "lifecycle": str(program.get("status"))}
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
            "trust_effect": float(agreement.get("trust_effect")),
            "last_violation_event_id": agreement.get("last_violation_event_id"),
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
