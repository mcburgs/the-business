extends RefCounted

const PhaseEFixture = preload("res://tests/helpers/phase_e_fixture.gd")
const MonthPipeline = preload("res://app/session/month_pipeline.gd")
const LogisticsSystem = preload("res://domain/touring/logistics_system.gd")
const BookingSystem = preload("res://domain/booking/booking_system.gd")
const ShowResolver = preload("res://domain/booking/show_resolver.gd")
const DrawingPowerQuery = preload("res://domain/audience/drawing_power_query.gd")
const RandomService = preload("res://app/session/random_service.gd")
const CampaignStateCodec = preload("res://persistence/codecs/campaign_state_codec.gd")

var _failures: Array[String] = []

func run() -> Dictionary:
    _test_automatic_booking_and_owner_constraints()
    _test_show_resolver_effect_boundary_and_determinism()
    _test_audience_locality_and_derived_drawing_power()
    return {"name": "phase_e_booking_audience", "passed": _failures.is_empty(), "failures": _failures}

func _test_automatic_booking_and_owner_constraints() -> void:
    var state: RefCounted = PhaseEFixture.make_state()
    var rival: RefCounted = (state.get("people") as Dictionary)[PhaseEFixture.RIVAL_ID]
    rival.set("health", {"status": "unavailable", "injury_risk": 0.2})
    var commands: Array = PhaseEFixture.strategy_commands(state, "good", 0)
    commands.append(PhaseEFixture.command(state, 20, "command.approve_major_outcome", {
        "promotion_id": PhaseEFixture.PLAYER_PROMOTION_ID, "winner_person_id": PhaseEFixture.STAR_ID,
        "loser_person_id": PhaseEFixture.RIVAL_ID, "championship_id": PhaseEFixture.TITLE_ID, "program_id": PhaseEFixture.PROGRAM_ID,
    }))
    commands.append(PhaseEFixture.command(state, 21, "command.set_champion", {"championship_id": PhaseEFixture.TITLE_ID, "holder_person_ids": [PhaseEFixture.SUPPORT_ID]}))
    var turn: RefCounted = MonthPipeline.new().call("advance_month", state, PhaseEFixture.make_chronicle(), commands, PhaseEFixture.content_index())
    _expect(bool(turn.get("passed")), "automatic booking month with owner constraints should pass")
    if not bool(turn.get("passed")): return
    var outputs: Dictionary = turn.get("phase_outputs")
    var plans: Array = outputs.get("show_plans", [])
    var results: Array = outputs.get("show_results", [])
    _expect(plans.size() == 1 and results.size() == 1, "routine card should be generated automatically from strategic state")
    var plan: RefCounted = plans[0]
    _expect(not PhaseEFixture.RIVAL_ID in (plan.get("participant_person_ids") as Array), "booking must respect unavailable personnel")
    _expect(str(plan.get("featured_person_id")) == PhaseEFixture.STAR_ID, "push directive should constrain automatic booking without requiring a manual card")
    _expect(str(plan.get("featured_program_id")) == PhaseEFixture.PROGRAM_ID and str(plan.get("featured_championship_id")) == PhaseEFixture.TITLE_ID, "program/title strategic directives should shape automatic ShowPlan")
    _expect(str((plan.get("approved_major_outcome") as Dictionary).get("winner_person_id")) == PhaseEFixture.STAR_ID, "owner-approved major outcome must reach the generated plan")
    var output_state: RefCounted = turn.get("state")
    var title: RefCounted = (output_state.get("championships") as Dictionary)[PhaseEFixture.TITLE_ID]
    _expect(title.get("holder_person_ids") == [PhaseEFixture.SUPPORT_ID], "championship intervention should work through command boundary without manual card construction")
    var result: RefCounted = results[0]
    _expect((result.get("causal_factors") as Array).size() >= 5, "ShowResult must expose structured causal contributors")

