extends RefCounted

const DomainEvent = preload("res://domain/events/domain_event.gd")
const DomainIds = preload("res://domain/core/domain_ids.gd")
const PhaseEMath = preload("res://domain/core/phase_e_math.gd")
const HotStateSystem = preload("res://domain/audience/hot_state_system.gd")

var _hot: RefCounted = HotStateSystem.new()

func apply(state: RefCounted, show_results: Array, target_date: String, random_service: RefCounted, tuning: Dictionary) -> Dictionary:
    var events: Array[Dictionary] = []
    var people: Dictionary = state.get("people")
    var programs: Dictionary = state.get("programs")
    var promotions: Dictionary = state.get("promotions")
    var championships: Dictionary = state.get("championships")
    var world_state: Dictionary = state.get("world_state")
    var visit_streaks: Dictionary = world_state.get("market_visit_streaks", {})
    var promotion_month_signals: Dictionary = {}
    for result_value: Variant in show_results:
        var result: RefCounted = result_value
        var market_id: String = str(result.get("market_id"))
        var promotion_id: String = str(result.get("promotion_id"))
        var response: float = float(result.get("crowd_response"))
        var quality: float = float(result.get("show_quality"))
        var streak: int = int(((visit_streaks.get(promotion_id, {}) as Dictionary).get(market_id, 0))) if visit_streaks.get(promotion_id, {}) is Dictionary else 0
        var repetition_penalty: float = maxf(0.0, float(streak - int(tuning.get("overuse_grace_visits", 2))) * float(tuning.get("audience_repetition_penalty", 0.035)))
        var effects: Dictionary = result.get("person_effects")
        for person_id: String in DomainIds.sorted_keys(effects):
            if not people.has(person_id):
                continue
            var person: RefCounted = people[person_id]
            var audience_by_market: Dictionary = person.get("audience_by_market")
            var local: Dictionary = _local_state(audience_by_market.get(market_id, {}))
            var prior_overness: float = float(local["overness"])
            var prior_momentum: float = float(local["momentum"])
            var effect: Dictionary = effects[person_id]
            var momentum: float = prior_momentum * float(tuning.get("momentum_retention", 0.62)) + float(effect.get("momentum_delta", 0.0)) - repetition_penalty
            local["momentum"] = PhaseEMath.clamp_signed(momentum)
            var reinforcement: float = maxf(0.0, float(local["momentum"])) * float(tuning.get("overness_momentum_conversion", 0.035))
            var response_delta: float = (response - 0.5) * float(tuning.get("overness_response_scale", 0.018))
            var overness_delta: float = reinforcement + response_delta - repetition_penalty * float(tuning.get("overness_repetition_scale", 0.18))
            local["overness"] = PhaseEMath.clamp01(prior_overness + overness_delta)
            if bool(effect.get("featured", false)):
                local["shine"] = PhaseEMath.clamp01(float(local["shine"]) + maxf(0.0, response - 0.45) * float(tuning.get("featured_shine_scale", 0.08)))
                local["heat"] = PhaseEMath.clamp01(float(local["heat"]) + maxf(0.0, 0.55 - response) * float(tuning.get("featured_heat_scale", 0.04)))
            else:
                local["heat"] = PhaseEMath.clamp01(float(local["heat"]) + maxf(0.0, response - 0.5) * float(tuning.get("supporting_heat_scale", 0.045)))
                local["shine"] = PhaseEMath.clamp01(float(local["shine"]) + maxf(0.0, response - 0.55) * float(tuning.get("supporting_shine_scale", 0.025)))
            audience_by_market[market_id] = local
            person.set("audience_by_market", audience_by_market)
            var hot_result: Dictionary = _hot.call("update", person, person_id, "wrestler", float(local["momentum"]), target_date, random_service, tuning, ["local_momentum", "show_response"])
            events.append_array(_hot_events(hot_result.get("events", []), target_date))
            if float(local["overness"]) - prior_overness >= float(tuning.get("breakthrough_overness_delta", 0.02)):
                events.append(DomainEvent.make("AudienceBreakthrough", target_date, [person_id, promotion_id], {
                    "person_id": person_id, "market_id": market_id, "overness_before": prior_overness, "overness_after": local["overness"], "momentum": local["momentum"],
                }, {"category": "audience", "historical_class": "state_change", "explanation": [{"source": "show", "show_id": result.get("show_id")}, {"source": "reinforcement", "value": reinforcement}]}))
        var program_effect: Dictionary = result.get("program_effect")
        if not program_effect.is_empty() and programs.has(str(program_effect.get("program_id"))):
            var program: RefCounted = programs[str(program_effect.get("program_id"))]
            var heat_before: float = float(program.get("heat"))
            var momentum_before: float = float(program.get("momentum"))
            program.set("heat", PhaseEMath.clamp01(heat_before + float(program_effect.get("heat_delta", 0.0)) - repetition_penalty * 0.25))
            program.set("momentum", PhaseEMath.clamp_signed(momentum_before * float(tuning.get("program_momentum_retention", 0.72)) + float(program_effect.get("momentum_delta", 0.0)) - repetition_penalty * 0.5))
            var program_hot: Dictionary = _hot.call("update", program, str(program.get("id")), "program", float(program.get("momentum")), target_date, random_service, tuning, ["program_momentum", "show_quality"])
            events.append_array(_hot_events(program_hot.get("events", []), target_date))
            if absf(float(program.get("momentum")) - momentum_before) >= float(tuning.get("journal_program_delta", 0.02)):
                events.append(DomainEvent.make("ProgramDeveloped", target_date, [str(program.get("id")), promotion_id], {
                    "program_id": program.get("id"), "heat_before": heat_before, "heat_after": program.get("heat"), "momentum_before": momentum_before, "momentum_after": program.get("momentum"),
                }, {"category": "booking", "historical_class": "state_change", "explanation": [{"source": "show", "show_id": result.get("show_id")}, {"source": "repetition_penalty", "value": repetition_penalty}]}))
        var championship_id: Variant = result.get("featured_championship_id")
        if championship_id != null and championships.has(str(championship_id)):
            var championship: RefCounted = championships[str(championship_id)]
            championship.set("prestige", PhaseEMath.clamp01(float(championship.get("prestige")) + (quality - 0.5) * float(tuning.get("championship_prestige_scale", 0.015))))
        promotion_month_signals[promotion_id] = float(promotion_month_signals.get(promotion_id, 0.0)) + (response - 0.5)
        events.append(DomainEvent.make("ShowResolved", target_date, [promotion_id, str(result.get("touring_company_id"))] + (result.get("participant_person_ids") as Array), {
            "show_id": result.get("show_id"), "market_id": market_id, "attendance": result.get("attendance"), "show_quality": quality, "crowd_response": response,
        }, {"category": "show", "historical_class": "routine", "explanation": (result.get("causal_factors") as Array).duplicate(true)}))
    for promotion_id: String in DomainIds.sorted_keys(promotion_month_signals):
        if not promotions.has(promotion_id):
            continue
        var promotion: RefCounted = promotions[promotion_id]
        var month_signal: float = float(promotion_month_signals[promotion_id])
        promotion.set("momentum", PhaseEMath.clamp_signed(float(promotion.get("momentum")) * float(tuning.get("promotion_momentum_retention", 0.75)) + month_signal * float(tuning.get("promotion_show_signal_scale", 0.12))))
        var promotion_hot: Dictionary = _hot.call("update", promotion, promotion_id, "promotion", float(promotion.get("momentum")), target_date, random_service, tuning, ["promotion_momentum", "show_response"])
        events.append_array(_hot_events(promotion_hot.get("events", []), target_date))
    return {"passed": true, "errors": [], "events": events}

func _local_state(value: Variant) -> Dictionary:
    var local: Dictionary = value.duplicate(true) if value is Dictionary else {}
    return {
        "overness": PhaseEMath.clamp01(float(local.get("overness", 0.1))),
        "heat": PhaseEMath.clamp01(float(local.get("heat", 0.1))),
        "shine": PhaseEMath.clamp01(float(local.get("shine", 0.1))),
        "momentum": PhaseEMath.clamp_signed(float(local.get("momentum", 0.0))),
    }

func _hot_events(raw_events: Array, date: String) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    for value: Variant in raw_events:
        if not value is Dictionary:
            continue
        var item: Dictionary = value
        var event_type: String = "HotStateStarted" if str(item.get("type")) == "started" else "HotStateEnded"
        output.append(DomainEvent.make(event_type, date, [str(item.get("target_id"))], item.duplicate(true), {"category": "audience", "historical_class": "state_change", "explanation": [{"source": "qualification", "causes": item.get("causes", [])}]}))
    return output
