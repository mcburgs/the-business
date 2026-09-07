extends RefCounted

const PhaseEFixture = preload("res://tests/helpers/phase_e_fixture.gd")
const PersonState = preload("res://domain/people/person_state.gd")
const PromotionState = preload("res://domain/promotions/promotion_state.gd")
const MarketState = preload("res://domain/world/market_state.gd")
const TouringCompanyState = preload("res://domain/touring/touring_company_state.gd")
const ContractState = preload("res://domain/people/contract_state.gd")
const ChampionshipState = preload("res://domain/booking/championship_state.gd")
const MediaDealState = preload("res://domain/media/media_deal_state.gd")
const KnowledgeBase = preload("res://domain/knowledge/knowledge_base.gd")
const PhaseEMath = preload("res://domain/core/phase_e_math.gd")

const PROMOTION_A := "promotion:PRO00001"
const PROMOTION_B := "promotion:PRO00002"
const PROMOTION_C := "promotion:PRO00003"
const MARKET_A := "market.fixture_a"
const MARKET_B := "market.fixture_b"
const MARKET_C := "market.fixture_c"
const UNSIGNED_STAR := "person:PER00010"
const UNSIGNED_PROSPECT := "person:PER00011"

static func tuning() -> Dictionary:
    return {
        "strategy_profiles": {
            "strategy.balanced": {"expansion": 0.58, "defense": 0.58, "creative": 0.62, "talent_aggression": 0.56, "loyalty": 0.60, "favorite_bias": 0.05, "cost_sensitivity": 0.55, "diplomacy": 0.50, "decision_noise": 0.025},
            "strategy.expansionist": {"expansion": 0.90, "defense": 0.28, "creative": 0.55, "talent_aggression": 0.82, "loyalty": 0.42, "favorite_bias": 0.12, "cost_sensitivity": 0.25, "diplomacy": 0.35, "decision_noise": 0.045},
            "strategy.defensive": {"expansion": 0.30, "defense": 0.92, "creative": 0.48, "talent_aggression": 0.40, "loyalty": 0.84, "favorite_bias": 0.18, "cost_sensitivity": 0.82, "diplomacy": 0.75, "decision_noise": 0.015},
        },
        "decision_noise_strength": 0.03,
        "recovery_stress_threshold": 0.58,
        "recovery_cash_threshold_minor_units": 220000,
        "recovery_minimum_touring_budget_minor_units": 45000,
        "recovery_budget_ratio": 0.62,
        "talent_roster_target": 4,
        "minimum_roster_size": 2,
        "renewal_window_months": 3,
        "default_contract_offer_minor_units": 12000,
        "scouting_familiarity_gain": 0.16,
        "default_scouting_quality": 0.58,
        "scouting_base_error": 0.28,
        "scouting_minimum_error": 0.025,
        "agreement_proposal_trust_threshold": 0.22,
        "agreement_acceptance_threshold": -0.05,
    }

static func content_index() -> Dictionary:
    var index: Dictionary = PhaseEFixture.content_index().duplicate(true)
    index["markets"][MARKET_C] = true
    index["phase_f_tuning"] = tuning()
    index["phase_f_ai_controlled_promotions"] = {PROMOTION_A: "automation", PROMOTION_B: "ai", PROMOTION_C: "ai"}
    index["promotion_strategies"] = {"strategy.balanced": true, "strategy.expansionist": true, "strategy.defensive": true}
    index["travel_connections"] = {
        MARKET_A + "|" + MARKET_B: {"base_cost_index": 0.48},
        MARKET_B + "|" + MARKET_C: {"base_cost_index": 0.36},
        MARKET_A + "|" + MARKET_C: {"base_cost_index": 0.62},
    }
    return index

static func make_chronicle(checkpoint_cadence_months: int = 6) -> RefCounted:
    return PhaseEFixture.make_chronicle(checkpoint_cadence_months)

