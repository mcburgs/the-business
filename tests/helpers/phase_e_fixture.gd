extends RefCounted

const PhaseCFixture = preload("res://tests/helpers/phase_c_fixture.gd")
const ChronicleStore = preload("res://domain/chronicle/chronicle_store.gd")
const PersonState = preload("res://domain/people/person_state.gd")
const ContractState = preload("res://domain/people/contract_state.gd")
const RandomService = preload("res://app/session/random_service.gd")
const CommandEnvelope = preload("res://app/commands/command_envelope.gd")

const PLAYER_PROMOTION_ID := "promotion:PRO00001"
const COMPANY_ID := "touring:TOU00001"
const STAR_ID := "person:PER00001"
const RIVAL_ID := "person:PER00003"
const SUPPORT_ID := "person:PER00004"
const PROGRAM_ID := "program:PRG00001"
const TITLE_ID := "championship:CHA00001"
const MARKET_A := "market.fixture_a"
const MARKET_B := "market.fixture_b"

static func tuning() -> Dictionary:
    return {
        "same_market_travel_index": 0.04,
        "default_travel_index": 0.48,
        "fatigue_recovery": 0.09,
        "fatigue_travel_gain": 0.30,
        "booking_base_coherence": 0.42,
        "booker_coherence_weight": 0.28,
        "road_agent_coherence_weight": 0.15,
        "program_coherence_weight": 0.14,
        "protect_coherence_bonus": 0.04,
        "fatigue_booking_penalty": 0.12,
        "drawing_overness_weight": 0.42,
        "drawing_momentum_weight": 0.18,
        "drawing_charisma_weight": 0.18,
        "drawing_market_fit_weight": 0.06,
        "drawing_program_weight": 0.08,
        "drawing_promotion_weight": 0.05,
        "drawing_media_weight": 0.03,
        "performance_weight": 0.34,
        "psychology_weight": 0.18,
        "booking_quality_weight": 0.26,
        "program_show_weight": 0.14,
        "show_quality_base": 0.08,
        "show_variance": 0.055,
        "fatigue_show_penalty": 0.14,
        "quality_crowd_weight": 0.48,
        "draw_crowd_weight": 0.32,
        "interest_crowd_weight": 0.20,
        "base_attendance": 900,
        "attendance_floor_multiplier": 0.35,
        "crowd_attendance_weight": 0.85,
        "draw_attendance_weight": 0.65,
        "prestige_attendance_weight": 0.25,
        "ticket_price_minor_units": 2500,
        "featured_momentum_bonus": 0.06,
        "show_momentum_scale": 0.22,
        "program_heat_scale": 0.18,
        "program_momentum_scale": 0.24,
        "momentum_retention": 0.62,
        "overness_momentum_conversion": 0.035,
        "overness_response_scale": 0.018,
        "overness_repetition_scale": 0.18,
        "featured_shine_scale": 0.08,
        "featured_heat_scale": 0.04,
        "supporting_heat_scale": 0.045,
        "supporting_shine_scale": 0.025,
        "program_momentum_retention": 0.72,
        "championship_prestige_scale": 0.015,
        "promotion_momentum_retention": 0.75,
        "promotion_show_signal_scale": 0.12,
        "breakthrough_overness_delta": 0.012,
        "journal_program_delta": 0.018,
        "overuse_grace_visits": 2,
        "audience_repetition_penalty": 0.035,
        "market_response_scale": 0.032,
        "market_overuse_penalty": 0.018,
        "market_interest_floor": 0.12,
        "influence_audience_gain": 0.028,
        "influence_business_gain": 0.018,
        "influence_media_gain": 0.018,
        "local_media_response_scale": 0.00000045,
        "media_familiarity_gain": 0.018,
        "influence_weights": {"audience": 0.40, "media": 0.25, "business": 0.25, "infrastructure": 0.10},
        "venue_cost_minor_units": 45000,
        "travel_cost_base_minor_units": 18000,
        "production_cost_minor_units": 12000,
        "monthly_overhead_minor_units": 30000,
        "local_tv_default_cost_minor_units": 10000,
        "local_tv_default_revenue_minor_units": 14000,
        "loss_stress_gain": 0.08,
        "profit_stress_recovery": 0.04,
        "low_cash_stress_gain": 0.08,
        "financial_stress_cash_threshold_minor_units": 200000,
        "hot_state": {
            "hot_threshold": 0.26,
            "cold_threshold": -0.26,
            "qualified_activation_chance": 0.33,
            "qualification_intensity_scale": 1.25,
            "duration_months": 3,
            "decay": 0.72,
            "minimum_intensity": 0.08,
            "propagation_scale": 0.15,
        },
    }

static func content_index() -> Dictionary:
    var index: Dictionary = PhaseCFixture.content_index().duplicate(true)
    index["phase_e_tuning"] = tuning()
    index["travel_connections"] = {
        MARKET_A + "|" + MARKET_B: {"base_cost_index": 0.48},
    }
    return index

