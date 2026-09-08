extends Control

const StrategicMapView = preload("res://presentation/map/strategic_map_view.gd")
const ThemeFactory = preload("res://presentation/common/ui_theme_factory.gd")

var session: RefCounted = null
var view: Dictionary = {}
var surface: String = "map"
var selected_market_id: String = ""
var status_message: String = ""
var _narrow: bool = false

var top_panel: PanelContainer
var context_label: Label
var date_label: Label
var cash_label: Label
var prestige_label: Label
var momentum_label: Label
var advance_button: Button
var status_label: Label
var wide_nav: PanelContainer
var narrow_nav: PanelContainer
var map_panel: PanelContainer
var map_view: Control
var map_signal_label: Label
var detail_panel: PanelContainer
var detail_title: Label
var detail_subtitle: Label
var detail_content: VBoxContainer
var back_button: Button

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    theme = ThemeFactory.build()
    _build_interface()
    resized.connect(_apply_layout)
    _apply_layout()

func bind_session(value: RefCounted) -> void:
    session = value
    refresh()

func refresh() -> void:
    if session == null or not session.call("is_started"): return
    var projected: Dictionary = session.call("current_projection")
    if not bool(projected.get("passed", false)):
        status_message = "Presentation projection unavailable."
        return
    view = projected
    if selected_market_id.is_empty() and not (view.get("markets", []) as Array).is_empty():
        var home_market: Dictionary = {}
        for market: Dictionary in view.get("markets", []):
            if bool(market.get("is_home_market", false)): home_market = market; break
        selected_market_id = str((home_market if not home_market.is_empty() else (view.get("markets", []) as Array)[0]).get("market_id", ""))
    _refresh_header()
    map_view.call("set_model", view)
    map_view.call("select_market", selected_market_id, false)
    _render_detail()

func prepare_capture(capture_name: String) -> void:
    match capture_name:
        "initial": surface = "map"
        "market":
            surface = "market"
            if not (view.get("markets", []) as Array).is_empty(): selected_market_id = str((view.get("markets", []) as Array)[0].get("market_id", ""))
        "roster": surface = "roster"
        "touring": surface = "touring"
        "history": surface = "history"
        "post_month":
            var result: Dictionary = _advance_month()
            if not bool(result.get("passed", false)): status_message = "Month advance failed during capture."
            surface = "map"
        _: surface = "map"
    if map_view != null: map_view.call("select_market", selected_market_id, false)
    _render_detail(); _apply_layout()