static func make_state(seed: int = 424242, strategy_rotation: int = 0) -> RefCounted:
    var state: RefCounted = PhaseEFixture.make_state(seed)
    var people: Dictionary = state.get("people")
    _configure_person(people["person:PER00001"], 16000, 0.74)
    _configure_person(people["person:PER00002"], 11000, 0.48)
    _configure_person(people["person:PER00003"], 12500, 0.61)
    _configure_person(people["person:PER00004"], 9000, 0.35)

    people["person:PER00005"] = _person("person:PER00005", "Boreal Ace", 0.78, 0.75, 0.70, 14500, "contract:CON00005", {MARKET_A: 0.22, MARKET_B: 0.57, MARKET_C: 0.24})
    people["person:PER00006"] = _person("person:PER00006", "Boreal Booker", 0.61, 0.66, 0.54, 9200, "contract:CON00006", {MARKET_A: 0.12, MARKET_B: 0.31, MARKET_C: 0.18}, {"skill.booking": 0.76, "skill.road_agenting": 0.74})
    people["person:PER00007"] = _person("person:PER00007", "Crown Owner", 0.55, 0.62, 0.64, 10000, "contract:CON00007", {MARKET_A: 0.13, MARKET_B: 0.22, MARKET_C: 0.42})
    people["person:PER00008"] = _person("person:PER00008", "Crown Standard", 0.80, 0.72, 0.81, 15000, "contract:CON00008", {MARKET_A: 0.20, MARKET_B: 0.26, MARKET_C: 0.60})
    people["person:PER00009"] = _person("person:PER00009", "Crown Booker", 0.59, 0.69, 0.51, 8800, "contract:CON00009", {MARKET_A: 0.11, MARKET_B: 0.19, MARKET_C: 0.29}, {"skill.booking": 0.82, "skill.road_agenting": 0.70})
    people[UNSIGNED_STAR] = _person(UNSIGNED_STAR, "Free Agent Nova", 0.88, 0.80, 0.90, 17200, "", {MARKET_A: 0.40, MARKET_B: 0.44, MARKET_C: 0.46})
    people[UNSIGNED_PROSPECT] = _person(UNSIGNED_PROSPECT, "Prospect Eleven", 0.69, 0.63, 0.72, 10500, "", {MARKET_A: 0.25, MARKET_B: 0.27, MARKET_C: 0.30})

    var contracts: Dictionary = state.get("contracts")
    contracts["contract:CON00001"].set("end_date", "2001-03-01")
    contracts["contract:CON00002"].set("end_date", "2001-05-01")
    contracts["contract:CON00003"].set("end_date", "2002-06-01")
    contracts["contract:CON00004"].set("end_date", "2002-08-01")
    contracts["contract:CON00005"] = _contract("contract:CON00005", "person:PER00005", PROMOTION_B, 14500, "2002-04-01")
    contracts["contract:CON00006"] = _contract("contract:CON00006", "person:PER00006", PROMOTION_B, 9200, "2002-09-01")
    contracts["contract:CON00007"] = _contract("contract:CON00007", "person:PER00007", PROMOTION_C, 10000, "2001-04-01")
    contracts["contract:CON00008"] = _contract("contract:CON00008", "person:PER00008", PROMOTION_C, 15000, "2002-05-01")
    contracts["contract:CON00009"] = _contract("contract:CON00009", "person:PER00009", PROMOTION_C, 8800, "2002-10-01")

    var promotions: Dictionary = state.get("promotions")
    var promotion_a: RefCounted = promotions[PROMOTION_A]
    promotion_a.set("strategy_profile_id", "strategy.balanced")
    var promotion_b: RefCounted = promotions[PROMOTION_B]
    promotion_b.set("cash", {"minor_units": 1650000, "currency_id": "currency.fixture"})
    promotion_b.set("contract_ids", ["contract:CON00002", "contract:CON00005", "contract:CON00006"])
    promotion_b.set("touring_company_ids", ["touring:TOU00002"])
    promotion_b.set("championship_ids", ["championship:CHA00002"])
    promotion_b.set("media_deal_ids", ["media_deal:MED00002"])
    promotion_b.set("strategy_profile_id", "strategy.expansionist")
    var promotion_c: RefCounted = PromotionState.new()
    promotion_c.set("id", PROMOTION_C); promotion_c.set("brand_name", "Crown Territory Wrestling"); promotion_c.set("controlling_owner_person_id", "person:PER00007")
    promotion_c.set("cash", {"minor_units": 880000, "currency_id": "currency.fixture"}); promotion_c.set("prestige", 0.44); promotion_c.set("locker_room_morale", 0.58); promotion_c.set("momentum", 0.02)
    promotion_c.set("home_market_ids", [MARKET_C]); promotion_c.set("contract_ids", ["contract:CON00007", "contract:CON00008", "contract:CON00009"]); promotion_c.set("touring_company_ids", ["touring:TOU00003"]); promotion_c.set("championship_ids", ["championship:CHA00003"]); promotion_c.set("media_deal_ids", ["media_deal:MED00003"]); promotion_c.set("strategy_profile_id", "strategy.defensive")
    promotions[PROMOTION_C] = promotion_c
    if strategy_rotation != 0:
        var profile_ids: Array[String] = ["strategy.balanced", "strategy.expansionist", "strategy.defensive"]
        promotion_a.set("strategy_profile_id", profile_ids[posmod(strategy_rotation, 3)])
        promotion_b.set("strategy_profile_id", profile_ids[posmod(strategy_rotation + 1, 3)])
        promotion_c.set("strategy_profile_id", profile_ids[posmod(strategy_rotation + 2, 3)])

    var markets: Dictionary = state.get("markets")
    _set_influence(markets[MARKET_A], {PROMOTION_A: [0.58, 0.42, 0.48, 0.30], PROMOTION_B: [0.31, 0.22, 0.24, 0.15], PROMOTION_C: [0.18, 0.16, 0.20, 0.16]})
    _set_influence(markets[MARKET_B], {PROMOTION_A: [0.28, 0.22, 0.25, 0.20], PROMOTION_B: [0.59, 0.48, 0.46, 0.32], PROMOTION_C: [0.29, 0.24, 0.27, 0.21]})
    var market_c: RefCounted = MarketState.new(); market_c.set("market_id", MARKET_C); market_c.set("wrestling_interest", 0.68); market_c.set("economic_strength", 0.62)
    _set_influence(market_c, {PROMOTION_A: [0.25, 0.20, 0.24, 0.18], PROMOTION_B: [0.32, 0.25, 0.29, 0.20], PROMOTION_C: [0.61, 0.46, 0.50, 0.35]}); markets[MARKET_C] = market_c

    var touring: Dictionary = state.get("touring_companies")
    touring["touring:TOU00002"] = _company("touring:TOU00002", PROMOTION_B, ["person:PER00002", "person:PER00005", "person:PER00006"], "championship:CHA00002", MARKET_B, 205000, 0.16)
    touring["touring:TOU00003"] = _company("touring:TOU00003", PROMOTION_C, ["person:PER00007", "person:PER00008", "person:PER00009"], "championship:CHA00003", MARKET_C, 155000, 0.24)

    var championships: Dictionary = state.get("championships")
    championships["championship:CHA00002"] = _championship("championship:CHA00002", PROMOTION_B, "person:PER00005", MARKET_B)
    championships["championship:CHA00003"] = _championship("championship:CHA00003", PROMOTION_C, "person:PER00008", MARKET_C)

    var media_deals: Dictionary = state.get("media_deals")
    media_deals["media_deal:MED00002"] = _media("media_deal:MED00002", PROMOTION_B, [MARKET_A, MARKET_B, MARKET_C], 13500, 17500)
    media_deals["media_deal:MED00003"] = _media("media_deal:MED00003", PROMOTION_C, [MARKET_B, MARKET_C], 10500, 14000)

    var world: Dictionary = state.get("world_state")
    world["booker_by_promotion"] = {PROMOTION_A: "person:PER00004", PROMOTION_B: "person:PER00006", PROMOTION_C: "person:PER00009"}
    world["financial_stress_by_promotion"] = {PROMOTION_A: 0.08, PROMOTION_B: 0.18, PROMOTION_C: 0.62}
    world["promotion_relations_v1"] = {
        PROMOTION_A + "|" + PROMOTION_B: {"trust": 0.06, "grievance": 0.14},
        PROMOTION_A + "|" + PROMOTION_C: {"trust": 0.34, "grievance": 0.03},
        PROMOTION_B + "|" + PROMOTION_C: {"trust": 0.30, "grievance": 0.02},
    }
    world["contract_negotiations_v1"] = {}; world["pending_territory_violations_v1"] = []; world["talent_shares_v1"] = []
    var agreement: RefCounted = (state.get("agreements") as Dictionary)["agreement:AGR00001"]
    agreement.set("clauses", [{"clause_id": "agreement_clause.territory", "market_ids": [MARKET_A], "protected_promotion_id": PROMOTION_A}])

    var knowledge: Dictionary = state.get("knowledge_bases")
    knowledge[PROMOTION_A] = _knowledge(PROMOTION_A, 0.46)
    knowledge[PROMOTION_B] = _knowledge(PROMOTION_B, 0.28)
    knowledge[PROMOTION_C] = _knowledge(PROMOTION_C, 0.64)
    return state

