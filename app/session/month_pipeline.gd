extends RefCounted

const CampaignStateCodec = preload("res://persistence/codecs/campaign_state_codec.gd")
const ChronicleCodec = preload("res://persistence/codecs/chronicle_codec.gd")
const CampaignStateValidator = preload("res://domain/core/campaign_state_validator.gd")
const ChronicleValidator = preload("res://domain/chronicle/chronicle_validator.gd")
const HistoricalProjection = preload("res://domain/chronicle/historical_projection.gd")
const ChronicleCommitter = preload("res://domain/chronicle/chronicle_committer.gd")
const CommandRouter = preload("res://app/commands/command_router.gd")
const RandomService = preload("res://app/session/random_service.gd")
const DomainEvent = preload("res://domain/events/domain_event.gd")
const TurnContext = preload("res://app/session/turn_context.gd")
const TurnResult = preload("res://app/session/turn_result.gd")
const LedgerService = preload("res://domain/economy/ledger_service.gd")
const LogisticsSystem = preload("res://domain/touring/logistics_system.gd")
const BookingSystem = preload("res://domain/booking/booking_system.gd")
const ShowResolver = preload("res://domain/booking/show_resolver.gd")
const AudienceCreativeSystem = preload("res://domain/audience/audience_creative_system.gd")
const MediaMarketSystem = preload("res://domain/media/media_market_system.gd")
const EconomySystem = preload("res://domain/economy/economy_system.gd")
const AIPlanningService = preload("res://domain/ai/ai_planning_service.gd")
const ContractSystem = preload("res://domain/people/contract_system.gd")
const DiplomacySystem = preload("res://domain/diplomacy/diplomacy_system.gd")
const ScoutingSystem = preload("res://domain/knowledge/scouting_system.gd")

const PHASE_NAMES: Array[String] = [
    "preflight", "calendar_environment", "planning_snapshot", "commit_strategic_commands",
    "logistics_availability", "booking_generation", "show_resolution", "audience_creative",
    "media_market", "economy", "careers_relationships", "diplomacy_narrative", "knowledge",
    "chronicle_commit", "postflight"
]

var _state_codec: RefCounted = CampaignStateCodec.new()
var _chronicle_codec: RefCounted = ChronicleCodec.new()
var _state_validator: RefCounted = CampaignStateValidator.new()
var _chronicle_validator: RefCounted = ChronicleValidator.new()
var _command_router: RefCounted = CommandRouter.new()
var _committer: RefCounted = ChronicleCommitter.new()
var _ledger: RefCounted = LedgerService.new()
var _logistics: RefCounted = LogisticsSystem.new()
var _booking: RefCounted = BookingSystem.new()
var _show_resolver: RefCounted = ShowResolver.new()
var _audience: RefCounted = AudienceCreativeSystem.new()
var _media_market: RefCounted = MediaMarketSystem.new()
var _economy_system: RefCounted = EconomySystem.new()
var _ai_planning: RefCounted = AIPlanningService.new()
var _contracts: RefCounted = ContractSystem.new()
var _diplomacy: RefCounted = DiplomacySystem.new()
var _scouting: RefCounted = ScoutingSystem.new()

