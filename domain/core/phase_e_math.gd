extends RefCounted

const SCALE: float = 1000000000.0

static func canonical(value: float) -> float:
    if not is_finite(value):
        return 0.0
    return round(value * SCALE) / SCALE

static func clamp01(value: float) -> float:
    return canonical(clampf(value, 0.0, 1.0))

static func clamp_signed(value: float) -> float:
    return canonical(clampf(value, -1.0, 1.0))

static func weighted_average(values: Array[float], weights: Array[float]) -> float:
    if values.is_empty() or values.size() != weights.size():
        return 0.0
    var numerator: float = 0.0
    var denominator: float = 0.0
    for index: int in range(values.size()):
        numerator += values[index] * weights[index]
        denominator += weights[index]
    if denominator <= 0.0:
        return 0.0
    return canonical(numerator / denominator)
