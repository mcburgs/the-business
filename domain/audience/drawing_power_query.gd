extends RefCounted

const PhaseEMath = preload("res://domain/core/phase_e_math.gd")

static func collect_inputs(person: RefCounted, promotion: RefCounted, market_id: String, context: Dictionary = {}) -> Dictionary:
    var audience_by_market: Dictionary = person.get("audience_by_market") as Dictionary
    var local_state: Dictionary = {}
    if audience_by_market.has(market_id) and audience_by_market[market_id] is Dictionary:
        local_state = (audience_by_market[market_id] as Dictionary).duplicate(true)
    return {
        "market_id": market_id,
        "local_audience_state": local_state,
        "promotion_prestige": promotion.get("prestige"),
        "promotion_momentum": promotion.get("momentum"),
        "person_skills": (person.get("skills") as Dictionary).duplicate(true),
        "person_traits": (person.get("traits") as Dictionary).duplicate(true),
        "current_hot_state": person.get("current_hot_state"),
        "program_strength": float(context.get("program_strength", 0.0)),
        "media_support": float(context.get("media_support", 0.0)),
        "market_fit": float(context.get("market_fit", 0.5)),
        "opponent_quality": float(context.get("opponent_quality", 0.5)),
    }

static func evaluate(person: RefCounted, promotion: RefCounted, market_id: String, tuning: Dictionary = {}, context: Dictionary = {}) -> float:
    var inputs: Dictionary = collect_inputs(person, promotion, market_id, context)
    var local: Dictionary = inputs["local_audience_state"]
    var weights: Dictionary = tuning.get("drawing_power_weights", {
        "overness": 0.36, "momentum": 0.16, "charisma": 0.12, "market_fit": 0.08,
        "program": 0.1, "promotion": 0.08, "media": 0.05, "opponent": 0.05,
    })
    var momentum_normalized: float = (float(local.get("momentum", 0.0)) + 1.0) * 0.5
    var charisma: float = float((inputs["person_skills"] as Dictionary).get("skill.charisma", (inputs["person_skills"] as Dictionary).get("skill.performance", 0.5)))
    var values: Array[float] = [
        float(local.get("overness", 0.0)), momentum_normalized, charisma,
        float(inputs["market_fit"]), float(inputs["program_strength"]),
        float(inputs["promotion_prestige"]), float(inputs["media_support"]),
        float(inputs["opponent_quality"]),
    ]
    var weight_values: Array[float] = [
        float(weights.get("overness", 0.36)), float(weights.get("momentum", 0.16)),
        float(weights.get("charisma", 0.12)), float(weights.get("market_fit", 0.08)),
        float(weights.get("program", 0.1)), float(weights.get("promotion", 0.08)),
        float(weights.get("media", 0.05)), float(weights.get("opponent", 0.05)),
    ]
    var score: float = PhaseEMath.weighted_average(values, weight_values)
    var hot_state: Variant = inputs.get("current_hot_state")
    if hot_state is Dictionary and str((hot_state as Dictionary).get("direction", "")) == "hot":
        score += float((hot_state as Dictionary).get("intensity", 0.0)) * float(tuning.get("hot_drawing_bonus", 0.08))
    elif hot_state is Dictionary and str((hot_state as Dictionary).get("direction", "")) == "cold":
        score -= float((hot_state as Dictionary).get("intensity", 0.0)) * float(tuning.get("cold_drawing_penalty", 0.08))
    return PhaseEMath.clamp01(score)

static func evaluate_with_ruleset(person: RefCounted, promotion: RefCounted, market_id: String, evaluator: Callable) -> Variant:
    if not evaluator.is_valid():
        return null
    return evaluator.call(collect_inputs(person, promotion, market_id))
