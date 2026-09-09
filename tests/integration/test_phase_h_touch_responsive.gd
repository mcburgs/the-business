extends RefCounted

const CampaignSession = preload("res://app/session/campaign_session.gd")
const StrategicHome = preload("res://presentation/shell/strategic_home.gd")
const StrategicMapView = preload("res://presentation/map/strategic_map_view.gd")

const CAMPAIGN := "res://content/campaigns/great_lakes_1975"
const SEED := 424242

func run() -> Dictionary:
    var failures: Array[String] = []
    _test_responsive_shell_and_touch_targets(failures)
    _test_touch_pan_pinch_and_selection(failures)
    return {"name": "phase_h_touch_responsive", "passed": failures.is_empty(), "failures": failures}

func _test_responsive_shell_and_touch_targets(failures: Array[String]) -> void:
    var session: RefCounted = CampaignSession.new()
    var started: Dictionary = session.call("start", CAMPAIGN, SEED)
    _expect(bool(started.get("passed", false)), "Phase H responsive fixture must start.", failures)
    if not bool(started.get("passed", false)): return

    var home: Control = StrategicHome.new()
    home.call("_ready")
    home.call("bind_session", session)
    home.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)

    home.size = Vector2(1080, 2424)
    home.call("_apply_layout")
    _expect(str(home.call("layout_mode_name")) == "narrow", "Pixel-class portrait dimensions must use the narrow/mobile shell.", failures)
    _expect(str(home.get("surface")) == "map" and bool((home.get("map_panel") as Control).visible), "Strategic map must remain the mobile home surface.", failures)
    var narrow_nav: Control = home.get("narrow_nav")
    var map_panel: Control = home.get("map_panel")
    _expect(narrow_nav.position.y > map_panel.position.y + 100.0, "Narrow navigation must sit at the lower ergonomic edge instead of consuming map-top space.", failures)
    _expect(float(home.call("minimum_touch_target")) >= 48.0, "Phase H mobile controls must expose at least a 48 logical-pixel target policy.", failures)
    _expect(_all_buttons_at_least(home, 48.0), "Visible primary/navigation controls must not regress below the mobile touch target policy.", failures)

    home.call("_set_surface", "roster")
    _expect(not bool((home.get("map_panel") as Control).visible) and bool((home.get("detail_panel") as Control).visible), "Mobile People must use the same authoritative projection in a readable drill-down surface.", failures)
    _expect(bool(home.call("handle_system_back")) and str(home.get("surface")) == "map", "Android system Back from a detail surface must return to the strategic map before exiting.", failures)
    _expect(not bool(ProjectSettings.get_setting("application/config/quit_on_go_back", true)), "Godot automatic Android Back exit must be disabled so the Phase H map-first Back policy can run before an explicit exit.", failures)

    home.size = Vector2(2424, 1080)
    home.call("_apply_layout")
    _expect(str(home.call("layout_mode_name")) == "wide", "Pixel-class landscape dimensions must use the wide map-plus-context shell.", failures)
    _expect(bool((home.get("map_panel") as Control).visible) and bool((home.get("detail_panel") as Control).visible), "Landscape must retain map context and detail simultaneously.", failures)
    home.free()

func _test_touch_pan_pinch_and_selection(failures: Array[String]) -> void:
    var session: RefCounted = CampaignSession.new()
    var started: Dictionary = session.call("start", CAMPAIGN, SEED)
    if not bool(started.get("passed", false)):
        failures.append("Phase H map touch fixture could not start.")
        return
    var map := StrategicMapView.new()
    map.call("_ready")
    map.size = Vector2(800, 600)
    map.call("set_model", session.call("current_projection"))

    var start_pan: Vector2 = map.get("pan")
    map.call("_gui_input", _touch(0, true, Vector2(260, 260)))
    map.call("_gui_input", _drag(0, Vector2(305, 285), Vector2(45, 25)))
    map.call("_gui_input", _touch(0, false, Vector2(305, 285)))
    _expect((map.get("pan") as Vector2).distance_to(start_pan) > 10.0, "Single-finger drag must pan the strategic map.", failures)

    map.call("reset_view")
    var start_zoom: float = float(map.get("zoom"))
    map.call("_gui_input", _touch(0, true, Vector2(280, 300)))
    map.call("_gui_input", _touch(1, true, Vector2(520, 300)))
    map.call("_gui_input", _drag(1, Vector2(620, 300), Vector2(100, 0)))
    _expect(float(map.get("zoom")) > start_zoom, "Two-finger pinch/spread must zoom the strategic map without a hover or wheel dependency.", failures)
    map.call("_gui_input", _touch(1, false, Vector2(620, 300)))
    map.call("_gui_input", _touch(0, false, Vector2(280, 300)))

    var markets: Array = (session.call("current_projection") as Dictionary).get("markets", [])
    if markets.is_empty():
        failures.append("Touch selection fixture contains no markets.")
    else:
        map.call("reset_view")
        var first: Dictionary = markets[0]
        var point: Vector2 = map.call("_market_point", first)
        map.call("_gui_input", _touch(0, true, point))
        map.call("_gui_input", _touch(0, false, point))
        _expect(str(map.get("selected_market_id")) == str(first.get("market_id", "")), "Finger tap must select a market through the retained touch abstraction.", failures)
    map.free()

func _all_buttons_at_least(root: Node, minimum: float) -> bool:
    for node: Node in root.find_children("*", "Button", true, false):
        var button := node as Button
        if button.custom_minimum_size.y < minimum:
            return false
    return true

func _touch(index: int, pressed: bool, position: Vector2) -> InputEventScreenTouch:
    var event := InputEventScreenTouch.new()
    event.index = index
    event.pressed = pressed
    event.position = position
    return event

func _drag(index: int, position: Vector2, relative: Vector2) -> InputEventScreenDrag:
    var event := InputEventScreenDrag.new()
    event.index = index
    event.position = position
    event.relative = relative
    return event

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition: failures.append(message)
