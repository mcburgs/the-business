extends SceneTree

const CampaignSession = preload("res://app/session/campaign_session.gd")
const StrategicHome = preload("res://presentation/shell/strategic_home.gd")

const CAMPAIGN := "res://content/campaigns/great_lakes_1975"
const SEED := 424242

var _failures: Array[String] = []
var _metrics: Dictionary = {}
var _session: RefCounted
var _home: Control
var _map: Control

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    _session = CampaignSession.new()
    var started: Dictionary = _session.call("start", CAMPAIGN, SEED)
    _expect(bool(started.get("passed", false)), "campaign_start")
    if not bool(started.get("passed", false)):
        _finish()
        return

    _home = StrategicHome.new()
    root.add_child(_home)
    _home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _home.call("bind_session", _session)
    _map = _home.get("map_view") as Control
    await process_frame
    await process_frame

    _attack_touch_selection_and_drag()
    _attack_repeated_action_callbacks()
    _attack_duplicate_month_activation()
    await process_frame
    _attack_navigation_history_churn()
    _attack_knowledge_projection()
    await process_frame
    await process_frame
    _capture_if_requested()
    _finish()

func _attack_touch_selection_and_drag() -> void:
    var view: Dictionary = _session.call("current_projection")
    var markets: Array = view.get("markets", [])
    _expect(not markets.is_empty(), "touch_fixture_has_markets")
    if markets.is_empty() or _map == null: return
    var target: Dictionary = markets[min(1, markets.size() - 1)]
    var target_id := str(target.get("market_id", ""))
    var target_point: Vector2 = _map.call("_market_point", target)
    var press := InputEventScreenTouch.new(); press.index = 0; press.position = target_point; press.pressed = true
    var release := InputEventScreenTouch.new(); release.index = 0; release.position = target_point; release.pressed = false
    _map.call("_gui_input", press); _map.call("_gui_input", release)
    _expect(str(_home.get("selected_market_id")) == target_id, "touch_tap_selects_market")

    var pan_before: Vector2 = _map.get("pan")
    var drag_press := InputEventScreenTouch.new(); drag_press.index = 0; drag_press.position = Vector2(240, 220); drag_press.pressed = true
    var drag := InputEventScreenDrag.new(); drag.index = 0; drag.position = Vector2(270, 245); drag.relative = Vector2(30, 25)
    var drag_release := InputEventScreenTouch.new(); drag_release.index = 0; drag_release.position = Vector2(270, 245); drag_release.pressed = false
    _map.call("_gui_input", drag_press); _map.call("_gui_input", drag); _map.call("_gui_input", drag_release)
    _expect((_map.get("pan") as Vector2) != pan_before, "touch_drag_changes_pan_only")
    _metrics["touch_selected_market_id"] = target_id
    _metrics["touch_pan_delta"] = ((_map.get("pan") as Vector2) - pan_before)

func _attack_repeated_action_callbacks() -> void:
    var view: Dictionary = _session.call("current_projection")
    var company: Dictionary = {}
    var wrestler: Dictionary = {}
    for item: Dictionary in view.get("touring", []):
        if str(item.get("ownership", "")) == "controlled": company = item; break
    var assigned: Array = company.get("person_assignment_ids", [])
    for person: Dictionary in view.get("roster", []):
        if str(person.get("person_id", "")) in assigned and "role.wrestler" in (person.get("roles", []) as Array): wrestler = person; break
    var markets: Array = view.get("markets", [])
    _expect(not company.is_empty() and not wrestler.is_empty() and not markets.is_empty(), "repeated_action_fixture")
    if company.is_empty() or wrestler.is_empty() or markets.is_empty(): return
    var market_id := str((markets[-1] as Dictionary).get("market_id", ""))
    var company_id := str(company.get("company_id", ""))
    for _i: int in range(12): _home.call("_queue_route", market_id)
    for _i: int in range(12): _home.call("_queue_budget", company_id, 0.10, company.get("budget", {}))
    for _i: int in range(12): _home.call("_queue_market_focus", market_id)
    for _i: int in range(12): _home.call("_queue_push", company_id, str(wrestler.get("person_id", "")))
    _expect(int(_session.call("pending_count")) == 4, "repeated_callbacks_reduce_to_four_intents")
    _metrics["pending_after_48_repeated_callbacks"] = int(_session.call("pending_count"))

func _attack_duplicate_month_activation() -> void:
    var before: Dictionary = _session.call("current_projection")
    var first: Dictionary = _home.call("_advance_month")
    var second: Dictionary = _home.call("_advance_month")
    var after: Dictionary = _session.call("current_projection")
    _expect(bool(first.get("passed", false)), "first_month_activation_passes")
    _expect(not bool(second.get("passed", true)) and bool(second.get("suppressed", false)), "immediate_duplicate_month_suppressed")
    _expect(int(after.get("turn_number", -1)) == int(before.get("turn_number", -1)) + 1, "duplicate_activation_advances_exactly_once")
    _metrics["turn_before_duplicate_attack"] = int(before.get("turn_number", -1))
    _metrics["turn_after_duplicate_attack"] = int(after.get("turn_number", -1))

