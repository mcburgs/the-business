extends RefCounted

const DomainEvent = preload("res://domain/events/domain_event.gd")
const DomainIds = preload("res://domain/core/domain_ids.gd")
const PhaseEMath = preload("res://domain/core/phase_e_math.gd")
const LedgerService = preload("res://domain/economy/ledger_service.gd")

var _ledger: RefCounted = LedgerService.new()

func settle(state: RefCounted, show_results: Array, target_date: String, tuning: Dictionary) -> Dictionary:
    var errors: Array[Dictionary] = []
    var events: Array[Dictionary] = []
    var summary_by_promotion: Dictionary = {}
    var promotions: Dictionary = state.get("promotions")
    for promotion_id: String in DomainIds.sorted_keys(promotions):
        summary_by_promotion[promotion_id] = {"revenue_minor_units": 0, "cost_minor_units": 0, "profit_minor_units": 0, "categories": {}}
    for result_value: Variant in show_results:
        var result: RefCounted = result_value
        var promotion_id: String = str(result.get("promotion_id"))
        if not promotions.has(promotion_id):
            continue
        var currency_id: String = str(((promotions[promotion_id] as RefCounted).get("cash") as Dictionary).get("currency_id"))
        var gate: int = int(result.get("gate_minor_units"))
        if gate > 0:
            _post_category(state, promotion_id, target_date, str(result.get("show_id")), "live_gate", gate, true, currency_id, summary_by_promotion, errors)
        var participants: Array = result.get("participant_person_ids")
        var talent_cost: int = _talent_cost(state, promotion_id, participants, currency_id)
        if talent_cost > 0:
            _post_category(state, promotion_id, target_date, str(result.get("show_id")), "talent_pay", talent_cost, false, currency_id, summary_by_promotion, errors)
        var venue_cost: int = int(tuning.get("venue_cost_minor_units", 45000))
        _post_category(state, promotion_id, target_date, str(result.get("show_id")), "venue", venue_cost, false, currency_id, summary_by_promotion, errors)
        var travel_cost: int = int(round(float(tuning.get("travel_cost_base_minor_units", 18000)) * (0.4 + float(result.get("travel_pressure")))))
        _post_category(state, promotion_id, target_date, str(result.get("show_id")), "travel", travel_cost, false, currency_id, summary_by_promotion, errors)
        var production_cost: int = int(tuning.get("production_cost_minor_units", 12000))
        _post_category(state, promotion_id, target_date, str(result.get("show_id")), "production", production_cost, false, currency_id, summary_by_promotion, errors)
    var media_spend: Dictionary = (state.get("world_state") as Dictionary).get("local_media_spend_by_promotion", {})
    var deals: Dictionary = state.get("media_deals")
    var active_deal_ids_by_promotion: Dictionary = {}
    for deal_id: String in DomainIds.sorted_keys(deals):
        var deal: RefCounted = deals[deal_id]
        if str(deal.get("status")) != "active":
            continue
        var promotion_id: String = str(deal.get("promotion_id"))
        if not promotions.has(promotion_id):
            continue
        if not active_deal_ids_by_promotion.has(promotion_id):
            active_deal_ids_by_promotion[promotion_id] = []
        active_deal_ids_by_promotion[promotion_id].append(deal_id)
        var currency_id: String = str(((promotions[promotion_id] as RefCounted).get("cash") as Dictionary).get("currency_id"))
        var cost: int = _money_minor_units(deal.get("cost"), currency_id, int(tuning.get("local_tv_default_cost_minor_units", 10000)))
        var revenue: int = _money_minor_units(deal.get("revenue"), currency_id, int(tuning.get("local_tv_default_revenue_minor_units", 14000)))
        if revenue > 0:
            _post_category(state, promotion_id, target_date, deal_id, "local_tv_revenue", revenue, true, currency_id, summary_by_promotion, errors)
        if cost > 0:
            _post_category(state, promotion_id, target_date, deal_id, "local_tv_cost", cost, false, currency_id, summary_by_promotion, errors)
    for promotion_id: String in DomainIds.sorted_keys(promotions):
        var promotion: RefCounted = promotions[promotion_id]
        var currency_id: String = str((promotion.get("cash") as Dictionary).get("currency_id"))
        var overhead: int = int(tuning.get("monthly_overhead_minor_units", 30000))
        _post_category(state, promotion_id, target_date, "month", "overhead", overhead, false, currency_id, summary_by_promotion, errors)
        var spend_record: Variant = media_spend.get(promotion_id, null)
        if spend_record is Dictionary:
            var spend: int = int((spend_record as Dictionary).get("minor_units", 0))
            if spend > 0:
                _post_category(state, promotion_id, target_date, "month", "local_media_spend", spend, false, currency_id, summary_by_promotion, errors)
        var summary: Dictionary = summary_by_promotion[promotion_id]
        summary["profit_minor_units"] = int(summary.get("revenue_minor_units", 0)) - int(summary.get("cost_minor_units", 0))
        summary["cash_minor_units"] = int((promotion.get("cash") as Dictionary).get("minor_units", 0))
        var stress_map: Dictionary = (state.get("world_state") as Dictionary).get("financial_stress_by_promotion", {})
        var prior_stress: float = float(stress_map.get(promotion_id, 0.0))
        var stress_delta: float = float(tuning.get("loss_stress_gain", 0.08)) if int(summary["profit_minor_units"]) < 0 else -float(tuning.get("profit_stress_recovery", 0.04))
        if int(summary["cash_minor_units"]) < int(tuning.get("financial_stress_cash_threshold_minor_units", 200000)):
            stress_delta += float(tuning.get("low_cash_stress_gain", 0.08))
        stress_map[promotion_id] = PhaseEMath.clamp01(prior_stress + stress_delta)
        (state.get("world_state") as Dictionary)["financial_stress_by_promotion"] = stress_map
        events.append(DomainEvent.make("FinancialMonthResolved", target_date, [promotion_id], summary.duplicate(true), {
            "category": "economy", "historical_class": "state_change",
            "explanation": _category_explanation(summary.get("categories", {})),
        }))
    return {"passed": errors.is_empty(), "errors": errors, "events": events, "summary_by_promotion": summary_by_promotion}

