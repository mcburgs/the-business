extends RefCounted

const PhaseFFixture = preload("res://tests/helpers/phase_f_fixture.gd")
const CampaignStateValidator = preload("res://domain/core/campaign_state_validator.gd")
const CampaignStateCodec = preload("res://persistence/codecs/campaign_state_codec.gd")
const CommandEnvelope = preload("res://app/commands/command_envelope.gd")
const CommandRouter = preload("res://app/commands/command_router.gd")
const MonthPipeline = preload("res://app/session/month_pipeline.gd")
const HistoricalProjection = preload("res://domain/chronicle/historical_projection.gd")
const LogisticsSystem = preload("res://domain/touring/logistics_system.gd")
const BookingSystem = preload("res://domain/booking/booking_system.gd")
const ShowResolver = preload("res://domain/booking/show_resolver.gd")
const RandomService = preload("res://app/session/random_service.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    _test_non_person_ownership_seat_and_campaign_execution(failures)
    _test_player_command_identity_boundary(failures)
    _test_npc_owner_and_chronicle_separation(failures)
    _test_reality_perception_presentation_and_language_seams(failures)
    return {"name": "phase_f_r_reconciliation", "passed": failures.is_empty(), "failures": failures}

func _test_non_person_ownership_seat_and_campaign_execution(failures: Array[String]) -> void:
    var state: RefCounted = PhaseFFixture.make_state()
    var seat_dict: Dictionary = (state.get("ownership_seat") as RefCounted).call("to_dict")
    _expect(seat_dict.keys().has("promotion_id") and seat_dict.keys().has("transition_pending"), "OwnershipSeatState must retain only control-seat state.", failures)
    _expect(not seat_dict.has("owner_person_id"), "OwnershipSeatState must not serialize a player Person identity.", failures)
    var player_promotion_id: String = str(seat_dict.get("promotion_id"))
    ((state.get("promotions") as Dictionary)[player_promotion_id] as RefCounted).set("controlling_owner_person_id", null)
    var validation: Dictionary = CampaignStateValidator.new().validate(state, PhaseFFixture.content_index())
    _expect(bool(validation.get("passed", false)), "A player-controlled campaign must validate with no human controlling owner attached to the controlled promotion: %s" % JSON.stringify(validation.get("errors", [])), failures)
    if not bool(validation.get("passed", false)):
        return
    var turn: RefCounted = MonthPipeline.new().call("advance_month", state, PhaseFFixture.make_chronicle(), [], PhaseFFixture.content_index())
    _expect(bool(turn.get("passed")), "A full competitive month must run without any player Person/avatar dependency: %s" % JSON.stringify(turn.get("errors")), failures)
    if bool(turn.get("passed")):
        var encoded: Dictionary = CampaignStateCodec.new().encode(turn.get("state"))
        _expect(not (encoded.get("ownership_seat", {}) as Dictionary).has("owner_person_id"), "Player Person identity must remain absent after simulation and serialization.", failures)

func _test_player_command_identity_boundary(failures: Array[String]) -> void:
    var state: RefCounted = PhaseFFixture.make_state()
    var router: RefCounted = CommandRouter.new()
    var with_person: RefCounted = _command(state, "command:FR00001", {"kind": "player", "promotion_id": PhaseFFixture.PROMOTION_A, "person_id": "person:PER00001"})
    var person_result: Dictionary = router.call("apply", state, with_person)
    _expect(not bool(person_result.get("accepted", true)) and _has_path(person_result, "issuer.person_id"), "Player commands must reject person_id rather than treating the player as an owner avatar.", failures)
    var wrong_promotion: RefCounted = _command(state, "command:FR00002", {"kind": "player", "promotion_id": PhaseFFixture.PROMOTION_B})
    var scope_result: Dictionary = router.call("apply", state, wrong_promotion)
    _expect(not bool(scope_result.get("accepted", true)) and _has_path(scope_result, "issuer.promotion_id"), "Player command scope must be derived from OwnershipSeatState, not an arbitrary promotion/person identity.", failures)

func _test_npc_owner_and_chronicle_separation(failures: Array[String]) -> void:
    var state: RefCounted = PhaseFFixture.make_state()
    var npc_owner_id: Variant = ((state.get("promotions") as Dictionary)[PhaseFFixture.PROMOTION_C] as RefCounted).get("controlling_owner_person_id")
    _expect(npc_owner_id == "person:PER00007" and (state.get("people") as Dictionary).has(str(npc_owner_id)), "NPC promoter/owner Person modeling must remain intact.", failures)
    var projection: Dictionary = HistoricalProjection.from_campaign_state(state)
    _expect((projection.get("ownership_seat", {}) as Dictionary).get("promotion_id") == PhaseFFixture.PROMOTION_A, "Chronicle projection must retain the non-person control seat separately.", failures)
    _expect(not (projection.get("ownership_seat", {}) as Dictionary).has("owner_person_id"), "Chronicle control-seat history must not reintroduce player Person identity.", failures)
    _expect((projection.get("promotions", {}).get(PhaseFFixture.PROMOTION_C, {}) as Dictionary).get("owner_person_id") == "person:PER00007", "Chronicle must preserve legitimate NPC promotion-owner history.", failures)

func _test_reality_perception_presentation_and_language_seams(failures: Array[String]) -> void:
    var state: RefCounted = PhaseFFixture.make_state()
    var world: Dictionary = state.get("world_state")
    world["presentation_context_by_promotion"] = {PhaseFFixture.PROMOTION_A: {"public_frame_id": "presentation.fixture.heroic"}}
    world["wrestling_language_context_by_market"] = {PhaseFFixture.MARKET_A: {"profile_id": "wrestling_language.fixture", "era_id": "era.fixture", "region_id": "region.fixture"}}
    state.set("world_state", world)
    var schedules: Array = LogisticsSystem.new().call("resolve", state, PhaseFFixture.content_index(), PhaseFFixture.tuning()).get("schedules", [])
    var plans: Array = BookingSystem.new().call("generate", state, schedules, PhaseFFixture.tuning()).get("plans", [])
    var found: RefCounted = null
    for value: Variant in plans:
        if str((value as RefCounted).get("promotion_id")) == PhaseFFixture.PROMOTION_A and str((value as RefCounted).get("market_id")) == PhaseFFixture.MARKET_A:
            found = value
            break
    _expect(found != null, "BookingSystem must produce a player-promotion ShowPlan for seam verification.", failures)
    if found == null:
        return
    _expect(str((found.get("presentation_context") as Dictionary).get("public_frame_id")) == "presentation.fixture.heroic", "ShowPlan must carry explicit Presentation context separately from market/reality state.", failures)
    _expect(str((found.get("wrestling_language_context") as Dictionary).get("profile_id")) == "wrestling_language.fixture", "ShowPlan must carry era/region/audience WrestlingLanguage context through the shared booking path.", failures)
    var resolved: Dictionary = ShowResolver.new().call("resolve", state, [found], RandomService.new(424242), PhaseFFixture.tuning())
    _expect(bool(resolved.get("passed", false)), "ShowResolver must accept the reconciled ShowPlan seams.", failures)
    if bool(resolved.get("passed", false)):
        var factors: Array = ((resolved.get("results", [])[0] as RefCounted).get("causal_factors") as Array)
        _expect(_has_source(factors, "presentation_context") and _has_source(factors, "wrestling_language_context"), "ShowResolver must explicitly consume/preserve Presentation and WrestlingLanguage context seams without collapsing them into Reality.", failures)

func _command(state: RefCounted, id: String, issuer: Dictionary) -> RefCounted:
    var command: RefCounted = CommandEnvelope.new()
    command.set("command_id", id)
    command.set("command_type", "command.save_campaign")
    command.set("issued_for_turn", int(state.get("turn_number")))
    command.set("issued_on", str(state.get("current_date")))
    command.set("issuer", issuer.duplicate(true))
    command.set("turn_phase_ordinal", 14)
    command.set("priority", 0)
    command.set("issuer_key", "player." + str(issuer.get("promotion_id", "none")))
    command.set("payload", {})
    return command

func _has_path(result: Dictionary, path: String) -> bool:
    for error_value: Variant in result.get("errors", []):
        if error_value is Dictionary and str((error_value as Dictionary).get("path", "")) == path:
            return true
    return false

func _has_source(factors: Array, source: String) -> bool:
    for factor_value: Variant in factors:
        if factor_value is Dictionary and str((factor_value as Dictionary).get("source", "")) == source:
            return true
    return false

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)