func _test_show_resolver_effect_boundary_and_determinism() -> void:
    var left: RefCounted = PhaseEFixture.make_state()
    var schedules: Array = LogisticsSystem.new().call("resolve", left, PhaseEFixture.content_index(), PhaseEFixture.tuning()).get("schedules", [])
    var plans: Array = BookingSystem.new().call("generate", left, schedules, PhaseEFixture.tuning()).get("plans", [])
    var before: Dictionary = CampaignStateCodec.new().encode(left)
    var rng_a: RefCounted = RandomService.new(424242)
    var resolved_a: Dictionary = ShowResolver.new().call("resolve", left, plans, rng_a, PhaseEFixture.tuning())
    _expect(CampaignStateCodec.new().encode(left) == before, "ShowResolver must return effects instead of directly mutating unrelated authoritative state")
    var right: RefCounted = PhaseEFixture.make_state()
    var schedules_b: Array = LogisticsSystem.new().call("resolve", right, PhaseEFixture.content_index(), PhaseEFixture.tuning()).get("schedules", [])
    var plans_b: Array = BookingSystem.new().call("generate", right, schedules_b, PhaseEFixture.tuning()).get("plans", [])
    var resolved_b: Dictionary = ShowResolver.new().call("resolve", right, plans_b, RandomService.new(424242), PhaseEFixture.tuning())
    _expect(bool(resolved_a.get("passed")) and bool(resolved_b.get("passed")), "show resolution should succeed for coherent automatic plans")
    if bool(resolved_a.get("passed")) and bool(resolved_b.get("passed")):
        _expect((resolved_a.get("results", [])[0] as RefCounted).call("to_dict") == (resolved_b.get("results", [])[0] as RefCounted).call("to_dict"), "equal state/plan/seed must resolve identical shows")

func _test_audience_locality_and_derived_drawing_power() -> void:
    var state: RefCounted = PhaseEFixture.make_state()
    var star: RefCounted = (state.get("people") as Dictionary)[PhaseEFixture.STAR_ID]
    var promotion: RefCounted = (state.get("promotions") as Dictionary)[PhaseEFixture.PLAYER_PROMOTION_ID]
    var before_a: Dictionary = (star.get("audience_by_market") as Dictionary)[PhaseEFixture.MARKET_A].duplicate(true)
    var before_b: Dictionary = (star.get("audience_by_market") as Dictionary)[PhaseEFixture.MARKET_B].duplicate(true)
    var drawing_a: float = DrawingPowerQuery.evaluate(star, promotion, PhaseEFixture.MARKET_A, PhaseEFixture.tuning())
    var drawing_b: float = DrawingPowerQuery.evaluate(star, promotion, PhaseEFixture.MARKET_B, PhaseEFixture.tuning())
    _expect(drawing_a != drawing_b, "same wrestler should have contextual drawing power because local audience state differs")
    var encoded: Dictionary = CampaignStateCodec.new().encode(state)
    _expect(not JSON.stringify(encoded).contains("drawing_power"), "drawing power must remain derived rather than persisted authoritative truth")
    var turn: RefCounted = MonthPipeline.new().call("advance_month", state, PhaseEFixture.make_chronicle(), PhaseEFixture.strategy_commands(state, "good", 0), PhaseEFixture.content_index())
    _expect(bool(turn.get("passed")), "one coherent deployment month should resolve")
    if not bool(turn.get("passed")): return
    var updated: RefCounted = ((turn.get("state") as RefCounted).get("people") as Dictionary)[PhaseEFixture.STAR_ID]
    var after_a: Dictionary = (updated.get("audience_by_market") as Dictionary)[PhaseEFixture.MARKET_A]
    var after_b: Dictionary = (updated.get("audience_by_market") as Dictionary)[PhaseEFixture.MARKET_B]
    _expect(float(after_a.get("momentum")) > float(before_a.get("momentum")), "successful local deployment should increase volatile wrestler momentum")
    _expect(float(after_a.get("overness")) - float(before_a.get("overness")) < 0.08, "one strong result must not instantly convert momentum into permanent superstar overness")
    _expect(after_b == before_b or float(after_b.get("overness")) >= float(before_b.get("overness")), "non-local audience state must remain distinct and only change through governed media/locality effects")
    _expect(float(after_a.get("heat")) != float(after_a.get("shine")), "heat and shine must remain distinct audience-response dimensions")

func _expect(condition: bool, message: String) -> void:
    if not condition: _failures.append(message)
