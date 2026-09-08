extends RefCounted

const ContentLoader = preload("res://app/content/content_loader.gd")
const CampaignRuntimeFactory = preload("res://app/session/campaign_runtime_factory.gd")
const OwnerPresentationQuery = preload("res://app/queries/owner_presentation_query.gd")
const CommandEnvelope = preload("res://app/commands/command_envelope.gd")
const CommandRouter = preload("res://app/commands/command_router.gd")
const MonthPipeline = preload("res://app/session/month_pipeline.gd")
const CampaignStateCodec = preload("res://persistence/codecs/campaign_state_codec.gd")
const ChronicleCodec = preload("res://persistence/codecs/chronicle_codec.gd")

var _registry: RefCounted = null
var _state: RefCounted = null
var _chronicle: RefCounted = null
var _content_index: Dictionary = {}
var _pending_commands: Array = []
var _command_serial: int = 0
var _query: RefCounted = OwnerPresentationQuery.new()
var _router: RefCounted = CommandRouter.new()
var _state_codec: RefCounted = CampaignStateCodec.new()
var _chronicle_codec: RefCounted = ChronicleCodec.new()
var _advance_in_progress: bool = false

func start(campaign_directory: String, seed: int = 424242) -> Dictionary:
    var loader: RefCounted = ContentLoader.new()
    var search_roots: Array[String] = ["res://content/base", "res://content/campaigns"]
    var loaded: Dictionary = loader.call("load_campaign", campaign_directory, search_roots)
    if not bool(loaded.get("passed", false)):
        return loaded
    var built: Dictionary = CampaignRuntimeFactory.new().call("build", loaded.get("registry"), seed)
    if not bool(built.get("passed", false)):
        return built
    _registry = loaded.get("registry")
    _state = built.get("state")
    _chronicle = built.get("chronicle")
    _content_index = (built.get("content_index", {}) as Dictionary).duplicate(true)
    _pending_commands.clear()
    _command_serial = 0
    _advance_in_progress = false
    return {"passed": true, "errors": [], "projection": current_projection()}

func is_started() -> bool:
    return _state != null and _chronicle != null and _registry != null

func current_projection() -> Dictionary:
    if not is_started(): return {"passed": false, "errors": [{"code": "STATE001", "path": "session", "message": "Campaign session has not started."}]}
    return _query.call("build", _state, _chronicle, _registry)

func historical_projection(target_date: String) -> Dictionary:
    if not is_started(): return {"passed": false, "errors": [{"code": "STATE001", "path": "session"}]}
    return _query.call("historical", _state, _chronicle, _registry, target_date)

func queue_player_command(command_type: String, payload: Dictionary) -> Dictionary:
    if not is_started(): return {"accepted": false, "errors": [{"code": "STATE001", "path": "session"}]}
    var intent_key: String = _player_intent_key(command_type, payload)
    if not intent_key.is_empty():
        for pending: RefCounted in _pending_commands:
            if _player_intent_key(str(pending.get("command_type")), pending.get("payload")) == intent_key and pending.get("payload") == payload:
                return {
                    "accepted": true,
                    "command_id": pending.get("command_id"),
                    "errors": [],
                    "details": {"interaction_disposition": "duplicate_suppressed"},
                    "pending_count": _pending_commands.size(),
                }
    var command: RefCounted = _make_player_command(command_type, payload)
    var clone_result: Dictionary = _state_codec.call("decode", _state_codec.call("encode", _state), _content_index)
    if not bool(clone_result.get("passed", false)):
        return {"accepted": false, "errors": clone_result.get("errors", [])}
    var preview_state: RefCounted = clone_result.get("state")
    for pending: RefCounted in _pending_commands:
        if not intent_key.is_empty() and _player_intent_key(str(pending.get("command_type")), pending.get("payload")) == intent_key:
            continue
        var pending_result: Dictionary = _router.call("apply", preview_state, pending, _content_index)
        if not bool(pending_result.get("accepted", false)):
            return {"accepted": false, "errors": pending_result.get("errors", []), "details": {"reason": "pending_command_preview_invalid"}}
    var validation_result: Dictionary = _router.call("apply", preview_state, command, _content_index)
    if not bool(validation_result.get("accepted", false)):
        return validation_result
    var replaced: bool = false
    if not intent_key.is_empty():
        for index: int in range(_pending_commands.size()):
            var pending: RefCounted = _pending_commands[index]
            if _player_intent_key(str(pending.get("command_type")), pending.get("payload")) == intent_key:
                _pending_commands[index] = command
                replaced = true
                break
    if not replaced:
        _pending_commands.append(command)
    var details: Dictionary = (validation_result.get("details", {}) as Dictionary).duplicate(true)
    details["interaction_disposition"] = "superseded" if replaced else "queued"
    return {
        "accepted": true,
        "command_id": command.get("command_id"),
        "errors": [],
        "details": details,
        "pending_count": _pending_commands.size(),
    }

