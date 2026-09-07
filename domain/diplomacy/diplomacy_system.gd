extends RefCounted

const DomainIds = preload("res://domain/core/domain_ids.gd")
const AgreementState = preload("res://domain/diplomacy/agreement_state.gd")
const CommandResult = preload("res://app/commands/command_result.gd")
const DomainEvent = preload("res://domain/events/domain_event.gd")
const PhaseEMath = preload("res://domain/core/phase_e_math.gd")

func apply_proposal(state: RefCounted, command: RefCounted, tuning: Dictionary) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed(command, ["agreement_id", "party_promotion_ids", "clause_ids", "clauses", "end_date"], ["agreement_id", "party_promotion_ids", "clause_ids", "clauses"])
    if not closed.is_empty(): return closed
    var agreement_id: String = str(payload.get("agreement_id")); var parties: Array = payload.get("party_promotion_ids", [])
    if not DomainIds.is_runtime_id(agreement_id, "agreement"): return _reject(command, "ID001", "payload.agreement_id", {"id": agreement_id})
    if (state.get("agreements") as Dictionary).has(agreement_id): return _reject(command, "STATE002", "payload.agreement_id", {"reason": "already_exists"})
    if parties.size() != 2 or str(parties[0]) == str(parties[1]): return _reject(command, "CMD001", "payload.party_promotion_ids", {"reason": "two_distinct_parties_required"})
    for party: Variant in parties:
        if not (state.get("promotions") as Dictionary).has(str(party)): return _reject(command, "REF001", "payload.party_promotion_ids", {"id": party})
    var issuer_scope: Dictionary = _issuer_scope(command, "", parties)
    if not issuer_scope.is_empty(): return issuer_scope
    for clause_value: Variant in payload.get("clauses", []):
        if not clause_value is Dictionary: return _reject(command, "CMD001", "payload.clauses", {"reason": "clause_object_required"})
        for market_id: Variant in (clause_value as Dictionary).get("market_ids", []):
            if not (state.get("markets") as Dictionary).has(str(market_id)): return _reject(command, "REF001", "payload.clauses.market_ids", {"id": market_id})
    for existing_value: Variant in (state.get("agreements") as Dictionary).values():
        var existing: RefCounted = existing_value
        var existing_parties: Array = existing.get("party_promotion_ids")
        if str(existing.get("status")) == "active" and _same_pair(parties, existing_parties):
            return CommandResult.success(str(command.get("command_id")), {"mutation": "none", "outcome": "rejected", "agreement_id": agreement_id, "reason": "active_pair_already_exists"})
    var relation: Dictionary = _relation_read(state, str(parties[0]), str(parties[1]))
    var accepted: bool = float(relation.get("trust", 0.0)) - float(relation.get("grievance", 0.0)) >= float(tuning.get("agreement_acceptance_threshold", -0.05))
    if not accepted: return CommandResult.success(str(command.get("command_id")), {"mutation": "none", "outcome": "rejected", "agreement_id": agreement_id, "reason": "trust_grievance_conditions"})
    var agreement: RefCounted = AgreementState.new(); agreement.set("id", agreement_id); agreement.set("party_promotion_ids", parties.duplicate()); agreement.set("status", "active"); agreement.set("start_date", str(state.get("current_date"))); agreement.set("end_date", payload.get("end_date", null)); agreement.set("clause_ids", (payload.get("clause_ids") as Array).duplicate()); agreement.set("clauses", (payload.get("clauses") as Array).duplicate(true)); agreement.set("trust_effect", 0.05)
    (state.get("agreements") as Dictionary)[agreement_id] = agreement
    for party: Variant in parties:
        var promotion: RefCounted = (state.get("promotions") as Dictionary)[str(party)]; var ids: Array = promotion.get("agreement_ids"); ids.append(agreement_id); ids.sort(); promotion.set("agreement_ids", ids)
    var mutable_relation: Dictionary = _relation(state, str(parties[0]), str(parties[1]))
    mutable_relation["trust"] = PhaseEMath.clamp_signed(float(mutable_relation.get("trust", 0.0)) + 0.04)
    return CommandResult.success(str(command.get("command_id")), {"mutation": "agreement_created", "outcome": "accepted", "agreement_id": agreement_id, "party_promotion_ids": parties.duplicate()})

