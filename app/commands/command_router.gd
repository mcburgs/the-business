extends RefCounted

const DomainIds = preload("res://domain/core/domain_ids.gd")
const CommandResult = preload("res://app/commands/command_result.gd")

const COMMAND_TYPES: Array[String] = [
    "command.hire_staff", "command.assign_role", "command.fire_person", "command.set_booker", "command.adjust_budget",
    "command.create_touring_company", "command.assign_person", "command.set_route", "command.set_directive", "command.split_company", "command.merge_company",
    "command.start_program", "command.end_program", "command.set_champion", "command.approve_major_outcome", "command.push_person", "command.protect_person",
    "command.offer_contract", "command.counter_offer", "command.renew_contract", "command.release_person",
    "command.book_market_focus", "command.set_local_media_spend", "command.sign_media_deal",
    "command.propose_agreement", "command.violate_territory", "command.accept_talent_share",
    "command.advance_month", "command.save_campaign",
]

func apply(state: RefCounted, command: RefCounted) -> Dictionary:
    var rejection: Dictionary = _validate_envelope(state, command)
    if not rejection.is_empty():
        return rejection
    match str(command.get("command_type")):
        "command.set_champion":
            return _apply_set_champion(state, command)
        _:
            return CommandResult.rejection(
                str(command.get("command_id")),
                "CMD001",
                "command_type",
                "validation.cmd001",
                {"reason": "resolution_deferred_beyond_phase_c", "command_type": command.get("command_type")}
            )

func sort_commands(commands: Array) -> Array:
    var output: Array = commands.duplicate()
    output.sort_custom(_command_before)
    return output

func _command_before(a: Variant, b: Variant) -> bool:
    var left: RefCounted = a as RefCounted
    var right: RefCounted = b as RefCounted
    if int(left.get("turn_phase_ordinal")) != int(right.get("turn_phase_ordinal")):
        return int(left.get("turn_phase_ordinal")) < int(right.get("turn_phase_ordinal"))
    if int(left.get("priority")) != int(right.get("priority")):
        return int(left.get("priority")) < int(right.get("priority"))
    if str(left.get("issuer_key")) != str(right.get("issuer_key")):
        return str(left.get("issuer_key")) < str(right.get("issuer_key"))
    return str(left.get("command_id")) < str(right.get("command_id"))

func _validate_envelope(state: RefCounted, command: RefCounted) -> Dictionary:
    var command_id: String = str(command.get("command_id"))
    if int(command.get("command_schema_version")) != 1:
        return CommandResult.rejection(command_id, "CMD001", "command_schema_version", "validation.cmd001", {"expected": 1})
    if not DomainIds.is_runtime_id(command_id, "command"):
        return CommandResult.rejection(command_id, "ID001", "command_id", "validation.id001", {"id": command_id})
    var command_type: String = str(command.get("command_type"))
    if not command_type in COMMAND_TYPES:
        return CommandResult.rejection(command_id, "CMD001", "command_type", "validation.cmd001", {"command_type": command_type})
    if int(command.get("issued_for_turn")) != int(state.get("turn_number")):
        return CommandResult.rejection(command_id, "CMD002", "issued_for_turn", "validation.cmd002", {"expected": state.get("turn_number"), "actual": command.get("issued_for_turn")})
    if str(command.get("issued_on")) != str(state.get("current_date")):
        return CommandResult.rejection(command_id, "CMD002", "issued_on", "validation.cmd002", {"expected": state.get("current_date"), "actual": command.get("issued_on")})
    var issuer_rejection: Dictionary = _validate_issuer(state, command_id, command.get("issuer"))
    if not issuer_rejection.is_empty():
        return issuer_rejection
    if str(command.get("issuer_key")).is_empty():
        return CommandResult.rejection(command_id, "CMD001", "ordering.issuer_key", "validation.cmd001", {"reason": "required"})
    if not command.get("payload") is Dictionary:
        return CommandResult.rejection(command_id, "CMD001", "payload", "validation.cmd001", {"reason": "expected_object"})
    return {}