func _build_interface() -> void:
    var background := ColorRect.new(); background.color = Color("081015"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); background.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(background)
    top_panel = PanelContainer.new(); top_panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style("101a20", "2c414b", 0, 0)); add_child(top_panel)
    var top_h := HBoxContainer.new(); top_h.add_theme_constant_override("separation", 18); top_panel.add_child(top_h)
    var brand_box := VBoxContainer.new(); brand_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top_h.add_child(brand_box)
    brand_box.add_child(_label("THE BUSINESS", 24, Color("eff5f6")))
    context_label = _label("Ownership", 12, Color("7f959e")); brand_box.add_child(context_label)
    var metrics := HBoxContainer.new(); metrics.add_theme_constant_override("separation", 18); top_h.add_child(metrics)
    date_label = _metric(metrics, "DATE"); cash_label = _metric(metrics, "CASH"); prestige_label = _metric(metrics, "PRESTIGE"); momentum_label = _metric(metrics, "MOMENTUM")
    advance_button = Button.new(); advance_button.text = "Advance Month"; advance_button.custom_minimum_size = Vector2(138, 46); advance_button.pressed.connect(_on_advance_pressed); top_h.add_child(advance_button)

    wide_nav = PanelContainer.new(); wide_nav.add_theme_stylebox_override("panel", ThemeFactory.panel_style("0e171c", "20323b")); add_child(wide_nav)
    var nav_v := VBoxContainer.new(); wide_nav.add_child(nav_v); nav_v.add_child(_label("OFFICE", 11, Color("6f858e")))
    nav_v.add_child(_nav_button("Map", "map")); nav_v.add_child(_nav_button("People", "roster")); nav_v.add_child(_nav_button("Touring", "touring")); nav_v.add_child(_nav_button("Wrestling", "wrestling")); nav_v.add_child(_nav_button("Chronicle", "history"))
    var spacer := Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL; nav_v.add_child(spacer)
    status_label = _label("", 12, Color("8aa0a8")); status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; nav_v.add_child(status_label)

    narrow_nav = PanelContainer.new(); narrow_nav.add_theme_stylebox_override("panel", ThemeFactory.panel_style("0e171c", "20323b", 8)); add_child(narrow_nav)
    var nav_h := HBoxContainer.new(); nav_h.alignment = BoxContainer.ALIGNMENT_CENTER; nav_h.add_theme_constant_override("separation", 5); narrow_nav.add_child(nav_h)
    for item: Array in [["Map", "map"], ["People", "roster"], ["Tour", "touring"], ["Card", "wrestling"], ["History", "history"]]:
        var b := _nav_button(str(item[0]), str(item[1])); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; b.custom_minimum_size = Vector2(72, 44); nav_h.add_child(b)

    map_panel = PanelContainer.new(); map_panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style("0b1419", "263c46", 12)); add_child(map_panel)
    var map_v := VBoxContainer.new(); map_panel.add_child(map_v)
    var map_header := HBoxContainer.new(); map_v.add_child(map_header)
    var map_header_left := VBoxContainer.new(); map_header_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL; map_header.add_child(map_header_left)
    map_header_left.add_child(_label("STRATEGIC MAP", 12, Color("718993"))); map_signal_label = _label("World conditions", 17, Color("e1eaed")); map_header_left.add_child(map_signal_label)
    var reset := Button.new(); reset.text = "Reset View"; reset.custom_minimum_size = Vector2(104, 42); reset.pressed.connect(func(): map_view.call("reset_view")); map_header.add_child(reset)
    map_view = StrategicMapView.new(); map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL; map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL; map_view.market_selected.connect(_on_market_selected); map_v.add_child(map_view)

    detail_panel = PanelContainer.new(); detail_panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style("111a20", "2c414a", 12)); add_child(detail_panel)
    var detail_v := VBoxContainer.new(); detail_panel.add_child(detail_v)
    var detail_head := VBoxContainer.new(); detail_v.add_child(detail_head)
    back_button = Button.new(); back_button.text = "← Back to Map"; back_button.custom_minimum_size = Vector2(140, 42); back_button.pressed.connect(_set_surface.bind("map")); detail_head.add_child(back_button)
    detail_title = _label("Market", 22, Color("eff5f6")); detail_head.add_child(detail_title); detail_subtitle = _label("Known strategic context", 12, Color("78909a")); detail_head.add_child(detail_subtitle)
    detail_v.add_child(HSeparator.new())
    var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; detail_v.add_child(scroll)
    detail_content = VBoxContainer.new(); detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL; detail_content.add_theme_constant_override("separation", 12); scroll.add_child(detail_content)

func _apply_layout() -> void:
    if not is_inside_tree(): return
    _narrow = size.x < 900.0
    var margin := 14.0; var top_h := 82.0 if not _narrow else 78.0
    top_panel.position = Vector2.ZERO; top_panel.size = Vector2(size.x, top_h)
    if not _narrow:
        wide_nav.visible = true; narrow_nav.visible = false; back_button.visible = false
        wide_nav.position = Vector2(margin, top_h + margin); wide_nav.size = Vector2(154, maxf(250.0, size.y - top_h - margin * 2.0))
        detail_panel.visible = true; detail_panel.position = Vector2(size.x - 358.0 - margin, top_h + margin); detail_panel.size = Vector2(358.0, maxf(250.0, size.y - top_h - margin * 2.0))
        map_panel.visible = true; map_panel.position = Vector2(154 + margin * 2.0, top_h + margin); map_panel.size = Vector2(maxf(420.0, size.x - 154.0 - 358.0 - margin * 4.0), maxf(250.0, size.y - top_h - margin * 2.0))
    else:
        wide_nav.visible = false; narrow_nav.visible = true
        narrow_nav.position = Vector2(margin, top_h + 8.0); narrow_nav.size = Vector2(maxf(320.0, size.x - margin * 2.0), 58.0)
        var body_y := top_h + 74.0; var body_size := Vector2(maxf(320.0, size.x - margin * 2.0), maxf(300.0, size.y - body_y - margin)); var detail_active := surface != "map"
        map_panel.visible = not detail_active; detail_panel.visible = detail_active; map_panel.position = Vector2(margin, body_y); map_panel.size = body_size; detail_panel.position = Vector2(margin, body_y); detail_panel.size = body_size; back_button.visible = detail_active
    _refresh_top_visibility()

