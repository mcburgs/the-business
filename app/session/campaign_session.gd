extends RefCounted

const ContentLoader = preload("res://app/content/content_loader.gd")
const CampaignRuntimeFactory = preload("res://app/session/campaign_runtime_factory.gd")
const OwnerPresentationQuery = preload("res://app/queries/owner_presentation_query.gd")
const CommandEnvelope = preload("res://app/commands/command_envelope.gd")
const CommandRouter = preload("res://app/commands/command_router.gd")
const MonthPipeline = preload("res://app/session/month_pipeline.gd")
const CampaignStateCodec = preload("res://persistence/codecs/campaign_state_codec.gd")
const ChronicleCodec = preload("res://persistence/codecs/chronicle_codec.gd")
const SaveService = preload("res://persistence/services/save_service.gd")

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

# Persistence remains an application/session concern. Domain state and Chronicle are the
# only authoritative saved game truth; pending UI intentions are deliberately transient
# until the canonical month pipeline commits them.
var _persistence_enabled: bool = false
var _save_service: RefCounted = null
var _save_id: String = ""
var _save_display_name: String = "The Business"
var _checkpoint_requested: bool = false
var _checkpoint_reason: String = ""
var _last_checkpoint_signature: String = ""
var _last_checkpoint_result: Dictionary = {}

func start(campaign_directory: String, seed: int = 424242) -> Dictionary:
    _disable_persistence()
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
    _reset_transient_application_state()
    return {"passed": true, "errors": [], "projection": current_projection(), "start_mode": "fresh_ephemeral"}

func start_or_resume(campaign_directory: String, save_id: String, seed: int = 424242, save_root: String = "user://saves", display_name: String = "The Business") -> Dictionary:
    if save_id.is_empty():
        return {"passed": false, "errors": [{"code": "SAVE001", "path": "session.save_id", "details": {"reason": "required"}}]}
    var fresh: Dictionary = start(campaign_directory, seed)
    if not bool(fresh.get("passed", false)):
        return fresh

    _persistence_enabled = true
    _save_id = save_id
    _save_display_name = display_name
    _save_service = SaveService.new()
    _save_service.set("root_path", save_root)
    var expected_fingerprint: String = str(_state.get("content_fingerprint"))
    var interrupted_recovery: Dictionary = _save_service.call("recover_interrupted_transaction", _save_id, expected_fingerprint)
    if not bool(interrupted_recovery.get("passed", false)):
        return {
            "passed": false,
            "errors": interrupted_recovery.get("errors", []),
            "details": {"reason": "interrupted_save_recovery_failed"},
            "interrupted_recovery": interrupted_recovery,
        }

    if bool(_save_service.call("has_save_artifact", _save_id)):
        var primary: Dictionary = _save_service.call("load_save", _save_id, expected_fingerprint)
        if bool(primary.get("passed", false)):
            _adopt_loaded_save(primary)
            _last_checkpoint_signature = _checkpoint_signature()
            _last_checkpoint_result = {"passed": true, "disposition": "loaded_primary"}
            var interrupted_was_recovered: bool = bool(interrupted_recovery.get("recovered", false))
            return {
                "passed": true,
                "errors": [],
                "projection": current_projection(),
                "start_mode": "recovered_interrupted_transaction" if interrupted_was_recovered else "resumed",
                "recovered": interrupted_was_recovered,
                "recovery_source": interrupted_recovery.get("disposition", ""),
                "manifest": primary.get("manifest", {}),
            }

        var recovery: Dictionary = _save_service.call("load_last_good", _save_id, expected_fingerprint)
        var recovery_source: String = "last_good"
        if not bool(recovery.get("passed", false)):
            recovery = _save_service.call("load_older_good", _save_id, expected_fingerprint)
            recovery_source = "older_good"
        if bool(recovery.get("passed", false)):
            _adopt_loaded_save(recovery)
            _last_checkpoint_signature = ""
            var restored: Dictionary = _checkpoint_current_state("recovery_restore")
            if not bool(restored.get("passed", false)):
                return {
                    "passed": false,
                    "errors": restored.get("errors", []),
                    "recovery_errors": primary.get("errors", []),
                    "details": {"reason": "last_good_loaded_but_primary_restore_failed"},
                }
            return {
                "passed": true,
                "errors": [],
                "projection": current_projection(),
                "start_mode": "recovered_" + recovery_source,
                "recovered": true,
                "recovery_source": recovery_source,
                "manifest": recovery.get("manifest", {}),
                "primary_errors": primary.get("errors", []),
                "checkpoint": restored,
            }

        return {
            "passed": false,
            "errors": primary.get("errors", []),
            "recovery_errors": recovery.get("errors", []),
            "details": {"reason": "current_save_invalid_and_last_good_unavailable"},
        }

    var initial_checkpoint: Dictionary = _checkpoint_current_state("initial_campaign")
    if not bool(initial_checkpoint.get("passed", false)):
        return {
            "passed": false,
            "errors": initial_checkpoint.get("errors", []),
            "details": {"reason": "initial_checkpoint_failed"},
        }
    return {
        "passed": true,
        "errors": [],
        "projection": current_projection(),
        "start_mode": "new_persistent",
        "recovered": false,
        "checkpoint": initial_checkpoint,
    }

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

    var checkpoint: Dictionary = {"passed": true, "disposition": "persistence_disabled"}
    if _persistence_enabled:
        checkpoint = _checkpoint_current_state("month_resolved")
    return {
        "passed": true,
        "errors": [],
        "turn": turn_result.call("to_summary"),
        "projection": current_projection(),
        "persistence_passed": bool(checkpoint.get("passed", false)),
        "checkpoint": checkpoint,
    }

