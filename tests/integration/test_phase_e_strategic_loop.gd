extends RefCounted

const PhaseEFixture = preload("res://tests/helpers/phase_e_fixture.gd")
const MonthPipeline = preload("res://app/session/month_pipeline.gd")
const CampaignStateCodec = preload("res://persistence/codecs/campaign_state_codec.gd")
const ChronicleCodec = preload("res://persistence/codecs/chronicle_codec.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var good: Dictionary = _simulate("good", 424242, 12)
    var bad: Dictionary = _simulate("bad", 424242, 12)
    var replay: Dictionary = _simulate("good", 424242, 12)
    if not bool(good.get("passed", false)): failures.append("good strategic run failed: " + JSON.stringify(good.get("errors", [])))
    if not bool(bad.get("passed", false)): failures.append("bad strategic run failed: " + JSON.stringify(bad.get("errors", [])))
    if bool(good.get("passed", false)) and bool(replay.get("passed", false)):
        if good.get("state_encoded") != replay.get("state_encoded") or good.get("chronicle_encoded") != replay.get("chronicle_encoded") or good.get("summary") != replay.get("summary"):
            failures.append("equal initial state, commands and seed must reproduce identical strategic results")
    if failures.is_empty():
        var gs: Dictionary = good["summary"]
        var bs: Dictionary = bad["summary"]
        if gs == bs: failures.append("materially different command schedules must not produce indistinguishable worlds")
        if float(gs["star_market_a_momentum"]) <= float(bs["star_market_a_momentum"]): failures.append("coherent star deployment should retain more home-market star momentum")
        if float(gs["market_a_interest"]) <= float(bs["market_a_interest"]): failures.append("alternating coherent deployment should preserve home-market interest better than overuse")
        if int(gs["profit_minor_units"]) <= int(bs["profit_minor_units"]): failures.append("coherent sustainable deployment should finish with stronger cumulative profit than wasteful deployment")
        if str(gs["program_status"]) != "active" or str(bs["program_status"]) != "ended": failures.append("creative strategy should create an understandable program-state divergence")
        if float(gs["star_market_b_overness"]) <= 0.18: failures.append("credible repeated deployment should grow durable local overness outside the home market")
        if float(gs["star_market_a_overness"]) >= 0.90: failures.append("one year of momentum must not automatically manufacture near-max durable overness")
    return {
        "name": "phase_e_strategic_loop",
        "passed": failures.is_empty(),
        "failures": failures,
        "good_summary": good.get("summary", {}),
        "bad_summary": bad.get("summary", {}),
        "deterministic_replay": failures.is_empty() and good.get("summary", {}) == replay.get("summary", {}),
    }

func _simulate(strategy: String, seed: int, months: int) -> Dictionary:
    var state: RefCounted = PhaseEFixture.make_state(seed)
    var chronicle: RefCounted = PhaseEFixture.make_chronicle()
    var pipeline: RefCounted = MonthPipeline.new()
    var total_attendance: int = 0
    var total_revenue: int = 0
    var total_cost: int = 0
    var show_count: int = 0
    var hot_starts: int = 0
    var hot_ends: int = 0
    for month_index: int in range(months):
        var turn: RefCounted = pipeline.call("advance_month", state, chronicle, PhaseEFixture.strategy_commands(state, strategy, month_index), PhaseEFixture.content_index())
        if not bool(turn.get("passed")):
            return {"passed": false, "errors": turn.get("errors"), "month_index": month_index}
        var phase_outputs: Dictionary = turn.get("phase_outputs")
        for show_value: Variant in phase_outputs.get("show_results", []):
            var show: RefCounted = show_value
            total_attendance += int(show.get("attendance")); show_count += 1
        var economy: Dictionary = phase_outputs.get("economy", {})
        if economy.has(PhaseEFixture.PLAYER_PROMOTION_ID):
            var month_summary: Dictionary = economy[PhaseEFixture.PLAYER_PROMOTION_ID]
            total_revenue += int(month_summary.get("revenue_minor_units", 0))
            total_cost += int(month_summary.get("cost_minor_units", 0))
        for event_value: Variant in turn.get("events"):
            var event: Dictionary = event_value
            if str(event.get("event_type")) == "HotStateStarted": hot_starts += 1
            if str(event.get("event_type")) == "HotStateEnded": hot_ends += 1
        state = turn.get("state")
        chronicle = turn.get("chronicle")
    return {
        "passed": true,
        "state_encoded": CampaignStateCodec.new().encode(state),
        "chronicle_encoded": ChronicleCodec.new().encode(chronicle),
        "summary": _summary(state, chronicle, show_count, total_attendance, total_revenue, total_cost, hot_starts, hot_ends),
    }

func _summary(state: RefCounted, chronicle: RefCounted, shows: int, attendance: int, revenue: int, cost: int, hot_starts: int, hot_ends: int) -> Dictionary:
    var star: RefCounted = (state.get("people") as Dictionary)[PhaseEFixture.STAR_ID]
    var audience: Dictionary = star.get("audience_by_market")
    var market_a: RefCounted = (state.get("markets") as Dictionary)[PhaseEFixture.MARKET_A]
    var market_b: RefCounted = (state.get("markets") as Dictionary)[PhaseEFixture.MARKET_B]
    var program: RefCounted = (state.get("programs") as Dictionary)[PhaseEFixture.PROGRAM_ID]
    var promotion: RefCounted = (state.get("promotions") as Dictionary)[PhaseEFixture.PLAYER_PROMOTION_ID]
    var company: RefCounted = (state.get("touring_companies") as Dictionary)[PhaseEFixture.COMPANY_ID]
    var a_local: Dictionary = audience.get(PhaseEFixture.MARKET_A, {})
    var b_local: Dictionary = audience.get(PhaseEFixture.MARKET_B, {})
    return {
        "date": state.get("current_date"),
        "shows": shows,
        "attendance": attendance,
        "revenue_minor_units": revenue,
        "cost_minor_units": cost,
        "profit_minor_units": revenue - cost,
        "cash_minor_units": (promotion.get("cash") as Dictionary).get("minor_units"),
        "star_market_a_overness": a_local.get("overness", 0.0),
        "star_market_a_momentum": a_local.get("momentum", 0.0),
        "star_market_b_overness": b_local.get("overness", 0.0),
        "star_market_b_momentum": b_local.get("momentum", 0.0),
        "program_status": program.get("status"),
        "program_heat": program.get("heat"),
        "program_momentum": program.get("momentum"),
        "market_a_interest": market_a.get("wrestling_interest"),
        "market_b_interest": market_b.get("wrestling_interest"),
        "market_a_influence": (market_a.get("influence_by_promotion") as Dictionary).get(PhaseEFixture.PLAYER_PROMOTION_ID, {}).duplicate(true),
        "market_b_influence": (market_b.get("influence_by_promotion") as Dictionary).get(PhaseEFixture.PLAYER_PROMOTION_ID, {}).duplicate(true),
        "company_fatigue": company.get("fatigue_pressure"),
        "financial_stress": (state.get("world_state") as Dictionary).get("financial_stress_by_promotion", {}).get(PhaseEFixture.PLAYER_PROMOTION_ID, 0.0),
        "hot_starts": hot_starts,
        "hot_ends": hot_ends,
        "chronicle_counts": chronicle.call("counts"),
        "chronicle_head_sequence": chronicle.get("head_sequence"),
    }