func _post_category(state: RefCounted, promotion_id: String, date: String, source_id: String, category: String, amount: int, revenue: bool, currency_id: String, summaries: Dictionary, errors: Array[Dictionary]) -> void:
    if amount <= 0:
        return
    var cash_delta: int = amount if revenue else -amount
    var counter_delta: int = -cash_delta
    var transaction_id: String = "phase_e:" + str(state.get("turn_number")) + ":" + promotion_id.get_slice(":", 1) + ":" + category + ":" + str((state.get("world_state") as Dictionary).get("ledger_v1", {}).get("transactions", []).size())
    var transaction: Dictionary = {
        "transaction_id": transaction_id,
        "occurred_on": date,
        "promotion_id": promotion_id,
        "category": category,
        "source_id": source_id,
        "postings": [
            {"account_id": promotion_id + ".cash", "currency_id": currency_id, "minor_units": cash_delta},
            {"account_id": promotion_id + "." + ("revenue." if revenue else "expense.") + category, "currency_id": currency_id, "minor_units": counter_delta},
        ],
    }
    var posted: Dictionary = _ledger.call("post_for_promotion", state, promotion_id, transaction)
    if not bool(posted.get("passed", false)):
        errors.append_array(posted.get("errors", []))
        return
    var summary: Dictionary = summaries[promotion_id]
    if revenue:
        summary["revenue_minor_units"] = int(summary.get("revenue_minor_units", 0)) + amount
    else:
        summary["cost_minor_units"] = int(summary.get("cost_minor_units", 0)) + amount
    var categories: Dictionary = summary.get("categories", {})
    categories[category] = int(categories.get(category, 0)) + amount
    summary["categories"] = categories
    summaries[promotion_id] = summary

func _talent_cost(state: RefCounted, promotion_id: String, participants: Array, currency_id: String) -> int:
    var contracts: Dictionary = state.get("contracts")
    var participant_set: Dictionary = {}
    for value: Variant in participants:
        participant_set[str(value)] = true
    var total: int = 0
    for contract_id: String in DomainIds.sorted_keys(contracts):
        var contract: RefCounted = contracts[contract_id]
        if str(contract.get("promotion_id")) != promotion_id or str(contract.get("status")) != "active":
            continue
        if not participant_set.has(str(contract.get("person_id"))):
            continue
        var compensation: Dictionary = contract.get("compensation")
        var base: Variant = compensation.get("base", null)
        if base is Dictionary and str((base as Dictionary).get("currency_id", "")) == currency_id:
            total += int((base as Dictionary).get("minor_units", 0))
    return total

func _money_minor_units(value: Variant, currency_id: String, fallback: int) -> int:
    if value is Dictionary:
        var record: Dictionary = value
        if record.has("minor_units") and str(record.get("currency_id", currency_id)) == currency_id:
            return int(record.get("minor_units", 0))
        if record.has("base") and record["base"] is Dictionary:
            return _money_minor_units(record["base"], currency_id, fallback)
    return fallback

func _category_explanation(categories: Dictionary) -> Array:
    var output: Array = []
    var keys: Array[String] = []
    for key: Variant in categories.keys():
        keys.append(str(key))
    keys.sort()
    for key: String in keys:
        output.append({"source": "ledger_category", "category": key, "minor_units": categories[key]})
    return output
