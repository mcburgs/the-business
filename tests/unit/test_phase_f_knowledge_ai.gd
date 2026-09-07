extends RefCounted

const Fixture = preload("res://tests/helpers/phase_f_fixture.gd")
const AIPlanningView = preload("res://domain/ai/ai_planning_view.gd")
const AIPlanningService = preload("res://domain/ai/ai_planning_service.gd")
const ScoutingSystem = preload("res://domain/knowledge/scouting_system.gd")
const RandomService = preload("res://app/session/random_service.gd")
const Codec = preload("res://persistence/codecs/campaign_state_codec.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var state: RefCounted = Fixture.make_state(717171)
    var codec: RefCounted = Codec.new()
    var view: Dictionary = AIPlanningView.new().build(state, Fixture.PROMOTION_B)
    _expect(not view.has("people") and not view.has("contracts") and not view.has("rng_state"), "Planning view must not expose authoritative hidden stores.", failures)
    var employed_external: Dictionary = _candidate(view, "person:PER00008")
    _expect(not employed_external.has("skills") and employed_external.has("performance"), "External talent must be represented only by knowledge projections.", failures)
    var unknown: Dictionary = _candidate(view, "person:PER00004").get("contract_demand", {})
    _expect(str(unknown.get("status")) == "unknown" and unknown.get("value") == null and not unknown.has("true_value"), "Unknown knowledge must remain unknown without a true-value escape hatch.", failures)

    var snapshot: Dictionary = codec.call("encode", state)
    var rng_a: RefCounted = RandomService.new(9911)
    var rng_b: RefCounted = RandomService.new(9911)
    var plan_a: Dictionary = AIPlanningService.new().plan(state, Fixture.content_index(), rng_a)
    var state_b: Dictionary = codec.call("decode", snapshot, Fixture.content_index())
    var plan_b: Dictionary = AIPlanningService.new().plan(state_b.get("state"), Fixture.content_index(), rng_b)
    _expect(snapshot == codec.call("encode", state), "AI planning must leave its input snapshot immutable.", failures)
    _expect(_plan_signature(plan_a) == _plan_signature(plan_b), "Same state and RNG must produce exactly the same AI command plan.", failures)
    _expect(_families(plan_a).has_all(["owner_strategy", "talent", "touring", "booker", "recovery", "diplomacy"]), "Separated AI modules must all produce structured decisions in the Phase F fixture.", failures)
    for command_value: Variant in plan_a.get("commands", []):
        var command: RefCounted = command_value
        _expect(str((command.get("issuer") as Dictionary).get("kind")) in ["ai", "automation"], "AI decisions must use ordinary AI/automation command envelopes.", failures)
        _expect(str(command.get("command_type")) != "show_plan", "Booker AI may issue priorities but must not create resolved cards.", failures)

    var intent: Array = [{"owner_promotion_id": Fixture.PROMOTION_B, "subject_id": Fixture.UNSIGNED_STAR, "field_ids": ["skill.performance", "contract.demand_minor_units"]}]
    var scout_rng: RefCounted = RandomService.new(4321)
    var first: Dictionary = ScoutingSystem.new().update(state, intent, "2001-02-01", scout_rng, Fixture.tuning())
    var first_margin: float = float((first.get("reports") as Array)[0].get("bounded_error_margin"))
    var second: Dictionary = ScoutingSystem.new().update(state, intent, "2001-03-01", scout_rng, Fixture.tuning())
    var second_margin: float = float((second.get("reports") as Array)[0].get("bounded_error_margin"))
    _expect(second_margin < first_margin, "Higher familiarity must narrow scouting uncertainty.", failures)
    _expect(float((second.get("reports") as Array)[0].get("confidence")) > float((first.get("reports") as Array)[0].get("confidence")), "Higher familiarity must increase report confidence.", failures)
    return {"name": "phase_f_knowledge_ai", "passed": failures.is_empty(), "failures": failures}

func _candidate(view: Dictionary, person_id: String) -> Dictionary:
    for value: Variant in view.get("external_talent", []):
        if value is Dictionary and str((value as Dictionary).get("person_id")) == person_id: return value
    return {}

func _plan_signature(plan: Dictionary) -> String:
    var values: Array = []
    for command_value: Variant in plan.get("commands", []):
        var command: RefCounted = command_value; values.append({"id": command.get("command_id"), "type": command.get("command_type"), "issuer": command.get("issuer"), "payload": command.get("payload")})
    return JSON.stringify({"commands": values, "decisions": plan.get("decisions", []), "intents": plan.get("scouting_intents", [])})

func _families(plan: Dictionary) -> Dictionary:
    var output: Dictionary = {}
    for decision: Dictionary in plan.get("decisions", []): output[str((decision.get("explanation", {}) as Dictionary).get("decision_family"))] = true
    return output

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition: failures.append(message)
