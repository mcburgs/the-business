extends RefCounted

const DomainIds = preload("res://domain/core/domain_ids.gd")
const CommandResult = preload("res://app/commands/command_result.gd")
const TouringCompanyState = preload("res://domain/touring/touring_company_state.gd")
const ProgramState = preload("res://domain/booking/program_state.gd")
const MediaDealState = preload("res://domain/media/media_deal_state.gd")
const ContractSystem = preload("res://domain/people/contract_system.gd")
const DiplomacySystem = preload("res://domain/diplomacy/diplomacy_system.gd")

var _contracts: RefCounted = ContractSystem.new()
var _diplomacy: RefCounted = DiplomacySystem.new()

const COMMAND_TYPES: Array[String] = [
    "command.hire_staff", "command.assign_role", "command.fire_person", "command.set_booker", "command.adjust_budget",
    "command.create_touring_company", "command.assign_person", "command.set_route", "command.set_directive", "command.split_company", "command.merge_company",
    "command.start_program", "command.end_program", "command.set_champion", "command.approve_major_outcome", "command.push_person", "command.protect_person",
    "command.offer_contract", "command.counter_offer", "command.renew_contract", "command.release_person",
    "command.book_market_focus", "command.set_local_media_spend", "command.sign_media_deal",
    "command.propose_agreement", "command.violate_territory", "command.accept_talent_share",
    "command.advance_month", "command.save_campaign",
]

