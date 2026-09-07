extends RefCounted

func plan(view: Dictionary, profile: Dictionary, tuning: Dictionary) -> Dictionary:
    var stress: float = float(view.get("financial_stress", 0.0))
    var cash_minor: int = int((view.get("cash", {}) as Dictionary).get("minor_units", 0))
    var threshold: float = float(tuning.get("recovery_stress_threshold", 0.58))
    var cash_threshold: int = int(tuning.get("recovery_cash_threshold_minor_units", 220000))
    var active: bool = stress >= threshold or cash_minor < cash_threshold
    var actions: Array[Dictionary] = []
    if active:
        for company: Dictionary in view.get("companies", []):
            var budget: Dictionary = company.get("monthly_budget", {})
            var before: int = int(budget.get("minor_units", 0))
            var floor_minor: int = int(tuning.get("recovery_minimum_touring_budget_minor_units", 45000))
            var after: int = maxi(floor_minor, int(round(float(before) * float(tuning.get("recovery_budget_ratio", 0.62)))))
            if after < before:
                actions.append({
                    "command_type": "command.adjust_budget",
                    "payload": {"touring_company_id": company.get("touring_company_id"), "monthly_budget": {"minor_units": after, "currency_id": budget.get("currency_id")}},
                    "historical": true,
                    "explanation": {"decision_family": "recovery", "goal": "reduce_overextension", "observed_state": {"cash_minor_units": cash_minor, "touring_budget_before": before}, "financial_pressure": stress, "strategy_weight": profile.get("cost_sensitivity", 0.5), "bounded_noise": 0.0, "principal_reasons": ["financial_stress", "cash_runway", "cost_pressure"]},
                })
    return {"active": active, "actions": actions}
