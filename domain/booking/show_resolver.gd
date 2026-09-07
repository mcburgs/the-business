extends RefCounted

const PhaseEMath = preload("res://domain/core/phase_e_math.gd")
const DrawingPowerQuery = preload("res://domain/audience/drawing_power_query.gd")
const ShowResult = preload("res://domain/booking/show_result.gd")

func resolve(state: RefCounted, plans: Array, random_service: RefCounted, tuning: Dictionary) -> Dictionary:
    var results: Array = []
    var people: Dictionary = state.get("people")
    var promotions: Dictionary = state.get("promotions")
    var programs: Dictionary = state.get("programs")
    for plan_value: Variant in plans:
        var plan: RefCounted = plan_value
        var promotion_id: String = str(plan.get("promotion_id"))
        var market_id: String = str(plan.get("market_id"))
        if not promotions.has(promotion_id):
            continue
        var promotion: RefCounted = promotions[promotion_id]
        var participants: Array = plan.get("participant_person_ids")
        var performance_total: float = 0.0
        var psychology_total: float = 0.0
        var count: int = 0
        for person_value: Variant in participants:
            var person_id: String = str(person_value)
            if not people.has(person_id):
                continue
            var skills: Dictionary = (people[person_id] as RefCounted).get("skills")
            performance_total += float(skills.get("skill.performance", 0.5))
            psychology_total += float(skills.get("skill.psychology", skills.get("skill.performance", 0.5)))
            count += 1
        var performance: float = performance_total / float(count) if count > 0 else 0.0
        var psychology: float = psychology_total / float(count) if count > 0 else 0.0
        var program_strength: float = float((plan.get("market_context") as Dictionary).get("program_strength", 0.0))
        var presentation_context: Dictionary = (plan.get("presentation_context") as Dictionary).duplicate(true)
        var wrestling_language_context: Dictionary = (plan.get("wrestling_language_context") as Dictionary).duplicate(true)
        var variance_width: float = float(tuning.get("show_variance", 0.08))
        var raw_draw: float = float(random_service.call("draw_float", "phase_e.show." + str(plan.get("show_id"))))
        var variance: float = (raw_draw * 2.0 - 1.0) * variance_width
        var quality: float = PhaseEMath.clamp01(
            performance * float(tuning.get("performance_weight", 0.34))
            + psychology * float(tuning.get("psychology_weight", 0.18))
            + float(plan.get("booking_quality")) * float(tuning.get("booking_quality_weight", 0.26))
            + program_strength * float(tuning.get("program_show_weight", 0.14))
            + float(tuning.get("show_quality_base", 0.08))
            + variance
            - float(plan.get("travel_pressure")) * float(tuning.get("fatigue_show_penalty", 0.14))
        )
        var featured_person_id: String = str(plan.get("featured_person_id"))
        var drawing_power: float = 0.0
        if people.has(featured_person_id):
            drawing_power = DrawingPowerQuery.evaluate(people[featured_person_id], promotion, market_id, tuning, {"program_strength": program_strength})
        var market_interest: float = float((plan.get("market_context") as Dictionary).get("wrestling_interest", 0.5))
        var crowd_response: float = PhaseEMath.clamp01(
            quality * float(tuning.get("quality_crowd_weight", 0.48))
            + drawing_power * float(tuning.get("draw_crowd_weight", 0.32))
            + market_interest * float(tuning.get("interest_crowd_weight", 0.20))
        )
        var base_attendance: int = int(tuning.get("base_attendance", 900))
        var attendance_multiplier: float = maxf(0.1,
            float(tuning.get("attendance_floor_multiplier", 0.35))
            + crowd_response * float(tuning.get("crowd_attendance_weight", 0.85))
            + drawing_power * float(tuning.get("draw_attendance_weight", 0.65))
            + float(promotion.get("prestige")) * float(tuning.get("prestige_attendance_weight", 0.25))
        )
        var attendance: int = maxi(0, int(round(float(base_attendance) * attendance_multiplier)))
        var ticket_price: int = int(tuning.get("ticket_price_minor_units", 2500))
        var result: RefCounted = ShowResult.new()
        result.set("show_id", plan.get("show_id"))
        result.set("promotion_id", promotion_id)
        result.set("touring_company_id", plan.get("touring_company_id"))
        result.set("market_id", market_id)
        result.set("participant_person_ids", participants.duplicate())
        result.set("featured_person_id", plan.get("featured_person_id"))
        result.set("featured_program_id", plan.get("featured_program_id"))
        result.set("featured_championship_id", plan.get("featured_championship_id"))
        result.set("approved_major_outcome", (plan.get("approved_major_outcome") as Dictionary).duplicate(true))
        result.set("show_quality", quality)
        result.set("crowd_response", crowd_response)
        result.set("attendance", attendance)
        result.set("gate_minor_units", attendance * ticket_price)
        result.set("travel_pressure", plan.get("travel_pressure"))
        var person_effects: Dictionary = {}
        for person_value: Variant in participants:
            var person_id: String = str(person_value)
            var featured_bonus: float = float(tuning.get("featured_momentum_bonus", 0.06)) if person_id == featured_person_id else 0.0
            person_effects[person_id] = {
                "momentum_delta": PhaseEMath.canonical((crowd_response - 0.5) * float(tuning.get("show_momentum_scale", 0.22)) + featured_bonus),
                "response": crowd_response,
                "featured": person_id == featured_person_id,
            }
        result.set("person_effects", person_effects)
        if plan.get("featured_program_id") != null and programs.has(str(plan.get("featured_program_id"))):
            result.set("program_effect", {
                "program_id": str(plan.get("featured_program_id")),
                "heat_delta": PhaseEMath.canonical((crowd_response - 0.45) * float(tuning.get("program_heat_scale", 0.18))),
                "momentum_delta": PhaseEMath.canonical((quality - 0.5) * float(tuning.get("program_momentum_scale", 0.24))),
            })
        result.set("causal_factors", (plan.get("causal_factors") as Array).duplicate(true) + [
            {"source": "performance", "value": performance},
            {"source": "psychology", "value": psychology},
            {"source": "drawing_power", "value": drawing_power},
            {"source": "market_interest", "value": market_interest},
            {"source": "bounded_variance", "value": variance},
            {"source": "presentation_context", "context": presentation_context},
            {"source": "wrestling_language_context", "context": wrestling_language_context},
        ])
        results.append(result)
    return {"passed": true, "errors": [], "results": results}