func _refresh_top_visibility() -> void:
    if date_label == null: return
    cash_label.visible = not _narrow; prestige_label.visible = not _narrow; momentum_label.visible = not _narrow
    advance_button.text = "Advance" if _narrow else "Advance Month"; advance_button.custom_minimum_size = Vector2(92 if _narrow else 138, 46)

func _refresh_header() -> void:
    var promotion: Dictionary = view.get("promotion", {})
    context_label.text = "OWNERSHIP  /  " + _clean(str(promotion.get("name", "")))
    date_label.text = _metric_text("DATE", _format_date(str(view.get("date", "")))); cash_label.text = _metric_text("CASH", _money(promotion.get("cash", {}))); prestige_label.text = _metric_text("PRESTIGE", _percent(float(promotion.get("prestige", 0.0)))); momentum_label.text = _metric_text("MOMENTUM", _signed_percent(float(promotion.get("momentum", 0.0))))
    var pending := int(session.call("pending_count")) if session != null else 0
    status_label.text = (str(pending) + " decision" + ("s" if pending != 1 else "") + " queued for resolution.") if pending > 0 else (status_message if not status_message.is_empty() else "Signal first. Detail on demand.")
    var attention: Array = view.get("attention", []); map_signal_label.text = str(attention[0].get("title", "World conditions")) if not attention.is_empty() else "World conditions"

func _render_detail() -> void:
    if detail_content == null: return
    for child: Node in detail_content.get_children(): child.queue_free()
    match surface:
        "roster": _render_roster()
        "touring": _render_touring()
        "wrestling": _render_wrestling()
        "history": _render_history()
        _: _render_market()
    _apply_layout()

func _render_market() -> void:
    var market := _selected_market()
    if market.is_empty(): detail_title.text = "Strategic Map"; detail_subtitle.text = "Select a market to inspect known conditions."; return
    detail_title.text = _clean(str(market.get("name", "Market"))); detail_subtitle.text = str(market.get("region_name", "")) + "  •  " + ("Home market" if bool(market.get("is_home_market", false)) else "Strategic market")
    _section("MARKET SIGNAL"); _key_value("Audience interest", str(market.get("interest_signal", "Unknown"))); _key_value("Economic condition", str(market.get("economic_signal", "Unknown"))); _key_value("Your presence", _presence(float(market.get("own_presence", 0.0))))
    if not str(market.get("hot_state", "")).is_empty(): _key_value("Current condition", str(market.get("hot_state")))
    _section("RIVAL READ"); var rivals: Array = market.get("rival_presence", [])
    if rivals.is_empty(): _body("No reliable rival estimate is available to the office here.", Color("83979f"))
    else:
        for rival: Dictionary in rivals:
            var range: Variant = rival.get("estimate_range", null); var description := "Observed"
            if range is Dictionary: description = _presence((float((range as Dictionary).get("min", 0.0)) + float((range as Dictionary).get("max", 0.0))) * 0.5) + " estimate"
            _key_value(_clean(str(rival.get("promotion_name", "Rival"))), description + "  ·  " + str(round(float(rival.get("confidence", 0.0)) * 100.0)) + "% confidence")
    _section("OFFICE ACTIONS"); _body("Actions are queued into the current month and resolved through the same command path as the simulation.", Color("788e97")); _action_button("Focus booking on this market", _queue_market_focus.bind(str(market.get("market_id", "")))); _action_button("Route your tour here next", _queue_route.bind(str(market.get("market_id", ""))))
    _section("RECENT MEMORY"); var shown := 0
    for event: Dictionary in view.get("recent_history", []):
        if str(event.get("market_id", "")) == str(market.get("market_id", "")): _history_row(event); shown += 1; if shown >= 4: break
    if shown == 0: _body("No recent recorded event involving your promotion is tied to this market.", Color("788e97"))