func advance_month(input_state: RefCounted, input_chronicle: RefCounted, commands: Array = [], content_index: Dictionary = {}, phase_hooks: Dictionary = {}) -> RefCounted:
    var result: RefCounted = TurnResult.new()
    result.set("start_date", str(input_state.get("current_date")))
    result.set("start_turn", int(input_state.get("turn_number")))
    var starting_validation: Dictionary = _state_validator.call("validate", input_state, content_index)
    if not bool(starting_validation.get("passed", false)):
        result.get("phase_trace").append(0); result.get("phase_names").append(PHASE_NAMES[0]); result.set("errors", starting_validation.get("errors", [])); return result
    var starting_chronicle_validation: Dictionary = _chronicle_validator.call("validate", input_chronicle)
    if not bool(starting_chronicle_validation.get("passed", false)):
        result.get("phase_trace").append(0); result.get("phase_names").append(PHASE_NAMES[0]); result.set("errors", starting_chronicle_validation.get("errors", [])); return result
    var cloned_state_result: Dictionary = _state_codec.call("decode", _state_codec.call("encode", input_state), content_index)
    if not bool(cloned_state_result.get("passed", false)): result.set("errors", cloned_state_result.get("errors", [])); return result
    var cloned_chronicle_result: Dictionary = _chronicle_codec.call("decode", _chronicle_codec.call("encode", input_chronicle))
    if not bool(cloned_chronicle_result.get("passed", false)): result.set("errors", cloned_chronicle_result.get("errors", [])); return result
    var context: RefCounted = TurnContext.new()
    context.set("state", cloned_state_result["state"]); context.set("chronicle", cloned_chronicle_result["chronicle"])
    context.set("commands", commands.duplicate()); context.set("content_index", content_index.duplicate(true)); context.set("phase_hooks", phase_hooks.duplicate())
    context.set("start_date", str(input_state.get("current_date"))); context.set("start_turn", int(input_state.get("turn_number")))
    var random_service: RefCounted = RandomService.new(int((context.get("state") as RefCounted).get("rng_state").get("seed")))
    var restore_result: Dictionary = random_service.call("restore", (context.get("state") as RefCounted).get("rng_state"))
    if not bool(restore_result.get("passed", false)): result.set("errors", restore_result.get("errors", [])); return result
    context.set("random_service", random_service)

    for ordinal: int in range(PHASE_NAMES.size()):
        result.get("phase_trace").append(ordinal); result.get("phase_names").append(PHASE_NAMES[ordinal])
        var phase_result: Dictionary = _run_phase(ordinal, context)
        if not bool(phase_result.get("passed", false)):
            result.set("errors", phase_result.get("errors", [])); result.set("command_results", context.get("command_results")); result.set("events", context.get("transient_events")); result.set("phase_outputs", context.get("phase_outputs")); return result

    result.set("passed", true); result.set("completed_month", true)
    result.set("end_date", str((context.get("state") as RefCounted).get("current_date"))); result.set("end_turn", int((context.get("state") as RefCounted).get("turn_number")))
    result.set("command_results", context.get("command_results")); result.set("events", context.get("transient_events")); result.set("journaled_events", context.get("diagnostics")); result.set("phase_outputs", context.get("phase_outputs"))
    result.set("autosave_requested", true); result.set("state", context.get("state")); result.set("chronicle", context.get("chronicle"))
    return result

func _run_phase(ordinal: int, context: RefCounted) -> Dictionary:
    match ordinal:
        0: return _preflight(context)
        1: return _calendar_environment(context)
        2: return _planning_snapshot(context)
        3: return _commit_commands(context)
        4: return _logistics_phase(context)
        5: return _booking_phase(context)
        6: return _show_resolution_phase(context)
        7: return _audience_phase(context)
        8: return _media_market_phase(context)
        9: return _economy(context)
        10: return _careers_contracts_phase(context)
        11: return _diplomacy_phase(context)
        12: return _knowledge_phase(context)
        13: return _chronicle_commit(context)
        14: return _postflight(context)
        _: return _failure("STATE001", "turn.phase", {"ordinal": ordinal})

func _preflight(context: RefCounted) -> Dictionary:
    var validation: Dictionary = _state_validator.call("validate", context.get("state"), context.get("content_index"))
    if not bool(validation["passed"]): return validation
    var chronicle_validation: Dictionary = _chronicle_validator.call("validate", context.get("chronicle"))
    if not bool(chronicle_validation["passed"]): return chronicle_validation
    for index: int in range((context.get("commands") as Array).size()):
        if not context.get("commands")[index] is RefCounted: return _failure("CMD001", "commands[" + str(index) + "]", {"reason": "command_object_required"})
    context.set("start_projection", HistoricalProjection.from_campaign_state(context.get("state"), context.get("start_date")))
    return _invoke_hook(0, context)

func _calendar_environment(context: RefCounted) -> Dictionary:
    context.set("target_date", _next_month(str(context.get("start_date"))))
    return _invoke_hook(1, context)

func _planning_snapshot(context: RefCounted) -> Dictionary:
    context.set("planning_snapshot", _state_codec.call("encode", context.get("state")))
    if _phase_f_enabled(context):
        var decoded: Dictionary = _state_codec.call("decode", context.get("planning_snapshot"), context.get("content_index"))
        if not bool(decoded.get("passed", false)): return decoded
        var planning_state: RefCounted = decoded.get("state")
        var planned: Dictionary = _ai_planning.call("plan", planning_state, context.get("content_index"), context.get("random_service"))
        if not bool(planned.get("passed", false)): return planned
        if _state_codec.call("encode", planning_state) != context.get("planning_snapshot"):
            return _failure("STATE003", "planning_snapshot", {"reason": "ai_planner_mutated_frozen_snapshot"})
        (context.get("commands") as Array).append_array(planned.get("commands", []))
        context.get("phase_outputs")["ai_decisions"] = planned.get("decisions", [])
        context.get("phase_outputs")["ai_explanations"] = planned.get("explanations", {})
        context.get("phase_outputs")["scouting_intents"] = planned.get("scouting_intents", [])
    return _invoke_hook(2, context)

