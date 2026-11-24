class_name MapToast
extends TapPanel

## O aviso de Explorar (explore-hud/02): um balão escuro no meio de baixo que some sozinho
## ou ao ser tocado. O fixo (o "Chegando..." e o erro da entrada) fica até ser trocado.

const SECONDS := 3.0
const DANGER_SECONDS := 5.0
const FADE_SECONDS := 0.2
const FONT_SIZE := 22
const OUTLINE := 6
const MAX_WIDTH_RATIO := 0.8

var _label := Label.new()
var _timer := Timer.new()
var _fade: Tween = null


func _init() -> void:
	visible = false
	size_flags_horizontal = SIZE_SHRINK_CENTER
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	var style := ExplorePlates.panel_style()
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	add_theme_stylebox_override(&"panel", style)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	_label.add_theme_constant_override(&"outline_size", OUTLINE)
	_label.add_theme_color_override(&"font_outline_color", UiPalette.TEXT_OUTLINE)
	_label.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_label)
	_timer.one_shot = true
	_timer.timeout.connect(_fade_out)
	add_child(_timer)
	pressed.connect(hide_now)


## `variation` é o estilo do texto do tema (`SecondaryLabel` ou `DangerLabel`).
func show_text(text: String, variation: StringName, sticky := false) -> void:
	if _fade != null:
		_fade.kill()
	_label.text = text
	_label.theme_type_variation = variation
	var font := _label.get_theme_font(&"font")
	var wanted := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x + OUTLINE
	var room := get_parent_area_size().x * MAX_WIDTH_RATIO - get_theme_stylebox(&"panel").get_minimum_size().x
	_label.custom_minimum_size.x = minf(ceilf(wanted), maxf(room, 0.0))
	modulate.a = 1.0
	show()
	_timer.stop()
	if not sticky:
		_timer.start(DANGER_SECONDS if variation == &"DangerLabel" else SECONDS)


func hide_now() -> void:
	_timer.stop()
	if _fade != null:
		_fade.kill()
	hide()


func _fade_out() -> void:
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
	_fade.tween_callback(hide)

