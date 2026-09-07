extends RefCounted

const PhaseEFixture = preload("res://tests/helpers/phase_e_fixture.gd")
const MonthPipeline = preload("res://app/session/month_pipeline.gd")
const MediaMarketSystem = preload("res://domain/media/media_market_system.gd")
const HotStateSystem = preload("res://domain/audience/hot_state_system.gd")
const RandomService = preload("res://app/session/random_service.gd")
const LedgerService = preload("res://domain/economy/ledger_service.gd")
const InfluenceQuery = preload("res://domain/world/influence_query.gd")

var _failures: Array[String] = []

func run() -> Dictionary:
    _test_loss_month_and_traceable_ledger()
    _test_media_boundary_and_component_influence()
    _test_hot_state_qualification_and_decay()
    return {"name": "phase_e_economy_media_hot", "passed": _failures.is_empty(), "failures": _failures}

func _test_loss_month_and_traceable_ledger() -> void:
    var state: RefCounted = PhaseEFixture.make_state()
    ((state.get("promotions") as Dictionary)[PhaseEFixture.PLAYER_PROMOTION_ID] as RefCounted).set("cash", {"minor_units": 150000, "currency_id": "currency.fixture"})
    var turn: RefCounted = MonthPipeline.new().call("advance_month", state, PhaseEFixture.make_chronicle(), PhaseEFixture.strategy_commands(state, "good", 0), PhaseEFixture.financial_stress_content_index())
    _expect(bool(turn.get("passed")) and bool(turn.get("completed_month")), "a clearly loss-making month must advance rather than instantly ending the campaign")
    if not bool(turn.get("passed")): return
    var output_state: RefCounted = turn.get("state")
    var economy: Dictionary = (turn.get("phase_outputs") as Dictionary).get("economy", {})
    var summary: Dictionary = economy.get(PhaseEFixture.PLAYER_PROMOTION_ID, {})
    _expect(int(summary.get("profit_minor_units", 0)) < 0, "stress fixture must actually lose money")
    var stress: float = float((output_state.get("world_state") as Dictionary).get("financial_stress_by_promotion", {}).get(PhaseEFixture.PLAYER_PROMOTION_ID, 0.0))
    _expect(stress > 0.0 and stress <= 1.0, "financial stress should be stateful and bounded after a loss")
    var categories: Dictionary = summary.get("categories", {})
    for required: String in ["live_gate", "talent_pay", "venue", "travel", "production", "local_tv_revenue", "local_tv_cost", "overhead", "local_media_spend"]:
        _expect(categories.has(required), "monthly economics should expose traceable ledger category: " + required)
    _expect(bool(LedgerService.new().validate_ledger(output_state.get("world_state"))["passed"]), "all retained Phase E postings must reconcile")
    var promotion: RefCounted = (output_state.get("promotions") as Dictionary)[PhaseEFixture.PLAYER_PROMOTION_ID]
    var ledger: Dictionary = (output_state.get("world_state") as Dictionary).get("ledger_v1", {})
    var cash_key: String = PhaseEFixture.PLAYER_PROMOTION_ID + ".cash|currency.fixture"
    _expect(int((promotion.get("cash") as Dictionary).get("minor_units")) == 150000 + int(ledger.get("accounts", {}).get(cash_key, 0)), "promotion cash must equal opening cash plus reconciled ledger cash postings")