func _render_roster() -> void:
    detail_title.text = "People"; detail_subtitle.text = "Controlled roster  •  people remain people, not map units"
    var roster: Array = view.get("roster", []); _section("ROSTER  ·  " + str(roster.size()))
    for person: Dictionary in roster:
        var roles: Array[String] = []; for role: Variant in person.get("roles", []): roles.append(str(role).get_slice(".", 1).capitalize())
        var card := _card(); card.add_child(_label(_clean(str(person.get("name", ""))), 16, Color("e7eef0"))); card.add_child(_label(" / ".join(roles) + "  ·  " + str(person.get("health_status", "available")).capitalize(), 11, Color("80959e")))
        var local: Dictionary = {}; for audience: Dictionary in person.get("audience", []):
            if str(audience.get("market_id", "")) == selected_market_id: local = audience; break
        if not local.is_empty(): card.add_child(_label("In " + _clean(str(local.get("market_name", ""))) + ": " + _presence(float(local.get("overness", 0.0))) + " audience standing", 12, Color("a6bbc2")))
        var ids := _controlled_company_ids_for_person(str(person.get("person_id", "")))
        if not ids.is_empty() and "role.wrestler" in (person.get("roles", []) as Array):
            var push := Button.new(); push.text = "Queue featured push"; push.custom_minimum_size = Vector2(180, 44); push.pressed.connect(_queue_push.bind(str(ids[0]), str(person.get("person_id", "")))); card.add_child(push)

func _render_touring() -> void:
    detail_title.text = "Touring"; detail_subtitle.text = "Geography in motion  •  known routes and current directives"
    for company: Dictionary in view.get("touring", []):
        var own := str(company.get("ownership", "")) == "controlled"; var card := _card(); card.add_child(_label((_clean(str(company.get("name", ""))) if own else _clean(str(company.get("promotion_name", "Rival"))) + "  • observed route"), 16, Color("e7eef0") if own else Color("d5b27d")))
        var route_names: Array[String] = []; for stop: Dictionary in company.get("route", []): route_names.append(_clean(str(stop.get("market_name", ""))))
        card.add_child(_label(" → ".join(route_names) if not route_names.is_empty() else "Route not known", 12, Color("9eb0b7")))
        if own:
            card.add_child(_label("Budget " + _money(company.get("budget", {})) + "  ·  fatigue " + _signal_percent(float(company.get("fatigue_pressure", 0.0))) + "  ·  cohesion " + _percent(float(company.get("cohesion", 0.0))), 11, Color("7f959e")))
            var row := HBoxContainer.new(); card.add_child(row); var down := Button.new(); down.text = "Budget −10%"; down.custom_minimum_size = Vector2(116, 44); down.pressed.connect(_queue_budget.bind(str(company.get("company_id", "")), -0.10, company.get("budget", {}))); row.add_child(down); var up := Button.new(); up.text = "Budget +10%"; up.custom_minimum_size = Vector2(116, 44); up.pressed.connect(_queue_budget.bind(str(company.get("company_id", "")), 0.10, company.get("budget", {}))); row.add_child(up)
        else: card.add_child(_label("Observed " + str(company.get("observed_on", "")) + "  ·  " + str(round(float(company.get("confidence", 0.0)) * 100.0)) + "% confidence", 11, Color("9b8569")))

func _render_wrestling() -> void:
    detail_title.text = "Wrestling"; detail_subtitle.text = "Delegation-first program context  •  one authoritative resolver"
    _section("BOOKING OFFICE"); _key_value("Booker", _clean(str((view.get("promotion", {}) as Dictionary).get("booker_name", "Unassigned")))); _body("The office sets strategic direction. Card construction remains delegated unless a meaningful exception needs intervention.", Color("879ba3")); _section("ACTIVE PROGRAMS")
    var programs: Array = view.get("programs", []); if programs.is_empty(): _body("No active program is currently indexed for this promotion.", Color("788e97"))
    for program: Dictionary in programs:
        var card := _card(); card.add_child(_label(" vs ".join(program.get("side_a", [])) + "  /  " + " vs ".join(program.get("side_b", [])), 16, Color("e6edef"))); card.add_child(_label("Heat " + _percent(float(program.get("heat", 0.0))) + "  ·  momentum " + _signed_percent(float(program.get("momentum", 0.0))) + "  ·  " + str(program.get("phase_id", "")).get_slice(".", 1).capitalize(), 11, Color("81969e")))
    _section("CHAMPIONSHIPS"); for title: Dictionary in view.get("championships", []): _key_value(_clean(str(title.get("name", "Championship"))), ", ".join(title.get("holder_names", [])) if not (title.get("holder_names", []) as Array).is_empty() else "Vacant")

