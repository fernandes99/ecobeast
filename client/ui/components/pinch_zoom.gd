class_name PinchZoom
extends RefCounted
## Lê a pinça de dois dedos e a roda do mouse; quem usa decide o que é o zoom.

signal pinch_started(center: Vector2)
## A distância entre os dedos dividida pela do começo da pinça.
signal pinched(ratio: float, center: Vector2)

var _touches: Dictionary[int, Vector2] = {}
var _start_distance := 0.0
var _pinching := false
var _blocking := false


## Devolve `true` quando o evento é parte de uma pinça. A pinça só começa com os dois
## dedos dentro de `area`.
func feed(event: InputEvent, area: Rect2) -> bool:
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			_touches[touch.index] = touch.position
			if _touches.size() == 2 and not _pinching and _all_inside(area):
				_pinching = true
				_blocking = true
				_start_distance = maxf(1.0, _distance())
				pinch_started.emit(_center())
			return _pinching
		var was_pinching := _pinching
		_touches.erase(touch.index)
		if _touches.size() < 2:
			_pinching = false
		if _touches.is_empty():
			_blocking = false
		return was_pinching
	var drag := event as InputEventScreenDrag
	if drag == null or not _touches.has(drag.index):
		return false
	_touches[drag.index] = drag.position
	if _pinching:
		pinched.emit(_distance() / _start_distance, _center())
	return _pinching


## +1 para a roda para cima dentro de `area`, −1 para baixo, 0 para o resto.
func wheel(event: InputEvent, area: Rect2) -> int:
	var button := event as InputEventMouseButton
	if button == null or not button.pressed or not area.has_point(button.position):
		return 0
	if button.button_index == MOUSE_BUTTON_WHEEL_UP:
		return 1
	if button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		return -1
	return 0


## Do começo de uma pinça até o último dedo sair: o toque emulado como mouse chega
## antes do toque de verdade, então soltar os dedos não vira toque.
func blocks_tap() -> bool:
	return _blocking


func cancel() -> void:
	_touches.clear()
	_pinching = false
	_blocking = false


func _all_inside(area: Rect2) -> bool:
	for point: Vector2 in _touches.values():
		if not area.has_point(point):
			return false
	return true


func _distance() -> float:
	var points := _touches.values()
	return (points[0] as Vector2).distance_to(points[1])


func _center() -> Vector2:
	var points := _touches.values()
	return ((points[0] as Vector2) + (points[1] as Vector2)) / 2.0
