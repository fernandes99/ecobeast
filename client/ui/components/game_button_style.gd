class_name GameButtonStyle
extends RefCounted

## O botão de jogo (hub-start/04, explore-hud/02): a face com a borda clara e, embaixo, a
## lateral, uma sombra sólida; apertado, a face desce sobre ela e o texto vai junto.
## Desligado, fica na cor da superfície.

const EDGE := 3
const LIP := 10
const PRESSED_LIP := 4
const LIGHTEN := 0.3
const LIP_DARKEN := 0.4
const PRESSED_DARKEN := 0.08
const TEXT_DARKEN := 0.65
const PADDING := 12

const _TEXT_STATES: Array[StringName] = [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]


static func apply(button: Button, fill: Color, radius: int, outline: int, lip: int = LIP, padding: int = PADDING) -> void:
	var edge := fill.lightened(LIGHTEN)
	var lip_color := fill.darkened(LIP_DARKEN)
	var pressed_lip := mini(PRESSED_LIP, lip)
	var normal := face(fill, edge, lip_color, lip, lip, radius, padding)
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", normal)
	button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	var pressed := face(fill.darkened(PRESSED_DARKEN), edge, lip_color, pressed_lip, lip, radius, padding)
	button.add_theme_stylebox_override(&"pressed", pressed)
	button.add_theme_stylebox_override(&"hover_pressed", pressed)
	var off := UiPalette.SURFACE_RAISED
	button.add_theme_stylebox_override(&"disabled", face(off, off.lightened(LIGHTEN), off.darkened(LIP_DARKEN), lip, lip, radius, padding))
	for state in _TEXT_STATES:
		button.add_theme_color_override(state, UiPalette.TEXT)
	button.add_theme_color_override(&"font_disabled_color", UiPalette.TEXT_SECONDARY)
	button.add_theme_constant_override(&"outline_size", outline)
	button.add_theme_color_override(&"font_outline_color", fill.darkened(TEXT_DARKEN))


## `full_lip` é a lateral do botão solto; com `lip_size` menor, a face desce a diferença.
static func face(fill: Color, edge: Color, lip_color: Color, lip_size: int, full_lip: int, radius: int, padding: int = PADDING) -> StyleBoxFlat:
	var sink := full_lip - lip_size
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(EDGE)
	style.set_corner_radius_all(radius)
	style.expand_margin_top = -sink
	style.expand_margin_bottom = -lip_size
	style.shadow_color = lip_color
	style.shadow_size = 1
	style.shadow_offset = Vector2(0.0, lip_size)
	style.set_content_margin_all(padding)
	style.content_margin_top = padding + sink
	style.content_margin_bottom = padding + lip_size
	return style