func apply(state: RefCounted, command: RefCounted, content_index: Dictionary = {}) -> Dictionary:
    var rejection: Dictionary = _validate_envelope(state, command)
    if not rejection.is_empty():
        return rejection
    match str(command.get("command_type")):
        "command.set_champion": return _apply_set_champion(state, command)
        "command.create_touring_company": return _apply_create_touring_company(state, command, content_index)
        "command.assign_person": return _apply_assign_person(state, command)
        "command.set_route": return _apply_set_route(state, command, content_index)
        "command.set_directive": return _apply_set_directive(state, command)
        "command.split_company": return _apply_split_company(state, command, content_index)
        "command.merge_company": return _apply_merge_company(state, command)
        "command.start_program": return _apply_start_program(state, command)
        "command.end_program": return _apply_end_program(state, command)
        "command.approve_major_outcome": return _apply_approve_major_outcome(state, command)
        "command.push_person": return _apply_person_directive(state, command, "push")
        "command.protect_person": return _apply_person_directive(state, command, "protect")
        "command.adjust_budget": return _apply_adjust_budget(state, command)
        "command.set_booker": return _apply_set_booker(state, command)
        "command.book_market_focus": return _apply_book_market_focus(state, command)
        "command.set_local_media_spend": return _apply_local_media_spend(state, command)
        "command.sign_media_deal": return _apply_sign_media_deal(state, command)
        "command.offer_contract": return _contracts.call("apply_offer", state, command)
        "command.counter_offer": return _contracts.call("apply_counter", state, command)
        "command.renew_contract": return _contracts.call("apply_renew", state, command)
        "command.release_person": return _contracts.call("apply_release", state, command)
        "command.propose_agreement": return _diplomacy.call("apply_proposal", state, command, content_index.get("phase_f_tuning", {}))
        "command.violate_territory": return _diplomacy.call("apply_violation", state, command)
        "command.accept_talent_share": return _diplomacy.call("apply_talent_share", state, command)
        _:
            return CommandResult.rejection(
                str(command.get("command_id")), "CMD001", "command_type", "validation.cmd001",
                {"reason": "resolution_deferred_beyond_phase_f", "command_type": command.get("command_type")}
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
    if kind == "player" and issuer.has("person_id") and issuer["person_id"] != null:
        return CommandResult.rejection(command_id, "CMD001", "issuer.person_id", "validation.cmd001", {"reason": "player_is_non_person_ownership_seat"})
    if issuer.has("promotion_id") and issuer["promotion_id"] != null:
        var promotion_id: String = str(issuer["promotion_id"])
        var invalid_promotion: Dictionary = _runtime_ref_error(command_id, promotion_id, "promotion", state.get("promotions"), "issuer.promotion_id")
        if not invalid_promotion.is_empty(): return invalid_promotion
        if kind == "player":
            var player_promotion_id: String = str((state.get("ownership_seat") as RefCounted).get("promotion_id"))
            if promotion_id != player_promotion_id:
                return CommandResult.rejection(command_id, "STATE003", "issuer.promotion_id", "validation.state003", {"reason": "player_ownership_seat_scope_mismatch", "expected": player_promotion_id, "actual": promotion_id})
    elif kind == "player":
        return CommandResult.rejection(command_id, "CMD001", "issuer.promotion_id", "validation.cmd001", {"reason": "player_ownership_seat_requires_promotion_scope"})
    if issuer.has("person_id") and issuer["person_id"] != null:
        var person_id: String = str(issuer["person_id"])
        var invalid_person: Dictionary = _runtime_ref_error(command_id, person_id, "person", state.get("people"), "issuer.person_id")
        if not invalid_person.is_empty(): return invalid_person
    return {}

func _apply_create_touring_company(state: RefCounted, command: RefCounted, content_index: Dictionary) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var allowed: Array[String] = ["touring_company_id", "promotion_id", "name", "person_assignment_ids", "carried_championship_ids", "route", "directives", "monthly_budget"]
    var closed: Dictionary = _closed_payload(command, allowed, ["touring_company_id", "promotion_id", "name", "person_assignment_ids", "route", "monthly_budget"])
    if not closed.is_empty(): return closed
    var company_id: String = str(payload["touring_company_id"])
    var promotion_id: String = str(payload["promotion_id"])
    if not DomainIds.is_runtime_id(company_id, "touring"):
        return _reject(command, "ID001", "payload.touring_company_id", {"id": company_id})
    if (state.get("touring_companies") as Dictionary).has(company_id):
        return _reject(command, "STATE002", "payload.touring_company_id", {"id": company_id, "reason": "already_exists"})
    var promotion_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), promotion_id, "promotion", state.get("promotions"), "payload.promotion_id")
    if not promotion_error.is_empty(): return promotion_error
    var assignments: Array = payload["person_assignment_ids"]
    var assignment_error: Dictionary = _validate_assignments(state, promotion_id, assignments, "", command)
    if not assignment_error.is_empty(): return assignment_error
    var route_error: Dictionary = _validate_route(state, payload["route"], content_index, command)
    if not route_error.is_empty(): return route_error
    var titles: Array = payload.get("carried_championship_ids", [])
    var title_error: Dictionary = _validate_titles(state, promotion_id, titles, command)
    if not title_error.is_empty(): return title_error
    var money_error: Dictionary = _validate_money(payload["monthly_budget"], command, "payload.monthly_budget")
    if not money_error.is_empty(): return money_error
    var company: RefCounted = TouringCompanyState.new()
    company.set("id", company_id)
    company.set("promotion_id", promotion_id)
    company.set("name", str(payload["name"]))
    company.set("person_assignment_ids", assignments.duplicate(true))
    company.set("carried_championship_ids", titles.duplicate(true))
    company.set("route", (payload["route"] as Array).duplicate(true))
    company.set("directives", (payload.get("directives", []) as Array).duplicate(true))
    company.set("monthly_budget", (payload["monthly_budget"] as Dictionary).duplicate(true))
    company.set("cohesion", 0.5)
    (state.get("touring_companies") as Dictionary)[company_id] = company
    var promotion: RefCounted = (state.get("promotions") as Dictionary)[promotion_id]
    var company_ids: Array = promotion.get("touring_company_ids")
    company_ids.append(company_id)
    company_ids.sort()
    promotion.set("touring_company_ids", company_ids)
    return CommandResult.success(str(command.get("command_id")), {"mutation": "touring_company_created", "touring_company_id": company_id})

func _apply_assign_person(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed_payload(command, ["touring_company_id", "person_id", "assigned"], ["touring_company_id", "person_id"])
    if not closed.is_empty(): return closed
    var company_id: String = str(payload["touring_company_id"])
    var person_id: String = str(payload["person_id"])
    var company_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), company_id, "touring", state.get("touring_companies"), "payload.touring_company_id")
    if not company_error.is_empty(): return company_error
    var person_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), person_id, "person", state.get("people"), "payload.person_id")
    if not person_error.is_empty(): return person_error
    var company: RefCounted = (state.get("touring_companies") as Dictionary)[company_id]
    var assigned: bool = bool(payload.get("assigned", true))
    var assignments: Array = company.get("person_assignment_ids")
    if assigned:
        var assignment_error: Dictionary = _validate_assignments(state, str(company.get("promotion_id")), [person_id], company_id, command)
        if not assignment_error.is_empty(): return assignment_error
        if not person_id in assignments:
            assignments.append(person_id)
            assignments.sort()
    else:
        assignments.erase(person_id)
    company.set("person_assignment_ids", assignments)
    return CommandResult.success(str(command.get("command_id")), {"mutation": "touring_assignment_updated", "assigned": assigned, "person_id": person_id})

