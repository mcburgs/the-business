extends RefCounted

const Fixture = preload("res://tests/helpers/phase_f_fixture.gd")
const MonthPipeline = preload("res://app/session/month_pipeline.gd")
const CampaignStateCodec = preload("res://persistence/codecs/campaign_state_codec.gd")
const ChronicleCodec = preload("res://persistence/codecs/chronicle_codec.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var run_a: Dictionary = _simulate(246810, 24)
    var replay: Dictionary = _simulate(246810, 24)
    var variant: Dictionary = _simulate(246811, 24)
    _expect(bool(run_a.get("passed", false)), "Primary 24-month competition run must complete: " + JSON.stringify(run_a.get("errors", [])), failures)
    _expect(bool(replay.get("passed", false)) and run_a.get("state") == replay.get("state") and run_a.get("chronicle") == replay.get("chronicle") and run_a.get("summary") == replay.get("summary"), "Equal initial state and seed must reproduce exact commands, outcomes, Chronicle, and summary.", failures)
    _expect(bool(variant.get("passed", false)) and run_a.get("summary") != variant.get("summary"), "A different seed must be capable of producing a different competitive history.", failures)
    if bool(run_a.get("passed", false)):
        var summary: Dictionary = run_a.get("summary")
        _expect(summary.get("shows_by_promotion", {}).size() == 3 and _minimum_value(summary.get("shows_by_promotion", {})) >= 18, "All three promotions must sustain operations across the two-year fixture.", failures)
        _expect(int(summary.get("talent_signed", 0)) >= 1 and int(summary.get("contract_events", 0)) >= 2, "Talent competition must create signings plus renewal/expiry/release consequences.", failures)
        _expect(int(summary.get("scouting_reports", 0)) >= 50, "Monthly organizational scouting must accumulate useful knowledge.", failures)
        _expect(int(summary.get("route_changes", 0)) >= 2 and int(summary.get("contested_market_months", 0)) >= 24, "Promotions must enter/defend markets and sustain visible rivalry.", failures)
        _expect(int(summary.get("recovery_decisions", 0)) >= 1 and int(summary.get("recovery_budget_after", 0)) < int(summary.get("recovery_budget_before", 0)), "Financially stressed promotion must take visible recovery action.", failures)
        _expect(int(summary.get("agreement_events", 0)) >= 1 and int(summary.get("territory_violations", 0)) >= 1, "Shallow diplomacy must create agreements and visible hostile-entry consequences.", failures)
        _expect(float(summary.get("maximum_market_concentration", 1.0)) < 0.96, "Normal two-year play must not collapse into automatic total dominance.", failures)
        _expect(bool(summary.get("all_ai_explanations_structured", false)), "AI actions must expose structured principal reasons, observed state, pressure, opportunity, inertia, or bounded noise as applicable.", failures)
    return {"name": "phase_f_competition", "passed": failures.is_empty(), "failures": failures, "summary": run_a.get("summary", {}), "deterministic_replay": failures.is_empty() and run_a.get("summary", {}) == replay.get("summary", {})}

func _simulate(seed: int, months: int) -> Dictionary:
    var state: RefCounted = Fixture.make_state(seed); var chronicle: RefCounted = Fixture.make_chronicle(6); var pipeline: RefCounted = MonthPipeline.new()
    var metrics: Dictionary = {"shows_by_promotion": {}, "talent_signed": 0, "contract_events": 0, "scouting_reports": 0, "route_changes": 0, "contested_market_months": 0, "recovery_decisions": 0, "recovery_budget_before": 155000, "recovery_budget_after": 155000, "agreement_events": 0, "territory_violations": 0, "all_ai_explanations_structured": true}
    var last_routes: Dictionary = _routes(state)
    for month_index: int in range(months):
        var turn: RefCounted = pipeline.call("advance_month", state, chronicle, [], Fixture.content_index())
        if not bool(turn.get("passed")): return {"passed": false, "errors": turn.get("errors"), "month_index": month_index}
        state = turn.get("state"); chronicle = turn.get("chronicle")
        var outputs: Dictionary = turn.get("phase_outputs")
        for show_value: Variant in outputs.get("show_results", []):
            var promotion_id: String = str((show_value as RefCounted).get("promotion_id")); metrics["shows_by_promotion"][promotion_id] = int(metrics["shows_by_promotion"].get(promotion_id, 0)) + 1
        metrics["scouting_reports"] = int(metrics["scouting_reports"]) + (outputs.get("scouting_reports", []) as Array).size()
        for decision: Dictionary in outputs.get("ai_decisions", []):
            var explanation: Dictionary = decision.get("explanation", {})
            if not explanation.has("decision_family") or not explanation.has("principal_reasons") or (explanation.get("principal_reasons", []) as Array).is_empty() or not explanation.has("bounded_noise"): metrics["all_ai_explanations_structured"] = false
            if str(explanation.get("decision_family")) == "recovery": metrics["recovery_decisions"] = int(metrics["recovery_decisions"]) + 1
        for event: Dictionary in turn.get("events"):
            var type: String = str(event.get("event_type"))
            if type == "TalentSigned": metrics["talent_signed"] = int(metrics["talent_signed"]) + 1
            if type in ["TalentSigned", "TalentReleased", "ContractRenewed", "ContractExpired"]: metrics["contract_events"] = int(metrics["contract_events"]) + 1
            if type == "AgreementCreated": metrics["agreement_events"] = int(metrics["agreement_events"]) + 1
            if type == "TerritoryViolated": metrics["territory_violations"] = int(metrics["territory_violations"]) + 1
        var current_routes: Dictionary = _routes(state)
        for company_id: Variant in current_routes.keys():
            if last_routes.get(company_id) != current_routes[company_id]: metrics["route_changes"] = int(metrics["route_changes"]) + 1
        last_routes = current_routes
        metrics["contested_market_months"] = int(metrics["contested_market_months"]) + _contested_markets(state)
        metrics["recovery_budget_after"] = int((((state.get("touring_companies") as Dictionary)["touring:TOU00003"] as RefCounted).get("monthly_budget") as Dictionary).get("minor_units"))
    metrics["maximum_market_concentration"] = _maximum_concentration(state)
    metrics["final_date"] = state.get("current_date"); metrics["chronicle_counts"] = chronicle.call("counts")
    return {"passed": true, "state": CampaignStateCodec.new().encode(state), "chronicle": ChronicleCodec.new().encode(chronicle), "summary": metrics}

func _routes(state: RefCounted) -> Dictionary:
    var output: Dictionary = {}
    for id: Variant in (state.get("touring_companies") as Dictionary).keys(): output[str(id)] = ((state.get("touring_companies") as Dictionary)[id] as RefCounted).get("route").duplicate(true)
    return output

func _contested_markets(state: RefCounted) -> int:
    var count: int = 0
    for market_value: Variant in (state.get("markets") as Dictionary).values():
        var meaningful: int = 0
        for influence_value: Variant in ((market_value as RefCounted).get("influence_by_promotion") as Dictionary).values():
            if _composite(influence_value) >= 0.20: meaningful += 1
        if meaningful >= 2: count += 1
    return count

func _maximum_concentration(state: RefCounted) -> float:
    var maximum: float = 0.0
    for market_value: Variant in (state.get("markets") as Dictionary).values():
        for influence_value: Variant in ((market_value as RefCounted).get("influence_by_promotion") as Dictionary).values(): maximum = maxf(maximum, _composite(influence_value))
    return maximum

func _composite(value: Variant) -> float:
    var v: Dictionary = value; return float(v.get("audience", 0.0)) * 0.4 + float(v.get("media", 0.0)) * 0.25 + float(v.get("business", 0.0)) * 0.25 + float(v.get("infrastructure", 0.0)) * 0.1

func _minimum_value(values: Dictionary) -> int:
    var output: int = 999999
    for value: Variant in values.values(): output = mini(output, int(value))
    return output

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition: failures.append(message)
