class_name InteriorRoute
extends RefCounted

## O andar dentro de uma sala (interiors/02): o caminho de quadrados pelo `AStarGrid2D`,
## que vira retas do ponto dos pés até o ponto tocado (.specs/interiors/architecture.md).

const SAMPLE_STEP := 4.0
const NONE := Vector2i(-1, -1)
const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var _size := Vector2i.ZERO
var _blocked: Dictionary[Vector2i, bool] = {}
var _grid := AStarGrid2D.new()


## `extra_blocked` são os quadrados dos NPCs.
func _init(interior: Interior, extra_blocked: Dictionary[Vector2i, bool] = {}) -> void:
	_size = Vector2i(interior.width, interior.height)
	_blocked = InteriorTiles.blocked(interior)
	_blocked.merge(extra_blocked)
	_grid.region = Rect2i(Vector2i.ZERO, _size)
	_grid.cell_size = Vector2(InteriorTiles.CELL, InteriorTiles.CELL)
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	_grid.update()
	for cell: Vector2i in _blocked:
		if _grid.is_in_boundsv(cell):
			_grid.set_point_solid(cell)


## Fora da sala conta como bloqueado.
func is_blocked(cell: Vector2i) -> bool:
	return not _grid.is_in_boundsv(cell) or _blocked.has(cell)


## O quadrado livre de centro mais perto do ponto, ou NONE.
func nearest_free(point: Vector2) -> Vector2i:
	var best := NONE
	var best_distance := INF
	for y: int in _size.y:
		for x: int in _size.x:
			var cell := Vector2i(x, y)
			if _blocked.has(cell):
				continue
			var distance := point.distance_squared_to(InteriorTiles.cell_center(cell))
			if distance < best_distance:
				best = cell
				best_distance = distance
	return best


func is_clear(from: Vector2, to: Vector2) -> bool:
	var steps := maxi(1, ceili(from.distance_to(to) / SAMPLE_STEP))
	for step: int in steps + 1:
		if is_blocked(InteriorTiles.cell_of(from.lerp(to, float(step) / steps))):
			return false
	return true


## As retas do ponto `from` até `to`, sem o ponto de partida. Um destino bloqueado vira
## o centro do quadrado livre mais perto dele; sem caminho, vazio.
func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	var finish := to
	var target := InteriorTiles.cell_of(to)
	if is_blocked(target):
		target = nearest_free(to)
		if target == NONE:
			return PackedVector2Array()
		finish = InteriorTiles.cell_center(target)
	var start := InteriorTiles.cell_of(from)
	if is_blocked(start):
		return PackedVector2Array()
	if start == target:
		return PackedVector2Array() if finish == from else PackedVector2Array([finish])
	var cells := _grid.get_id_path(start, target)
	if cells.is_empty():
		return PackedVector2Array()
	var points := PackedVector2Array()
	for index: int in range(1, cells.size()):
		points.append(InteriorTiles.cell_center(cells[index]))
	points[points.size() - 1] = finish
	return _straighten(from, points)


func route_to_cell(from: Vector2, cell: Vector2i) -> PackedVector2Array:
	return route(from, InteriorTiles.cell_center(cell))


## O quadrado livre ao lado de `target` (cima, baixo, esquerda ou direita) com o caminho
## mais curto a partir de `from`, ou NONE.
func approach(from: Vector2, target: Vector2i) -> Vector2i:
	var start := InteriorTiles.cell_of(from)
	if is_blocked(start):
		return NONE
	var best := NONE
	var best_length := INF
	for side: Vector2i in SIDES:
		var cell := target + side
		if is_blocked(cell):
			continue
		var length := 0.0
		if cell != start:
			var path := _grid.get_point_path(start, cell)
			if path.is_empty():
				continue
			for index: int in range(1, path.size()):
				length += path[index - 1].distance_to(path[index])
		if length < best_length:
			best = cell
			best_length = length
	return best


func _straighten(from: Vector2, points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	var current := from
	var index := 0
	while index < points.size():
		var reach := index
		for ahead: int in range(points.size() - 1, index, -1):
			if is_clear(current, points[ahead]):
				reach = ahead
				break
		result.append(points[reach])
		current = points[reach]
		index = reach + 1
	return result
