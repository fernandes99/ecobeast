class_name WalkRoute
extends RefCounted

## Pixels da arte por segundo, medidos com a altura esticada: a 130, um hexágono leva
## pelo menos 0,43 s em qualquer direção, e o servidor exige 0,3 s.
const WALK_SPEED := 130.0
## A grade é achatada (42 de uma linha à outra, contra 55,4 de um hexágono regular de 64).
const Y_STRETCH := 55.4256 / 42.0
const SAMPLE_STEP := 4.0


## O caminho de `from` até `to`, passando pelo centro dos `hexes` (o primeiro é o do
## `from`, o último o do `to`) e esticado em retas que não saem do mapa nem cruzam
## paredes. Cada trecho de um centro ao seguinte já é livre pela busca; o centro do
## próprio hexágono só entra quando alcançável, e o fim para rente à primeira parede
## (free-fences/02).
static func points(map: ExplorationMap, from: Vector2, hexes: Array[Vector2i], to: Vector2) -> PackedVector2Array:
	var waypoints := PackedVector2Array([from])
	var own := HexMapView.flat_center(hexes[0])
	var deck := map.deck_of(from)
	if deck >= 0 and map.is_blocked_hex(hexes[0]) and hexes.size() > 1:
		# Em cima de uma ponte: sai pela ponta do hexágono seguinte (bridges/04).
		var bridge := map.bridges[deck]
		waypoints.append(bridge.from if HexMapView.grid_coord(bridge.from) == hexes[1] else bridge.to)
	elif map.is_clear(from, own):
		waypoints.append(own)
	for index: int in range(1, hexes.size()):
		waypoints.append_array(map.bridge_hop(hexes[index - 1], hexes[index]))
		waypoints.append(HexMapView.flat_center(hexes[index]))
	var last := waypoints[waypoints.size() - 1]
	var target_deck := map.deck_of(to)
	if target_deck >= 0 and not map.is_clear(last, to):
		var bridge := map.bridges[target_deck]
		waypoints.append(bridge.from if bridge.from.distance_to(last) <= bridge.to.distance_to(last) else bridge.to)
	waypoints.append(map.clip_to_walls(waypoints[waypoints.size() - 1], to))
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
		if not map.has(coord):
			return false
	return map.is_clear(from, to)


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