func _apply_set_route(state: RefCounted, command: RefCounted, content_index: Dictionary) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed_payload(command, ["touring_company_id", "route"], ["touring_company_id", "route"])
    if not closed.is_empty(): return closed
    var company_id: String = str(payload["touring_company_id"])
    var company_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), company_id, "touring", state.get("touring_companies"), "payload.touring_company_id")
    if not company_error.is_empty(): return company_error
    var route_error: Dictionary = _validate_route(state, payload["route"], content_index, command)
    if not route_error.is_empty(): return route_error
    ((state.get("touring_companies") as Dictionary)[company_id] as RefCounted).set("route", (payload["route"] as Array).duplicate(true))
    return CommandResult.success(str(command.get("command_id")), {"mutation": "touring_route_updated", "touring_company_id": company_id})

func _apply_set_directive(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed_payload(command, ["touring_company_id", "directive"], ["touring_company_id", "directive"])
    if not closed.is_empty(): return closed
    var company_id: String = str(payload["touring_company_id"])
    var company_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), company_id, "touring", state.get("touring_companies"), "payload.touring_company_id")
    if not company_error.is_empty(): return company_error
    if not payload["directive"] is Dictionary:
        return _reject(command, "CMD001", "payload.directive", {"reason": "expected_object"})
    var directive_error: Dictionary = _validate_directive(state, (state.get("touring_companies") as Dictionary)[company_id], payload["directive"], command)
    if not directive_error.is_empty(): return directive_error
    _upsert_directive((state.get("touring_companies") as Dictionary)[company_id], payload["directive"])
    return CommandResult.success(str(command.get("command_id")), {"mutation": "touring_directive_updated", "touring_company_id": company_id, "kind": (payload["directive"] as Dictionary).get("kind")})

func _apply_split_company(state: RefCounted, command: RefCounted, content_index: Dictionary) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed_payload(command, ["source_touring_company_id", "new_touring_company_id", "name", "person_ids", "route", "monthly_budget"], ["source_touring_company_id", "new_touring_company_id", "name", "person_ids"])
    if not closed.is_empty(): return closed
    var source_id: String = str(payload["source_touring_company_id"])
    var new_id: String = str(payload["new_touring_company_id"])
    var source_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), source_id, "touring", state.get("touring_companies"), "payload.source_touring_company_id")
    if not source_error.is_empty(): return source_error
    if not DomainIds.is_runtime_id(new_id, "touring"):
        return _reject(command, "ID001", "payload.new_touring_company_id", {"id": new_id})
    if (state.get("touring_companies") as Dictionary).has(new_id):
        return _reject(command, "STATE002", "payload.new_touring_company_id", {"reason": "already_exists", "id": new_id})
    if not payload["person_ids"] is Array or (payload["person_ids"] as Array).is_empty():
        return _reject(command, "CMD001", "payload.person_ids", {"reason": "nonempty_array_required"})
    var source: RefCounted = (state.get("touring_companies") as Dictionary)[source_id]
    var source_people: Array = source.get("person_assignment_ids")
    for person_value: Variant in payload["person_ids"]:
        if not str(person_value) in source_people:
            return _reject(command, "STATE002", "payload.person_ids", {"reason": "person_not_in_source", "person_id": person_value})
    if source_people.size() <= (payload["person_ids"] as Array).size():
        return _reject(command, "STATE002", "payload.person_ids", {"reason": "split_must_leave_source_nonempty"})
    var route: Array = (payload.get("route", source.get("route")) as Array).duplicate(true)
    var route_error: Dictionary = _validate_route(state, route, content_index, command)
    if not route_error.is_empty(): return route_error
    var budget: Dictionary = (payload.get("monthly_budget", source.get("monthly_budget")) as Dictionary).duplicate(true)
    var money_error: Dictionary = _validate_money(budget, command, "payload.monthly_budget")
    if not money_error.is_empty(): return money_error
    var moved: Array = (payload["person_ids"] as Array).duplicate(true)
    var remaining: Array = source_people.duplicate()
    for person_value: Variant in moved: remaining.erase(person_value)
    source.set("person_assignment_ids", remaining)
    var company: RefCounted = TouringCompanyState.new()
    company.set("id", new_id)
    company.set("promotion_id", source.get("promotion_id"))
    company.set("name", str(payload["name"]))
    company.set("person_assignment_ids", moved)
    company.set("route", route)
    company.set("directives", (source.get("directives") as Array).duplicate(true))
    company.set("monthly_budget", budget)
    company.set("cohesion", float(source.get("cohesion")) * 0.8)
    (state.get("touring_companies") as Dictionary)[new_id] = company
    var promotion: RefCounted = (state.get("promotions") as Dictionary)[str(source.get("promotion_id"))]
    var ids: Array = promotion.get("touring_company_ids")
    ids.append(new_id); ids.sort(); promotion.set("touring_company_ids", ids)
    return CommandResult.success(str(command.get("command_id")), {"mutation": "touring_company_split", "source_id": source_id, "new_id": new_id})