func apply_violation(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed(command, ["agreement_id", "violator_promotion_id", "market_id"], ["agreement_id", "violator_promotion_id", "market_id"])
    if not closed.is_empty(): return closed
    var agreement_id: String = str(payload.get("agreement_id")); var violator: String = str(payload.get("violator_promotion_id")); var market_id: String = str(payload.get("market_id"))
    var scope: Dictionary = _issuer_scope(command, violator, [violator])
    if not scope.is_empty(): return scope
    if not (state.get("agreements") as Dictionary).has(agreement_id): return _reject(command, "REF001", "payload.agreement_id", {"id": agreement_id})
    if not (state.get("markets") as Dictionary).has(market_id): return _reject(command, "REF001", "payload.market_id", {"id": market_id})
    var agreement: RefCounted = (state.get("agreements") as Dictionary)[agreement_id]
    if str(agreement.get("status")) != "active" or not violator in (agreement.get("party_promotion_ids") as Array): return _reject(command, "STATE003", "payload.agreement_id", {"reason": "active_party_agreement_required"})
    var protected_for: String = ""
    for clause_value: Variant in agreement.get("clauses"):
        if clause_value is Dictionary and market_id in ((clause_value as Dictionary).get("market_ids", []) as Array): protected_for = str((clause_value as Dictionary).get("protected_promotion_id", ""))
    if protected_for.is_empty() or protected_for == violator: return _reject(command, "STATE003", "payload.market_id", {"reason": "market_not_protected_against_violator"})
    var pending: Array = (state.get("world_state") as Dictionary).get("pending_territory_violations_v1", [])
    pending.append({"agreement_id": agreement_id, "violator_promotion_id": violator, "protected_promotion_id": protected_for, "market_id": market_id, "command_id": command.get("command_id")}); (state.get("world_state") as Dictionary)["pending_territory_violations_v1"] = pending
    agreement.set("trust_effect", PhaseEMath.clamp_signed(float(agreement.get("trust_effect")) - 0.25))
    var relation: Dictionary = _relation(state, violator, protected_for); relation["trust"] = PhaseEMath.clamp_signed(float(relation.get("trust", 0.0)) - 0.18); relation["grievance"] = PhaseEMath.clamp01(float(relation.get("grievance", 0.0)) + 0.24)
    return CommandResult.success(str(command.get("command_id")), {"mutation": "territory_violation_recorded", "outcome": "violated", "agreement_id": agreement_id, "violator_promotion_id": violator, "protected_promotion_id": protected_for, "market_id": market_id})

func apply_talent_share(state: RefCounted, command: RefCounted) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    var closed: Dictionary = _closed(command, ["agreement_id", "person_id", "borrowing_promotion_id"], ["agreement_id", "person_id", "borrowing_promotion_id"])
    if not closed.is_empty(): return closed
    if not (state.get("agreements") as Dictionary).has(str(payload.get("agreement_id"))): return _reject(command, "REF001", "payload.agreement_id", {"id": payload.get("agreement_id")})
    if not (state.get("people") as Dictionary).has(str(payload.get("person_id"))): return _reject(command, "REF001", "payload.person_id", {"id": payload.get("person_id")})
    var agreement: RefCounted = (state.get("agreements") as Dictionary)[str(payload.get("agreement_id"))]
    if str(agreement.get("status")) != "active" or not str(payload.get("borrowing_promotion_id")) in (agreement.get("party_promotion_ids") as Array): return _reject(command, "STATE003", "payload.borrowing_promotion_id", {"reason": "active_agreement_party_required"})
    var scope: Dictionary = _issuer_scope(command, str(payload.get("borrowing_promotion_id")), [str(payload.get("borrowing_promotion_id"))])
    if not scope.is_empty(): return scope
    var shares: Array = (state.get("world_state") as Dictionary).get("talent_shares_v1", []); shares.append(payload.duplicate(true)); (state.get("world_state") as Dictionary)["talent_shares_v1"] = shares
    return CommandResult.success(str(command.get("command_id")), {"mutation": "talent_share_accepted", "outcome": "accepted", "agreement_id": payload.get("agreement_id"), "person_id": payload.get("person_id")})

func resolve(state: RefCounted, target_date: String) -> Dictionary:
    var pending: Array = (state.get("world_state") as Dictionary).get("pending_territory_violations_v1", [])
    var events: Array[Dictionary] = []
    for violation_value: Variant in pending:
        if not violation_value is Dictionary: continue
        var violation: Dictionary = violation_value
        events.append(DomainEvent.make("TerritoryViolated", target_date, [str(violation.get("agreement_id")), str(violation.get("violator_promotion_id")), str(violation.get("protected_promotion_id"))], violation.duplicate(true), {"category": "diplomacy", "historical_class": "state_change", "market_id": violation.get("market_id"), "explanation": [{"source": "command", "command_id": violation.get("command_id")}, {"source": "formal_agreement", "agreement_id": violation.get("agreement_id")}, {"source": "hostile_entry", "market_id": violation.get("market_id")}]}))
    (state.get("world_state") as Dictionary)["pending_territory_violations_v1"] = []
    return {"passed": true, "errors": [], "events": events}

func _relation(state: RefCounted, a: String, b: String) -> Dictionary:
    var world: Dictionary = state.get("world_state"); var relations: Dictionary = world.get("promotion_relations_v1", {}); var key: String = a + "|" + b if a < b else b + "|" + a
    if not relations.has(key): relations[key] = {"trust": 0.0, "grievance": 0.0}
    world["promotion_relations_v1"] = relations
    return relations[key]

func _relation_read(state: RefCounted, a: String, b: String) -> Dictionary:
    var relations: Variant = (state.get("world_state") as Dictionary).get("promotion_relations_v1", {})
    if not relations is Dictionary: return {}
    var key: String = a + "|" + b if a < b else b + "|" + a
    var value: Variant = (relations as Dictionary).get(key, {})
    return (value as Dictionary).duplicate(true) if value is Dictionary else {}

func _issuer_scope(command: RefCounted, required_promotion_id: String, allowed_parties: Array) -> Dictionary:
    var issuer: Dictionary = command.get("issuer")
    if str(issuer.get("kind")) in ["player", "ai", "automation"]:
        var issuer_promotion_id: String = str(issuer.get("promotion_id", ""))
        if (not required_promotion_id.is_empty() and issuer_promotion_id != required_promotion_id) or not issuer_promotion_id in allowed_parties:
            return _reject(command, "STATE003", "issuer.promotion_id", {"reason": "promotion_scope_mismatch", "required_promotion_id": required_promotion_id})
    return {}

func _same_pair(left: Array, right: Array) -> bool:
    if left.size() != 2 or right.size() != 2: return false
    return (str(left[0]) == str(right[0]) and str(left[1]) == str(right[1])) or (str(left[0]) == str(right[1]) and str(left[1]) == str(right[0]))

func _closed(command: RefCounted, allowed: Array[String], required: Array[String]) -> Dictionary:
    var payload: Dictionary = command.get("payload")
    for key: Variant in payload.keys():
        if not str(key) in allowed: return _reject(command, "CMD001", "payload." + str(key), {"reason": "unknown_field"})
    for field: String in required:
        if not payload.has(field): return _reject(command, "CMD001", "payload." + field, {"reason": "required"})
    return {}

func _reject(command: RefCounted, code: String, path: String, details: Dictionary) -> Dictionary:
    return CommandResult.rejection(str(command.get("command_id")), code, path, "validation." + code.to_lower(), details)