func _render_history() -> void:
    detail_title.text = "Chronicle"; detail_subtitle.text = "Recorded history  •  inspection never re-simulates the past"; _section("RECENT HISTORY")
    var events: Array = view.get("recent_history", []); if events.is_empty(): _body("The campaign has only its opening checkpoint so far. Advance a month and the Chronicle will begin accumulating history.", Color("788e97"))
    for event: Dictionary in events: _history_row(event)
    _section("HISTORICAL INSPECTION"); var dates: Array = view.get("history_dates", []); if dates.is_empty(): return
    var option := OptionButton.new(); option.custom_minimum_size = Vector2(220, 44); for date_value: Variant in dates: option.add_item(_format_date(str(date_value))); option.item_selected.connect(func(index: int): _show_historical(str(dates[index]))); detail_content.add_child(option); _show_historical(str(dates[0]))

func _show_historical(date_value: String) -> void:
    if session == null: return
    var historical: Dictionary = session.call("historical_projection", date_value); if not bool(historical.get("passed", false)): return
    var promo: Dictionary = historical.get("promotion", {}); var card := _card(); card.name = "HistoricalProjectionCard"; card.add_child(_label(_format_date(date_value) + "  ·  " + _clean(str(promo.get("name", ""))), 15, Color("dfe8eb"))); card.add_child(_label("Cash " + _money(promo.get("cash", {})) + "  ·  prestige " + _percent(float(promo.get("prestige", 0.0))) + "  ·  momentum " + _signed_percent(float(promo.get("momentum", 0.0))), 11, Color("81969e")))

func _history_row(event: Dictionary) -> void:
    var card := _card(); var place := ("  ·  " + _clean(str(event.get("market_name", "")))) if not str(event.get("market_name", "")).is_empty() else ""; card.add_child(_label(_event_title(str(event.get("event_type", "Event"))) + place, 14, Color("d9e5e8"))); var names := ", ".join(event.get("entity_names", [])); card.add_child(_label(_format_date(str(event.get("date", ""))) + (("  ·  " + names) if not names.is_empty() else ""), 11, Color("7b9098")))

func _queue_market_focus(market_id: String) -> void:
    _queue_result(session.call("queue_player_command", "command.book_market_focus", {"promotion_id": str((view.get("ownership", {}) as Dictionary).get("promotion_id", "")), "market_id": market_id, "intensity": 0.72}), "Market focus queued for this month.")
func _queue_route(market_id: String) -> void:
    var company := _controlled_company(); if company.is_empty(): return
    _queue_result(session.call("queue_player_command", "command.set_route", {"touring_company_id": str(company.get("company_id", "")), "route": [{"market_id": market_id}]}), "Touring route change queued.")
func _queue_push(company_id: String, person_id: String) -> void: _queue_result(session.call("queue_player_command", "command.push_person", {"touring_company_id": company_id, "person_id": person_id, "weight": 1.0}), "Featured push queued.")
func _queue_budget(company_id: String, delta: float, budget_value: Variant) -> void:
    if not budget_value is Dictionary: return
    var current := int((budget_value as Dictionary).get("minor_units", 0)); _queue_result(session.call("queue_player_command", "command.adjust_budget", {"touring_company_id": company_id, "monthly_budget": {"minor_units": maxi(0, int(round(current * (1.0 + delta)))), "currency_id": str((budget_value as Dictionary).get("currency_id", "currency.usd"))}}), "Touring budget adjustment queued.")
func _queue_result(result: Dictionary, success_text: String) -> void: status_message = success_text if bool(result.get("accepted", false)) else "Decision rejected by the authoritative command boundary."; _refresh_header()
func _on_advance_pressed() -> void: _advance_month()
func _advance_month() -> Dictionary:
    if session == null: return {"passed": false}
    advance_button.disabled = true; var result: Dictionary = session.call("advance_month"); advance_button.disabled = false
    if bool(result.get("passed", false)):
        var turn: Dictionary = result.get("turn", {}); var events: Array = turn.get("events", []); status_message = "Month resolved. " + str(events.size()) + " material simulation event" + ("s" if events.size() != 1 else "") + " recorded."; view = result.get("projection", {}); _refresh_header(); map_view.call("set_model", view); map_view.call("select_market", selected_market_id, false); _render_detail()
    else: status_message = "Month could not advance; the current state was not replaced."; _refresh_header()
    return result
