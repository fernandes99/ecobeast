class_name WalkRoute
extends RefCounted

## Pixels da arte por segundo, medidos com a altura esticada: a 160, um hexágono leva
## pelo menos 0,34 s em qualquer direção, e o servidor exige 0,3 s.
const WALK_SPEED := 160.0
## A grade é achatada (42 de uma linha à outra, contra 55,4 de um hexágono regular de 64).
const Y_STRETCH := 55.4256 / 42.0
const SAMPLE_STEP := 4.0


## O caminho de `from` até `to`, passando pelo centro dos `hexes` (o primeiro é o do
## `from`, o último o do `to`) e esticado em retas que não cruzam bloqueados.
static func points(map: ExplorationMap, from: Vector2, hexes: Array[Vector2i], to: Vector2) -> PackedVector2Array:
	var waypoints := PackedVector2Array([from])
	for index: int in range(1, hexes.size() - 1):
		waypoints.append(HexMapView.flat_center(hexes[index]))
	waypoints.append(to)
	var result := PackedVector2Array([from])
	var at := 0
	while at < waypoints.size() - 1:
		var next := at + 1
		for ahead: int in range(waypoints.size() - 1, at + 1, -1):
			if is_clear(map, waypoints[at], waypoints[ahead]):
				next = ahead
				break
		result.append(waypoints[next])
		at = next
	return result


static func is_clear(map: ExplorationMap, from: Vector2, to: Vector2) -> bool:
	var steps := maxi(1, ceili(from.distance_to(to) / SAMPLE_STEP))
	for step: int in range(steps + 1):
		var coord := HexMapView.grid_coord(from.lerp(to, float(step) / steps))
		if not map.has(coord) or map.is_blocked(coord):
			return false
	return true


static func world(vector: Vector2) -> Vector2:
	return Vector2(vector.x, vector.y * Y_STRETCH)


static func length(route: PackedVector2Array) -> float:
	var total := 0.0
	for index: int in range(1, route.size()):
		total += world(route[index] - route[index - 1]).length()
	return total


static func point_at(route: PackedVector2Array, distance: float) -> Vector2:
	var left := distance
	for index: int in range(1, route.size()):
		var part := world(route[index] - route[index - 1]).length()
		if left <= part and part > 0.0:
			return route[index - 1].lerp(route[index], left / part)
		left -= part
	return route[route.size() - 1]
