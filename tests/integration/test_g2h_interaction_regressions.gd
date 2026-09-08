extends RefCounted

const CampaignSession = preload("res://app/session/campaign_session.gd")
const StrategicHome = preload("res://presentation/shell/strategic_home.gd")
const CommandEnvelope = preload("res://app/commands/command_envelope.gd")
const CommandRouter = preload("res://app/commands/command_router.gd")

const CAMPAIGN := "res://content/campaigns/great_lakes_1975"
const SEED := 424242

func run() -> Dictionary:
    var failures: Array[String] = []
    _test_repeated_command_coalescing(failures)
    _test_duplicate_month_activation(failures)
    _test_stale_and_cross_promotion_validation(failures)
    _test_navigation_history_and_selection_churn(failures)
    _test_knowledge_boundary_paths(failures)
    _test_touring_churn_determinism(failures)
    return {"name": "g2h_interaction_regressions", "passed": failures.is_empty(), "failures": failures}

func _test_repeated_command_coalescing(failures: Array[String]) -> void:
    var session: RefCounted = _session(failures, "repeated-command")
    if session == null: return
    var view: Dictionary = session.call("current_projection")
    var own: Dictionary = _controlled_company(view)
    var wrestler: Dictionary = _assigned_wrestler(view, own)
    var markets: Array = view.get("markets", [])
    _expect(not own.is_empty() and not wrestler.is_empty() and markets.size() >= 2, "G→H repeated-command fixture must expose controlled touring, an assigned wrestler and multiple markets.", failures)
    if own.is_empty() or wrestler.is_empty() or markets.size() < 2: return

    var company_id := str(own.get("company_id", ""))
    var promotion_id := str((view.get("ownership", {}) as Dictionary).get("promotion_id", ""))
    var person_id := str(wrestler.get("person_id", ""))
    var market_a := str((markets[0] as Dictionary).get("market_id", ""))
    var market_b := str((markets[1] as Dictionary).get("market_id", ""))
    var budget: Dictionary = own.get("budget", {})
    var current_minor := int(budget.get("minor_units", 0))
    var currency_id := str(budget.get("currency_id", "currency.usd"))

    var first_route: Dictionary = {}
    for _i: int in range(5):
        first_route = session.call("queue_player_command", "command.set_route", {"touring_company_id": company_id, "route": [{"market_id": market_a}]})
        _expect(bool(first_route.get("accepted", false)), "Repeated legal route taps must remain accepted as one UI intent.", failures)
    _expect(int(session.call("pending_count")) == 1, "G2H-001: five identical route taps must occupy one pending authoritative intent.", failures)
    _expect(str((first_route.get("details", {}) as Dictionary).get("interaction_disposition", "")) == "duplicate_suppressed", "G2H-001: exact repeated route intent should be explicitly suppressed rather than duplicated.", failures)

    var replaced_route: Dictionary = session.call("queue_player_command", "command.set_route", {"touring_company_id": company_id, "route": [{"market_id": market_b}]})
    _expect(bool(replaced_route.get("accepted", false)) and int(session.call("pending_count")) == 1, "G2H-001: changing the same route before resolution must supersede instead of append.", failures)

    var budget_one: Dictionary = session.call("queue_player_command", "command.adjust_budget", {"touring_company_id": company_id, "monthly_budget": {"minor_units": int(round(current_minor * 1.10)), "currency_id": currency_id}})
    var budget_two: Dictionary = session.call("queue_player_command", "command.adjust_budget", {"touring_company_id": company_id, "monthly_budget": {"minor_units": int(round(current_minor * 1.20)), "currency_id": currency_id}})
    _expect(bool(budget_one.get("accepted", false)) and bool(budget_two.get("accepted", false)) and int(session.call("pending_count")) == 2, "G2H-001: repeated budget adjustment for one company must collapse to one final budget intent.", failures)

    var focus: Dictionary = {}
    for _i: int in range(4):
        focus = session.call("queue_player_command", "command.book_market_focus", {"promotion_id": promotion_id, "market_id": market_b, "intensity": 0.72})
    _expect(bool(focus.get("accepted", false)) and int(session.call("pending_count")) == 3, "G2H-001: repeated market-focus taps must collapse to one promotion focus intent.", failures)

    var push: Dictionary = {}
    for _i: int in range(4):
        push = session.call("queue_player_command", "command.push_person", {"touring_company_id": company_id, "person_id": person_id, "weight": 1.0})
    _expect(bool(push.get("accepted", false)) and int(session.call("pending_count")) == 4, "G2H-001: repeated push taps for the same person/company must collapse to one intent.", failures)

    var final_ids: Array[String] = [str(replaced_route.get("command_id", "")), str(budget_two.get("command_id", "")), str(focus.get("command_id", "")), str(push.get("command_id", ""))]
    var advanced: Dictionary = session.call("advance_month")
    _expect(bool(advanced.get("passed", false)), "Coalesced G→H interaction intents must resolve through the normal MonthPipeline.", failures)
    if not bool(advanced.get("passed", false)): return
    var player_results: Dictionary = {}
    for result: Dictionary in (advanced.get("turn", {}) as Dictionary).get("command_results", []):
        var command_id := str(result.get("command_id", ""))
        if command_id in final_ids:
            player_results[command_id] = int(player_results.get(command_id, 0)) + 1
    for command_id: String in final_ids:
        _expect(int(player_results.get(command_id, 0)) == 1, "G2H-001: each final coalesced player intent must produce exactly one authoritative command result: " + command_id, failures)
    var refreshed: Dictionary = session.call("current_projection")
    var refreshed_company: Dictionary = _company_by_id(refreshed, company_id)
    _expect(not refreshed_company.is_empty() and not (refreshed_company.get("route", []) as Array).is_empty() and str(((refreshed_company.get("route", []) as Array)[0] as Dictionary).get("market_id", "")) == market_b, "G2H-001: the superseding route, not an earlier tap, must be authoritative after resolution.", failures)

