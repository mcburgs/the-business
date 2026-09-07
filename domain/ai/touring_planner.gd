extends RefCounted

func plan(view: Dictionary, target_market_id: String, profile: Dictionary, tuning: Dictionary) -> Dictionary:
    var actions: Array[Dictionary] = []
    if target_market_id.is_empty(): return {"actions": actions}
    var promotion_id: String = str(view.get("promotion_id"))
    var stress: float = float(view.get("financial_stress", 0.0))
    for company: Dictionary in view.get("companies", []):
        var route: Array = company.get("route", [])
        var current_market: String = str((route[0] as Dictionary).get("market_id", "")) if not route.is_empty() and route[0] is Dictionary else ""
        if current_market != target_market_id or route.size() != 1:
            var explanation: Dictionary = {
                "decision_family": "touring", "goal": "retreat" if stress >= float(tuning.get("recovery_stress_threshold", 0.58)) else ("defend" if target_market_id in (view.get("home_market_ids", []) as Array) else "enter_market"),
                "observed_state": {"from_market_id": current_market, "target_market_id": target_market_id, "fatigue_pressure": company.get("fatigue_pressure", 0.0)},
                "strategy_weight": {"expansion": profile.get("expansion", 0.5), "defense": profile.get("defense", 0.5)}, "financial_pressure": stress,
                "market_opportunity": target_market_id, "bounded_noise": 0.0, "principal_reasons": ["owner_market_priority", "touring_capacity", "financial_stress" if stress >= float(tuning.get("recovery_stress_threshold", 0.58)) else "market_competition"],
            }
            actions.append({"command_type": "command.set_route", "payload": {"touring_company_id": company.get("touring_company_id"), "route": [{"market_id": target_market_id}]}, "explanation": explanation, "historical": true})
            var violation: Dictionary = _territory_violation(view, promotion_id, target_market_id)
            if not violation.is_empty():
                actions.append({"command_type": "command.violate_territory", "payload": violation, "historical": true, "explanation": {"decision_family": "diplomacy", "goal": "hostile_entry", "observed_state": {"agreement_id": violation.get("agreement_id"), "market_id": target_market_id}, "strategy_weight": profile.get("aggression", profile.get("expansion", 0.5)), "financial_pressure": stress, "market_opportunity": target_market_id, "bounded_noise": 0.0, "principal_reasons": ["owner_market_priority", "protected_market", "competitive_entry"]}})
    return {"actions": actions}

func _territory_violation(view: Dictionary, promotion_id: String, market_id: String) -> Dictionary:
    for agreement: Dictionary in view.get("agreements", []):
        if str(agreement.get("status")) != "active" or not promotion_id in (agreement.get("party_promotion_ids", []) as Array): continue
        for clause_value: Variant in agreement.get("clauses", []):
            if not clause_value is Dictionary: continue
            var clause: Dictionary = clause_value
            if market_id in (clause.get("market_ids", []) as Array) and str(clause.get("protected_promotion_id", "")) != promotion_id:
                return {"agreement_id": agreement.get("agreement_id"), "violator_promotion_id": promotion_id, "market_id": market_id}
    return {}