func _commit_commands(context: RefCounted) -> Dictionary:
    var sorted: Array = _command_router.call("sort_commands", context.get("commands"))
    for command_value: Variant in sorted:
        var command: RefCounted = command_value
        var command_result: Dictionary = _command_router.call("apply", context.get("state"), command, context.get("content_index"))
        context.get("command_results").append(command_result)
        if bool(command_result.get("accepted", false)):
            var command_type: String = str(command.get("command_type"))
            var payload: Dictionary = command.get("payload")
            var details: Dictionary = command_result.get("details", {})
            var explanation: Array = _command_explanation(context, command)
            if command_type == "command.set_champion":
                context.get("transient_events").append(DomainEvent.make("ChampionshipChanged", str(context.get("target_date")), [str(payload.get("championship_id"))] + (payload.get("holder_person_ids", []) as Array), {"championship_id": payload.get("championship_id"), "holder_person_ids": (payload.get("holder_person_ids", []) as Array).duplicate()}, {"category": "booking", "historical_class": "state_change", "explanation": [{"source": "command", "command_id": command.get("command_id")}]}))
            elif command_type == "command.start_program":
                context.get("transient_events").append(DomainEvent.make("ProgramStarted", str(context.get("target_date")), [str(payload.get("program_id")), str(payload.get("promotion_id"))], payload.duplicate(true), {"category": "booking", "historical_class": "state_change", "explanation": [{"source": "command", "command_id": command.get("command_id")}]}))
            elif command_type == "command.end_program":
                context.get("transient_events").append(DomainEvent.make("ProgramEnded", str(context.get("target_date")), [str(payload.get("program_id"))], payload.duplicate(true), {"category": "booking", "historical_class": "state_change", "explanation": [{"source": "command", "command_id": command.get("command_id")}]}))
            elif command_type == "command.sign_media_deal":
                context.get("transient_events").append(DomainEvent.make("MediaDealSigned", str(context.get("target_date")), [str(payload.get("media_deal_id")), str(payload.get("promotion_id"))], payload.duplicate(true), {"category": "media", "historical_class": "state_change", "explanation": [{"source": "command", "command_id": command.get("command_id")}]}))
            elif command_type in ["command.offer_contract", "command.counter_offer"] and str(details.get("outcome")) == "accepted":
                context.get("transient_events").append(DomainEvent.make("TalentSigned", str(context.get("target_date")), [str(details.get("contract_id")), str(details.get("person_id")), str(details.get("promotion_id"))], details.duplicate(true), {"category": "talent", "historical_class": "state_change", "explanation": explanation}))
            elif command_type == "command.renew_contract" and str(details.get("outcome")) == "accepted":
                context.get("transient_events").append(DomainEvent.make("ContractRenewed", str(context.get("target_date")), [str(details.get("contract_id")), str(details.get("person_id")), str(details.get("promotion_id"))], details.duplicate(true), {"category": "talent", "historical_class": "state_change", "explanation": explanation}))
            elif command_type == "command.release_person" and str(details.get("outcome")) == "released":
                context.get("transient_events").append(DomainEvent.make("TalentReleased", str(context.get("target_date")), [str(details.get("contract_id")), str(details.get("person_id")), str(details.get("promotion_id"))], details.duplicate(true), {"category": "talent", "historical_class": "state_change", "explanation": explanation}))
            elif command_type == "command.propose_agreement" and str(details.get("outcome")) == "accepted":
                context.get("transient_events").append(DomainEvent.make("AgreementCreated", str(context.get("target_date")), [str(details.get("agreement_id"))] + (details.get("party_promotion_ids", []) as Array), details.duplicate(true), {"category": "diplomacy", "historical_class": "state_change", "explanation": explanation}))
            _journal_ai_decision(context, command, details, explanation)
    return _invoke_hook(3, context)

func _logistics_phase(context: RefCounted) -> Dictionary:
    if _phase_e_enabled(context):
        var resolved: Dictionary = _logistics.call("resolve", context.get("state"), context.get("content_index"), _tuning(context))
        if not bool(resolved.get("passed", false)): return resolved
        context.get("phase_outputs")["logistics"] = resolved.get("schedules", [])
    return _invoke_hook(4, context)