func _attack_navigation_history_churn() -> void:
    # Deferred unlock has now fired; one more intentional advance creates a third historical date.
    var deliberate: Dictionary = _home.call("_advance_month")
    _expect(bool(deliberate.get("passed", false)), "deliberate_followup_month_after_idle_passes")
    _home.call("_release_advance_lock")
    var state_before: Dictionary = _session.call("state_snapshot")
    var chronicle_before: Dictionary = _session.call("chronicle_snapshot")
    var valid_market := str(_home.get("selected_market_id"))
    _home.call("_on_market_selected", "market:STALEG2H")
    _expect(str(_home.get("selected_market_id")) == valid_market, "stale_market_selection_ignored")
    var surfaces: Array[String] = ["map", "roster", "touring", "wrestling", "history", "market"]
    for i: int in range(40): _home.call("_set_surface", surfaces[i % surfaces.size()])
    _home.call("_set_surface", "history")
    var dates: Array = (_session.call("current_projection") as Dictionary).get("history_dates", [])
    for i: int in range(50):
        if not dates.is_empty(): _home.call("_show_historical", str(dates[i % dates.size()]))
    var details: VBoxContainer = _home.get("detail_content")
    _expect(details.find_children("*", "OptionButton", true, false).size() == 1, "history_has_one_date_selector")
    _expect(details.find_children("HistoricalProjectionCard", "", true, false).size() == 1, "history_has_one_transient_projection_card")
    _expect(_session.call("state_snapshot") == state_before, "navigation_history_churn_state_read_only")
    _expect(_session.call("chronicle_snapshot") == chronicle_before, "navigation_history_churn_chronicle_read_only")
    _metrics["history_date_count"] = dates.size()
    _metrics["navigation_cycles"] = 40
    _metrics["historical_reselections"] = 50

func _attack_knowledge_projection() -> void:
    var live: Dictionary = _session.call("current_projection")
    var live_json := JSON.stringify(live)
    _expect(not live_json.contains("true_value"), "live_projection_no_true_value")
    _expect(not live_json.contains("influence_by_promotion"), "live_projection_no_raw_influence")
    for company: Dictionary in live.get("touring", []):
        if str(company.get("ownership", "")) != "observed": continue
        for forbidden: String in ["budget", "fatigue_pressure", "cohesion", "person_assignment_ids", "directives"]:
            _expect(not company.has(forbidden), "observed_rival_no_" + forbidden)
    for date_value: Variant in live.get("history_dates", []):
        var historical: Dictionary = _session.call("historical_projection", str(date_value))
        var historical_json := JSON.stringify(historical)
        _expect(not historical_json.contains("true_value") and not historical_json.contains("influence_by_promotion"), "historical_projection_no_truth_escape")

func _capture_if_requested() -> void:
    var path := _arg("--screenshot=")
    if path.is_empty(): return
    var image := root.get_viewport().get_texture().get_image()
    var error := image.save_png(path)
    _expect(error == OK, "screenshot_saved")
    _metrics["screenshot"] = path

func _expect(condition: bool, code: String) -> void:
    if not condition: _failures.append(code)

func _arg(prefix: String) -> String:
    for argument: String in OS.get_cmdline_user_args():
        if argument.begins_with(prefix): return argument.trim_prefix(prefix)
    return ""

func _finish() -> void:
    var result := {
        "schema": "we.g2h.interaction.v1",
        "passed": _failures.is_empty(),
        "failures": _failures.duplicate(),
        "metrics": _json_safe_metrics(),
        "engine": str(Engine.get_version_info().get("string", "unknown")),
        "game_version": ProjectSettings.get_setting("application/config/version", ""),
    }
    var output := _arg("--output=")
    if not output.is_empty():
        var base := output.get_base_dir()
        if not base.is_empty(): DirAccess.make_dir_recursive_absolute(base)
        var file := FileAccess.open(output, FileAccess.WRITE)
        if file != null:
            file.store_string(JSON.stringify(result, "  "))
            file.store_line("")
            file.close()
    print("WE_G2H_INTERACTION " + JSON.stringify(result))
    if _home != null and is_instance_valid(_home): _home.queue_free()
    quit(0 if _failures.is_empty() else 1)

func _json_safe_metrics() -> Dictionary:
    var output := _metrics.duplicate(true)
    if output.get("touch_pan_delta") is Vector2:
        var value: Vector2 = output["touch_pan_delta"]
        output["touch_pan_delta"] = {"x": value.x, "y": value.y}
    return output