func _test_duplicate_month_activation(failures: Array[String]) -> void:
    var session: RefCounted = _session(failures, "duplicate-month")
    if session == null: return
    var home: Control = StrategicHome.new()
    home.call("_ready")
    home.call("bind_session", session)
    var before_turn := int((session.call("current_projection") as Dictionary).get("turn_number", -1))
    var first: Dictionary = home.call("_advance_month")
    var second: Dictionary = home.call("_advance_month")
    var after_turn := int((session.call("current_projection") as Dictionary).get("turn_number", -1))
    _expect(bool(first.get("passed", false)), "G2H-003: the first deliberate month activation must resolve.", failures)
    _expect(not bool(second.get("passed", true)) and bool(second.get("suppressed", false)), "G2H-003: a second activation in the same UI burst must be suppressed.", failures)
    _expect(after_turn == before_turn + 1, "G2H-003: one immediate double activation must advance exactly one month, never two.", failures)
    home.call("_release_advance_lock")
    home.free()

func _test_stale_and_cross_promotion_validation(failures: Array[String]) -> void:
    var session: RefCounted = _session(failures, "stale-command")
    if session == null: return
    var view: Dictionary = session.call("current_projection")
    var own: Dictionary = _controlled_company(view)
    var rival: Dictionary = _observed_company(view)
    var markets: Array = view.get("markets", [])
    _expect(not own.is_empty() and not rival.is_empty() and not markets.is_empty(), "G→H stale/cross-promotion fixture must expose own/rival touring and a market.", failures)
    if own.is_empty() or rival.is_empty() or markets.is_empty(): return
    var target := str((markets[0] as Dictionary).get("market_id", ""))
    var controlled_id := str((view.get("ownership", {}) as Dictionary).get("promotion_id", ""))
    var stale := CommandEnvelope.new()
    stale.set("command_id", "command:G2H00001")
    stale.set("command_type", "command.set_route")
    stale.set("issued_for_turn", int(view.get("turn_number", 0)))
    stale.set("issued_on", str(view.get("date", "")))
    stale.set("issuer", {"kind": "player", "promotion_id": controlled_id})
    stale.set("turn_phase_ordinal", 3)
    stale.set("priority", 100)
    stale.set("issuer_key", "player." + controlled_id)
    stale.set("payload", {"touring_company_id": str(own.get("company_id", "")), "route": [{"market_id": target}]})
    var advance: Dictionary = session.call("advance_month")
    _expect(bool(advance.get("passed", false)), "G→H stale-envelope setup month must resolve.", failures)
    if bool(advance.get("passed", false)):
        var stale_result: Dictionary = CommandRouter.new().call("apply", session.get("_state"), stale, session.get("_content_index"))
        var stale_errors: Array = stale_result.get("errors", [])
        _expect(not bool(stale_result.get("accepted", true)) and not stale_errors.is_empty() and str((stale_errors[0] as Dictionary).get("code", "")) == "CMD002", "Stale command envelopes must be rejected against current authoritative turn/date rather than trusted from the old view.", failures)
    var cross: Dictionary = session.call("test_route_command_for", controlled_id, str(rival.get("company_id", "")), [{"market_id": target}])
    _expect(not bool(cross.get("accepted", true)), "F2G-001/G→H: rapid target churn must not permit a player command against rival touring authority.", failures)