func advance_month() -> Dictionary:
    if not is_started(): return {"passed": false, "errors": [{"code": "STATE001", "path": "session"}]}
    if _advance_in_progress:
        return {"passed": false, "suppressed": true, "errors": [{"code": "G2H001", "path": "session.advance_month", "message": "Month resolution is already in progress."}], "projection": current_projection()}
    _advance_in_progress = true
    var commands: Array = _pending_commands.duplicate()
    var turn_result: RefCounted = MonthPipeline.new().call("advance_month", _state, _chronicle, commands, _content_index)
    if not bool(turn_result.get("passed")):
        _advance_in_progress = false
        return {"passed": false, "errors": turn_result.get("errors"), "turn": turn_result.call("to_summary"), "projection": current_projection()}
    _state = turn_result.get("state")
    _chronicle = turn_result.get("chronicle")
    _pending_commands.clear()
    _advance_in_progress = false
    return {"passed": true, "errors": [], "turn": turn_result.call("to_summary"), "projection": current_projection()}

func pending_count() -> int:
    return _pending_commands.size()

func controlled_promotion_id() -> String:
    if _state == null: return ""
    return str((_state.get("ownership_seat") as RefCounted).get("promotion_id"))

func state_snapshot() -> Dictionary:
    if _state == null: return {}
    return _state_codec.call("encode", _state)

func chronicle_snapshot() -> Dictionary:
    if _chronicle == null: return {}
    return _chronicle_codec.call("encode", _chronicle)

func test_route_command_for(promotion_id: String, touring_company_id: String, route: Array) -> Dictionary:
    # Test seam for proving the canonical router still rejects player cross-promotion scope.
    if not is_started(): return {"accepted": false, "errors": [{"code": "STATE001", "path": "session"}]}
    var command: RefCounted = _make_command("command.set_route", {"touring_company_id": touring_company_id, "route": route}, promotion_id)
    var clone_result: Dictionary = _state_codec.call("decode", _state_codec.call("encode", _state), _content_index)
    if not bool(clone_result.get("passed", false)): return {"accepted": false, "errors": clone_result.get("errors", [])}
    return _router.call("apply", clone_result.get("state"), command, _content_index)


func _player_intent_key(command_type: String, payload_value: Variant) -> String:
    if not payload_value is Dictionary:
        return ""
    var payload: Dictionary = payload_value
    match command_type:
        "command.set_route":
            return "route:" + str(payload.get("touring_company_id", ""))
        "command.adjust_budget":
            return "budget:" + str(payload.get("touring_company_id", ""))
        "command.book_market_focus":
            return "market_focus:" + str(payload.get("promotion_id", controlled_promotion_id()))
        "command.push_person":
            return "push:" + str(payload.get("touring_company_id", "")) + ":" + str(payload.get("person_id", ""))
        _:
            return ""

func _make_player_command(command_type: String, payload: Dictionary) -> RefCounted:
    return _make_command(command_type, payload, controlled_promotion_id())

func _make_command(command_type: String, payload: Dictionary, issuer_promotion_id: String) -> RefCounted:
    _command_serial += 1
    var command: RefCounted = CommandEnvelope.new()
    command.set("command_id", "command:CMD" + str(_command_serial).pad_zeros(7))
    command.set("command_type", command_type)
    command.set("issued_for_turn", int(_state.get("turn_number")))
    command.set("issued_on", str(_state.get("current_date")))
    command.set("issuer", {"kind": "player", "promotion_id": issuer_promotion_id})
    command.set("turn_phase_ordinal", 3)
    command.set("priority", 100 + _command_serial)
    command.set("issuer_key", "player." + issuer_promotion_id)
    command.set("payload", payload.duplicate(true))
    return command
