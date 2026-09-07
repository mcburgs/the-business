extends RefCounted

func plan(view: Dictionary, profile: Dictionary, random_service: RefCounted, tuning: Dictionary) -> Dictionary:
    var promotion_id: String = str(view.get("promotion_id"))
    var stress: float = float(view.get("financial_stress", 0.0))
    var recovery_threshold: float = float(tuning.get("recovery_stress_threshold", 0.58))
    var best_market: String = ""
    var best_score: float = -1000.0
    var best_factors: Dictionary = {}
    var markets: Dictionary = view.get("markets", {})
    var market_ids: Array[String] = []
    for key: Variant in markets.keys(): market_ids.append(str(key))
    market_ids.sort()
    for market_id: String in market_ids:
        var market: Dictionary = markets[market_id]
        var influence: Dictionary = market.get("influence_by_promotion", {})
        var own: float = _composite(influence.get(promotion_id, {}))
        var rival: float = 0.0
        for other_id: Variant in influence.keys():
            if str(other_id) != promotion_id: rival = maxf(rival, _composite(influence[other_id]))
        var home: bool = market_id in (view.get("home_market_ids", []) as Array)
        var expansion: float = float(profile.get("expansion", 0.5))
        var defense: float = float(profile.get("defense", 0.5))
        var opportunity: float = float(market.get("wrestling_interest", 0.0)) * 0.35 + float(market.get("economic_strength", 0.0)) * 0.20 + (1.0 - own) * 0.25
        var defense_pressure: float = maxf(0.0, rival - own + 0.18) if home else 0.0
        var stress_penalty: float = stress * (0.75 if not home else 0.15)
        var noise_strength: float = float(profile.get("decision_noise", tuning.get("decision_noise_strength", 0.03)))
        var noise: float = (float(random_service.call("draw_float", "ai_owner_market")) - 0.5) * 2.0 * noise_strength
        var score: float = opportunity * (0.55 + expansion * 0.45) + defense_pressure * defense - stress_penalty + noise
        if stress >= recovery_threshold:
            score = own + (0.35 if home else 0.0) - stress_penalty + noise
        if score > best_score or (is_equal_approx(score, best_score) and market_id < best_market):
            best_score = score
            best_market = market_id
            best_factors = {"own_influence": own, "rival_influence": rival, "opportunity": opportunity, "defense_pressure": defense_pressure, "noise": noise, "home": home}
    if best_market.is_empty():
        return {"actions": [], "target_market_id": ""}
    var goal: String = "retreat" if stress >= recovery_threshold else ("defend" if bool(best_factors.get("home")) and float(best_factors.get("defense_pressure")) > 0.0 else ("enter" if float(best_factors.get("rival_influence")) > float(best_factors.get("own_influence")) else "expand"))
    var explanation: Dictionary = {
        "decision_family": "owner_strategy", "goal": goal,
        "observed_state": best_factors.duplicate(true),
        "strategy_weight": {"expansion": profile.get("expansion", 0.5), "defense": profile.get("defense", 0.5)},
        "financial_pressure": stress, "market_opportunity": best_factors.get("opportunity", 0.0),
        "bounded_noise": best_factors.get("noise", 0.0),
        "principal_reasons": ["market_opportunity", "rival_pressure" if goal == "defend" else "strategy_posture", "financial_stress" if goal == "retreat" else "available_capacity"],
    }
    return {
        "target_market_id": best_market,
        "actions": [{"command_type": "command.book_market_focus", "payload": {"promotion_id": promotion_id, "market_id": best_market, "intensity": clampf(0.45 + float(profile.get("expansion", 0.5)) * 0.35 - stress * 0.25, 0.2, 0.9)}, "explanation": explanation, "historical": goal in ["enter", "retreat", "defend"]}],
    }

func _composite(value: Variant) -> float:
    if not value is Dictionary: return 0.0
    var components: Dictionary = value
    return float(components.get("audience", 0.0)) * 0.4 + float(components.get("media", 0.0)) * 0.25 + float(components.get("business", 0.0)) * 0.25 + float(components.get("infrastructure", 0.0)) * 0.1
