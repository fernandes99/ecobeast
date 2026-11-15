class_name IslandBlocks
extends RefCounted
## Os hexágonos que as linhas de bloqueio das peças e as paredes bloqueiam, a mesma conta
## do `blocked-hexes.ts` do servidor: os de centro a até CENTER_REACH de um trecho e, na
## linha fechada, os de centro dentro dela (prop-depth-blocks/02). Só o editor usa, para
## mostrar.

const CENTER_REACH := 8.0
const NEIGHBORS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 1)]


## `lines`: as linhas no chão plano, como `MapProp.world_lines` (a fechada repete o
## primeiro ponto no fim).
static func blocked_hexes(lines: Array[PackedVector2Array]) -> Dictionary[Vector2i, bool]:
	var keys: Dictionary[Vector2i, bool] = {}
	for line: PackedVector2Array in lines:
		for index: int in range(1, line.size()):
			var from := line[index - 1]
			var to := line[index]
			var seen: Dictionary[Vector2i, bool] = {}
			var steps := maxi(1, ceili(maxf(absf(to.x - from.x), absf(to.y - from.y)) / CENTER_REACH))
			for step: int in steps + 1:
				var coord := HexMapView.grid_coord(from.lerp(to, float(step) / steps))
				for shift: Vector2i in [Vector2i.ZERO] + NEIGHBORS:
					var candidate := coord + shift
					if seen.has(candidate):
						continue
					seen[candidate] = true
					var center := HexMapView.flat_center(candidate)
					if center.distance_to(Geometry2D.get_closest_point_to_segment(center, from, to)) <= CENTER_REACH:
						keys[candidate] = true
		if line.size() >= 4 and line[0] == line[line.size() - 1]:
			_add_inside(line, keys)
	return keys


static func _add_inside(line: PackedVector2Array, keys: Dictionary[Vector2i, bool]) -> void:
	var polygon := line.slice(0, line.size() - 1)
	var box := Rect2(polygon[0], Vector2.ZERO)
	for point: Vector2 in polygon:
		box = box.expand(point)
	var first := HexMapView.grid_coord(box.position) - Vector2i(2, 1)
	var last := HexMapView.grid_coord(box.end) + Vector2i(2, 1)
	for r: int in range(first.y, last.y + 1):
		for q: int in range(first.x - (last.y - first.y), last.x + 2):
			var coord := Vector2i(q, r)
			if Geometry2D.is_point_in_polygon(HexMapView.flat_center(coord), polygon):
				keys[coord] = true
