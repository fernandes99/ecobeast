class_name XpLine
extends ProgressBar

signal filled

const FILL_TIME := 0.7
const FLASH_TIME := 0.25

var _fill := StyleBoxFlat.new()
var _tween: Tween = null


func _init(line_height: int = 4) -> void:
	custom_minimum_size.y = line_height
	min_value = 0.0
	max_value = 1.0
	step = 0.0
	show_percentage = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := StyleBoxFlat.new()
	track.bg_color = UiPalette.TRACK
	track.set_corner_radius_all(line_height)
	_fill.bg_color = UiPalette.XP_LINE
	_fill.set_corner_radius_all(line_height)
	add_theme_stylebox_override(&"background", track)
	add_theme_stylebox_override(&"fill", _fill)


func set_ratio(ratio: float) -> void:
	_stop()
	value = clampf(ratio, 0.0, 1.0)


func fill_to(ratio: float) -> void:
	_stop()
	var target := clampf(ratio, 0.0, 1.0)
	if is_equal_approx(target, value):
		return
	_tween = create_tween()
	_tween.tween_property(self, ^"value", target, FILL_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.finished.connect(filled.emit)
	await filled


func flash() -> void:
	_fill.bg_color = Color.WHITE
	await get_tree().create_timer(FLASH_TIME).timeout
	_fill.bg_color = UiPalette.XP_LINE


func _stop() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
		_tween = null
		filled.emit()
	_tween = null
