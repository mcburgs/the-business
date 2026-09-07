extends RefCounted

func plan(view: Dictionary, profile: Dictionary) -> Dictionary:
    var actions: Array[Dictionary] = []
    var people: Dictionary = view.get("own_people", {})
    var ids: Array[String] = []
    for id: Variant in people.keys(): ids.append(str(id))
    ids.sort_custom(func(a: String, b: String) -> bool: return float((people[a] as Dictionary).get("skills", {}).get("skill.performance", 0.0)) > float((people[b] as Dictionary).get("skills", {}).get("skill.performance", 0.0)) if not is_equal_approx(float((people[a] as Dictionary).get("skills", {}).get("skill.performance", 0.0)), float((people[b] as Dictionary).get("skills", {}).get("skill.performance", 0.0))) else a < b)
    if ids.is_empty() or (view.get("companies", []) as Array).is_empty(): return {"actions": actions}
    var company_id: String = str(((view.get("companies") as Array)[0] as Dictionary).get("touring_company_id"))
    var favorite_bias: float = float(profile.get("favorite_bias", 0.0))
    actions.append({"command_type": "command.push_person", "payload": {"touring_company_id": company_id, "person_id": ids[0], "weight": clampf(0.65 + float(profile.get("creative", 0.5)) * 0.25 + favorite_bias * 0.1, 0.0, 1.0)}, "historical": false, "explanation": {"decision_family": "booker", "goal": "push", "observed_state": {"person_id": ids[0], "performance": (people[ids[0]] as Dictionary).get("skills", {}).get("skill.performance", 0.0)}, "knowledge_confidence": 1.0, "strategy_weight": profile.get("creative", 0.5), "financial_pressure": view.get("financial_stress", 0.0), "inertia_bias": favorite_bias, "bounded_noise": 0.0, "principal_reasons": ["talent_quality", "creative_priority", "booker_preference"]}})
    if ids.size() > 1:
        actions.append({"command_type": "command.protect_person", "payload": {"touring_company_id": company_id, "person_id": ids[1], "weight": 0.55}, "historical": false, "explanation": {"decision_family": "booker", "goal": "protect", "observed_state": {"person_id": ids[1]}, "knowledge_confidence": 1.0, "strategy_weight": profile.get("creative", 0.5), "financial_pressure": view.get("financial_stress", 0.0), "inertia_bias": favorite_bias, "bounded_noise": 0.0, "principal_reasons": ["roster_depth", "program_balance"]}})
        if (view.get("active_programs", []) as Array).is_empty():
            var program_id: String = "program:F" + str(int(view.get("turn_number"))).pad_zeros(5) + _token(str(view.get("promotion_id")))
            actions.append({"command_type": "command.start_program", "payload": {"program_id": program_id, "promotion_id": view.get("promotion_id"), "side_a_person_ids": [ids[0]], "side_b_person_ids": [ids[1]], "purpose_id": "program_purpose.build_star", "phase_id": "program_phase.opening", "objective_ids": ["program_objective.build_star"]}, "historical": true, "explanation": {"decision_family": "booker", "goal": "start_program", "observed_state": {"lead_person_id": ids[0], "opponent_person_id": ids[1]}, "knowledge_confidence": 1.0, "strategy_weight": profile.get("creative", 0.5), "financial_pressure": view.get("financial_stress", 0.0), "inertia_bias": favorite_bias, "bounded_noise": 0.0, "principal_reasons": ["no_active_program", "talent_utilization", "star_development"]}})
    return {"actions": actions}

func _token(value: String) -> String:
    return value.get_slice(":", 1).replace("-", "").replace("_", "").substr(0, 10)
