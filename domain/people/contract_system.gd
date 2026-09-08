extends RefCounted

const DomainIds = preload("res://domain/core/domain_ids.gd")
const ContractState = preload("res://domain/people/contract_state.gd")
const CommandResult = preload("res://app/commands/command_result.gd")
const DomainEvent = preload("res://domain/events/domain_event.gd")

func apply_offer(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed(command, ["contract_id", "promotion_id", "person_id", "compensation", "exclusivity_id", "end_date", "clause_ids", "clause_parameters"], ["contract_id", "promotion_id", "person_id", "compensation", "exclusivity_id", "end_date"])
    if not closed.is_empty(): return closed
    var contract_id: String = str(payload.get("contract_id"))
    var promotion_id: String = str(payload.get("promotion_id"))
    var person_id: String = str(payload.get("person_id"))
    var validation: Dictionary = _validate_new_offer(state, command, contract_id, promotion_id, person_id, payload.get("compensation"), str(payload.get("end_date")))
    if not validation.is_empty(): return validation
    var offered: int = _minor_units(payload.get("compensation"))
    var person: RefCounted = (state.get("people") as Dictionary)[person_id]
    var threshold: int = _acceptance_threshold(person, _active_contract_for_person(state, person_id), state)
    var blocked: bool = _blocked_by_exclusivity(state, person_id)
    if not blocked and offered >= threshold:
        _replace_expiring_contracts(state, person_id)
        _activate(state, contract_id, promotion_id, person_id, payload)
        return CommandResult.success(str(command.get("command_id")), {"mutation": "contract_activated", "outcome": "accepted", "contract_id": contract_id, "person_id": person_id, "promotion_id": promotion_id, "offered_minor_units": offered, "required_minor_units": threshold})
    if not blocked and offered >= int(round(float(threshold) * 0.76)):
        var counter: int = threshold
        _pending(state)[contract_id] = {"status": "countered", "promotion_id": promotion_id, "person_id": person_id, "counter_minor_units": counter, "proposal": payload.duplicate(true), "source_command_id": command.get("command_id")}
        return CommandResult.success(str(command.get("command_id")), {"mutation": "negotiation_recorded", "outcome": "countered", "contract_id": contract_id, "person_id": person_id, "counter_minor_units": counter})
    return CommandResult.success(str(command.get("command_id")), {"mutation": "none", "outcome": "rejected", "contract_id": contract_id, "person_id": person_id, "reason": "exclusive_commitment" if blocked else "price_below_expectation", "offered_minor_units": offered, "required_minor_units": threshold})

func apply_counter(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed(command, ["contract_id", "promotion_id", "compensation", "end_date"], ["contract_id", "promotion_id", "compensation"])
    if not closed.is_empty(): return closed
    var contract_id: String = str(payload.get("contract_id"))
    var pending: Dictionary = (state.get("world_state") as Dictionary).get("contract_negotiations_v1", {})
    if not pending.has(contract_id): return _reject(command, "REF001", "payload.contract_id", {"reason": "pending_negotiation_missing", "id": contract_id})
    var negotiation: Dictionary = pending[contract_id]
    if str(negotiation.get("promotion_id")) != str(payload.get("promotion_id")): return _reject(command, "STATE003", "payload.promotion_id", {"reason": "negotiation_scope_mismatch"})
    var scope: Dictionary = _scope(command, str(payload.get("promotion_id")))
    if not scope.is_empty(): return scope
    var money_error: Dictionary = _money(command, payload.get("compensation"), "payload.compensation")
    if not money_error.is_empty(): return money_error
    var offered: int = _minor_units(payload.get("compensation"))
    if offered < int(negotiation.get("counter_minor_units", 0)):
        return CommandResult.success(str(command.get("command_id")), {"mutation": "none", "outcome": "rejected", "contract_id": contract_id, "reason": "counter_not_met"})
    var proposal: Dictionary = (negotiation.get("proposal", {}) as Dictionary).duplicate(true)
    proposal["compensation"] = (payload.get("compensation") as Dictionary).duplicate(true)
    if payload.has("end_date"): proposal["end_date"] = payload.get("end_date")
    _replace_expiring_contracts(state, str(negotiation.get("person_id")))
    _activate(state, contract_id, str(negotiation.get("promotion_id")), str(negotiation.get("person_id")), proposal)
    pending.erase(contract_id)
    return CommandResult.success(str(command.get("command_id")), {"mutation": "contract_activated", "outcome": "accepted", "contract_id": contract_id, "person_id": negotiation.get("person_id"), "promotion_id": negotiation.get("promotion_id"), "offered_minor_units": offered})

func apply_renew(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed(command, ["contract_id", "promotion_id", "compensation", "end_date"], ["contract_id", "promotion_id", "compensation", "end_date"])
    if not closed.is_empty(): return closed
    var contract_id: String = str(payload.get("contract_id"))
    if not (state.get("contracts") as Dictionary).has(contract_id): return _reject(command, "REF001", "payload.contract_id", {"id": contract_id})
    var contract: RefCounted = (state.get("contracts") as Dictionary)[contract_id]
    if str(contract.get("status")) != "active" or str(contract.get("promotion_id")) != str(payload.get("promotion_id")): return _reject(command, "STATE003", "payload.contract_id", {"reason": "active_contract_scope_required"})
    var scope: Dictionary = _scope(command, str(payload.get("promotion_id")))
    if not scope.is_empty(): return scope
    var money_error: Dictionary = _money(command, payload.get("compensation"), "payload.compensation")
    if not money_error.is_empty(): return money_error
    var person: RefCounted = (state.get("people") as Dictionary)[str(contract.get("person_id"))]
    var threshold: int = _acceptance_threshold(person, contract, state)
    var offered: int = _minor_units(payload.get("compensation"))
    if offered < int(round(float(threshold) * 0.80)):
        return CommandResult.success(str(command.get("command_id")), {"mutation": "none", "outcome": "rejected", "contract_id": contract_id, "reason": "renewal_price_below_expectation", "required_minor_units": threshold})
    if offered < threshold:
        _pending(state)[contract_id] = {"status": "countered_renewal", "promotion_id": contract.get("promotion_id"), "person_id": contract.get("person_id"), "counter_minor_units": threshold, "proposal": {"contract_id": contract_id, "promotion_id": contract.get("promotion_id"), "person_id": contract.get("person_id"), "compensation": payload.get("compensation"), "exclusivity_id": contract.get("exclusivity_id"), "end_date": payload.get("end_date")}, "source_command_id": command.get("command_id")}
        return CommandResult.success(str(command.get("command_id")), {"mutation": "negotiation_recorded", "outcome": "countered", "contract_id": contract_id, "counter_minor_units": threshold})
    contract.set("compensation", (payload.get("compensation") as Dictionary).duplicate(true)); contract.set("end_date", str(payload.get("end_date")))
    return CommandResult.success(str(command.get("command_id")), {"mutation": "contract_renewed", "outcome": "accepted", "contract_id": contract_id, "person_id": contract.get("person_id"), "promotion_id": contract.get("promotion_id")})

func apply_release(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed(command, ["contract_id", "promotion_id"], ["contract_id", "promotion_id"])
    if not closed.is_empty(): return closed
    var contract_id: String = str(payload.get("contract_id"))
    if not (state.get("contracts") as Dictionary).has(contract_id): return _reject(command, "REF001", "payload.contract_id", {"id": contract_id})
    var contract: RefCounted = (state.get("contracts") as Dictionary)[contract_id]
    if str(contract.get("status")) != "active" or str(contract.get("promotion_id")) != str(payload.get("promotion_id")): return _reject(command, "STATE003", "payload.contract_id", {"reason": "active_contract_scope_required"})
    var scope: Dictionary = _scope(command, str(payload.get("promotion_id")))
    if not scope.is_empty(): return scope
    var person_id: String = str(contract.get("person_id")); var promotion_id: String = str(contract.get("promotion_id"))
    _deactivate(state, contract, "released")
    return CommandResult.success(str(command.get("command_id")), {"mutation": "contract_released", "outcome": "released", "contract_id": contract_id, "person_id": person_id, "promotion_id": promotion_id})

func resolve_expiry(state: RefCounted, target_date: String) -> Dictionary:
    var events: Array[Dictionary] = []
    for contract_id: String in DomainIds.sorted_keys(state.get("contracts")):
        var contract: RefCounted = (state.get("contracts") as Dictionary)[contract_id]
        var end_value: Variant = contract.get("end_date")
        if str(contract.get("status")) == "active" and end_value != null and str(end_value) <= target_date:
            var person_id: String = str(contract.get("person_id")); var promotion_id: String = str(contract.get("promotion_id"))
            _deactivate(state, contract, "expired")
            events.append(DomainEvent.make("ContractExpired", target_date, [contract_id, person_id, promotion_id], {"contract_id": contract_id, "person_id": person_id, "promotion_id": promotion_id}, {"category": "talent", "historical_class": "state_change", "explanation": [{"source": "contract_term", "end_date": end_value}]}))
    return {"passed": true, "errors": [], "events": events}

func _validate_new_offer(state: RefCounted, command: RefCounted, contract_id: String, promotion_id: String, person_id: String, compensation: Variant, end_date: String) -> Dictionary:
    if not DomainIds.is_runtime_id(contract_id, "contract"): return _reject(command, "ID001", "payload.contract_id", {"id": contract_id})
    var existing_negotiations: Dictionary = (state.get("world_state") as Dictionary).get("contract_negotiations_v1", {})
    if (state.get("contracts") as Dictionary).has(contract_id) or existing_negotiations.has(contract_id): return _reject(command, "STATE002", "payload.contract_id", {"reason": "already_exists", "id": contract_id})
    if not (state.get("promotions") as Dictionary).has(promotion_id): return _reject(command, "REF001", "payload.promotion_id", {"id": promotion_id})
    if not (state.get("people") as Dictionary).has(person_id): return _reject(command, "REF001", "payload.person_id", {"id": person_id})
    var scope: Dictionary = _scope(command, promotion_id)
    if not scope.is_empty(): return scope
    var money_error: Dictionary = _money(command, compensation, "payload.compensation")
    if not money_error.is_empty(): return money_error
    if end_date <= str(state.get("current_date")): return _reject(command, "STATE001", "payload.end_date", {"reason": "future_date_required"})
    return {}

func _activate(state: RefCounted, contract_id: String, promotion_id: String, person_id: String, payload: Dictionary) -> void:
    var contract: RefCounted = ContractState.new()
    contract.set("id", contract_id); contract.set("person_id", person_id); contract.set("promotion_id", promotion_id); contract.set("status", "active")
    contract.set("start_date", str(state.get("current_date"))); contract.set("end_date", payload.get("end_date")); contract.set("compensation", (payload.get("compensation") as Dictionary).duplicate(true)); contract.set("exclusivity_id", str(payload.get("exclusivity_id")))
    contract.set("clause_ids", (payload.get("clause_ids", []) as Array).duplicate()); contract.set("clause_parameters", (payload.get("clause_parameters", {}) as Dictionary).duplicate(true)); contract.set("leverage", 0.4)
    (state.get("contracts") as Dictionary)[contract_id] = contract
    var person: RefCounted = (state.get("people") as Dictionary)[person_id]; var person_ids: Array = person.get("active_contract_ids"); person_ids.append(contract_id); person_ids.sort(); person.set("active_contract_ids", person_ids)
    var promotion: RefCounted = (state.get("promotions") as Dictionary)[promotion_id]; var promotion_ids: Array = promotion.get("contract_ids"); promotion_ids.append(contract_id); promotion_ids.sort(); promotion.set("contract_ids", promotion_ids)

func _deactivate(state: RefCounted, contract: RefCounted, status: String) -> void:
    contract.set("status", status)
    var person_id: String = str(contract.get("person_id")); var promotion_id: String = str(contract.get("promotion_id")); var contract_id: String = str(contract.get("id"))
    if (state.get("people") as Dictionary).has(person_id):
        var person: RefCounted = (state.get("people") as Dictionary)[person_id]; var ids: Array = person.get("active_contract_ids"); ids.erase(contract_id); person.set("active_contract_ids", ids)
    if (state.get("promotions") as Dictionary).has(promotion_id):
        var promotion: RefCounted = (state.get("promotions") as Dictionary)[promotion_id]; var ids: Array = promotion.get("contract_ids"); ids.erase(contract_id); promotion.set("contract_ids", ids)
    var bookers: Dictionary = (state.get("world_state") as Dictionary).get("booker_by_promotion", {})
    if str(bookers.get(promotion_id, "")) == person_id:
        bookers.erase(promotion_id)
        (state.get("world_state") as Dictionary)["booker_by_promotion"] = bookers
    for company_value: Variant in (state.get("touring_companies") as Dictionary).values():
        var company: RefCounted = company_value
        if str(company.get("promotion_id")) == promotion_id:
            var assignments: Array = company.get("person_assignment_ids"); assignments.erase(person_id); company.set("person_assignment_ids", assignments)

func _replace_expiring_contracts(state: RefCounted, person_id: String) -> void:
    for contract_value: Variant in (state.get("contracts") as Dictionary).values():
        var contract: RefCounted = contract_value
        if str(contract.get("person_id")) == person_id and str(contract.get("status")) == "active": _deactivate(state, contract, "superseded")

func _active_contract_for_person(state: RefCounted, person_id: String) -> Variant:
    for contract_value: Variant in (state.get("contracts") as Dictionary).values():
        var contract: RefCounted = contract_value
        if str(contract.get("person_id")) == person_id and str(contract.get("status")) == "active": return contract
    return null

func _blocked_by_exclusivity(state: RefCounted, person_id: String) -> bool:
    var contract: Variant = _active_contract_for_person(state, person_id)
    if not contract is RefCounted: return false
    var end_value: Variant = (contract as RefCounted).get("end_date")
    if end_value == null: return true
    return _months_between(str(state.get("current_date")), str(end_value)) > 3

func _acceptance_threshold(person: RefCounted, current_contract: Variant, state: RefCounted) -> int:
    var career: Dictionary = person.get("career")
    var demand: int = int(career.get("contract_demand_minor_units", 12000))
    var leverage: float = float(career.get("contract_leverage", 0.45))
    if current_contract is RefCounted: leverage = maxf(leverage, float((current_contract as RefCounted).get("leverage")))
    return maxi(1000, int(round(float(demand) * (0.88 + leverage * 0.24))))

func _pending(state: RefCounted) -> Dictionary:
    var world: Dictionary = state.get("world_state")
    if not world.has("contract_negotiations_v1"): world["contract_negotiations_v1"] = {}
    return world["contract_negotiations_v1"]

func _money(command: RefCounted, value: Variant, path: String) -> Dictionary:
    if not value is Dictionary or not (value as Dictionary).get("base") is Dictionary: return _reject(command, "CMD001", path, {"reason": "base_money_required"})
    var base: Dictionary = (value as Dictionary).get("base")
    if not base.get("minor_units") is int or int(base.get("minor_units")) < 0 or str(base.get("currency_id", "")).is_empty(): return _reject(command, "CMD001", path + ".base", {"reason": "nonnegative_integer_minor_units_and_currency_required"})
    return {}

func _minor_units(value: Variant) -> int:
    return int((((value as Dictionary).get("base", {}) as Dictionary).get("minor_units", 0))) if value is Dictionary else 0

func _scope(command: RefCounted, promotion_id: String) -> Dictionary:
    var issuer: Dictionary = command.get("issuer")
    if str(issuer.get("kind")) in ["player", "ai", "automation"] and str(issuer.get("promotion_id", "")) != promotion_id: return _reject(command, "STATE003", "issuer.promotion_id", {"reason": "promotion_scope_mismatch", "payload_promotion_id": promotion_id})
    return {}

func _closed(command: RefCounted, allowed: Array[String], required: Array[String]) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    for key: Variant in payload.keys():
        if not str(key) in allowed: return _reject(command, "CMD001", "payload." + str(key), {"reason": "unknown_field"})
    for field: String in required:
        if not payload.has(field): return _reject(command, "CMD001", "payload." + field, {"reason": "required"})
    return {}

func _months_between(a: String, b: String) -> int:
    var ap: PackedStringArray = a.split("-"); var bp: PackedStringArray = b.split("-")
    if ap.size() < 2 or bp.size() < 2: return 999
    return (int(bp[0]) - int(ap[0])) * 12 + int(bp[1]) - int(ap[1])

func _reject(command: RefCounted, code: String, path: String, details: Dictionary) -> Dictionary:
    return CommandResult.rejection(str(command.get("command_id")), code, path, "validation." + code.to_lower(), details)
