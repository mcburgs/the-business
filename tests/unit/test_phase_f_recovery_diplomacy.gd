extends RefCounted

const Fixture = preload("res://tests/helpers/phase_f_fixture.gd")
const AIPlanningView = preload("res://domain/ai/ai_planning_view.gd")
const OwnerStrategy = preload("res://domain/ai/owner_strategy.gd")
const RecoveryAI = preload("res://domain/ai/recovery_ai.gd")
const RandomService = preload("res://app/session/random_service.gd")
const CommandEnvelope = preload("res://app/commands/command_envelope.gd")
const CommandRouter = preload("res://app/commands/command_router.gd")
const DiplomacySystem = preload("res://domain/diplomacy/diplomacy_system.gd")
const Codec = preload("res://persistence/codecs/campaign_state_codec.gd")

func run() -> Dictionary:
    var failures: Array[String] = []; var state: RefCounted = Fixture.make_state(); var router: RefCounted = CommandRouter.new(); var codec: RefCounted = Codec.new()
    var view: Dictionary = AIPlanningView.new().build(state, Fixture.PROMOTION_C); var profile: Dictionary = Fixture.tuning().get("strategy_profiles", {}).get("strategy.defensive", {})
    var recovery: Dictionary = RecoveryAI.new().plan(view, profile, Fixture.tuning())
    _expect(bool(recovery.get("active", false)) and not (recovery.get("actions", []) as Array).is_empty(), "A stressed promotion must enter recovery and cut discretionary touring budget.", failures)
    var owner: Dictionary = OwnerStrategy.new().plan(view, profile, RandomService.new(42), Fixture.tuning())
    _expect(str(owner.get("target_market_id")) == Fixture.MARKET_C, "Recovery posture should retreat to the strongest home market instead of expanding blindly.", failures)
    for market_value: Variant in (state.get("markets") as Dictionary).values(): _expect(not (market_value as RefCounted).to_dict().has("owner_promotion_id"), "Markets must remain contested influence spaces without binary ownership.", failures)

    var proposed: Dictionary = router.call("apply", state, _command(state, "command:FDIP00001", "command.propose_agreement", Fixture.PROMOTION_A, {"agreement_id": "agreement:FDIP00001", "party_promotion_ids": [Fixture.PROMOTION_A, Fixture.PROMOTION_C], "clause_ids": ["agreement_clause.non_aggression"], "clauses": [{"clause_id": "agreement_clause.non_aggression", "market_ids": [Fixture.MARKET_A], "protected_promotion_id": Fixture.PROMOTION_A}]}))
    _expect(str(proposed.get("details", {}).get("outcome")) == "accepted", "Positive trust should support a shallow non-aggression agreement through CommandRouter.", failures)
    var violated: Dictionary = router.call("apply", state, _command(state, "command:FDIP00002", "command.violate_territory", Fixture.PROMOTION_C, {"agreement_id": "agreement:FDIP00001", "violator_promotion_id": Fixture.PROMOTION_C, "market_id": Fixture.MARKET_A}))
    _expect(str(violated.get("details", {}).get("outcome")) == "violated", "Protected market entry must remain possible and record a violation instead of becoming an impossible barrier.", failures)
    var resolved: Dictionary = DiplomacySystem.new().resolve(state, "2001-02-01")
    _expect((resolved.get("events", []) as Array).size() == 1 and str((resolved.get("events", []) as Array)[0].get("event_type")) == "TerritoryViolated", "Territory violation must surface as a visible historical consequence.", failures)
    var before: Dictionary = codec.call("encode", state)
    var rejected: Dictionary = router.call("apply", state, _command(state, "command:FDIP00003", "command.propose_agreement", Fixture.PROMOTION_A, {"agreement_id": "agreement:FDIP00002", "party_promotion_ids": [Fixture.PROMOTION_A, Fixture.PROMOTION_C], "clause_ids": ["agreement_clause.non_aggression"], "clauses": [{"clause_id": "agreement_clause.non_aggression", "market_ids": ["market.missing"]}]}))
    _expect(not bool(rejected.get("accepted", true)) and before == codec.call("encode", state), "Rejected diplomacy commands must leave state completely unchanged.", failures)
    var cross_scope_before: Dictionary = codec.call("encode", state)
    var cross_scope: Dictionary = router.call("apply", state, _command(state, "command:FDIP00004", "command.violate_territory", Fixture.PROMOTION_B, {"agreement_id": "agreement:FDIP00001", "violator_promotion_id": Fixture.PROMOTION_C, "market_id": Fixture.MARKET_A}))
    _expect(not bool(cross_scope.get("accepted", true)) and cross_scope_before == codec.call("encode", state), "A promotion must not issue another promotion's territory violation.", failures)
    return {"name": "phase_f_recovery_diplomacy", "passed": failures.is_empty(), "failures": failures}

func _command(state: RefCounted, id: String, type: String, promotion_id: String, payload: Dictionary) -> RefCounted:
    var command: RefCounted = CommandEnvelope.new(); command.set("command_id", id); command.set("command_type", type); command.set("issued_for_turn", state.get("turn_number")); command.set("issued_on", state.get("current_date")); command.set("issuer", {"kind": "ai", "promotion_id": promotion_id}); command.set("turn_phase_ordinal", 3); command.set("priority", 10); command.set("issuer_key", "ai." + promotion_id); command.set("payload", payload.duplicate(true)); return command

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition: failures.append(message)
