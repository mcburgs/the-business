extends RefCounted

const DomainEvent = preload("res://domain/events/domain_event.gd")
const DomainIds = preload("res://domain/core/domain_ids.gd")
const PhaseEMath = preload("res://domain/core/phase_e_math.gd")
const HotStateSystem = preload("res://domain/audience/hot_state_system.gd")

var _hot: RefCounted = HotStateSystem.new()

func apply(state: RefCounted, show_results: Array, target_date: String, random_service: RefCounted, tuning: Dictionary) -> Dictionary:
    var events: Array[Dictionary] = []
    var effects: Array[Dictionary] = []
    var markets: Dictionary = state.get("markets")
    var promotions: Dictionary = state.get("promotions")
    var people: Dictionary = state.get("people")
    var world_state: Dictionary = state.get("world_state")
    var streaks: Dictionary = world_state.get("market_visit_streaks", {})
    var last_market: Dictionary = world_state.get("last_market_by_promotion", {})
    for result_value: Variant in show_results:
        var result: RefCounted = result_value
        var promotion_id: String = str(result.get("promotion_id"))
        var market_id: String = str(result.get("market_id"))
        if not markets.has(market_id) or not promotions.has(promotion_id):
            continue
        var market: RefCounted = markets[market_id]
        var promotion_streaks: Dictionary = (streaks.get(promotion_id, {}) as Dictionary).duplicate(true) if streaks.get(promotion_id, {}) is Dictionary else {}
        var streak: int = int(promotion_streaks.get(market_id, 0)) + 1 if str(last_market.get(promotion_id, "")) == market_id else 1
        promotion_streaks[market_id] = streak
        streaks[promotion_id] = promotion_streaks
        last_market[promotion_id] = market_id
        var overuse: float = maxf(0.0, float(streak - int(tuning.get("overuse_grace_visits", 2))) * float(tuning.get("market_overuse_penalty", 0.018)))
        var response: float = float(result.get("crowd_response"))
        var interest_before: float = float(market.get("wrestling_interest"))
        var interest_delta: float = (response - 0.5) * float(tuning.get("market_interest_show_scale", 0.028)) - overuse
        market.set("wrestling_interest", PhaseEMath.clamp01(interest_before + interest_delta))
        var influence: Dictionary = market.get("influence_by_promotion")
        var components: Dictionary = (influence.get(promotion_id, {}) as Dictionary).duplicate(true) if influence.get(promotion_id, {}) is Dictionary else {}
        var audience_before: float = float(components.get("audience", 0.0))
        var business_before: float = float(components.get("business", 0.0))
        components["audience"] = PhaseEMath.clamp01(audience_before + maxf(-0.02, response - 0.48) * float(tuning.get("influence_audience_scale", 0.04)) - overuse * 0.35)
        var attendance_factor: float = minf(1.0, float(result.get("attendance")) / maxf(1.0, float(tuning.get("influence_attendance_reference", 1200))))
        components["business"] = PhaseEMath.clamp01(business_before + (attendance_factor - 0.4) * float(tuning.get("influence_business_scale", 0.025)) - overuse * 0.2)
        components["media"] = PhaseEMath.clamp01(float(components.get("media", 0.0)))
        components["infrastructure"] = PhaseEMath.clamp01(float(components.get("infrastructure", 0.0)))
        influence[promotion_id] = components
        market.set("influence_by_promotion", influence)
        effects.append({"kind": "live_market", "promotion_id": promotion_id, "market_id": market_id, "interest_delta": PhaseEMath.canonical(float(market.get("wrestling_interest")) - interest_before), "overuse_penalty": overuse})
        if absf(float(market.get("wrestling_interest")) - interest_before) >= float(tuning.get("journal_market_delta", 0.01)):
            events.append(DomainEvent.make("MarketInfluenceChanged", target_date, [promotion_id], {
                "promotion_id": promotion_id, "market_id": market_id, "wrestling_interest_before": interest_before, "wrestling_interest_after": market.get("wrestling_interest"), "components": components.duplicate(true),
            }, {"category": "market", "historical_class": "state_change", "explanation": [{"source": "show", "show_id": result.get("show_id")}, {"source": "overuse", "value": overuse}]}))
        var market_hot: Dictionary = _hot.call("update", market, market_id, "market", PhaseEMath.clamp_signed(interest_delta * 12.0), target_date, random_service, tuning, ["market_interest_change", "overuse"])
        events.append_array(_hot_events(market_hot.get("events", []), target_date))
    world_state["market_visit_streaks"] = streaks
    world_state["last_market_by_promotion"] = last_market

    var media_spend: Dictionary = world_state.get("local_media_spend_by_promotion", {})
    var deals: Dictionary = state.get("media_deals")
    for deal_id: String in DomainIds.sorted_keys(deals):
        var deal: RefCounted = deals[deal_id]
        if str(deal.get("status")) != "active":
            continue
        var promotion_id: String = str(deal.get("promotion_id"))
        if not promotions.has(promotion_id):
            continue
        var spend_record: Dictionary = media_spend.get(promotion_id, {}) if media_spend.get(promotion_id, {}) is Dictionary else {}
        var spend_minor: int = int(spend_record.get("minor_units", 0))
        var spend_reference: float = maxf(1.0, float(tuning.get("media_spend_reference_minor_units", 25000)))
        var spend_factor: float = minf(1.0, float(spend_minor) / spend_reference)
        for market_value: Variant in deal.get("reach_market_ids"):
            var market_id: String = str(market_value)
            if not markets.has(market_id):
                continue
            var market: RefCounted = markets[market_id]
            var influence: Dictionary = market.get("influence_by_promotion")
            var components: Dictionary = (influence.get(promotion_id, {}) as Dictionary).duplicate(true) if influence.get(promotion_id, {}) is Dictionary else {}
            var before: float = float(components.get("media", 0.0))
            var media_gain: float = float(tuning.get("media_deal_base_influence_gain", 0.01)) + spend_factor * float(tuning.get("media_spend_influence_gain", 0.018))
            components["media"] = PhaseEMath.clamp01(before + media_gain)
            components["audience"] = PhaseEMath.clamp01(float(components.get("audience", 0.0)) + media_gain * float(tuning.get("media_to_audience_influence_ratio", 0.3)))
            components["business"] = PhaseEMath.clamp01(float(components.get("business", 0.0)))
            components["infrastructure"] = PhaseEMath.clamp01(float(components.get("infrastructure", 0.0)))
            influence[promotion_id] = components
            market.set("influence_by_promotion", influence)
            _apply_media_familiarity(state, promotion_id, market_id, media_gain, tuning)
            effects.append({"kind": "media", "promotion_id": promotion_id, "market_id": market_id, "deal_id": deal_id, "media_gain": media_gain, "spend_factor": spend_factor})
        events.append(DomainEvent.make("MediaExposureApplied", target_date, [promotion_id, deal_id], {
            "promotion_id": promotion_id, "media_deal_id": deal_id, "reach_market_ids": (deal.get("reach_market_ids") as Array).duplicate(), "local_media_spend_minor_units": spend_minor,
        }, {"category": "media", "historical_class": "routine", "explanation": [{"source": "media_deal", "deal_id": deal_id}, {"source": "local_media_spend", "minor_units": spend_minor}]}))
    return {"passed": true, "errors": [], "events": events, "effects": effects}