func _test_navigation_history_and_selection_churn(failures: Array[String]) -> void:
    var session: RefCounted = _session(failures, "navigation-history")
    if session == null: return
    _expect(bool((session.call("advance_month") as Dictionary).get("passed", false)), "History churn fixture month one must resolve.", failures)
    _expect(bool((session.call("advance_month") as Dictionary).get("passed", false)), "History churn fixture month two must resolve.", failures)
    var home: Control = StrategicHome.new()
    home.call("_ready")
    home.call("bind_session", session)
    var state_before: Dictionary = session.call("state_snapshot")
    var chronicle_before: Dictionary = session.call("chronicle_snapshot")
    var valid_selection := str(home.get("selected_market_id"))
    home.call("_on_market_selected", "market:STALEG2H")
    _expect(str(home.get("selected_market_id")) == valid_selection, "G2H-004: an invalid/stale market ID must not become current presentation selection.", failures)

    var surfaces: Array[String] = ["map", "roster", "touring", "wrestling", "history", "market"]
    for i: int in range(40):
        home.call("_set_surface", surfaces[i % surfaces.size()])
    home.call("_set_surface", "history")
    var dates: Array = (session.call("current_projection") as Dictionary).get("history_dates", [])
    _expect(dates.size() >= 3, "G→H Chronicle churn fixture should expose multiple historical dates.", failures)
    for i: int in range(50):
        if not dates.is_empty(): home.call("_show_historical", str(dates[i % dates.size()]))
    var detail_content: VBoxContainer = home.get("detail_content")
    _expect(detail_content.find_children("*", "OptionButton", true, false).size() == 1, "G2H-002: Chronicle rendering must attach exactly one historical-date selector.", failures)
    _expect(detail_content.find_children("HistoricalProjectionCard", "", true, false).size() == 1, "G2H-002: repeated historical inspection must retain exactly one transient historical projection card.", failures)
    _expect(session.call("state_snapshot") == state_before, "Navigation, selection and Chronicle inspection churn must not mutate current CampaignState.", failures)
    _expect(session.call("chronicle_snapshot") == chronicle_before, "Navigation, selection and Chronicle inspection churn must not mutate Chronicle storage.", failures)
    home.free()

func _test_knowledge_boundary_paths(failures: Array[String]) -> void:
    var session: RefCounted = _session(failures, "knowledge-boundary")
    if session == null: return
    var view: Dictionary = session.call("current_projection")
    var encoded := JSON.stringify(view)
    _expect(not encoded.contains("true_value") and not encoded.contains("influence_by_promotion"), "G→H knowledge attack: live Owner presentation must expose no raw/true rival influence escape hatch.", failures)
    for company: Dictionary in view.get("touring", []):
        if str(company.get("ownership", "")) != "observed": continue
        for forbidden: String in ["budget", "fatigue_pressure", "cohesion", "person_assignment_ids", "directives"]:
            _expect(not company.has(forbidden), "G→H knowledge attack: observed rival touring must not expose controlled-only field " + forbidden + ".", failures)
    var dates: Array = view.get("history_dates", [])
    for date_value: Variant in dates:
        var historical: Dictionary = session.call("historical_projection", str(date_value))
        var historical_json := JSON.stringify(historical)
        _expect(not historical_json.contains("true_value") and not historical_json.contains("influence_by_promotion") and not historical_json.contains("knowledge_bases"), "G→H knowledge attack: historical navigation must not become a hidden-current-truth escape route.", failures)

