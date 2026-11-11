class_name BattleTheme
extends RefCounted

const PANEL := &"BattlePanel"
const LOG := &"BattleLog"
const PILL := &"BattlePill"
const BUTTON := &"BattleButton"

const ICONS_DIR := "res://assets/ui/battle/icons/%s.png"

const PANEL_FILL := Color("#132A57F0")
const PANEL_BORDER := Color("#3F86E8")
const PANEL_SHADOW := Color("#00000059")
const PILL_FILL := Color("#0B1A36")
const PILL_BORDER := Color("#3B5C8F")
const BUTTON_FILL := Color("#2F6FD6")
const BUTTON_PRESSED_FILL := Color("#2459B5")
const BUTTON_BORDER := Color("#7CC0FF")
const BUTTON_SHADOW := Color("#0A2350")
const FOCUS_RING := Color("#FFB23E")
const TEXT := Color("#FFFFFF")
const TEXT_OUTLINE := Color("#0A1A3A")

const PANEL_RADIUS := 22
const PANEL_BORDER_WIDTH := 3
const BUTTON_RADIUS := 18
const BUTTON_BORDER_WIDTH := 3
const BUTTON_DEPTH := 6
const BUTTON_PRESSED_DEPTH := 2
const FOCUS_WIDTH := 4
const FOCUS_GLOW := 10
const BUTTON_FONT_SIZE := 28
const ICON_SIZE := 60

static var _theme: Theme = null


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


static func icon(icon_name: String) -> Texture2D:
	return load(ICONS_DIR % icon_name) as Texture2D


static func action_button(button: Button, icon_name: String) -> void:
	button.theme_type_variation = BUTTON
	button.icon = icon(icon_name)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP


static func _build() -> Theme:
	var theme := Theme.new()

	theme.set_type_variation(PANEL, &"PanelContainer")
	theme.set_stylebox(&"panel", PANEL, _panel(PANEL_RADIUS, 22, 16))

	theme.set_type_variation(LOG, &"PanelContainer")
	theme.set_stylebox(&"panel", LOG, _panel(PANEL_RADIUS, 18, 10))

	theme.set_type_variation(PILL, &"PanelContainer")
	var pill := _flat(PILL_FILL, PILL_BORDER, 2, 12)
	_margins(pill, 10, 2)
	theme.set_stylebox(&"panel", PILL, pill)

	theme.set_type_variation(BUTTON, &"Button")
	_button_styles(theme, BUTTON, 12)
	theme.set_font_size(&"font_size", BUTTON, BUTTON_FONT_SIZE)
	theme.set_constant(&"icon_max_width", BUTTON, ICON_SIZE)
	theme.set_constant(&"h_separation", BUTTON, 2)
	_button_text(theme, BUTTON)
	return theme


static func _panel(radius: int, margin_x: int, margin_y: int) -> StyleBoxFlat:
	var style := _flat(PANEL_FILL, PANEL_BORDER, PANEL_BORDER_WIDTH, radius)
	style.shadow_color = PANEL_SHADOW
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	_margins(style, margin_x, margin_y)
	return style


static func _button_styles(theme: Theme, variation: StringName, margin: int) -> void:
	var normal := _button(BUTTON_FILL, BUTTON_DEPTH, margin)
	var pressed := _button(BUTTON_PRESSED_FILL, BUTTON_PRESSED_DEPTH, margin)
	# Apertado, o conteúdo desce o que a borda de baixo perdeu.
	pressed.content_margin_top += BUTTON_DEPTH - BUTTON_PRESSED_DEPTH
	pressed.content_margin_bottom -= BUTTON_DEPTH - BUTTON_PRESSED_DEPTH
	var disabled := _button(Color(BUTTON_FILL, 0.45), BUTTON_DEPTH, margin)
	disabled.border_color = Color(BUTTON_BORDER, 0.35)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = FOCUS_RING
	focus.set_border_width_all(FOCUS_WIDTH)
	focus.set_corner_radius_all(BUTTON_RADIUS + 2)
	focus.set_expand_margin_all(3)
	focus.shadow_color = Color(FOCUS_RING, 0.5)
	focus.shadow_size = FOCUS_GLOW
	# No celular não há "passar o mouse": o hover é igual ao normal.
	theme.set_stylebox(&"normal", variation, normal)
	theme.set_stylebox(&"hover", variation, normal)
	theme.set_stylebox(&"pressed", variation, pressed)
	theme.set_stylebox(&"hover_pressed", variation, pressed)
	theme.set_stylebox(&"disabled", variation, disabled)
	theme.set_stylebox(&"focus", variation, focus)


static func _button(fill: Color, depth: int, margin: int) -> StyleBoxFlat:
	var style := _flat(fill, BUTTON_BORDER, BUTTON_BORDER_WIDTH, BUTTON_RADIUS)
	style.shadow_color = BUTTON_SHADOW
	style.shadow_size = 1
	style.shadow_offset = Vector2(0, depth)
	_margins(style, margin, margin)
	style.content_margin_bottom = margin + depth
	return style


static func _button_text(theme: Theme, variation: StringName) -> void:
	for color_name: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color", &"font_focus_color"]:
		theme.set_color(color_name, variation, TEXT)
	theme.set_color(&"font_disabled_color", variation, Color(TEXT, 0.5))
	theme.set_color(&"font_outline_color", variation, TEXT_OUTLINE)
	theme.set_constant(&"outline_size", variation, 6)


static func _flat(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.corner_detail = 8
	style.anti_aliasing = true
	return style


static func _margins(style: StyleBoxFlat, x: int, y: int) -> void:
	style.content_margin_left = x
	style.content_margin_right = x
	style.content_margin_top = y
	style.content_margin_bottom = y