func _on_market_selected(market_id: String) -> void: selected_market_id = market_id; surface = "market" if _narrow else "map"; _render_detail()
func _set_surface(value: String) -> void: surface = value; _render_detail()
func _selected_market() -> Dictionary:
    for market: Dictionary in view.get("markets", []):
        if str(market.get("market_id", "")) == selected_market_id: return market
    return {}
func _controlled_company() -> Dictionary:
    for company: Dictionary in view.get("touring", []):
        if str(company.get("ownership", "")) == "controlled": return company
    return {}
func _controlled_company_ids_for_person(person_id: String) -> Array:
    var output: Array = []; for company: Dictionary in view.get("touring", []):
        if str(company.get("ownership", "")) == "controlled" and person_id in (company.get("person_assignment_ids", []) as Array): output.append(company.get("company_id"))
    return output
func _section(text: String) -> void: detail_content.add_child(_label(text, 11, Color("6f8a94")))
func _key_value(key: String, value: String) -> void:
    var box := HBoxContainer.new(); box.size_flags_horizontal = Control.SIZE_EXPAND_FILL; detail_content.add_child(box); var key_label := _label(key, 13, Color("9fb1b8")); key_label.custom_minimum_size = Vector2(116, 0); box.add_child(key_label); var value_label := _label(value, 13, Color("e1e9eb")); value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; box.add_child(value_label)
func _body(text: String, color: Color) -> void: var label := _label(text, 13, color); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; detail_content.add_child(label)
func _action_button(text: String, callable: Callable) -> void: var button := Button.new(); button.text = text; button.custom_minimum_size = Vector2(220, 46); button.pressed.connect(callable); detail_content.add_child(button)
func _card() -> VBoxContainer: var panel := PanelContainer.new(); panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style("0d161b", "21333b", 9)); detail_content.add_child(panel); var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 5); panel.add_child(box); return box
func _nav_button(text: String, target: String) -> Button: var button := Button.new(); button.text = text; button.custom_minimum_size = Vector2(122, 46); button.alignment = HORIZONTAL_ALIGNMENT_LEFT if text.length() > 4 else HORIZONTAL_ALIGNMENT_CENTER; button.pressed.connect(_set_surface.bind(target)); return button
func _label(text: String, font_size: int, color: Color) -> Label: var label := Label.new(); label.text = text; label.add_theme_font_size_override("font_size", font_size); label.add_theme_color_override("font_color", color); return label
func _metric(parent: HBoxContainer, key: String) -> Label: var label := _label(_metric_text(key, "—"), 12, Color("d2dde1")); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; parent.add_child(label); return label
func _metric_text(key: String, value: String) -> String: return key + "\n" + value
func _clean(text: String) -> String: return text.replace(" (Placeholder)", "").replace("Placeholder — ", "")
func _format_date(value: String) -> String:
    if value.length() < 10: return value
    var months: Array[String] = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]; var month := int(value.substr(5, 2)); return (months[month - 1] if month >= 1 and month <= 12 else value.substr(5, 2)) + " " + value.substr(0, 4)
func _money(value: Variant) -> String:
    if not value is Dictionary: return "—"
    var dollars := float((value as Dictionary).get("minor_units", 0)) / 100.0
    if abs(dollars) >= 1000000.0: return "$" + str(snapped(dollars / 1000000.0, 0.01)) + "M"
    if abs(dollars) >= 1000.0: return "$" + str(snapped(dollars / 1000.0, 0.1)) + "K"
    return "$" + str(int(round(dollars)))
func _percent(value: float) -> String: return str(int(round(value * 100.0))) + "%"
func _signed_percent(value: float) -> String: var amount := int(round(value * 100.0)); return ("+" if amount > 0 else "") + str(amount) + "%"
func _signal_percent(value: float) -> String:
    if value >= 0.70: return "high"
    if value >= 0.45: return "elevated"
    if value >= 0.25: return "moderate"
    return "low"
func _presence(value: float) -> String:
    if value >= 0.55: return "Established"
    if value >= 0.38: return "Strong"
    if value >= 0.24: return "Visible"
    if value >= 0.12: return "Light"
    return "Minimal"
func _event_title(event_type: String) -> String:
    var output := ""
    for i: int in range(event_type.length()):
        var ch := event_type[i]
        if i > 0 and ch == ch.to_upper() and event_type[i - 1] != event_type[i - 1].to_upper(): output += " "
        output += ch
    return output
