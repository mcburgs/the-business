extends RefCounted
const CampaignSession = preload("res://app/session/campaign_session.gd")
func run() -> Dictionary:
    var failures: Array[String] = []; var session: RefCounted = CampaignSession.new(); var started: Dictionary = session.start("res://content/campaigns/great_lakes_1975", 424242); _expect(bool(started.get("passed", false)), "Phase G command-flow fixture must start.", failures)
    if not bool(started.get("passed", false)): return {"name": "phase_g_command_and_month_flow", "passed": false, "failures": failures}
    var view: Dictionary = session.current_projection(); var own: Dictionary = {}; var rival: Dictionary = {}
    for company: Dictionary in view.get("touring", []):
        if str(company.get("ownership", "")) == "controlled" and own.is_empty(): own = company
        elif str(company.get("ownership", "")) == "observed" and rival.is_empty(): rival = company
    _expect(not own.is_empty() and not rival.is_empty(), "Phase G must expose a controlled route and knowledge-limited rival touring context.", failures)
    if own.is_empty() or rival.is_empty(): return {"name": "phase_g_command_and_month_flow", "passed": false, "failures": failures}
    var target: String = str((view.get("markets", []) as Array)[-1].get("market_id", "")); var before: Dictionary = session.state_snapshot(); var queued: Dictionary = session.queue_player_command("command.set_route", {"touring_company_id": str(own.get("company_id", "")), "route": [{"market_id": target}]}); _expect(bool(queued.get("accepted", false)), "A legal UI touring intent must validate through the canonical CommandRouter path.", failures); _expect(session.state_snapshot() == before, "Queueing a UI command must not mutate authoritative state before month resolution.", failures)
    var cross: Dictionary = session.test_route_command_for(str((view.get("ownership", {}) as Dictionary).get("promotion_id", "")), str(rival.get("company_id", "")), [{"market_id": target}]); _expect(not bool(cross.get("accepted", true)), "A player cross-promotion touring mutation must remain rejected at the Phase G command boundary.", failures)
    var advance: Dictionary = session.advance_month(); _expect(bool(advance.get("passed", false)), "Phase G must advance a complete strategic month through MonthPipeline.", failures)
    if bool(advance.get("passed", false)):
        var refreshed: Dictionary = session.current_projection(); _expect(str(refreshed.get("date", "")) != str(view.get("date", "")), "Month advance must refresh the displayed projection from authoritative post-turn state.", failures)
        var found: bool = false
        for company: Dictionary in refreshed.get("touring", []):
            if str(company.get("company_id", "")) == str(own.get("company_id", "")): found = not (company.get("route", []) as Array).is_empty() and str((company.get("route", []) as Array)[0].get("market_id", "")) == target
        _expect(found, "The accepted UI route command must be visible in the authoritative post-month projection.", failures)
    return {"name": "phase_g_command_and_month_flow", "passed": failures.is_empty(), "failures": failures}
func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition: failures.append(message)
