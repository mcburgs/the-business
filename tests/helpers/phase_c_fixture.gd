extends RefCounted

const CampaignState = preload("res://domain/core/campaign_state.gd")
const OwnershipSeatState = preload("res://domain/core/ownership_seat_state.gd")
const PersonState = preload("res://domain/people/person_state.gd")
const PromotionState = preload("res://domain/promotions/promotion_state.gd")
const MarketState = preload("res://domain/world/market_state.gd")
const RegionState = preload("res://domain/world/region_state.gd")
const VenueState = preload("res://domain/world/venue_state.gd")
const TouringCompanyState = preload("res://domain/touring/touring_company_state.gd")
const ContractState = preload("res://domain/people/contract_state.gd")
const ChampionshipState = preload("res://domain/booking/championship_state.gd")
const ProgramState = preload("res://domain/booking/program_state.gd")
const MediaDealState = preload("res://domain/media/media_deal_state.gd")
const AgreementState = preload("res://domain/diplomacy/agreement_state.gd")
const RelationshipState = preload("res://domain/people/relationship_state.gd")
const KnowledgeBase = preload("res://domain/knowledge/knowledge_base.gd")
const RandomService = preload("res://app/session/random_service.gd")

static func content_index() -> Dictionary:
    return {
        "rulesets": {"ruleset.fixture": true},
        "markets": {"market.fixture_a": true, "market.fixture_b": true},
        "regions": {"region.fixture": true},
        "venues": {"venue.fixture": true},
    }

