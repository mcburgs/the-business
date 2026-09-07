extends RefCounted

func plan(view: Dictionary, profile: Dictionary, tuning: Dictionary) -> Dictionary:
    var actions: Array[Dictionary] = []
    var intents: Array[Dictionary] = []
    var candidates: Array = view.get("external_talent", [])
    var ranked: Array[Dictionary] = []
    for candidate: Dictionary in candidates:
        var performance: Dictionary = candidate.get("performance", {})
        var local_value: Dictionary = candidate.get("local_value", {})
        var talent: float = _estimate(performance, 0.42)
        var local: float = _estimate(local_value, 0.30)
        var confidence: float = minf(_numeric(performance.get("confidence", null)), _numeric(local_value.get("confidence", null)))
        ranked.append({"candidate": candidate, "score": talent * 0.68 + local * 0.32, "confidence": confidence})
    ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("score")) > float(b.get("score")) if not is_equal_approx(float(a.get("score")), float(b.get("score"))) else str((a.get("candidate") as Dictionary).get("person_id")) < str((b.get("candidate") as Dictionary).get("person_id")))
    for item: Dictionary in ranked.slice(0, mini(2, ranked.size())):
        intents.append({"owner_promotion_id": view.get("promotion_id"), "subject_id": (item.get("candidate") as Dictionary).get("person_id"), "field_ids": ["skill.performance", "talent.local_value", "contract.demand_minor_units"], "reason": "talent_market_priority"})
    var stress: float = float(view.get("financial_stress", 0.0))
    if stress >= float(tuning.get("recovery_stress_threshold", 0.58)):
        var release: Dictionary = _release_candidate(view, tuning)
        if not release.is_empty(): actions.append(release)
        return {"actions": actions, "scouting_intents": intents}
    var counter: Dictionary = _counter_action(view)
    if not counter.is_empty():
        actions.append(counter)
        return {"actions": actions, "scouting_intents": intents}
    var assignment: Dictionary = _assignment_action(view)
    if not assignment.is_empty():
        actions.append(assignment)
        return {"actions": actions, "scouting_intents": intents}
    var renewal: Dictionary = _renewal_action(view, profile, tuning)
    if not renewal.is_empty():
        actions.append(renewal)
        return {"actions": actions, "scouting_intents": intents}
    var roster_target: int = int(tuning.get("talent_roster_target", 4))
    if (view.get("own_contracts", []) as Array).size() < roster_target and not ranked.is_empty():
        var top: Dictionary = ranked[0]
        var candidate: Dictionary = top.get("candidate")
        var demand_projection: Dictionary = candidate.get("contract_demand", {})
        var demand: int = int(round(_estimate(demand_projection, float(tuning.get("default_contract_offer_minor_units", 12000)))))
        if demand < 1000: demand = int(tuning.get("default_contract_offer_minor_units", 12000))
        var premium: float = 0.90 + float(profile.get("talent_aggression", 0.5)) * 0.25
        var offer: int = int(round(float(demand) * premium))
        var person_id: String = str(candidate.get("person_id"))
        var contract_id: String = "contract:F" + str(int(view.get("turn_number"))).pad_zeros(5) + _token(str(view.get("promotion_id"))) + _token(person_id)
        actions.append({
            "command_type": "command.offer_contract",
            "payload": {"contract_id": contract_id, "promotion_id": view.get("promotion_id"), "person_id": person_id, "compensation": {"base": {"minor_units": offer, "currency_id": (view.get("cash", {}) as Dictionary).get("currency_id")}}, "exclusivity_id": "exclusivity.fixture", "end_date": _add_years(str(view.get("current_date")), 2)},
            "historical": true,
            "explanation": {"decision_family": "talent", "goal": "pursue_talent", "observed_state": {"estimated_talent": top.get("score"), "estimated_demand_minor_units": demand, "roster_count": (view.get("own_contracts", []) as Array).size()}, "knowledge_confidence": top.get("confidence"), "strategy_weight": profile.get("talent_aggression", 0.5), "financial_pressure": stress, "market_opportunity": candidate.get("local_value", {}), "bounded_noise": 0.0, "principal_reasons": ["roster_need", "estimated_talent", "estimated_price"]},
        })
    return {"actions": actions, "scouting_intents": intents}

func _renewal_action(view: Dictionary, profile: Dictionary, tuning: Dictionary) -> Dictionary:
    var today: String = str(view.get("current_date"))
    var window_months: int = int(tuning.get("renewal_window_months", 3))
    for contract: Dictionary in view.get("own_contracts", []):
        var end_value: Variant = contract.get("end_date")
        if end_value == null or _months_between(today, str(end_value)) > window_months: continue
        var base: Dictionary = (contract.get("compensation", {}) as Dictionary).get("base", {})
        var old_pay: int = int(base.get("minor_units", 0))
        var person: Dictionary = (view.get("own_people", {}) as Dictionary).get(str(contract.get("person_id")), {})
        var demand: int = int((person.get("career", {}) as Dictionary).get("contract_demand_minor_units", old_pay))
        var loyalty_offer: int = int(round(float(demand) * (0.92 + float(profile.get("loyalty", 0.5)) * 0.15)))
        var offer: int = maxi(int(round(float(old_pay) * (1.03 + float(profile.get("talent_aggression", 0.5)) * 0.08))), loyalty_offer)
        return {"command_type": "command.renew_contract", "payload": {"contract_id": contract.get("contract_id"), "promotion_id": view.get("promotion_id"), "compensation": {"base": {"minor_units": offer, "currency_id": base.get("currency_id")}}, "end_date": _add_years(today, 2)}, "historical": true, "explanation": {"decision_family": "talent", "goal": "retain_talent", "observed_state": {"contract_end_date": end_value, "old_pay_minor_units": old_pay, "known_internal_demand_minor_units": demand, "offer_minor_units": offer}, "knowledge_confidence": 1.0, "strategy_weight": profile.get("loyalty", 0.5), "financial_pressure": view.get("financial_stress", 0.0), "bounded_noise": 0.0, "principal_reasons": ["expiry_pressure", "retention", "roster_continuity"]}}
    return {}