func _apply_merge_company(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed_payload(command, ["target_touring_company_id", "source_touring_company_id"], ["target_touring_company_id", "source_touring_company_id"])
    if not closed.is_empty(): return closed
    var target_id: String = str(payload["target_touring_company_id"])
    var source_id: String = str(payload["source_touring_company_id"])
    if target_id == source_id: return _reject(command, "STATE002", "payload", {"reason": "distinct_companies_required"})
    for pair: Array in [[target_id, "payload.target_touring_company_id"], [source_id, "payload.source_touring_company_id"]]:
        var ref_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), str(pair[0]), "touring", state.get("touring_companies"), str(pair[1]))
        if not ref_error.is_empty(): return ref_error
    var target: RefCounted = (state.get("touring_companies") as Dictionary)[target_id]
    var source: RefCounted = (state.get("touring_companies") as Dictionary)[source_id]
    if str(target.get("promotion_id")) != str(source.get("promotion_id")):
        return _reject(command, "STATE003", "payload", {"reason": "promotion_mismatch"})
    if str(source.get("status")) != "active":
        return _reject(command, "STATE002", "payload.source_touring_company_id", {"reason": "source_not_active"})
    var people: Array = target.get("person_assignment_ids")
    for value: Variant in source.get("person_assignment_ids"):
        if not value in people: people.append(value)
    people.sort(); target.set("person_assignment_ids", people)
    var titles: Array = target.get("carried_championship_ids")
    for value: Variant in source.get("carried_championship_ids"):
        if not value in titles: titles.append(value)
    titles.sort(); target.set("carried_championship_ids", titles)
    source.set("status", "merged")
    source.set("person_assignment_ids", [])
    source.set("carried_championship_ids", [])
    return CommandResult.success(str(command.get("command_id")), {"mutation": "touring_company_merged", "target_id": target_id, "source_id": source_id})

func _apply_start_program(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var allowed: Array[String] = ["program_id", "promotion_id", "side_a_person_ids", "side_b_person_ids", "purpose_id", "phase_id", "objective_ids", "planned_direction_id"]
    var closed: Dictionary = _closed_payload(command, allowed, ["program_id", "promotion_id", "side_a_person_ids", "side_b_person_ids", "purpose_id", "phase_id"])
    if not closed.is_empty(): return closed
    var program_id: String = str(payload["program_id"])
    var promotion_id: String = str(payload["promotion_id"])
    if not DomainIds.is_runtime_id(program_id, "program"): return _reject(command, "ID001", "payload.program_id", {"id": program_id})
    if (state.get("programs") as Dictionary).has(program_id): return _reject(command, "STATE002", "payload.program_id", {"reason": "already_exists"})
    var promotion_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), promotion_id, "promotion", state.get("promotions"), "payload.promotion_id")
    if not promotion_error.is_empty(): return promotion_error
    for field: String in ["side_a_person_ids", "side_b_person_ids"]:
        if not payload[field] is Array or (payload[field] as Array).is_empty(): return _reject(command, "CMD001", "payload." + field, {"reason": "nonempty_array_required"})
        var seen: Dictionary = {}
        for person_value: Variant in payload[field]:
            var person_id: String = str(person_value)
            if seen.has(person_id): return _reject(command, "STATE002", "payload." + field, {"reason": "duplicate_person", "person_id": person_id})
            seen[person_id] = true
            var person_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), person_id, "person", state.get("people"), "payload." + field)
            if not person_error.is_empty(): return person_error
    var program: RefCounted = ProgramState.new()
    program.set("id", program_id); program.set("promotion_id", promotion_id); program.set("started_on", str(state.get("current_date")))
    program.set("side_a", {"person_ids": (payload["side_a_person_ids"] as Array).duplicate()})
    program.set("side_b", {"person_ids": (payload["side_b_person_ids"] as Array).duplicate()})
    program.set("purpose_id", str(payload["purpose_id"])); program.set("phase_id", str(payload["phase_id"]))
    program.set("objective_ids", (payload.get("objective_ids", []) as Array).duplicate())
    program.set("planned_direction_id", payload.get("planned_direction_id", null))
    program.set("heat", 0.3); program.set("momentum", 0.0)
    (state.get("programs") as Dictionary)[program_id] = program
    var promotion: RefCounted = (state.get("promotions") as Dictionary)[promotion_id]
    var ids: Array = promotion.get("program_ids"); ids.append(program_id); ids.sort(); promotion.set("program_ids", ids)
    return CommandResult.success(str(command.get("command_id")), {"mutation": "program_started", "program_id": program_id})

