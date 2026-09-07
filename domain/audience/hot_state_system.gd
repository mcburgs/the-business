extends RefCounted

const PhaseEMath = preload("res://domain/core/phase_e_math.gd")

func update(target: RefCounted, target_id: String, target_kind: String, qualification: float, date: String, random_service: RefCounted, tuning: Dictionary, causes: Array) -> Dictionary:
    var events: Array[Dictionary] = []
    var config: Dictionary = tuning.get("hot_state", {})
    var existing: Variant = target.get("current_hot_state")
    if existing is Dictionary:
        var state: Dictionary = (existing as Dictionary).duplicate(true)
        var direction: String = str(state.get("direction", "hot"))
        var intensity: float = float(state.get("intensity", 0.0)) * float(config.get("decay", 0.72))
        var remaining: int = int(state.get("remaining_months", 1)) - 1
        if remaining <= 0 or intensity < float(config.get("minimum_intensity", 0.08)):
            target.set("current_hot_state", null)
            events.append({"type": "ended", "target_id": target_id, "target_kind": target_kind, "direction": direction, "date": date})
        else:
            state["intensity"] = PhaseEMath.clamp01(intensity)
            state["remaining_months"] = remaining
            target.set("current_hot_state", state)
        return {"events": events, "state": target.get("current_hot_state")}

    var hot_threshold: float = float(config.get("hot_threshold", 0.34))
    var cold_threshold: float = float(config.get("cold_threshold", -0.34))
    if qualification < hot_threshold and qualification > cold_threshold:
        return {"events": events, "state": null}
    var chance: float = float(config.get("qualified_activation_chance", 0.28))
    var draw: float = float(random_service.call("draw_float", "phase_e.hot_state." + target_kind + "." + target_id))
    if draw >= chance:
        return {"events": events, "state": null}
    var direction: String = "hot" if qualification >= hot_threshold else "cold"
    var intensity: float = PhaseEMath.clamp01(absf(qualification) * float(config.get("qualification_intensity_scale", 1.25)))
    var new_state: Dictionary = {
        "target_id": target_id,
        "target_kind": target_kind,
        "direction": direction,
        "intensity": intensity,
        "started_on": date,
        "remaining_months": int(config.get("duration_months", 3)),
        "cause_codes": causes.duplicate(true),
        "propagation_modifier": PhaseEMath.canonical(intensity * float(config.get("propagation_scale", 0.15))),
    }
    target.set("current_hot_state", new_state)
    events.append({"type": "started", "target_id": target_id, "target_kind": target_kind, "direction": direction, "date": date, "intensity": intensity, "causes": causes.duplicate(true)})
    return {"events": events, "state": new_state}