static func make_state() -> RefCounted:
    var state: RefCounted = CampaignState.new()
    state.set("campaign_pack_id", "campaign.fixture")
    state.set("campaign_pack_version", "1.0.0")
    state.set("content_fingerprint", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    state.set("ruleset_id", "ruleset.fixture")
    state.set("current_date", "2001-01-01")
    state.set("turn_number", 7)
    state.set("world_state", {"era_id": "era.fixture", "available_technology_ids": [], "global_wrestling_interest": 0.5})

    var person_a: RefCounted = PersonState.new()
    person_a.set("id", "person:PER00001")
    person_a.set("legal_name", "Alpha Person")
    person_a.set("display_name", "Alpha")
    person_a.set("birth_date", "1970-01-01")
    person_a.set("pronoun_set_id", "pronoun.fixture")
    person_a.set("home_region_id", "region.fixture")
    person_a.set("skills", {"skill.performance": 0.8})
    person_a.set("traits", {"trait.example": 0.2})
    person_a.set("potential", {"skill.performance": 0.9})
    person_a.set("health", {"status": "available", "injury_risk": 0.3})
    person_a.set("career", {"status": "active"})
    person_a.set("audience_by_market", {"market.fixture_a": {"overness": 0.6, "momentum": 0.1, "heat": 0.4, "shine": 0.5}})
    person_a.set("active_contract_ids", ["contract:CON00001"])
    person_a.set("relationship_ids", ["relationship:REL00001"])

    var person_b: RefCounted = PersonState.new()
    person_b.set("id", "person:PER00002")
    person_b.set("legal_name", "Beta Person")
    person_b.set("display_name", "Beta")
    person_b.set("birth_date", "1972-01-01")
    person_b.set("pronoun_set_id", "pronoun.fixture")
    person_b.set("home_region_id", "region.fixture")
    person_b.set("skills", {"skill.performance": 0.7})
    person_b.set("traits", {})
    person_b.set("potential", {})
    person_b.set("health", {"status": "available", "injury_risk": 0.2})
    person_b.set("career", {"status": "active"})
    person_b.set("active_contract_ids", ["contract:CON00002"])
    person_b.set("relationship_ids", ["relationship:REL00001"])

    state.set("people", {person_a.get("id"): person_a, person_b.get("id"): person_b})

    var promotion_a: RefCounted = PromotionState.new()
    promotion_a.set("id", "promotion:PRO00001")
    promotion_a.set("brand_name", "Fixture Wrestling A")
    promotion_a.set("controlling_owner_person_id", "person:PER00001")
    promotion_a.set("cash", {"minor_units": 500000, "currency_id": "currency.fixture"})
    promotion_a.set("prestige", 0.5)
    promotion_a.set("locker_room_morale", 0.6)
    promotion_a.set("momentum", 0.1)
    promotion_a.set("home_market_ids", ["market.fixture_a"])
    promotion_a.set("contract_ids", ["contract:CON00001"])
    promotion_a.set("touring_company_ids", ["touring:TOU00001"])
    promotion_a.set("championship_ids", ["championship:CHA00001"])
    promotion_a.set("program_ids", ["program:PRG00001"])
    promotion_a.set("media_deal_ids", ["media_deal:MED00001"])
    promotion_a.set("agreement_ids", ["agreement:AGR00001"])

    var promotion_b: RefCounted = PromotionState.new()
    promotion_b.set("id", "promotion:PRO00002")
    promotion_b.set("brand_name", "Fixture Wrestling B")
    promotion_b.set("controlling_owner_person_id", "person:PER00002")
    promotion_b.set("cash", {"minor_units": 400000, "currency_id": "currency.fixture"})
    promotion_b.set("prestige", 0.4)
    promotion_b.set("locker_room_morale", 0.5)
    promotion_b.set("momentum", -0.1)
    promotion_b.set("home_market_ids", ["market.fixture_b"])
    promotion_b.set("contract_ids", ["contract:CON00002"])
    promotion_b.set("agreement_ids", ["agreement:AGR00001"])

    state.set("promotions", {promotion_a.get("id"): promotion_a, promotion_b.get("id"): promotion_b})

    var seat: RefCounted = OwnershipSeatState.new()
    seat.set("promotion_id", "promotion:PRO00001")
    state.set("ownership_seat", seat)

    var market_a: RefCounted = MarketState.new()
    market_a.set("market_id", "market.fixture_a")
    market_a.set("wrestling_interest", 0.6)
    market_a.set("economic_strength", 0.5)
    market_a.set("influence_by_promotion", {
        "promotion:PRO00001": {"audience": 0.6, "media": 0.4, "business": 0.5, "infrastructure": 0.3},
        "promotion:PRO00002": {"audience": 0.3, "media": 0.2, "business": 0.2, "infrastructure": 0.1},
    })
    var market_b: RefCounted = MarketState.new()
    market_b.set("market_id", "market.fixture_b")
    market_b.set("wrestling_interest", 0.5)
    market_b.set("economic_strength", 0.7)
    market_b.set("influence_by_promotion", {
        "promotion:PRO00001": {"audience": 0.2, "media": 0.2, "business": 0.2, "infrastructure": 0.2},
        "promotion:PRO00002": {"audience": 0.7, "media": 0.6, "business": 0.5, "infrastructure": 0.4},
    })
    state.set("markets", {market_a.get("market_id"): market_a, market_b.get("market_id"): market_b})

    var region: RefCounted = RegionState.new()
    region.set("region_id", "region.fixture")
    state.set("regions", {region.get("region_id"): region})

    var venue: RefCounted = VenueState.new()
    venue.set("venue_id", "venue.fixture")
    venue.set("relationship_by_promotion", {"promotion:PRO00001": 0.2})
    state.set("venues", {venue.get("venue_id"): venue})

    var contract_a: RefCounted = ContractState.new()
    contract_a.set("id", "contract:CON00001")
    contract_a.set("person_id", "person:PER00001")
    contract_a.set("promotion_id", "promotion:PRO00001")
    contract_a.set("start_date", "2001-01-01")
    contract_a.set("compensation", {"base": {"minor_units": 10000, "currency_id": "currency.fixture"}})
    contract_a.set("exclusivity_id", "exclusivity.fixture")
    contract_a.set("leverage", 0.5)
    var contract_b: RefCounted = ContractState.new()
    contract_b.set("id", "contract:CON00002")
    contract_b.set("person_id", "person:PER00002")
    contract_b.set("promotion_id", "promotion:PRO00002")
    contract_b.set("start_date", "2001-01-01")
    contract_b.set("compensation", {"base": {"minor_units": 9000, "currency_id": "currency.fixture"}})
    contract_b.set("exclusivity_id", "exclusivity.fixture")
    contract_b.set("leverage", 0.4)
    state.set("contracts", {contract_a.get("id"): contract_a, contract_b.get("id"): contract_b})

    var championship: RefCounted = ChampionshipState.new()
    championship.set("id", "championship:CHA00001")
    championship.set("promotion_id", "promotion:PRO00001")
    championship.set("definition_id", "championship.fixture")
    championship.set("prestige", 0.5)
    championship.set("holder_person_ids", ["person:PER00001"])
    championship.set("recognition_market_ids", ["market.fixture_a"])
    championship.set("recognition_promotion_ids", ["promotion:PRO00001"])
    state.set("championships", {championship.get("id"): championship})

    var program: RefCounted = ProgramState.new()
    program.set("id", "program:PRG00001")
    program.set("promotion_id", "promotion:PRO00001")
    program.set("started_on", "2001-01-01")
    program.set("side_a", {"person_ids": ["person:PER00001"]})
    program.set("side_b", {"person_ids": ["person:PER00002"]})
    program.set("purpose_id", "program_purpose.fixture")
    program.set("phase_id", "program_phase.fixture")
    program.set("heat", 0.4)
    program.set("momentum", 0.1)
    state.set("programs", {program.get("id"): program})

    var touring: RefCounted = TouringCompanyState.new()
    touring.set("id", "touring:TOU00001")
    touring.set("promotion_id", "promotion:PRO00001")
    touring.set("name", "Fixture Tour")
    touring.set("person_assignment_ids", ["person:PER00001"])
    touring.set("carried_championship_ids", ["championship:CHA00001"])
    touring.set("route", [{"market_id": "market.fixture_a"}])
    touring.set("monthly_budget", {"minor_units": 50000, "currency_id": "currency.fixture"})
    touring.set("fatigue_pressure", 0.2)
    touring.set("cohesion", 0.7)
    state.set("touring_companies", {touring.get("id"): touring})

    var media_deal: RefCounted = MediaDealState.new()
    media_deal.set("id", "media_deal:MED00001")
    media_deal.set("promotion_id", "promotion:PRO00001")
    media_deal.set("medium_id", "media_medium.fixture")
    media_deal.set("outlet_id", "media_outlet.fixture")
    media_deal.set("reach_market_ids", ["market.fixture_a"])
    media_deal.set("start_date", "2001-01-01")
    media_deal.set("schedule_id", "schedule.fixture")
    state.set("media_deals", {media_deal.get("id"): media_deal})

    var agreement: RefCounted = AgreementState.new()
    agreement.set("id", "agreement:AGR00001")
    agreement.set("party_promotion_ids", ["promotion:PRO00001", "promotion:PRO00002"])
    agreement.set("start_date", "2001-01-01")
    agreement.set("clause_ids", ["agreement_clause.territory"])
    agreement.set("clauses", [{"clause_id": "agreement_clause.territory", "market_ids": ["market.fixture_a"]}])
    agreement.set("trust_effect", 0.1)
    state.set("agreements", {agreement.get("id"): agreement})

    var relationship: RefCounted = RelationshipState.new()
    relationship.set("id", "relationship:REL00001")
    relationship.set("person_a_id", "person:PER00001")
    relationship.set("person_b_id", "person:PER00002")
    relationship.set("strength", 0.3)
    relationship.set("trust", 0.2)
    relationship.set("grievance", -0.1)
    state.set("relationships", {relationship.get("id"): relationship})

    var knowledge_a: RefCounted = KnowledgeBase.new()
    knowledge_a.set("owner_promotion_id", "promotion:PRO00001")
    knowledge_a.set("observations", [{
        "subject_id": "person:PER00002",
        "field_id": "skill.performance",
        "estimate_form": "range",
        "range": {"min": 0.55, "max": 0.75},
        "confidence": 0.6,
        "source_id": "system.fixture",
        "observed_on": "2001-01-01",
        "bias": 0.0,
        "error_margin": 0.1,
    }])
    var knowledge_b: RefCounted = KnowledgeBase.new()
    knowledge_b.set("owner_promotion_id", "promotion:PRO00002")
    state.set("knowledge_bases", {"promotion:PRO00001": knowledge_a, "promotion:PRO00002": knowledge_b})

    var random_service: RefCounted = RandomService.new(123456)
    random_service.call("draw_float", "fixture_prime")
    state.set("rng_state", random_service.call("capture", 7))
    return state
