extends RefCounted

const DomainIds = preload("res://domain/core/domain_ids.gd")
const KnowledgeQueryService = preload("res://app/queries/knowledge_query_service.gd")

var _knowledge_query: RefCounted = KnowledgeQueryService.new()

func build(state: RefCounted, promotion_id: String) -> Dictionary:
    var promotions: Dictionary = state.get("promotions")
    if not promotions.has(promotion_id):
        return {}
    var promotion: RefCounted = promotions[promotion_id]
    var contracts: Dictionary = state.get("contracts")
    var people: Dictionary = state.get("people")
    var own_contracts: Array[Dictionary] = []
    var own_people: Dictionary = {}
    var employed_by: Dictionary = {}
    for contract_id: String in DomainIds.sorted_keys(contracts):
        var contract: RefCounted = contracts[contract_id]
        if str(contract.get("status")) == "active":
            employed_by[str(contract.get("person_id"))] = str(contract.get("promotion_id"))
        if str(contract.get("promotion_id")) == promotion_id and str(contract.get("status")) == "active":
            var person_id: String = str(contract.get("person_id"))
            own_contracts.append({
                "contract_id": contract_id,
                "person_id": person_id,
                "end_date": contract.get("end_date"),
                "compensation": (contract.get("compensation") as Dictionary).duplicate(true),
                "leverage": float(contract.get("leverage")),
            })
            if people.has(person_id):
                var person: RefCounted = people[person_id]
                own_people[person_id] = {
                    "skills": (person.get("skills") as Dictionary).duplicate(true),
                    "traits": (person.get("traits") as Dictionary).duplicate(true),
                    "audience_by_market": (person.get("audience_by_market") as Dictionary).duplicate(true),
                    "career": (person.get("career") as Dictionary).duplicate(true),
                }
    var knowledge_base: Variant = (state.get("knowledge_bases") as Dictionary).get(promotion_id, null)
    var external_talent: Array[Dictionary] = []
    for person_id: String in DomainIds.sorted_keys(people):
        if own_people.has(person_id):
            continue
        external_talent.append({
            "person_id": person_id,
            "employer_promotion_id": employed_by.get(person_id, null),
            "performance": _projection(knowledge_base, person_id, "skill.performance"),
            "local_value": _projection(knowledge_base, person_id, "talent.local_value"),
            "contract_demand": _projection(knowledge_base, person_id, "contract.demand_minor_units"),
        })
    var companies: Array[Dictionary] = []
    for company_id: String in DomainIds.sorted_keys(state.get("touring_companies")):
        var company: RefCounted = (state.get("touring_companies") as Dictionary)[company_id]
        if str(company.get("promotion_id")) == promotion_id and str(company.get("status")) == "active":
            companies.append({
                "touring_company_id": company_id,
                "route": (company.get("route") as Array).duplicate(true),
                "person_assignment_ids": (company.get("person_assignment_ids") as Array).duplicate(),
                "monthly_budget": (company.get("monthly_budget") as Dictionary).duplicate(true),
                "fatigue_pressure": float(company.get("fatigue_pressure")),
            })
    var markets: Dictionary = {}
    for market_id: String in DomainIds.sorted_keys(state.get("markets")):
        var market: RefCounted = (state.get("markets") as Dictionary)[market_id]
        markets[market_id] = {
            "wrestling_interest": float(market.get("wrestling_interest")),
            "economic_strength": float(market.get("economic_strength")),
            "influence_by_promotion": (market.get("influence_by_promotion") as Dictionary).duplicate(true),
        }
    var agreements: Array[Dictionary] = []
    for agreement_id: String in DomainIds.sorted_keys(state.get("agreements")):
        var agreement: RefCounted = (state.get("agreements") as Dictionary)[agreement_id]
        agreements.append({
            "agreement_id": agreement_id,
            "status": str(agreement.get("status")),
            "party_promotion_ids": (agreement.get("party_promotion_ids") as Array).duplicate(),
            "clauses": (agreement.get("clauses") as Array).duplicate(true),
            "trust_effect": float(agreement.get("trust_effect")),
        })
    var world_state: Dictionary = state.get("world_state")
    return {
        "promotion_id": promotion_id,
        "turn_number": int(state.get("turn_number")),
        "current_date": str(state.get("current_date")),
        "cash": (promotion.get("cash") as Dictionary).duplicate(true),
        "prestige": float(promotion.get("prestige")),
        "momentum": float(promotion.get("momentum")),
        "home_market_ids": (promotion.get("home_market_ids") as Array).duplicate(),
        "strategy_profile_id": promotion.get("strategy_profile_id"),
        "financial_stress": float(world_state.get("financial_stress_by_promotion", {}).get(promotion_id, 0.0)),
        "market_focus": (world_state.get("market_focus_by_promotion", {}).get(promotion_id, {}) as Dictionary).duplicate(true) if world_state.get("market_focus_by_promotion", {}).get(promotion_id, {}) is Dictionary else {},
        "own_contracts": own_contracts,
        "pending_negotiations": _pending_negotiations(world_state, promotion_id),
        "own_people": own_people,
        "external_talent": external_talent,
        "companies": companies,
        "markets": markets,
        "agreements": agreements,
        "promotion_ids": DomainIds.sorted_keys(promotions),
        "promotion_relations": (world_state.get("promotion_relations_v1", {}) as Dictionary).duplicate(true),
        "active_programs": _active_programs(state, promotion_id),
        "championships": _championships(state, promotion_id),
    }

func _pending_negotiations(world_state: Dictionary, promotion_id: String) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    var negotiations: Variant = world_state.get("contract_negotiations_v1", {})
    if not negotiations is Dictionary: return output
    for contract_id: String in DomainIds.sorted_keys(negotiations):
        var value: Variant = (negotiations as Dictionary)[contract_id]
        if value is Dictionary and str((value as Dictionary).get("promotion_id")) == promotion_id:
            output.append({"contract_id": contract_id, "person_id": (value as Dictionary).get("person_id"), "counter_minor_units": int((value as Dictionary).get("counter_minor_units", 0)), "proposal": ((value as Dictionary).get("proposal", {}) as Dictionary).duplicate(true)})
    return output

func _projection(knowledge_base: Variant, subject_id: String, field_id: String) -> Dictionary:
    if not knowledge_base is RefCounted:
        return {"status": "unknown", "confidence": 0.0}
    var projected: RefCounted = _knowledge_query.call("project_field", knowledge_base, subject_id, field_id)
    return projected.call("to_dict")

func _active_programs(state: RefCounted, promotion_id: String) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    for program_id: String in DomainIds.sorted_keys(state.get("programs")):
        var program: RefCounted = (state.get("programs") as Dictionary)[program_id]
        if str(program.get("promotion_id")) == promotion_id and str(program.get("status")) == "active":
            output.append({"program_id": program_id, "heat": float(program.get("heat")), "momentum": float(program.get("momentum"))})
    return output

func _championships(state: RefCounted, promotion_id: String) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    for championship_id: String in DomainIds.sorted_keys(state.get("championships")):
        var championship: RefCounted = (state.get("championships") as Dictionary)[championship_id]
        if str(championship.get("promotion_id")) == promotion_id:
            output.append({"championship_id": championship_id, "holder_person_ids": (championship.get("holder_person_ids") as Array).duplicate(), "prestige": float(championship.get("prestige"))})
    return output
