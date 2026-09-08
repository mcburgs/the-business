extends RefCounted

static func build() -> Theme:
    var theme: Theme = Theme.new()
    theme.default_font_size = 16
    theme.set_font_size("font_size", "Label", 15)
    theme.set_font_size("font_size", "Button", 14)
    theme.set_color("font_color", "Label", Color("d9e3e8"))
    theme.set_color("font_color", "Button", Color("dce7eb"))
    theme.set_color("font_hover_color", "Button", Color("ffffff"))
    theme.set_color("font_pressed_color", "Button", Color("ffffff"))
    theme.set_constant("separation", "VBoxContainer", 9)
    theme.set_constant("separation", "HBoxContainer", 10)

    var button_normal: StyleBoxFlat = _box("17232b", 8, 1, "2b3d47")
    button_normal.content_margin_left = 16; button_normal.content_margin_right = 16
    button_normal.content_margin_top = 11; button_normal.content_margin_bottom = 11
    var button_hover: StyleBoxFlat = _box("20313b", 8, 1, "44616e")
    button_hover.content_margin_left = 16; button_hover.content_margin_right = 16
    button_hover.content_margin_top = 11; button_hover.content_margin_bottom = 11
    var button_pressed: StyleBoxFlat = _box("243944", 8, 1, "6aa7b6")
    button_pressed.content_margin_left = 16; button_pressed.content_margin_right = 16
    button_pressed.content_margin_top = 11; button_pressed.content_margin_bottom = 11
    theme.set_stylebox("normal", "Button", button_normal)
    theme.set_stylebox("hover", "Button", button_hover)
    theme.set_stylebox("pressed", "Button", button_pressed)
    theme.set_stylebox("focus", "Button", button_pressed)

    var panel: StyleBoxFlat = _box("111a20", 12, 1, "26363f")
    panel.content_margin_left = 16; panel.content_margin_right = 16
    panel.content_margin_top = 15; panel.content_margin_bottom = 15
    theme.set_stylebox("panel", "PanelContainer", panel)

    var line_edit: StyleBoxFlat = _box("0d151a", 8, 1, "334650")
    line_edit.content_margin_left = 10; line_edit.content_margin_right = 10
    line_edit.content_margin_top = 9; line_edit.content_margin_bottom = 9
    theme.set_stylebox("normal", "LineEdit", line_edit)
    theme.set_stylebox("normal", "OptionButton", button_normal)
    theme.set_stylebox("hover", "OptionButton", button_hover)
    theme.set_stylebox("pressed", "OptionButton", button_pressed)
    return theme

static func panel_style(background: String, border: String = "26363f", radius: int = 12, border_width: int = 1) -> StyleBoxFlat:
    var style: StyleBoxFlat = _box(background, radius, border_width, border)
    style.content_margin_left = 16; style.content_margin_right = 16
    style.content_margin_top = 14; style.content_margin_bottom = 14
    return style

static func _box(background: String, radius: int, border_width: int, border: String) -> StyleBoxFlat:
    var box: StyleBoxFlat = StyleBoxFlat.new()
    box.bg_color = Color(background)
    box.border_color = Color(border)
    box.set_border_width_all(border_width)
    box.corner_radius_top_left = radius
    box.corner_radius_top_right = radius
    box.corner_radius_bottom_left = radius
    box.corner_radius_bottom_right = radius
    return box