func _apply_end_program(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed_payload(command, ["program_id"], ["program_id"])
    if not closed.is_empty(): return closed
    var program_id: String = str(payload["program_id"])
    var error: Dictionary = _runtime_ref_error(str(command.get("command_id")), program_id, "program", state.get("programs"), "payload.program_id")
    if not error.is_empty(): return error
    var program: RefCounted = (state.get("programs") as Dictionary)[program_id]
    program.set("status", "ended"); program.set("ended_on", str(state.get("current_date")))
    return CommandResult.success(str(command.get("command_id")), {"mutation": "program_ended", "program_id": program_id})

func _apply_approve_major_outcome(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var allowed: Array[String] = ["promotion_id", "winner_person_id", "loser_person_id", "championship_id", "program_id"]
    var closed: Dictionary = _closed_payload(command, allowed, ["promotion_id", "winner_person_id"])
    if not closed.is_empty(): return closed
    var promotion_id: String = str(payload["promotion_id"])
    var promotion_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), promotion_id, "promotion", state.get("promotions"), "payload.promotion_id")
    if not promotion_error.is_empty(): return promotion_error
    for field: String in ["winner_person_id", "loser_person_id"]:
        if payload.has(field) and payload[field] != null:
            var person_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), str(payload[field]), "person", state.get("people"), "payload." + field)
            if not person_error.is_empty(): return person_error
    if payload.has("championship_id") and payload["championship_id"] != null:
        var title_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), str(payload["championship_id"]), "championship", state.get("championships"), "payload.championship_id")
        if not title_error.is_empty(): return title_error
    if payload.has("program_id") and payload["program_id"] != null:
        var program_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), str(payload["program_id"]), "program", state.get("programs"), "payload.program_id")
        if not program_error.is_empty(): return program_error
    var approved: Dictionary = (state.get("world_state") as Dictionary).get("approved_major_outcomes", {})
    approved[promotion_id] = payload.duplicate(true)
    (state.get("world_state") as Dictionary)["approved_major_outcomes"] = approved
    return CommandResult.success(str(command.get("command_id")), {"mutation": "major_outcome_approved", "promotion_id": promotion_id})

func _apply_person_directive(state: RefCounted, command: RefCounted, kind: String) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed_payload(command, ["touring_company_id", "person_id", "weight"], ["touring_company_id", "person_id"])
    if not closed.is_empty(): return closed
    var company_id: String = str(payload["touring_company_id"])
    var company_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), company_id, "touring", state.get("touring_companies"), "payload.touring_company_id")
    if not company_error.is_empty(): return company_error
    var person_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), str(payload["person_id"]), "person", state.get("people"), "payload.person_id")
    if not person_error.is_empty(): return person_error
    var company: RefCounted = (state.get("touring_companies") as Dictionary)[company_id]
    if not str(payload["person_id"]) in (company.get("person_assignment_ids") as Array):
        return _reject(command, "STATE002", "payload.person_id", {"reason": "person_not_assigned_to_company"})
    var directive: Dictionary = {"kind": kind, "person_id": str(payload["person_id"]), "weight": float(payload.get("weight", 1.0))}
    _upsert_directive(company, directive)
    return CommandResult.success(str(command.get("command_id")), {"mutation": "person_directive_updated", "kind": kind, "person_id": payload["person_id"]})

func _apply_adjust_budget(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed_payload(command, ["touring_company_id", "monthly_budget"], ["touring_company_id", "monthly_budget"])
    if not closed.is_empty(): return closed
    var company_id: String = str(payload["touring_company_id"])
    var company_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), company_id, "touring", state.get("touring_companies"), "payload.touring_company_id")
    if not company_error.is_empty(): return company_error
    var money_error: Dictionary = _validate_money(payload["monthly_budget"], command, "payload.monthly_budget")
    if not money_error.is_empty(): return money_error
    ((state.get("touring_companies") as Dictionary)[company_id] as RefCounted).set("monthly_budget", (payload["monthly_budget"] as Dictionary).duplicate(true))
    return CommandResult.success(str(command.get("command_id")), {"mutation": "touring_budget_updated"})

