class_name WanderingSprite
extends SheetSprite

const WALK_SPEED := 18.0
const MIN_PAUSE := 1.0
const MAX_PAUSE := 2.5
const MIN_TRIP := 12.0
const SPOT_TRIES := 8
const STRAIGHT_SINE := 0.92
const DIAGONAL_SINE := 0.38

var _coord := Vector2i.ZERO
var _center := Vector2.ZERO
## A posição antes de arredondar, para o passo não depender do pixel.
var _exact := Vector2.ZERO
var _target := Vector2.ZERO
var _pause_left := 0.0
## Só passeia no mapa, depois do `wander_in`. O Godot liga o `_process` sozinho
## quando o nó entra na árvore, e o `set_process(false)` do `_init` não basta.
var _wandering: bool = false


func _process(delta: float) -> void:
	if not _wandering:
		return
	if _pause_left > 0.0:
		_pause_left -= delta
		if _pause_left <= 0.0:
			_walk_to(_next_spot())
		return
	_exact = _exact.move_toward(_target, WALK_SPEED * delta)
	position = _exact.round()
	if _exact == _target:
		_rest()


func wander_in(coord: Vector2i, center: Vector2) -> void:
	_coord = coord
	_center = center
	_exact = random_spot(center)
	position = _exact.round()
	_rest()
	_wandering = true


func random_spot(center: Vector2) -> Vector2:
	for _index: int in SPOT_TRIES:
		var spot := Vector2(randf_range(-HexDecorations.MAX_X, HexDecorations.MAX_X), randf_range(-HexDecorations.MAX_Y, HexDecorations.MAX_Y))
		if absf(spot.x) / 2.0 + absf(spot.y) <= HexDecorations.MAX_EDGE_DISTANCE:
			return center + spot
	return center


func face_toward(direction: Vector2) -> void:
	var sine := direction.normalized().y
	if sine > STRAIGHT_SINE:
		_row = FRONT_ROW
	elif sine > DIAGONAL_SINE:
		_row = LOWER_ROW
	elif sine > -DIAGONAL_SINE:
		_row = SIDE_ROW
	elif sine > -STRAIGHT_SINE:
		_row = UPPER_ROW
	else:
		_row = BACK_ROW
	flip_h = direction.x < 0.0


func _play_still() -> void:
	pass


func _play_moving() -> void:
	pass


func _rest() -> void:
	_play_still()
	_pause_left = randf_range(MIN_PAUSE, MAX_PAUSE)


func _walk_to(spot: Vector2) -> void:
	_target = spot
	face_toward(_target - _exact)
	_play_moving()


func _next_spot() -> Vector2:
	var spot := random_spot(_center)
	for _index: int in SPOT_TRIES:
		if spot.distance_to(_exact) >= MIN_TRIP:
			break
		spot = random_spot(_center)
	return spot