func _booking_phase(context: RefCounted) -> Dictionary:
    if _phase_e_enabled(context):
        var generated: Dictionary = _booking.call("generate", context.get("state"), context.get("phase_outputs").get("logistics", []), _tuning(context))
        if not bool(generated.get("passed", false)): return generated
        context.get("phase_outputs")["show_plans"] = generated.get("plans", [])
    return _invoke_hook(5, context)

func _show_resolution_phase(context: RefCounted) -> Dictionary:
    if _phase_e_enabled(context):
        var resolved: Dictionary = _show_resolver.call("resolve", context.get("state"), context.get("phase_outputs").get("show_plans", []), context.get("random_service"), _tuning(context))
        if not bool(resolved.get("passed", false)): return resolved
        context.get("phase_outputs")["show_results"] = resolved.get("results", [])
        var world_state: Dictionary = (context.get("state") as RefCounted).get("world_state")
        world_state["approved_major_outcomes"] = {}
    return _invoke_hook(6, context)

func _audience_phase(context: RefCounted) -> Dictionary:
    if _phase_e_enabled(context):
        var applied: Dictionary = _audience.call("apply", context.get("state"), context.get("phase_outputs").get("show_results", []), str(context.get("target_date")), context.get("random_service"), _tuning(context))
        if not bool(applied.get("passed", false)): return applied
        context.get("transient_events").append_array(applied.get("events", []))
    return _invoke_hook(7, context)

func _media_market_phase(context: RefCounted) -> Dictionary:
    if _phase_e_enabled(context):
        var applied: Dictionary = _media_market.call("apply", context.get("state"), context.get("phase_outputs").get("show_results", []), str(context.get("target_date")), context.get("random_service"), _tuning(context))
        if not bool(applied.get("passed", false)): return applied
        context.get("transient_events").append_array(applied.get("events", []))
        context.get("phase_outputs")["media_market"] = applied.get("effects", [])
    return _invoke_hook(8, context)

func _economy(context: RefCounted) -> Dictionary:
    if _phase_e_enabled(context):
        var settled: Dictionary = _economy_system.call("settle", context.get("state"), context.get("phase_outputs").get("show_results", []), str(context.get("target_date")), _tuning(context))
        if not bool(settled.get("passed", false)): return settled
        context.get("transient_events").append_array(settled.get("events", []))
        context.get("phase_outputs")["economy"] = settled.get("summary_by_promotion", {})
    var ledger_validation: Dictionary = _ledger.call("validate_ledger", (context.get("state") as RefCounted).get("world_state"))
    if not bool(ledger_validation["passed"]): return ledger_validation
    return _invoke_hook(9, context)

func _careers_contracts_phase(context: RefCounted) -> Dictionary:
    if _phase_f_enabled(context):
        var resolved: Dictionary = _contracts.call("resolve_expiry", context.get("state"), str(context.get("target_date")))
        if not bool(resolved.get("passed", false)): return resolved
        context.get("transient_events").append_array(resolved.get("events", []))
    return _invoke_hook(10, context)

func _diplomacy_phase(context: RefCounted) -> Dictionary:
    if _phase_f_enabled(context):
        var resolved: Dictionary = _diplomacy.call("resolve", context.get("state"), str(context.get("target_date")))
        if not bool(resolved.get("passed", false)): return resolved
        context.get("transient_events").append_array(resolved.get("events", []))
    return _invoke_hook(11, context)

func _knowledge_phase(context: RefCounted) -> Dictionary:
    if _phase_f_enabled(context):
        var updated: Dictionary = _scouting.call("update", context.get("state"), context.get("phase_outputs").get("scouting_intents", []), str(context.get("target_date")), context.get("random_service"), _phase_f_tuning(context))
        if not bool(updated.get("passed", false)): return updated
        context.get("phase_outputs")["scouting_reports"] = updated.get("reports", [])
    return _invoke_hook(12, context)

func _chronicle_commit(context: RefCounted) -> Dictionary:
    var hook_result: Dictionary = _invoke_hook(13, context)
    if not bool(hook_result["passed"]): return hook_result
    var state: RefCounted = context.get("state")
    state.set("current_date", str(context.get("target_date"))); state.set("turn_number", int(context.get("start_turn")) + 1)
    context.get("transient_events").append(DomainEvent.make("MonthAdvanced", str(context.get("target_date")), [], {"from_date": context.get("start_date"), "to_date": context.get("target_date"), "turn_number": state.get("turn_number")}, {"category": "calendar", "historical_class": "routine"}))
    var commit_result: Dictionary = _committer.call("commit_month", context.get("chronicle"), state, context.get("transient_events"))
    if not bool(commit_result.get("passed", false)): return commit_result
    context.set("diagnostics", commit_result.get("journaled_events", []))
    return {"passed": true, "errors": []}

