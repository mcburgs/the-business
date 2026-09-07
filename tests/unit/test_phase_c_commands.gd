extends RefCounted

const Fixture = preload("res://tests/helpers/phase_c_fixture.gd")
const CommandEnvelope = preload("res://app/commands/command_envelope.gd")
const CommandRouter = preload("res://app/commands/command_router.gd")
const Codec = preload("res://persistence/codecs/campaign_state_codec.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var router: RefCounted = CommandRouter.new()
    var state: RefCounted = Fixture.make_state()
    var codec: RefCounted = Codec.new()

    var command: RefCounted = _command("command:CMD00001", "command.set_champion", 7, 3, 10, "player:primary", {"championship_id": "championship:CHA00001", "holder_person_ids": ["person:PER00002"]})
    var result: Dictionary = router.call("apply", state, command)
    _expect(bool(result.get("accepted", false)), "Validated retained mutation should succeed: %s" % JSON.stringify(result), failures)
    var holders: Array = ((state.get("championships") as Dictionary)["championship:CHA00001"] as RefCounted).get("holder_person_ids")
    _expect(holders == ["person:PER00002"], "set_champion must mutate only through the command boundary.", failures)

    var rejected_state: RefCounted = Fixture.make_state()
    var before: Dictionary = codec.call("encode", rejected_state)
    var bad_command: RefCounted = _command("command:CMD00002", "command.set_champion", 7, 3, 10, "player:primary", {"championship_id": "championship:CHA00001", "holder_person_ids": ["person:MISSING"]})
    var rejected: Dictionary = router.call("apply", rejected_state, bad_command)
    var after: Dictionary = codec.call("encode", rejected_state)
    _expect(not bool(rejected.get("accepted", true)), "Broken command reference must be rejected.", failures)
    _expect(before == after, "Rejected commands must leave authoritative state completely unchanged.", failures)

    var stale: RefCounted = _command("command:CMD00003", "command.set_champion", 6, 3, 10, "player:primary", {"championship_id": "championship:CHA00001", "holder_person_ids": []})
    _expect(_has_code(router.call("apply", Fixture.make_state(), stale), "CMD002"), "Stale command turn must emit CMD002.", failures)

    var stale_date: RefCounted = _command("command:CMD00010", "command.set_champion", 7, 3, 10, "player:primary", {"championship_id": "championship:CHA00001", "holder_person_ids": []})
    stale_date.set("issued_on", "2000-12-01")
    _expect(_has_code(router.call("apply", Fixture.make_state(), stale_date), "CMD002"), "Stale command date must emit CMD002.", failures)

    var wrong_issuer: RefCounted = _command("command:CMD00011", "command.set_champion", 7, 3, 10, "player:primary", {"championship_id": "championship:CHA00001", "holder_person_ids": []})
    wrong_issuer.set("issuer", {"kind": "ai", "promotion_id": "person:PER00001"})
    _expect(_has_code(router.call("apply", Fixture.make_state(), wrong_issuer), "REF003"), "Issuer scope must enforce canonical reference family.", failures)

    var shell: RefCounted = _command("command:CMD00004", "command.advance_month", 7, 14, 0, "player:primary", {})
    var shell_result: Dictionary = router.call("apply", Fixture.make_state(), shell)
    _expect(_has_code(shell_result, "CMD001"), "Known later-resolution command must not accidentally execute Phase D simulation.", failures)

    var commands: Array = [
        _command("command:CMD00009", "command.save_campaign", 7, 4, 5, "b", {}),
        _command("command:CMD00008", "command.save_campaign", 7, 4, 5, "a", {}),
        _command("command:CMD00007", "command.save_campaign", 7, 3, 9, "z", {}),
        _command("command:CMD00006", "command.save_campaign", 7, 3, 9, "z", {}),
    ]
    var ordered: Array = router.call("sort_commands", commands)
    var ids: Array[String] = []
    for item: Variant in ordered:
        ids.append(str((item as RefCounted).get("command_id")))
    _expect(ids == ["command:CMD00006", "command:CMD00007", "command:CMD00008", "command:CMD00009"], "Command order must be phase, priority, issuer_key, command_id.", failures)

    return {"name": "phase_c_commands", "passed": failures.is_empty(), "failures": failures}

func _command(id: String, type: String, turn: int, phase: int, priority: int, issuer_key: String, payload: Dictionary) -> RefCounted:
    var command: RefCounted = CommandEnvelope.new()
    command.set("command_id", id)
    command.set("command_type", type)
    command.set("issued_for_turn", turn)
    command.set("issued_on", "2001-01-01")
    command.set("issuer", {"kind": "player", "promotion_id": "promotion:PRO00001"})
    command.set("turn_phase_ordinal", phase)
    command.set("priority", priority)
    command.set("issuer_key", issuer_key)
    command.set("payload", payload.duplicate(true))
    return command

func _has_code(result: Dictionary, code: String) -> bool:
    for error_value: Variant in result.get("errors", []):
        if error_value is Dictionary and str((error_value as Dictionary).get("code", "")) == code:
            return true
    return false

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)