func _apply_set_booker(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed_payload(command, ["promotion_id", "person_id"], ["promotion_id", "person_id"])
    if not closed.is_empty(): return closed
    var promotion_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), str(payload["promotion_id"]), "promotion", state.get("promotions"), "payload.promotion_id")
    if not promotion_error.is_empty(): return promotion_error
    var person_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), str(payload["person_id"]), "person", state.get("people"), "payload.person_id")
    if not person_error.is_empty(): return person_error
    var map: Dictionary = (state.get("world_state") as Dictionary).get("booker_by_promotion", {})
    map[str(payload["promotion_id"])] = str(payload["person_id"])
    (state.get("world_state") as Dictionary)["booker_by_promotion"] = map
    return CommandResult.success(str(command.get("command_id")), {"mutation": "booker_updated"})

func _apply_book_market_focus(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed_payload(command, ["promotion_id", "market_id", "intensity"], ["promotion_id", "market_id", "intensity"])
    if not closed.is_empty(): return closed
    var promotion_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), str(payload["promotion_id"]), "promotion", state.get("promotions"), "payload.promotion_id")
    if not promotion_error.is_empty(): return promotion_error
    if not (state.get("markets") as Dictionary).has(str(payload["market_id"])): return _reject(command, "REF001", "payload.market_id", {"id": payload["market_id"]})
    var intensity: float = float(payload["intensity"])
    if intensity < 0.0 or intensity > 1.0: return _reject(command, "STATE001", "payload.intensity", {"minimum": 0.0, "maximum": 1.0, "value": intensity})
    var focus: Dictionary = (state.get("world_state") as Dictionary).get("market_focus_by_promotion", {})
    focus[str(payload["promotion_id"])] = {"market_id": str(payload["market_id"]), "intensity": intensity}
    (state.get("world_state") as Dictionary)["market_focus_by_promotion"] = focus
    return CommandResult.success(str(command.get("command_id")), {"mutation": "market_focus_updated"})

func _apply_local_media_spend(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed_payload(command, ["promotion_id", "spend"], ["promotion_id", "spend"])
    if not closed.is_empty(): return closed
    var promotion_id: String = str(payload["promotion_id"])
    var promotion_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), promotion_id, "promotion", state.get("promotions"), "payload.promotion_id")
    if not promotion_error.is_empty(): return promotion_error
    var money_error: Dictionary = _validate_money(payload["spend"], command, "payload.spend")
    if not money_error.is_empty(): return money_error
    var spend: Dictionary = (state.get("world_state") as Dictionary).get("local_media_spend_by_promotion", {})
    spend[promotion_id] = (payload["spend"] as Dictionary).duplicate(true)
    (state.get("world_state") as Dictionary)["local_media_spend_by_promotion"] = spend
    return CommandResult.success(str(command.get("command_id")), {"mutation": "local_media_spend_updated"})

func _apply_sign_media_deal(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var allowed: Array[String] = ["media_deal_id", "promotion_id", "medium_id", "outlet_id", "reach_market_ids", "start_date", "end_date", "schedule_id", "cost", "revenue", "exclusivity_id", "production_requirement_ids", "restriction_ids"]
    var closed: Dictionary = _closed_payload(command, allowed, ["media_deal_id", "promotion_id", "medium_id", "outlet_id", "reach_market_ids", "schedule_id"])
    if not closed.is_empty(): return closed
    var deal_id: String = str(payload["media_deal_id"])
    var promotion_id: String = str(payload["promotion_id"])
    if not DomainIds.is_runtime_id(deal_id, "media_deal"): return _reject(command, "ID001", "payload.media_deal_id", {"id": deal_id})
    if (state.get("media_deals") as Dictionary).has(deal_id): return _reject(command, "STATE002", "payload.media_deal_id", {"reason": "already_exists"})
    var promotion_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), promotion_id, "promotion", state.get("promotions"), "payload.promotion_id")
    if not promotion_error.is_empty(): return promotion_error
    if not payload["reach_market_ids"] is Array or (payload["reach_market_ids"] as Array).is_empty(): return _reject(command, "CMD001", "payload.reach_market_ids", {"reason": "nonempty_array_required"})
    for market_value: Variant in payload["reach_market_ids"]:
        if not (state.get("markets") as Dictionary).has(str(market_value)): return _reject(command, "REF001", "payload.reach_market_ids", {"id": market_value})
    for money_field: String in ["cost", "revenue"]:
        if payload.has(money_field) and payload[money_field] != null:
            var money_error: Dictionary = _validate_money(payload[money_field], command, "payload." + money_field)
            if not money_error.is_empty(): return money_error
    var deal: RefCounted = MediaDealState.new()
    deal.set("id", deal_id); deal.set("promotion_id", promotion_id); deal.set("medium_id", str(payload["medium_id"])); deal.set("outlet_id", str(payload["outlet_id"]))
    deal.set("reach_market_ids", (payload["reach_market_ids"] as Array).duplicate()); deal.set("start_date", str(payload.get("start_date", state.get("current_date"))))
    deal.set("end_date", payload.get("end_date", null)); deal.set("schedule_id", str(payload["schedule_id"])); deal.set("cost", payload.get("cost", null)); deal.set("revenue", payload.get("revenue", null))
    deal.set("exclusivity_id", payload.get("exclusivity_id", null)); deal.set("production_requirement_ids", (payload.get("production_requirement_ids", []) as Array).duplicate()); deal.set("restriction_ids", (payload.get("restriction_ids", []) as Array).duplicate())
    (state.get("media_deals") as Dictionary)[deal_id] = deal
    var promotion: RefCounted = (state.get("promotions") as Dictionary)[promotion_id]
    var ids: Array = promotion.get("media_deal_ids"); ids.append(deal_id); ids.sort(); promotion.set("media_deal_ids", ids)
    return CommandResult.success(str(command.get("command_id")), {"mutation": "media_deal_signed", "media_deal_id": deal_id})

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
    var championship: RefCounted = championships[championship_id]
    championship.set("holder_person_ids", holders.duplicate(true))
    return CommandResult.success(command_id, {"mutation": "championship_holders_updated", "championship_id": championship_id})

