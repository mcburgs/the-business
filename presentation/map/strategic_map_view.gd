extends Control

signal market_selected(market_id: String)

var model: Dictionary = {}
var selected_market_id: String = ""
var zoom: float = 1.0
var pan: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _drag_origin: Vector2 = Vector2.ZERO
var _pan_origin: Vector2 = Vector2.ZERO
var _mouse_down: Vector2 = Vector2.ZERO

const BG := Color("0b1419")
const GRID := Color("18282f")
const REGION_FILL := Color("13232a")
const REGION_STROKE := Color("28434d")
const CONNECTION := Color("34515c")
const CONTROLLED := Color("70bac7")
const CONTROLLED_SOFT := Color("376f7a")
const RIVAL := Color("c49a61")
const TEXT := Color("dbe5e8")
const TEXT_DIM := Color("82949c")
const HOT := Color("d67a63")
const HOME := Color("a8d3db")

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    clip_contents = true
    focus_mode = Control.FOCUS_ALL
    custom_minimum_size = Vector2(460, 380)

func set_model(value: Dictionary) -> void:
    model = value.duplicate(true)
    if selected_market_id.is_empty() and not (model.get("markets", []) as Array).is_empty():
        selected_market_id = str((model.get("markets", []) as Array)[0].get("market_id", ""))
    queue_redraw()

func select_market(market_id: String, emit_signal: bool = true) -> void:
    selected_market_id = market_id
    queue_redraw()
    if emit_signal: market_selected.emit(market_id)

func reset_view() -> void:
    zoom = 1.0; pan = Vector2.ZERO; queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), BG)
    _draw_grid()
    if model.is_empty(): _draw_empty(); return
    _draw_regions(); _draw_connections(); _draw_routes(); _draw_markets(); _draw_legend()

func _draw_grid() -> void:
    var spacing: float = 64.0 * zoom
    if spacing < 30.0: spacing *= 2.0
    var offset_x: float = fmod(pan.x, spacing)
    var offset_y: float = fmod(pan.y, spacing)
    for x: int in range(int(-spacing), int(size.x + spacing), int(maxf(1.0, spacing))): draw_line(Vector2(x + offset_x, 0), Vector2(x + offset_x, size.y), GRID, 1.0)
    for y: int in range(int(-spacing), int(size.y + spacing), int(maxf(1.0, spacing))): draw_line(Vector2(0, y + offset_y), Vector2(size.x, y + offset_y), GRID, 1.0)

func _draw_regions() -> void:
    var groups: Dictionary = {}
    for market: Dictionary in model.get("markets", []):
        var region_id: String = str(market.get("region_id", ""))
        if not groups.has(region_id): groups[region_id] = []
        groups[region_id].append(_market_point(market))
    for region_id: String in groups.keys():
        var points: Array = groups[region_id]
        if points.is_empty(): continue
        var min_p: Vector2 = points[0]; var max_p: Vector2 = points[0]
        for p: Vector2 in points:
            min_p = Vector2(minf(min_p.x, p.x), minf(min_p.y, p.y)); max_p = Vector2(maxf(max_p.x, p.x), maxf(max_p.y, p.y))
        var rect: Rect2 = Rect2(min_p - Vector2(42, 30), (max_p - min_p) + Vector2(84, 60))
        draw_style_box(_region_box(), rect)
        var region_name: String = ""
        for market: Dictionary in model.get("markets", []):
            if str(market.get("region_id", "")) == region_id: region_name = str(market.get("region_name", "")); break
        if not region_name.is_empty(): draw_string(ThemeDB.fallback_font, rect.position + Vector2(12, 19), region_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEXT_DIM)

func _region_box() -> StyleBoxFlat:
    var box := StyleBoxFlat.new(); box.bg_color = REGION_FILL; box.border_color = REGION_STROKE; box.set_border_width_all(1)
    box.corner_radius_top_left = 16; box.corner_radius_top_right = 16; box.corner_radius_bottom_left = 16; box.corner_radius_bottom_right = 16
    return box

func _draw_connections() -> void:
    for connection: Dictionary in model.get("connections", []):
        var a: Dictionary = _market(str(connection.get("from_market_id", ""))); var b: Dictionary = _market(str(connection.get("to_market_id", "")))
        if a.is_empty() or b.is_empty(): continue
        draw_line(_market_point(a), _market_point(b), CONNECTION, 1.5, true)

func _draw_routes() -> void:
    for company: Dictionary in model.get("touring", []):
        var route: Array = company.get("route", [])
        if route.size() < 2: continue
        var points: PackedVector2Array = []
        for stop: Dictionary in route:
            var market: Dictionary = _market(str(stop.get("market_id", "")))
            if not market.is_empty(): points.append(_market_point(market))
        if points.size() < 2: continue
        if str(company.get("ownership", "")) == "controlled": draw_polyline(points, CONTROLLED, 4.0, true)
        else: _draw_dashed_polyline(points, RIVAL, 2.5)