func _validate_issuer(state: RefCounted, command_id: String, issuer_value: Variant) -> Dictionary:
    if not issuer_value is Dictionary:
        return CommandResult.rejection(command_id, "CMD001", "issuer", "validation.cmd001", {"reason": "expected_object"})
    var issuer: Dictionary = issuer_value
    var allowed_fields: Array[String] = ["kind", "promotion_id", "person_id"]
    for key: Variant in issuer.keys():
        if not str(key) in allowed_fields:
            return CommandResult.rejection(command_id, "CMD001", "issuer." + str(key), "validation.cmd001", {"reason": "unknown_field"})
    var kind: String = str(issuer.get("kind", ""))
    if not kind in ["player", "ai", "automation", "system"]:
        return CommandResult.rejection(command_id, "CMD001", "issuer.kind", "validation.cmd001", {"kind": kind})
    if issuer.has("promotion_id") and issuer["promotion_id"] != null:
        var promotion_id: String = str(issuer["promotion_id"])
        if not DomainIds.is_runtime_id(promotion_id):
            return CommandResult.rejection(command_id, "ID001", "issuer.promotion_id", "validation.id001", {"id": promotion_id})
        if DomainIds.runtime_family(promotion_id) != "promotion":
            return CommandResult.rejection(command_id, "REF003", "issuer.promotion_id", "validation.ref003", {"id": promotion_id, "expected_family": "promotion"})
        if not (state.get("promotions") as Dictionary).has(promotion_id):
            return CommandResult.rejection(command_id, "REF001", "issuer.promotion_id", "validation.ref001", {"id": promotion_id})
    if issuer.has("person_id") and issuer["person_id"] != null:
        var person_id: String = str(issuer["person_id"])
        if not DomainIds.is_runtime_id(person_id):
            return CommandResult.rejection(command_id, "ID001", "issuer.person_id", "validation.id001", {"id": person_id})
        if DomainIds.runtime_family(person_id) != "person":
            return CommandResult.rejection(command_id, "REF003", "issuer.person_id", "validation.ref003", {"id": person_id, "expected_family": "person"})
        if not (state.get("people") as Dictionary).has(person_id):
            return CommandResult.rejection(command_id, "REF001", "issuer.person_id", "validation.ref001", {"id": person_id})
    return {}

func _apply_set_champion(state: RefCounted, command: RefCounted) -> Dictionary:
    var command_id: String = str(command.get("command_id"))
    var payload: Dictionary = command.get("payload")
    var allowed: Array[String] = ["championship_id", "holder_person_ids"]
    for key: Variant in payload.keys():
        if not str(key) in allowed:
            return CommandResult.rejection(command_id, "CMD001", "payload." + str(key), "validation.cmd001", {"reason": "unknown_field"})
    if not payload.has("championship_id") or not payload.has("holder_person_ids") or not payload["holder_person_ids"] is Array:
        return CommandResult.rejection(command_id, "CMD001", "payload", "validation.cmd001", {"reason": "required_fields"})
    var championship_id: String = str(payload["championship_id"])
    var championships: Dictionary = state.get("championships")
    if not DomainIds.is_runtime_id(championship_id, "championship"):
        return CommandResult.rejection(command_id, "ID001", "payload.championship_id", "validation.id001", {"id": championship_id})
    if not championships.has(championship_id):
        return CommandResult.rejection(command_id, "REF001", "payload.championship_id", "validation.ref001", {"id": championship_id})
    var people: Dictionary = state.get("people")
    var holders: Array = payload["holder_person_ids"]
    var seen: Dictionary = {}
    for index: int in range(holders.size()):
        var person_id: String = str(holders[index])
        if not DomainIds.is_runtime_id(person_id):
            return CommandResult.rejection(command_id, "ID001", "payload.holder_person_ids[" + str(index) + "]", "validation.id001", {"id": person_id})
        if DomainIds.runtime_family(person_id) != "person":
            return CommandResult.rejection(command_id, "REF003", "payload.holder_person_ids[" + str(index) + "]", "validation.ref003", {"id": person_id, "expected_family": "person"})
        if not people.has(person_id):
            return CommandResult.rejection(command_id, "REF001", "payload.holder_person_ids[" + str(index) + "]", "validation.ref001", {"id": person_id})
        if seen.has(person_id):
            return CommandResult.rejection(command_id, "STATE002", "payload.holder_person_ids", "validation.state002", {"id": person_id, "reason": "duplicate_holder"})
        seen[person_id] = true
    # Mutation happens only after the entire command has validated.
    var championship: RefCounted = championships[championship_id]
    championship.set("holder_person_ids", holders.duplicate(true))
    return CommandResult.success(command_id, {"mutation": "championship_holders_updated", "championship_id": championship_id})
