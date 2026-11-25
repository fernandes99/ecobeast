class_name QuestEditorStyle
extends RefCounted

## Os cartões e os botões leves da ferramenta Missões (editor-ui/03).

const CHOICE_COLORS: Array[Color] = [UiPalette.ACCENT, UiPalette.WARNING, UiPalette.HP_HIGH]
const SMALL_FONT := 14
const FIELD_FONT := 16
const LABEL_FONT := 18


static func card(parent: Control, title: String = "", margin := 10.0) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", box_style(UiPalette.BACKGROUND, UiPalette.BORDER, margin))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 6)
	panel.add_child(box)
	if not title.is_empty():
		var label := Label.new()
		label.text = title
		label.theme_type_variation = &"BoldLabel"
		box.add_child(label)
	return box


## O bloco da escolha: fundo escuro e a barra colorida do nível à esquerda.
static func choice_style(depth: int) -> StyleBoxFlat:
	var style := box_style(UiPalette.BACKGROUND_DEEP, CHOICE_COLORS[clampi(depth, 0, CHOICE_COLORS.size() - 1)], 8.0)
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.border_width_left = 4
	style.content_margin_left = 12.0
	return style


static func box_style(background: Color, border: Color, margin: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(margin)
	return style


## Botão pequeno sem fundo (↑, ↓, ✕); o fundo aparece ao passar o mouse.
static func mini(text: String, action: Callable, danger := false) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(30, 30)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var idle := StyleBoxEmpty.new()
	idle.set_content_margin_all(4)
	var hover := box_style(UiPalette.SURFACE_RAISED, UiPalette.SURFACE_RAISED, 4.0)
	for state: StringName in [&"normal", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(state, idle)
	for state: StringName in [&"hover", &"pressed", &"hover_pressed"]:
		button.add_theme_stylebox_override(state, hover)
	var color := UiPalette.DANGER if danger else UiPalette.TEXT_SECONDARY
	for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color", &"font_focus_color"]:
		button.add_theme_color_override(state, color)
	button.pressed.connect(action)
	return button


## Botão de contorno compacto ("+ Fala", "+ Missão"), mais leve que o Salvar.
static func outline(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var idle := box_style(Color(0, 0, 0, 0), UiPalette.ACCENT, 6.0)
	idle.content_margin_left = 12.0
	idle.content_margin_right = 12.0
	var hover: StyleBoxFlat = idle.duplicate()
	hover.bg_color = Color(UiPalette.ACCENT, 0.15)
	for state: StringName in [&"normal", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(state, idle)
	for state: StringName in [&"hover", &"pressed", &"hover_pressed"]:
		button.add_theme_stylebox_override(state, hover)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color", &"font_focus_color"]:
		button.add_theme_color_override(state, UiPalette.ACCENT)
	button.add_theme_font_size_override(&"font_size", SMALL_FONT)
	button.pressed.connect(action)
	return button


static func secondary(text: String, color := UiPalette.TEXT_SECONDARY) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_font_size_override(&"font_size", SMALL_FONT)
	return label