func _postflight(context: RefCounted) -> Dictionary:
    var hook_result: Dictionary = _invoke_hook(14, context)
    if not bool(hook_result["passed"]): return hook_result
    var state: RefCounted = context.get("state")
    state.set("rng_state", (context.get("random_service") as RefCounted).call("capture", int(state.get("turn_number"))))
    var state_validation: Dictionary = _state_validator.call("validate", state, context.get("content_index"))
    if not bool(state_validation["passed"]): return state_validation
    var ledger_validation: Dictionary = _ledger.call("validate_ledger", state.get("world_state"))
    if not bool(ledger_validation["passed"]): return ledger_validation
    var chronicle_validation: Dictionary = _chronicle_validator.call("validate", context.get("chronicle"))
    if not bool(chronicle_validation["passed"]): return chronicle_validation
    return {"passed": true, "errors": []}

func _phase_e_enabled(context: RefCounted) -> bool:
    return (context.get("content_index") as Dictionary).get("phase_e_tuning", null) is Dictionary

func _tuning(context: RefCounted) -> Dictionary:
    return ((context.get("content_index") as Dictionary).get("phase_e_tuning", {}) as Dictionary).duplicate(true)

func _phase_f_enabled(context: RefCounted) -> bool:
    return (context.get("content_index") as Dictionary).get("phase_f_tuning", null) is Dictionary

func _phase_f_tuning(context: RefCounted) -> Dictionary:
    return ((context.get("content_index") as Dictionary).get("phase_f_tuning", {}) as Dictionary).duplicate(true)

func _command_explanation(context: RefCounted, command: RefCounted) -> Array:
    var explanation: Dictionary = context.get("phase_outputs").get("ai_explanations", {}).get(str(command.get("command_id")), {})
    if explanation.is_empty(): return [{"source": "command", "command_id": command.get("command_id")}]
    return [explanation]

func _journal_ai_decision(context: RefCounted, command: RefCounted, details: Dictionary, explanation: Array) -> void:
    var command_id: String = str(command.get("command_id"))
    for decision_value: Variant in context.get("phase_outputs").get("ai_decisions", []):
        if not decision_value is Dictionary: continue
        var decision: Dictionary = decision_value
        if str(decision.get("command_id")) == command_id and bool(decision.get("historical", false)) and not str(command.get("command_type")) in ["command.offer_contract", "command.counter_offer", "command.renew_contract", "command.release_person", "command.propose_agreement", "command.violate_territory"]:
            context.get("transient_events").append(DomainEvent.make("AiStrategicDecision", str(context.get("target_date")), [str(decision.get("promotion_id"))], {"command_id": command_id, "command_type": command.get("command_type"), "result": details.duplicate(true)}, {"category": "ai", "historical_class": "state_change", "explanation": explanation}))
            return

func _invoke_hook(ordinal: int, context: RefCounted) -> Dictionary:
    var hooks: Dictionary = context.get("phase_hooks")
    if not hooks.has(ordinal): return {"passed": true, "errors": []}
    var callable: Callable = hooks[ordinal]
    if not callable.is_valid(): return _failure("STATE001", "phase_hooks[" + str(ordinal) + "]", {"reason": "invalid_callable"})
    var value: Variant = callable.call(context)
    if value is Dictionary: return value
    return {"passed": true, "errors": []}

func _next_month(date: String) -> String:
    var parts: PackedStringArray = date.split("-")
    if parts.size() != 3: return date
    var year: int = int(parts[0]); var month: int = int(parts[1]) + 1; var day: int = int(parts[2])
    if month > 12: month = 1; year += 1
    var max_day: int = _days_in_month(year, month); day = mini(day, max_day)
    return str(year).pad_zeros(4) + "-" + str(month).pad_zeros(2) + "-" + str(day).pad_zeros(2)

func _days_in_month(year: int, month: int) -> int:
    if month in [4, 6, 9, 11]: return 30
    if month == 2:
        var leap: bool = year % 400 == 0 or (year % 4 == 0 and year % 100 != 0)
        return 29 if leap else 28
    return 31

func _failure(code: String, path: String, details: Dictionary) -> Dictionary:
    return {"passed": false, "errors": [{"code": code, "path": path, "localization_key": "validation." + code.to_lower(), "details": details.duplicate(true)}]}