static func _configure_person(person: RefCounted, demand: int, leverage: float) -> void:
    var career: Dictionary = person.get("career"); career["contract_demand_minor_units"] = demand; career["contract_leverage"] = leverage; person.set("career", career)

static func _person(id: String, name: String, performance: float, psychology: float, charisma: float, demand: int, contract_id: String, overness: Dictionary, extra_skills: Dictionary = {}) -> RefCounted:
    var person: RefCounted = PersonState.new(); person.set("id", id); person.set("legal_name", name); person.set("display_name", name); person.set("birth_date", "1975-01-01"); person.set("pronoun_set_id", "pronoun.fixture"); person.set("home_region_id", "region.fixture")
    var skills: Dictionary = {"skill.performance": performance, "skill.psychology": psychology, "skill.charisma": charisma}; skills.merge(extra_skills); person.set("skills", skills); person.set("traits", {}); person.set("potential", {"skill.performance": minf(1.0, performance + 0.08)}); person.set("health", {"status": "available", "injury_risk": 0.2}); person.set("career", {"status": "active", "contract_demand_minor_units": demand, "contract_leverage": 0.45}); person.set("active_contract_ids", [contract_id] if not contract_id.is_empty() else []); person.set("relationship_ids", [])
    var audience: Dictionary = {}; for market_id: Variant in overness.keys(): audience[str(market_id)] = {"overness": overness[market_id], "momentum": 0.0, "heat": PhaseEMath.canonical(maxf(0.08, float(overness[market_id]) * 0.7)), "shine": PhaseEMath.canonical(maxf(0.10, float(overness[market_id]) * 0.8))}
    person.set("audience_by_market", audience); return person