func _validate_route(state: RefCounted, route_value: Variant, content_index: Dictionary, command: RefCounted) -> Dictionary:
    if not route_value is Array or (route_value as Array).is_empty():
        return _reject(command, "CMD001", "payload.route", {"reason": "nonempty_array_required"})
    var route: Array = route_value
    var market_ids: Array[String] = []
    for index: int in range(route.size()):
        if not route[index] is Dictionary or not (route[index] as Dictionary).has("market_id"):
            return _reject(command, "CMD001", "payload.route[" + str(index) + "]", {"reason": "tour_stop_market_required"})
        var market_id: String = str((route[index] as Dictionary)["market_id"])
        if not (state.get("markets") as Dictionary).has(market_id):
            return _reject(command, "REF001", "payload.route[" + str(index) + "].market_id", {"id": market_id})
        market_ids.append(market_id)
    var connections: Dictionary = content_index.get("travel_connections", {})
    if not connections.is_empty() and market_ids.size() > 1:
        for index: int in range(1, market_ids.size()):
            var a: String = market_ids[index - 1]; var b: String = market_ids[index]
            if a == b: continue
            if not connections.has(a + "|" + b) and not connections.has(b + "|" + a):
                return _reject(command, "REF001", "payload.route[" + str(index) + "]", {"reason": "markets_not_connected", "from_market_id": a, "to_market_id": b})
    return {}

func _validate_assignments(state: RefCounted, promotion_id: String, assignments: Array, exempt_company_id: String, command: RefCounted) -> Dictionary:
    var seen: Dictionary = {}
    for person_value: Variant in assignments:
        var person_id: String = str(person_value)
        if seen.has(person_id): return _reject(command, "STATE002", "payload.person_assignment_ids", {"reason": "duplicate_assignment", "person_id": person_id})
        seen[person_id] = true
        var person_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), person_id, "person", state.get("people"), "payload.person_assignment_ids")
        if not person_error.is_empty(): return person_error
        for company_id: String in DomainIds.sorted_keys(state.get("touring_companies")):
            if company_id == exempt_company_id: continue
            var company: RefCounted = (state.get("touring_companies") as Dictionary)[company_id]
            if str(company.get("promotion_id")) == promotion_id and str(company.get("status")) == "active" and person_id in (company.get("person_assignment_ids") as Array):
                return _reject(command, "STATE002", "payload.person_assignment_ids", {"reason": "incompatible_simultaneous_assignment", "person_id": person_id, "existing_touring_company_id": company_id})
    return {}

func _validate_titles(state: RefCounted, promotion_id: String, titles: Array, command: RefCounted) -> Dictionary:
    var seen: Dictionary = {}
    for title_value: Variant in titles:
        var title_id: String = str(title_value)
        if seen.has(title_id): return _reject(command, "STATE002", "payload.carried_championship_ids", {"reason": "duplicate_title", "id": title_id})
        seen[title_id] = true
        var error: Dictionary = _runtime_ref_error(str(command.get("command_id")), title_id, "championship", state.get("championships"), "payload.carried_championship_ids")
        if not error.is_empty(): return error
        if str(((state.get("championships") as Dictionary)[title_id] as RefCounted).get("promotion_id")) != promotion_id:
            return _reject(command, "STATE003", "payload.carried_championship_ids", {"reason": "championship_promotion_mismatch", "id": title_id})
    return {}