func _test_touring_churn_determinism(failures: Array[String]) -> void:
    var noisy: RefCounted = _session(failures, "touring-churn-noisy")
    var reduced: RefCounted = _session(failures, "touring-churn-reduced")
    if noisy == null or reduced == null: return
    var view: Dictionary = noisy.call("current_projection")
    var own: Dictionary = _controlled_company(view)
    var markets: Array = view.get("markets", [])
    _expect(not own.is_empty() and markets.size() >= 3, "Touring churn fixture must expose a controlled company and at least three markets.", failures)
    if own.is_empty() or markets.size() < 3: return
    var company_id := str(own.get("company_id", ""))
    var budget: Dictionary = own.get("budget", {})
    var base_minor := int(budget.get("minor_units", 0))
    var currency_id := str(budget.get("currency_id", "currency.usd"))
    var final_market := str((markets[2] as Dictionary).get("market_id", ""))
    var final_budget := int(round(base_minor * 1.17))
    for i: int in range(50):
        var market_id := str((markets[i % markets.size()] as Dictionary).get("market_id", ""))
        var minor := int(round(base_minor * (0.90 + float(i % 7) * 0.03)))
        _expect(bool((noisy.call("queue_player_command", "command.set_route", {"touring_company_id": company_id, "route": [{"market_id": market_id}]}) as Dictionary).get("accepted", false)), "Noisy legal route churn should remain valid.", failures)
        _expect(bool((noisy.call("queue_player_command", "command.adjust_budget", {"touring_company_id": company_id, "monthly_budget": {"minor_units": minor, "currency_id": currency_id}}) as Dictionary).get("accepted", false)), "Noisy legal budget churn should remain valid.", failures)
    _expect(bool((noisy.call("queue_player_command", "command.set_route", {"touring_company_id": company_id, "route": [{"market_id": final_market}]}) as Dictionary).get("accepted", false)), "Final noisy route intent should queue.", failures)
    _expect(bool((noisy.call("queue_player_command", "command.adjust_budget", {"touring_company_id": company_id, "monthly_budget": {"minor_units": final_budget, "currency_id": currency_id}}) as Dictionary).get("accepted", false)), "Final noisy budget intent should queue.", failures)
    _expect(int(noisy.call("pending_count")) == 2, "Touring churn must reduce to exactly one route and one budget intent.", failures)

    _expect(bool((reduced.call("queue_player_command", "command.set_route", {"touring_company_id": company_id, "route": [{"market_id": final_market}]}) as Dictionary).get("accepted", false)), "Reduced final route intent should queue.", failures)
    _expect(bool((reduced.call("queue_player_command", "command.adjust_budget", {"touring_company_id": company_id, "monthly_budget": {"minor_units": final_budget, "currency_id": currency_id}}) as Dictionary).get("accepted", false)), "Reduced final budget intent should queue.", failures)
    var noisy_result: Dictionary = noisy.call("advance_month")
    var reduced_result: Dictionary = reduced.call("advance_month")
    _expect(bool(noisy_result.get("passed", false)) and bool(reduced_result.get("passed", false)), "Noisy and reduced touring command sets must both resolve.", failures)
    _expect(noisy.call("state_snapshot") == reduced.call("state_snapshot"), "G→H touring churn must be deterministic and equivalent to the final reduced legal intent set.", failures)

func _session(failures: Array[String], label: String) -> RefCounted:
    var session: RefCounted = CampaignSession.new()
    var started: Dictionary = session.call("start", CAMPAIGN, SEED)
    _expect(bool(started.get("passed", false)), "G→H " + label + " fixture must start: " + JSON.stringify(started.get("errors", [])), failures)
    return session if bool(started.get("passed", false)) else null

func _controlled_company(view: Dictionary) -> Dictionary:
    for company: Dictionary in view.get("touring", []):
        if str(company.get("ownership", "")) == "controlled": return company
    return {}

func _observed_company(view: Dictionary) -> Dictionary:
    for company: Dictionary in view.get("touring", []):
        if str(company.get("ownership", "")) == "observed": return company
    return {}

func _company_by_id(view: Dictionary, company_id: String) -> Dictionary:
    for company: Dictionary in view.get("touring", []):
        if str(company.get("company_id", "")) == company_id: return company
    return {}

func _assigned_wrestler(view: Dictionary, company: Dictionary) -> Dictionary:
    var assigned: Array = company.get("person_assignment_ids", [])
    for person: Dictionary in view.get("roster", []):
        if str(person.get("person_id", "")) in assigned and "role.wrestler" in (person.get("roles", []) as Array): return person
    return {}

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition: failures.append(message)
