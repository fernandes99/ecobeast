class_name TapPanel
extends PanelContainer

signal pressed

const TAP_SLOP := 24.0

var _press_position := Vector2.ZERO
var _is_pressing: bool = false


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if button.pressed:
		_is_pressing = true
		_press_position = button.position
		self_modulate = UiPalette.PRESSED_TINT
	elif _is_pressing:
		_cancel_press()
		var is_tap := button.position.distance_to(_press_position) <= TAP_SLOP
		if is_tap and Rect2(Vector2.ZERO, size).has_point(button.position):
			pressed.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and _is_pressing:
		_cancel_press()


func _cancel_press() -> void:
	_is_pressing = false
	self_modulate = Color.WHITE