func _test_media_boundary_and_component_influence() -> void:
    var state: RefCounted = PhaseEFixture.make_state()
    var world: Dictionary = state.get("world_state")
    world["local_media_spend_by_promotion"] = {PhaseEFixture.PLAYER_PROMOTION_ID: {"minor_units": 25000, "currency_id": "currency.fixture"}}
    var program_before: Dictionary = ((state.get("programs") as Dictionary)[PhaseEFixture.PROGRAM_ID] as RefCounted).call("to_dict")
    var title_before: Dictionary = ((state.get("championships") as Dictionary)[PhaseEFixture.TITLE_ID] as RefCounted).call("to_dict")
    var company_before: Dictionary = ((state.get("touring_companies") as Dictionary)[PhaseEFixture.COMPANY_ID] as RefCounted).call("to_dict")
    var contract_before: Dictionary = ((state.get("contracts") as Dictionary)["contract:CON00001"] as RefCounted).call("to_dict")
    var market: RefCounted = (state.get("markets") as Dictionary)[PhaseEFixture.MARKET_B]
    var before_components: Dictionary = (market.get("influence_by_promotion") as Dictionary)[PhaseEFixture.PLAYER_PROMOTION_ID].duplicate(true)
    var star: RefCounted = (state.get("people") as Dictionary)[PhaseEFixture.STAR_ID]
    var before_overness: float = float(((star.get("audience_by_market") as Dictionary)[PhaseEFixture.MARKET_B] as Dictionary).get("overness"))
    var media_result: Dictionary = MediaMarketSystem.new().call("apply", state, [], "2001-02-01", RandomService.new(1234), PhaseEFixture.tuning())
    _expect(bool(media_result.get("passed")), "generic MediaDeal/local-media resolution should apply without a show")
    var after_components: Dictionary = (market.get("influence_by_promotion") as Dictionary)[PhaseEFixture.PLAYER_PROMOTION_ID]
    _expect(float(after_components.get("media")) > float(before_components.get("media")), "local media should increase the governed media influence component")
    _expect(float(((star.get("audience_by_market") as Dictionary)[PhaseEFixture.MARKET_B] as Dictionary).get("overness")) > before_overness, "media reach may increase simple wrestler familiarity in reached markets")
    _expect(((state.get("programs") as Dictionary)[PhaseEFixture.PROGRAM_ID] as RefCounted).call("to_dict") == program_before, "media-only resolution must not mutate programs")
    _expect(((state.get("championships") as Dictionary)[PhaseEFixture.TITLE_ID] as RefCounted).call("to_dict") == title_before, "media-only resolution must not mutate championships")
    _expect(((state.get("touring_companies") as Dictionary)[PhaseEFixture.COMPANY_ID] as RefCounted).call("to_dict") == company_before, "media-only resolution must not mutate touring state")
    _expect(((state.get("contracts") as Dictionary)["contract:CON00001"] as RefCounted).call("to_dict") == contract_before, "media-only resolution must not mutate contracts")
    var composite: float = InfluenceQuery.composite(after_components, PhaseEFixture.tuning())
    _expect(composite >= 0.0 and composite <= 1.0, "composite influence must remain a bounded derived query")
    _expect(not market.call("to_dict").has("owner") and not market.call("to_dict").has("owner_promotion_id"), "market influence must not become literal market ownership")

func _test_hot_state_qualification_and_decay() -> void:
    var qualified: RefCounted = (PhaseEFixture.make_state().get("people") as Dictionary)[PhaseEFixture.STAR_ID]
    qualified.set("current_hot_state", null)
    var config: Dictionary = PhaseEFixture.tuning()
    var hot_config: Dictionary = (config.get("hot_state", {}) as Dictionary).duplicate(true)
    hot_config["qualified_activation_chance"] = 1.0
    hot_config["duration_months"] = 3
    hot_config["decay"] = 0.5
    config["hot_state"] = hot_config
    var rng: RefCounted = RandomService.new(77)
    var started: Dictionary = HotStateSystem.new().call("update", qualified, PhaseEFixture.STAR_ID, "wrestler", 0.8, "2001-02-01", rng, config, ["credible_streak", "program_fit"])
    _expect(started.get("state") is Dictionary and str((started.get("state") as Dictionary).get("direction")) == "hot", "qualified seeded fixture should be capable of activating hot state")
    if started.get("state") is Dictionary:
        var intensity: float = float((started.get("state") as Dictionary).get("intensity"))
        _expect(intensity >= 0.0 and intensity <= 1.0, "hot-state intensity must remain bounded")
        _expect((started.get("events", []) as Array).size() == 1 and "credible_streak" in ((started.get("events", [])[0] as Dictionary).get("causes", []) as Array), "hot-state activation must retain causal contributors")
        HotStateSystem.new().call("update", qualified, PhaseEFixture.STAR_ID, "wrestler", 0.8, "2001-03-01", rng, config, [])
        var decayed: Variant = qualified.get("current_hot_state")
        _expect(decayed is Dictionary and float((decayed as Dictionary).get("intensity")) < intensity, "active hot state should decay according to tunable bounded rules")
    var unqualified: RefCounted = (PhaseEFixture.make_state().get("people") as Dictionary)[PhaseEFixture.SUPPORT_ID]
    unqualified.set("current_hot_state", null)
    var quiet_rng: RefCounted = RandomService.new(99)
    var quiet: Dictionary = HotStateSystem.new().call("update", unqualified, PhaseEFixture.SUPPORT_ID, "wrestler", 0.0, "2001-02-01", quiet_rng, config, ["ordinary_month"])
    _expect(quiet.get("state") == null and quiet_rng.call("diagnostic_tags").is_empty(), "unqualified ordinary months must not consume breakout RNG or create constant hot/cold noise")

func _expect(condition: bool, message: String) -> void:
    if not condition: _failures.append(message)