func _validate_directive(state: RefCounted, company: RefCounted, directive_value: Variant, command: RefCounted) -> Dictionary:
    if not directive_value is Dictionary: return _reject(command, "CMD001", "payload.directive", {"reason": "expected_object"})
    var directive: Dictionary = directive_value
    var allowed_fields: Array[String] = ["kind", "person_id", "program_id", "championship_id", "weight", "style_id"]
    for key: Variant in directive.keys():
        if not str(key) in allowed_fields: return _reject(command, "CMD001", "payload.directive." + str(key), {"reason": "unknown_field"})
    var kind: String = str(directive.get("kind", ""))
    if not kind in ["push", "protect", "program_emphasis", "title_priority", "style_emphasis"]:
        return _reject(command, "CMD001", "payload.directive.kind", {"kind": kind})
    if kind in ["push", "protect"]:
        if not directive.has("person_id"): return _reject(command, "CMD001", "payload.directive.person_id", {"reason": "required"})
        var person_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), str(directive["person_id"]), "person", state.get("people"), "payload.directive.person_id")
        if not person_error.is_empty(): return person_error
        if not str(directive["person_id"]) in (company.get("person_assignment_ids") as Array): return _reject(command, "STATE002", "payload.directive.person_id", {"reason": "person_not_assigned_to_company"})
    if kind == "program_emphasis":
        if not directive.has("program_id"): return _reject(command, "CMD001", "payload.directive.program_id", {"reason": "required"})
        var program_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), str(directive["program_id"]), "program", state.get("programs"), "payload.directive.program_id")
        if not program_error.is_empty(): return program_error
    if kind == "title_priority":
        if not directive.has("championship_id"): return _reject(command, "CMD001", "payload.directive.championship_id", {"reason": "required"})
        var title_error: Dictionary = _runtime_ref_error(str(command.get("command_id")), str(directive["championship_id"]), "championship", state.get("championships"), "payload.directive.championship_id")
        if not title_error.is_empty(): return title_error
    if directive.has("weight") and (float(directive["weight"]) < 0.0 or float(directive["weight"]) > 1.0): return _reject(command, "STATE001", "payload.directive.weight", {"minimum": 0.0, "maximum": 1.0})
    return {}

func _upsert_directive(company: RefCounted, directive_value: Variant) -> void:
    var directive: Dictionary = directive_value
    var directives: Array = company.get("directives")
    var kind: String = str(directive.get("kind"))
    for index: int in range(directives.size() - 1, -1, -1):
        if directives[index] is Dictionary and str((directives[index] as Dictionary).get("kind", "")) == kind:
            directives.remove_at(index)
    directives.append(directive.duplicate(true))
    company.set("directives", directives)

func _validate_money(value: Variant, command: RefCounted, path: String) -> Dictionary:
    if not value is Dictionary: return _reject(command, "CMD001", path, {"reason": "money_object_required"})
    var money: Dictionary = value
    if not money.get("minor_units") is int or str(money.get("currency_id", "")).is_empty(): return _reject(command, "CMD001", path, {"reason": "integer_minor_units_and_currency_required"})
    if int(money["minor_units"]) < 0: return _reject(command, "STATE001", path + ".minor_units", {"minimum": 0})
    return {}

func _closed_payload(command: RefCounted, allowed: Array[String], required: Array[String]) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    for key: Variant in payload.keys():
        if not str(key) in allowed: return _reject(command, "CMD001", "payload." + str(key), {"reason": "unknown_field"})
    for field: String in required:
        if not payload.has(field): return _reject(command, "CMD001", "payload." + field, {"reason": "required"})
    return {}

func _runtime_ref_error(command_id: String, value: String, family: String, store_value: Variant, path: String) -> Dictionary:
    if not DomainIds.is_runtime_id(value): return CommandResult.rejection(command_id, "ID001", path, "validation.id001", {"id": value})
    if DomainIds.runtime_family(value) != family: return CommandResult.rejection(command_id, "REF003", path, "validation.ref003", {"id": value, "expected_family": family})
    if not store_value is Dictionary or not (store_value as Dictionary).has(value): return CommandResult.rejection(command_id, "REF001", path, "validation.ref001", {"id": value})
    return {}

func _reject(command: RefCounted, code: String, path: String, details: Dictionary) -> Dictionary:
    return CommandResult.rejection(str(command.get("command_id")), code, path, "validation." + code.to_lower(), details)
