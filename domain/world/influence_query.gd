extends RefCounted

const PhaseEMath = preload("res://domain/core/phase_e_math.gd")

static func composite(components: Dictionary, tuning: Dictionary = {}) -> float:
    var weights: Dictionary = tuning.get("influence_weights", {
        "audience": 0.4, "media": 0.25, "business": 0.25, "infrastructure": 0.1,
    })
    var values: Array[float] = []
    var weight_values: Array[float] = []
    for key: String in ["audience", "media", "business", "infrastructure"]:
        values.append(float(components.get(key, 0.0)))
        weight_values.append(float(weights.get(key, 0.0)))
    return PhaseEMath.clamp01(PhaseEMath.weighted_average(values, weight_values))