func _counter_action(view: Dictionary) -> Dictionary:
    var pending: Array = view.get("pending_negotiations", [])
    if pending.is_empty(): return {}
    var negotiation: Dictionary = pending[0]
    var proposal: Dictionary = negotiation.get("proposal", {})
    var currency_id: String = str(((proposal.get("compensation", {}) as Dictionary).get("base", {}) as Dictionary).get("currency_id", (view.get("cash", {}) as Dictionary).get("currency_id")))
    return {"command_type": "command.counter_offer", "payload": {"contract_id": negotiation.get("contract_id"), "promotion_id": view.get("promotion_id"), "compensation": {"base": {"minor_units": int(negotiation.get("counter_minor_units", 0)), "currency_id": currency_id}}, "end_date": proposal.get("end_date", _add_years(str(view.get("current_date")), 2))}, "historical": true, "explanation": {"decision_family": "talent", "goal": "accept_counteroffer", "observed_state": {"person_id": negotiation.get("person_id"), "counter_minor_units": negotiation.get("counter_minor_units")}, "knowledge_confidence": 1.0, "strategy_weight": 1.0, "financial_pressure": view.get("financial_stress", 0.0), "bounded_noise": 0.0, "principal_reasons": ["active_negotiation", "counter_terms", "roster_need"]}}

func _assignment_action(view: Dictionary) -> Dictionary:
    var companies: Array = view.get("companies", [])
    if companies.is_empty(): return {}
    var assigned: Dictionary = {}
    for company: Dictionary in companies:
        for person_id: Variant in company.get("person_assignment_ids", []): assigned[str(person_id)] = true
    for contract: Dictionary in view.get("own_contracts", []):
        var person_id: String = str(contract.get("person_id"))
        if not assigned.has(person_id):
            return {"command_type": "command.assign_person", "payload": {"touring_company_id": (companies[0] as Dictionary).get("touring_company_id"), "person_id": person_id}, "historical": true, "explanation": {"decision_family": "talent", "goal": "deploy_new_signing", "observed_state": {"person_id": person_id, "assigned": false}, "knowledge_confidence": 1.0, "strategy_weight": 1.0, "financial_pressure": view.get("financial_stress", 0.0), "bounded_noise": 0.0, "principal_reasons": ["active_contract", "touring_assignment", "talent_utilization"]}}
    return {}

func _release_candidate(view: Dictionary, tuning: Dictionary) -> Dictionary:
    if (view.get("own_contracts", []) as Array).size() <= int(tuning.get("minimum_roster_size", 2)): return {}
    var worst: Dictionary = {}
    var worst_ratio: float = -1.0
    for contract: Dictionary in view.get("own_contracts", []):
        var person_id: String = str(contract.get("person_id"))
        var person: Dictionary = (view.get("own_people", {}) as Dictionary).get(person_id, {})
        var talent: float = float((person.get("skills", {}) as Dictionary).get("skill.performance", 0.4))
        var pay: int = int(((contract.get("compensation", {}) as Dictionary).get("base", {}) as Dictionary).get("minor_units", 0))
        var ratio: float = float(pay) / maxf(0.1, talent)
        if ratio > worst_ratio: worst_ratio = ratio; worst = contract
    if worst.is_empty(): return {}
    return {"command_type": "command.release_person", "payload": {"contract_id": worst.get("contract_id"), "promotion_id": view.get("promotion_id")}, "historical": true, "explanation": {"decision_family": "talent", "goal": "release_talent", "observed_state": {"person_id": worst.get("person_id"), "cost_value_ratio": worst_ratio}, "knowledge_confidence": 1.0, "strategy_weight": 1.0, "financial_pressure": view.get("financial_stress", 0.0), "bounded_noise": 0.0, "principal_reasons": ["financial_stress", "cost_pressure", "roster_depth"]}}

func _estimate(projection: Dictionary, fallback: float) -> float:
    if str(projection.get("status")) == "known" and (projection.get("value") is int or projection.get("value") is float): return float(projection.get("value"))
    var range_value: Variant = projection.get("estimate_range")
    if range_value is Dictionary: return (float((range_value as Dictionary).get("min", fallback)) + float((range_value as Dictionary).get("max", fallback))) * 0.5
    return fallback

func _numeric(value: Variant) -> float:
    return float(value) if value is int or value is float else 0.0

func _months_between(a: String, b: String) -> int:
    var ap: PackedStringArray = a.split("-"); var bp: PackedStringArray = b.split("-")
    if ap.size() < 2 or bp.size() < 2: return 999
    return (int(bp[0]) - int(ap[0])) * 12 + int(bp[1]) - int(ap[1])

func _add_years(date: String, years: int) -> String:
    var parts: PackedStringArray = date.split("-")
    return str(int(parts[0]) + years).pad_zeros(4) + "-" + parts[1] + "-" + parts[2] if parts.size() == 3 else date

func _token(value: String) -> String:
    return value.get_slice(":", 1).replace("-", "").replace("_", "").substr(0, 8)