func _draw_dashed_polyline(points: PackedVector2Array, color: Color, width: float) -> void:
    for i: int in range(points.size() - 1):
        var a := points[i]; var b := points[i + 1]; var length := a.distance_to(b)
        if length <= 0.0: continue
        var direction := (b - a) / length; var cursor := 0.0
        while cursor < length:
            draw_line(a + direction * cursor, a + direction * minf(length, cursor + 9.0), color, width, true); cursor += 15.0

func _draw_markets() -> void:
    for market: Dictionary in model.get("markets", []):
        var p := _market_point(market); var selected := str(market.get("market_id", "")) == selected_market_id
        var own_presence := float(market.get("own_presence", 0.0)); var radius := 8.0 + own_presence * 7.0
        if selected:
            draw_circle(p, radius + 8.0, Color(CONTROLLED, 0.20)); draw_arc(p, radius + 7.0, 0.0, TAU, 40, CONTROLLED, 2.5, true)
        draw_circle(p, radius + 2.0, Color("081015")); draw_circle(p, radius, CONTROLLED_SOFT if own_presence < 0.42 else CONTROLLED)
        if bool(market.get("is_home_market", false)): draw_arc(p, radius + 3.5, -PI * 0.9, -PI * 0.1, 12, HOME, 2.0, true)
        if not str(market.get("hot_state", "")).is_empty(): draw_circle(p + Vector2(radius - 1, -radius + 1), 3.5, HOT)
        draw_string(ThemeDB.fallback_font, p + Vector2(12 + radius, 5), str(market.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 13 if selected else 12, TEXT if selected else Color("aebdc2"))

func _draw_legend() -> void:
    var y := size.y - 24.0
    draw_line(Vector2(22, y), Vector2(54, y), CONTROLLED, 4.0); draw_string(ThemeDB.fallback_font, Vector2(62, y + 4), "Your touring route", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEXT_DIM)
    _draw_dashed_polyline(PackedVector2Array([Vector2(174, y), Vector2(206, y)]), RIVAL, 2.5); draw_string(ThemeDB.fallback_font, Vector2(214, y + 4), "Observed rival route", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEXT_DIM)

func _draw_empty() -> void: draw_string(ThemeDB.fallback_font, size * 0.5 - Vector2(100, 0), "Map data unavailable", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, TEXT_DIM)
func _market(market_id: String) -> Dictionary:
    for market: Dictionary in model.get("markets", []):
        if str(market.get("market_id", "")) == market_id: return market
    return {}
func _market_point(market: Dictionary) -> Vector2:
    var c: Dictionary = market.get("coordinates", {}); var padding := Vector2(60, 46); var usable := Vector2(maxf(1.0, size.x - padding.x * 2.0), maxf(1.0, size.y - padding.y * 2.0))
    var normalized := Vector2(float(c.get("x", 0.5)), float(c.get("y", 0.5))); var base := padding + Vector2(normalized.x * usable.x, normalized.y * usable.y); var center := size * 0.5
    return center + (base - center) * zoom + pan
func _nearest_market(position: Vector2, threshold: float = 34.0) -> String:
    var best_id := ""; var best_distance := threshold
    for market: Dictionary in model.get("markets", []):
        var distance := position.distance_to(_market_point(market))
        if distance < best_distance: best_distance = distance; best_id = str(market.get("market_id", ""))
    return best_id

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed: _zoom_at(mouse.position, 1.10); accept_event()
        elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed: _zoom_at(mouse.position, 0.91); accept_event()
        elif mouse.button_index == MOUSE_BUTTON_LEFT:
            if mouse.pressed: _dragging = true; _drag_origin = mouse.position; _pan_origin = pan; _mouse_down = mouse.position
            else:
                if _dragging and _mouse_down.distance_to(mouse.position) < 8.0:
                    var market_id := _nearest_market(mouse.position)
                    if not market_id.is_empty(): select_market(market_id)
                _dragging = false
            accept_event()
    elif event is InputEventMouseMotion and _dragging:
        var motion := event as InputEventMouseMotion; pan = _pan_origin + (motion.position - _drag_origin); queue_redraw(); accept_event()
    elif event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed: _mouse_down = touch.position; _drag_origin = touch.position; _pan_origin = pan; _dragging = true
        else:
            if _dragging and _mouse_down.distance_to(touch.position) < 12.0:
                var market_id := _nearest_market(touch.position, 44.0)
                if not market_id.is_empty(): select_market(market_id)
            _dragging = false
        accept_event()
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if _dragging: pan += drag.relative; queue_redraw(); accept_event()

func _zoom_at(position: Vector2, factor: float) -> void:
    var old_zoom := zoom; zoom = clampf(zoom * factor, 0.75, 2.2)
    if is_equal_approx(old_zoom, zoom): return
    var center := size * 0.5; var local_before := (position - center - pan) / old_zoom; pan = position - center - local_before * zoom; queue_redraw()