static func make_state(seed: int = 424242) -> RefCounted:
    var state: RefCounted = PhaseCFixture.make_state()
    state.set("turn_number", 0)
    state.set("current_date", "2001-01-01")
    state.set("world_state", {
        "era_id": "era.fixture",
        "available_technology_ids": [],
        "global_wrestling_interest": 0.5,
        "booker_by_promotion": {PLAYER_PROMOTION_ID: SUPPORT_ID},
        "local_media_spend_by_promotion": {},
        "financial_stress_by_promotion": {PLAYER_PROMOTION_ID: 0.0, "promotion:PRO00002": 0.0},
        "market_visit_streaks": {},
        "market_focus_by_promotion": {},
        "approved_major_outcomes": {},
    })
    var rng: RefCounted = RandomService.new(seed)
    state.set("rng_state", rng.call("capture", 0))

    var people: Dictionary = state.get("people")
    var star: RefCounted = people[STAR_ID]
    star.set("skills", {"skill.performance": 0.84, "skill.psychology": 0.82, "skill.charisma": 0.86})
    star.set("audience_by_market", {
        MARKET_A: {"overness": 0.56, "momentum": 0.06, "heat": 0.30, "shine": 0.48},
        MARKET_B: {"overness": 0.18, "momentum": 0.0, "heat": 0.12, "shine": 0.20},
    })

    var rival: RefCounted = _person(RIVAL_ID, "Gamma Rival", {"skill.performance": 0.76, "skill.psychology": 0.74, "skill.charisma": 0.68}, "contract:CON00003")
    rival.set("audience_by_market", {
        MARKET_A: {"overness": 0.34, "momentum": 0.03, "heat": 0.46, "shine": 0.18},
        MARKET_B: {"overness": 0.16, "momentum": 0.0, "heat": 0.22, "shine": 0.13},
    })
    var support: RefCounted = _person(SUPPORT_ID, "Delta Agent", {"skill.performance": 0.58, "skill.psychology": 0.64, "skill.charisma": 0.42, "skill.booking": 0.78, "skill.road_agenting": 0.82}, "contract:CON00004")
    support.set("audience_by_market", {
        MARKET_A: {"overness": 0.20, "momentum": 0.0, "heat": 0.16, "shine": 0.20},
        MARKET_B: {"overness": 0.08, "momentum": 0.0, "heat": 0.08, "shine": 0.10},
    })
    people[RIVAL_ID] = rival
    people[SUPPORT_ID] = support

    var contracts: Dictionary = state.get("contracts")
    contracts["contract:CON00003"] = _contract("contract:CON00003", RIVAL_ID, 8500)
    contracts["contract:CON00004"] = _contract("contract:CON00004", SUPPORT_ID, 7000)

    var promotion: RefCounted = (state.get("promotions") as Dictionary)[PLAYER_PROMOTION_ID]
    promotion.set("cash", {"minor_units": 2000000, "currency_id": "currency.fixture"})
    promotion.set("contract_ids", ["contract:CON00001", "contract:CON00003", "contract:CON00004"])
    promotion.set("momentum", 0.04)

    var program: RefCounted = (state.get("programs") as Dictionary)[PROGRAM_ID]
    program.set("side_a", {"person_ids": [STAR_ID]})
    program.set("side_b", {"person_ids": [RIVAL_ID]})
    program.set("heat", 0.36)
    program.set("momentum", 0.02)
    program.set("objective_ids", ["program_objective.build_star"])

    var company: RefCounted = (state.get("touring_companies") as Dictionary)[COMPANY_ID]
    company.set("person_assignment_ids", [STAR_ID, RIVAL_ID, SUPPORT_ID])
    company.set("route", [{"market_id": MARKET_A}, {"market_id": MARKET_B}])
    company.set("directives", [])
    company.set("monthly_budget", {"minor_units": 180000, "currency_id": "currency.fixture"})
    company.set("fatigue_pressure", 0.08)
    company.set("cohesion", 0.72)

    var media: RefCounted = (state.get("media_deals") as Dictionary)["media_deal:MED00001"]
    media.set("reach_market_ids", [MARKET_A, MARKET_B])
    media.set("cost", {"minor_units": 12000, "currency_id": "currency.fixture"})
    media.set("revenue", {"minor_units": 15000, "currency_id": "currency.fixture"})
    return state

static func make_chronicle(checkpoint_cadence_months: int = 6) -> RefCounted:
    var store: RefCounted = ChronicleStore.new()
    store.set("checkpoint_cadence_months", checkpoint_cadence_months)
    var definitions: Array[Dictionary] = [
        {"metric_id": "promotion.prestige", "subject_scope": "promotion", "field": "prestige", "cadence": "monthly", "aggregation": "point", "precision": "float", "retention": "campaign"},
        {"metric_id": "promotion.momentum", "subject_scope": "promotion", "field": "momentum", "cadence": "monthly", "aggregation": "point", "precision": "float", "retention": "campaign"},
    ]
    store.set("metric_definitions", definitions)
    return store

