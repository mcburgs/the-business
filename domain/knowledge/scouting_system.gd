extends RefCounted

const DomainIds = preload("res://domain/core/domain_ids.gd")
const PhaseEMath = preload("res://domain/core/phase_e_math.gd")

func update(state: RefCounted, intents: Array, target_date: String, random_service: RefCounted, tuning: Dictionary) -> Dictionary:
    var reports: Array[Dictionary] = []
    var sorted_intents: Array = intents.duplicate(true)
    sorted_intents.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("owner_promotion_id")) + "|" + str(a.get("subject_id")) < str(b.get("owner_promotion_id")) + "|" + str(b.get("subject_id")))
    for intent_value: Variant in sorted_intents:
        if not intent_value is Dictionary: continue
        var intent: Dictionary = intent_value
        var owner_id: String = str(intent.get("owner_promotion_id")); var subject_id: String = str(intent.get("subject_id"))
        var bases: Dictionary = state.get("knowledge_bases")
        if not bases.has(owner_id) or not (state.get("people") as Dictionary).has(subject_id): continue
        var knowledge: RefCounted = bases[owner_id]
        var familiarity: Dictionary = knowledge.get("familiarity_by_subject")
        var before: float = float(familiarity.get(subject_id, 0.0))
        var after: float = PhaseEMath.clamp01(before + float(tuning.get("scouting_familiarity_gain", 0.16)))
        familiarity[subject_id] = after; knowledge.set("familiarity_by_subject", familiarity)
        var fields: Array = intent.get("field_ids", [])
        for field_value: Variant in fields:
            var field_id: String = str(field_value)
            var truth: Variant = _truth(state, subject_id, field_id, owner_id)
            if not (truth is int or truth is float): continue
            var quality: float = float(tuning.get("default_scouting_quality", 0.58))
            var base_error: float = float(tuning.get("scouting_base_error", 0.28))
            var minimum_error: float = float(tuning.get("scouting_minimum_error", 0.025))
            var scale: float = 50000.0 if field_id == "contract.demand_minor_units" else 1.0
            var margin: float = maxf(minimum_error * scale, base_error * scale * (1.0 - after) * (1.15 - quality * 0.45))
            var noise: float = (float(random_service.call("draw_float", "scouting_error")) - 0.5) * 2.0 * margin
            var estimate: float = float(truth) + noise
            var lower: float = estimate - margin; var upper: float = estimate + margin
            if field_id != "contract.demand_minor_units": lower = PhaseEMath.clamp01(lower); upper = PhaseEMath.clamp01(upper); estimate = PhaseEMath.clamp01(estimate)
            else: lower = maxf(1000.0, lower); upper = maxf(lower, upper); estimate = maxf(1000.0, estimate)
            var range_min: Variant = int(round(lower)) if field_id == "contract.demand_minor_units" else PhaseEMath.canonical(lower)
            var range_max: Variant = int(round(upper)) if field_id == "contract.demand_minor_units" else PhaseEMath.canonical(upper)
            var recorded_bias: Variant = int(round(noise)) if field_id == "contract.demand_minor_units" else PhaseEMath.canonical(noise)
            var recorded_margin: Variant = int(round(margin)) if field_id == "contract.demand_minor_units" else PhaseEMath.canonical(margin)
            var observation: Dictionary = {"subject_id": subject_id, "field_id": field_id, "estimate_form": "range", "range": {"min": range_min, "max": range_max}, "confidence": PhaseEMath.clamp01(after * 0.72 + quality * 0.28), "source_id": "source.organizational_scouting", "observed_on": target_date, "bias": recorded_bias, "error_margin": recorded_margin}
            _append_observation(knowledge, observation)
            reports.append({"owner_promotion_id": owner_id, "subject_id": subject_id, "field_id": field_id, "estimate": observation.get("range"), "confidence": observation.get("confidence"), "familiarity_before": before, "familiarity_after": after, "bounded_error_margin": observation.get("error_margin"), "source_id": observation.get("source_id")})
    return {"passed": true, "errors": [], "reports": reports}

func _truth(state: RefCounted, person_id: String, field_id: String, owner_id: String) -> Variant:
    var person: RefCounted = (state.get("people") as Dictionary)[person_id]
    match field_id:
        "skill.performance": return float((person.get("skills") as Dictionary).get("skill.performance", 0.5))
        "talent.local_value":
            var total: float = 0.0; var count: int = 0
            for local_value: Variant in (person.get("audience_by_market") as Dictionary).values():
                if local_value is Dictionary: total += float((local_value as Dictionary).get("overness", 0.0)); count += 1
            return total / float(count) if count > 0 else 0.1
        "contract.demand_minor_units": return int((person.get("career") as Dictionary).get("contract_demand_minor_units", 12000))
        _: return null

func _append_observation(knowledge: RefCounted, observation: Dictionary) -> void:
    var observations: Array = knowledge.get("observations")
    observations.append(observation.duplicate(true)); knowledge.set("observations", observations)