func _apply_media_familiarity(state: RefCounted, promotion_id: String, market_id: String, media_gain: float, tuning: Dictionary) -> void:
    var promotion: RefCounted = (state.get("promotions") as Dictionary)[promotion_id]
    var people: Dictionary = state.get("people")
    var contracts: Dictionary = state.get("contracts")
    for contract_value: Variant in promotion.get("contract_ids"):
        var contract_id: String = str(contract_value)
        if not contracts.has(contract_id):
            continue
        var contract: RefCounted = contracts[contract_id]
        if str(contract.get("status")) != "active":
            continue
        var person_id: String = str(contract.get("person_id"))
        if not people.has(person_id):
            continue
        var person: RefCounted = people[person_id]
        var audience: Dictionary = person.get("audience_by_market")
        var local: Dictionary = audience.get(market_id, {}) if audience.get(market_id, {}) is Dictionary else {}
        local["overness"] = PhaseEMath.clamp01(float(local.get("overness", 0.05)) + media_gain * float(tuning.get("media_overness_conversion", 0.12)))
        local["heat"] = PhaseEMath.clamp01(float(local.get("heat", 0.05)))
        local["shine"] = PhaseEMath.clamp01(float(local.get("shine", 0.05)))
        local["momentum"] = PhaseEMath.clamp_signed(float(local.get("momentum", 0.0)))
        audience[market_id] = local
        person.set("audience_by_market", audience)

func _hot_events(raw_events: Array, date: String) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    for value: Variant in raw_events:
        if not value is Dictionary:
            continue
        var item: Dictionary = value
        var event_type: String = "HotStateStarted" if str(item.get("type")) == "started" else "HotStateEnded"
        output.append(DomainEvent.make(event_type, date, [str(item.get("target_id"))], item.duplicate(true), {"category": "market", "historical_class": "state_change", "explanation": [{"source": "qualification", "causes": item.get("causes", [])}]}))
    return output
