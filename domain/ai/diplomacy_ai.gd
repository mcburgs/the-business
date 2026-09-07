extends RefCounted

func plan(view: Dictionary, profile: Dictionary, tuning: Dictionary) -> Dictionary:
    var promotion_id: String = str(view.get("promotion_id"))
    var threshold: float = float(tuning.get("agreement_proposal_trust_threshold", 0.22))
    var existing_partners: Dictionary = {}
    for agreement: Dictionary in view.get("agreements", []):
        if str(agreement.get("status")) == "active" and promotion_id in (agreement.get("party_promotion_ids", []) as Array):
            for party: Variant in agreement.get("party_promotion_ids", []): existing_partners[str(party)] = true
    var others: Array[String] = []
    for value: Variant in view.get("promotion_ids", []):
        if str(value) != promotion_id: others.append(str(value))
    others.sort()
    for other_id: String in others:
        if existing_partners.has(other_id): continue
        var relation: Dictionary = _relation(view.get("promotion_relations", {}), promotion_id, other_id)
        var net: float = float(relation.get("trust", 0.0)) - float(relation.get("grievance", 0.0))
        if net < threshold: continue
        var home: Array = view.get("home_market_ids", [])
        if home.is_empty(): continue
        var agreement_id: String = "agreement:F" + str(int(view.get("turn_number"))).pad_zeros(5) + _token(promotion_id) + _token(other_id)
        return {"actions": [{"command_type": "command.propose_agreement", "payload": {"agreement_id": agreement_id, "party_promotion_ids": [promotion_id, other_id], "clause_ids": ["agreement_clause.non_aggression"], "clauses": [{"clause_id": "agreement_clause.non_aggression", "market_ids": [str(home[0])], "protected_promotion_id": promotion_id}]}, "historical": true, "explanation": {"decision_family": "diplomacy", "goal": "propose_non_aggression", "observed_state": relation.duplicate(true), "knowledge_confidence": 1.0, "strategy_weight": profile.get("diplomacy", 0.5), "financial_pressure": view.get("financial_stress", 0.0), "bounded_noise": 0.0, "principal_reasons": ["positive_trust", "territorial_stability", "shared_interest"]}}]}
    return {"actions": []}

func _relation(relations: Variant, a: String, b: String) -> Dictionary:
    if not relations is Dictionary: return {}
    var key: String = a + "|" + b if a < b else b + "|" + a
    return ((relations as Dictionary).get(key, {}) as Dictionary).duplicate(true) if (relations as Dictionary).get(key, {}) is Dictionary else {}

func _token(value: String) -> String:
    return value.get_slice(":", 1).replace("-", "").replace("_", "").substr(0, 6)