static func strategy_commands(state: RefCounted, strategy: String, month_index: int) -> Array:
    var commands: Array = []
    if month_index == 0:
        if strategy == "good":
            commands.append(command(state, 1, "command.set_route", {"touring_company_id": COMPANY_ID, "route": [{"market_id": MARKET_A}, {"market_id": MARKET_B}]}))
            commands.append(command(state, 2, "command.push_person", {"touring_company_id": COMPANY_ID, "person_id": STAR_ID, "weight": 1.0}))
            commands.append(command(state, 3, "command.set_directive", {"touring_company_id": COMPANY_ID, "directive": {"kind": "program_emphasis", "program_id": PROGRAM_ID, "weight": 1.0}}))
            commands.append(command(state, 4, "command.set_directive", {"touring_company_id": COMPANY_ID, "directive": {"kind": "title_priority", "championship_id": TITLE_ID, "weight": 0.8}}))
            commands.append(command(state, 5, "command.protect_person", {"touring_company_id": COMPANY_ID, "person_id": RIVAL_ID, "weight": 0.7}))
            commands.append(command(state, 6, "command.set_local_media_spend", {"promotion_id": PLAYER_PROMOTION_ID, "spend": {"minor_units": 15000, "currency_id": "currency.fixture"}}))
        else:
            commands.append(command(state, 1, "command.set_route", {"touring_company_id": COMPANY_ID, "route": [{"market_id": MARKET_A}]}))
            commands.append(command(state, 2, "command.push_person", {"touring_company_id": COMPANY_ID, "person_id": SUPPORT_ID, "weight": 1.0}))
            commands.append(command(state, 3, "command.set_local_media_spend", {"promotion_id": PLAYER_PROMOTION_ID, "spend": {"minor_units": 120000, "currency_id": "currency.fixture"}}))
    if strategy == "good" and month_index in [2, 5, 8]:
        commands.append(command(state, 10 + month_index, "command.approve_major_outcome", {"promotion_id": PLAYER_PROMOTION_ID, "winner_person_id": STAR_ID, "loser_person_id": RIVAL_ID, "championship_id": TITLE_ID, "program_id": PROGRAM_ID}))
    if strategy == "bad" and month_index == 5:
        commands.append(command(state, 20, "command.end_program", {"program_id": PROGRAM_ID}))
    return commands

static func command(state: RefCounted, sequence: int, command_type: String, payload: Dictionary) -> RefCounted:
    var envelope: RefCounted = CommandEnvelope.new()
    envelope.set("command_id", "command:E" + str(int(state.get("turn_number"))).pad_zeros(7) + str(sequence).pad_zeros(2))
    envelope.set("command_type", command_type)
    envelope.set("issued_for_turn", int(state.get("turn_number")))
    envelope.set("issued_on", str(state.get("current_date")))
    envelope.set("issuer", {"kind": "player", "promotion_id": PLAYER_PROMOTION_ID})
    envelope.set("turn_phase_ordinal", 3)
    envelope.set("priority", sequence)
    envelope.set("issuer_key", "player." + PLAYER_PROMOTION_ID)
    envelope.set("payload", payload.duplicate(true))
    return envelope

static func financial_stress_content_index() -> Dictionary:
    var index: Dictionary = content_index()
    var config: Dictionary = (index["phase_e_tuning"] as Dictionary).duplicate(true)
    config["base_attendance"] = 30
    config["ticket_price_minor_units"] = 100
    config["venue_cost_minor_units"] = 180000
    config["travel_cost_base_minor_units"] = 90000
    config["production_cost_minor_units"] = 120000
    config["monthly_overhead_minor_units"] = 250000
    index["phase_e_tuning"] = config
    return index

static func _person(id: String, name: String, skills: Dictionary, contract_id: String) -> RefCounted:
    var person: RefCounted = PersonState.new()
    person.set("id", id)
    person.set("legal_name", name)
    person.set("display_name", name)
    person.set("birth_date", "1974-01-01")
    person.set("pronoun_set_id", "pronoun.fixture")
    person.set("home_region_id", "region.fixture")
    person.set("skills", skills.duplicate(true))
    person.set("traits", {})
    person.set("potential", {})
    person.set("health", {"status": "available", "injury_risk": 0.2})
    person.set("career", {"status": "active"})
    person.set("active_contract_ids", [contract_id])
    person.set("relationship_ids", [])
    return person

static func _contract(id: String, person_id: String, monthly_minor_units: int) -> RefCounted:
    var contract: RefCounted = ContractState.new()
    contract.set("id", id)
    contract.set("person_id", person_id)
    contract.set("promotion_id", PLAYER_PROMOTION_ID)
    contract.set("start_date", "2001-01-01")
    contract.set("compensation", {"base": {"minor_units": monthly_minor_units, "currency_id": "currency.fixture"}})
    contract.set("exclusivity_id", "exclusivity.fixture")
    contract.set("leverage", 0.3)
    return contract