static func _contract(id: String, person_id: String, promotion_id: String, pay: int, end_date: String) -> RefCounted:
    var contract: RefCounted = ContractState.new(); contract.set("id", id); contract.set("person_id", person_id); contract.set("promotion_id", promotion_id); contract.set("start_date", "2001-01-01"); contract.set("end_date", end_date); contract.set("compensation", {"base": {"minor_units": pay, "currency_id": "currency.fixture"}}); contract.set("exclusivity_id", "exclusivity.fixture"); contract.set("leverage", 0.45); return contract

static func _company(id: String, promotion_id: String, people: Array, title_id: String, market_id: String, budget: int, fatigue: float) -> RefCounted:
    var company: RefCounted = TouringCompanyState.new(); company.set("id", id); company.set("promotion_id", promotion_id); company.set("name", id); company.set("person_assignment_ids", people.duplicate()); company.set("carried_championship_ids", [title_id]); company.set("route", [{"market_id": market_id}]); company.set("monthly_budget", {"minor_units": budget, "currency_id": "currency.fixture"}); company.set("fatigue_pressure", fatigue); company.set("cohesion", 0.68); return company

static func _championship(id: String, promotion_id: String, holder: String, market_id: String) -> RefCounted:
    var title: RefCounted = ChampionshipState.new(); title.set("id", id); title.set("promotion_id", promotion_id); title.set("definition_id", "championship.fixture"); title.set("prestige", 0.46); title.set("holder_person_ids", [holder]); title.set("recognition_market_ids", [market_id]); title.set("recognition_promotion_ids", [promotion_id]); return title