func request_checkpoint(reason: String = "lifecycle") -> Dictionary:
    if not _persistence_enabled:
        return {"passed": true, "requested": false, "disposition": "persistence_disabled"}
    if not is_started():
        return {"passed": false, "requested": false, "errors": [{"code": "STATE001", "path": "session.checkpoint"}]}
    var signature: String = _checkpoint_signature()
    if not _checkpoint_requested and signature == _last_checkpoint_signature:
        return {"passed": true, "requested": false, "disposition": "already_checkpointed", "signature": signature}
    if _checkpoint_requested:
        return {"passed": true, "requested": true, "disposition": "duplicate_suppressed", "reason": _checkpoint_reason, "signature": signature}
    _checkpoint_requested = true
    _checkpoint_reason = reason
    return {"passed": true, "requested": true, "disposition": "scheduled", "reason": reason, "signature": signature}

func flush_checkpoint() -> Dictionary:
    if not _persistence_enabled:
        return {"passed": true, "disposition": "persistence_disabled"}
    if not _checkpoint_requested:
        return {"passed": true, "disposition": "nothing_pending"}
    return _checkpoint_current_state(_checkpoint_reason if not _checkpoint_reason.is_empty() else "lifecycle")

func persistence_status() -> Dictionary:
    return {
        "enabled": _persistence_enabled,
        "save_id": _save_id,
        "checkpoint_requested": _checkpoint_requested,
        "checkpoint_reason": _checkpoint_reason,
        "last_checkpoint_signature": _last_checkpoint_signature,
        "last_checkpoint_result": _last_checkpoint_result.duplicate(true),
    }

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

func _checkpoint_current_state(reason: String) -> Dictionary:
    if not _persistence_enabled or _save_service == null:
        return {"passed": true, "disposition": "persistence_disabled"}
    if not is_started():
        return {"passed": false, "errors": [{"code": "STATE001", "path": "session.checkpoint"}]}
    var signature: String = _checkpoint_signature()
    var result: Dictionary = _save_service.call("safe_checkpoint", _save_id, _save_display_name, _state, _chronicle, {"checkpoint_reason": reason})
    if bool(result.get("passed", false)):
        _last_checkpoint_signature = signature
        _checkpoint_requested = false
        _checkpoint_reason = ""
        result["disposition"] = "saved"
        result["signature"] = signature
        result["reason"] = reason
    else:
        _checkpoint_requested = true
        _checkpoint_reason = reason
        result["disposition"] = "save_failed_retry_pending"
        result["signature"] = signature
        result["reason"] = reason
    _last_checkpoint_result = result.duplicate(true)
    return result

func _checkpoint_signature() -> String:
    if not is_started(): return ""
    return str(_state.get("turn_number")) + "|" + str(_state.get("current_date")) + "|" + str(_chronicle.get("head_sequence")) + "|" + str(_chronicle.get("checkpoint_generation"))

func _adopt_loaded_save(loaded: Dictionary) -> void:
    _state = loaded.get("state")
    _chronicle = loaded.get("chronicle")
    _reset_transient_application_state()

func _reset_transient_application_state() -> void:
    _pending_commands.clear()
    _command_serial = 0
    _advance_in_progress = false
    _checkpoint_requested = false
    _checkpoint_reason = ""

func _disable_persistence() -> void:
    _persistence_enabled = false
    _save_service = null
    _save_id = ""
    _save_display_name = "The Business"
    _last_checkpoint_signature = ""
    _last_checkpoint_result = {}
    _checkpoint_requested = false
    _checkpoint_reason = ""

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