static func _media(id: String, promotion_id: String, markets: Array, cost: int, revenue: int) -> RefCounted:
    var deal: RefCounted = MediaDealState.new(); deal.set("id", id); deal.set("promotion_id", promotion_id); deal.set("medium_id", "media_medium.fixture"); deal.set("outlet_id", "media_outlet.fixture"); deal.set("reach_market_ids", markets.duplicate()); deal.set("start_date", "2001-01-01"); deal.set("schedule_id", "schedule.fixture"); deal.set("cost", {"minor_units": cost, "currency_id": "currency.fixture"}); deal.set("revenue", {"minor_units": revenue, "currency_id": "currency.fixture"}); return deal

static func _knowledge(owner_id: String, familiarity: float) -> RefCounted:
    var base: RefCounted = KnowledgeBase.new(); base.set("owner_promotion_id", owner_id); base.set("familiarity_by_subject", {UNSIGNED_STAR: familiarity, UNSIGNED_PROSPECT: maxf(0.08, familiarity - 0.12)})
    base.set("observations", [
        _observation(UNSIGNED_STAR, "skill.performance", 0.76, 0.94, familiarity), _observation(UNSIGNED_STAR, "talent.local_value", 0.34, 0.52, familiarity), _money_observation(UNSIGNED_STAR, 14500, 20200, familiarity),
        _observation(UNSIGNED_PROSPECT, "skill.performance", 0.61, 0.76, familiarity), _observation(UNSIGNED_PROSPECT, "talent.local_value", 0.21, 0.38, familiarity), _money_observation(UNSIGNED_PROSPECT, 8500, 13200, familiarity),
    ]); return base

static func _observation(subject_id: String, field_id: String, low: float, high: float, confidence: float) -> Dictionary:
    return {"subject_id": subject_id, "field_id": field_id, "estimate_form": "range", "range": {"min": low, "max": high}, "confidence": confidence, "source_id": "source.fixture_scouting", "observed_on": "2001-01-01", "bias": 0.0, "error_margin": PhaseEMath.canonical((high - low) * 0.5)}

static func _money_observation(subject_id: String, low: int, high: int, confidence: float) -> Dictionary:
    return {"subject_id": subject_id, "field_id": "contract.demand_minor_units", "estimate_form": "range", "range": {"min": low, "max": high}, "confidence": confidence, "source_id": "source.fixture_scouting", "observed_on": "2001-01-01", "bias": 0, "error_margin": int(round(float(high - low) * 0.5))}

static func _set_influence(market: RefCounted, values: Dictionary) -> void:
    var influence: Dictionary = {}; for promotion_id: Variant in values.keys(): var v: Array = values[promotion_id]; influence[str(promotion_id)] = {"audience": v[0], "media": v[1], "business": v[2], "infrastructure": v[3]}
    market.set("influence_by_promotion", influence)
