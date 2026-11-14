class_name HexRounding
extends RefCounted
## As pontas dos hexágonos arredondadas onde a altura ou o bioma muda. Em cada
## canto, quem é diferente dos outros dois perde a ponta num arco, e os dois iguais
## avançam sobre ele com o mesmo arco; com três alturas diferentes, o mais alto perde a
## ponta, e com três biomas diferentes o canto fica reto (terrain-height/04).

const RADIUS := 6.0
const STEPS := 4
const PLAIN := 0
const CUT := 1
const FILL_BEFORE := 2
const FILL_AFTER := 3
const LOWER_EDGES: Array[int] = [2, 3]

static var _third_edges: Array[Vector2] = []


class Segment:
	extends RefCounted
	var from: Vector2
	var to: Vector2
	var normal: Vector2
	var owner: Vector2i
	var edge := -1


class Shape:
	extends RefCounted
	var triangles := PackedVector2Array()
	var segments: Array[Segment] = []


static func shape_of(tile: HexTile, map: ExplorationMap) -> Shape:
	_prepare()
	var corners := HexMapView.HEX_CORNERS
	var shape := Shape.new()
	var outline := PackedVector2Array()
	var edge_start: Array[Vector2] = []
	var edge_end: Array[Vector2] = []
	edge_start.assign(corners)
	edge_end.resize(6)
	for k: int in 6:
		edge_end[k] = corners[(k + 1) % 6]
	for k: int in 6:
		var corner := corners[k]
		var to_previous := (corners[(k + 5) % 6] - corner).normalized()
		var to_next := (corners[(k + 1) % 6] - corner).normalized()
		var before_coord := tile.coord + HexGrounds.EDGE_NEIGHBORS[(k + 5) % 6]
		var after_coord := tile.coord + HexGrounds.EDGE_NEIGHBORS[k]
		var role := _role(tile, map.tile_at(before_coord), map.tile_at(after_coord))
		if role == CUT:
			var cut_arc := _arc(corner, to_previous, to_next)
			outline.append_array(cut_arc)
			edge_end[(k + 5) % 6] = cut_arc[0]
			edge_start[k] = cut_arc[cut_arc.size() - 1]
			var cut_center := _center(corner, to_previous, to_next)
			for index: int in cut_arc.size() - 1:
				var owner := before_coord if index * 2 < STEPS else after_coord
				_add_segment(shape, cut_arc[index], cut_arc[index + 1], cut_center, false, owner)
			continue
		outline.append(corner)
		if role == PLAIN:
			continue
		var shared := to_next if role == FILL_AFTER else to_previous
		var split := -to_previous if role == FILL_AFTER else -to_next
		var odd_coord := after_coord if role == FILL_AFTER else before_coord
		var third := _third_edges[k]
		var arc := _arc(corner, shared, third)
		var center := _center(corner, shared, third)
		var piece := _piece(corner, arc, split)
		if role == FILL_AFTER:
			edge_start[k] = arc[0]
		else:
			edge_end[(k + 5) % 6] = arc[0]
		for index: int in range(1, piece.size() - 1):
			shape.triangles.append_array(PackedVector2Array([corner, piece[index], piece[index + 1]]))
		for index: int in range(1, piece.size() - 1):
			_add_segment(shape, piece[index], piece[index + 1], center, true, odd_coord)
		var partner_coord := before_coord if role == FILL_AFTER else after_coord
		var cut := Segment.new()
		cut.from = corner
		cut.to = piece[piece.size() - 1]
		cut.normal = Vector2(split.y, -split.x)
		if cut.normal.dot(arc[0] - corner) > 0.0:
			cut.normal = -cut.normal
		cut.owner = partner_coord
		shape.segments.append(cut)
	var middle := HexMapView.SURFACE_CENTER
	for index: int in outline.size():
		shape.triangles.append_array(PackedVector2Array([middle, outline[index], outline[(index + 1) % outline.size()]]))
	for edge: int in 6:
		var segment := Segment.new()
		segment.from = edge_start[edge]
		segment.to = edge_end[edge]
		var direction := segment.to - segment.from
		segment.normal = Vector2(direction.y, -direction.x).normalized()
		segment.owner = tile.coord + HexGrounds.EDGE_NEIGHBORS[edge]
		segment.edge = edge
		shape.segments.append(segment)
	return shape


## Quem é diferente num canto: primeiro pela altura e, com as três iguais, pelo bioma.
static func _role(tile: HexTile, before: HexTile, after: HexTile) -> int:
	var keys: Array = [tile.height, _height_of(before), _height_of(after)]
	if keys[0] == keys[1] and keys[1] == keys[2]:
		keys = [tile.biome, before.biome, after.biome]
	if keys[1] == keys[2] and keys[0] != keys[1]:
		return CUT
	if keys[0] == keys[1] and keys[2] != keys[0]:
		return FILL_AFTER
	if keys[0] == keys[2] and keys[1] != keys[0]:
		return FILL_BEFORE
	if keys[0] is String:
		return PLAIN
	var highest: int = keys.max()
	if keys[0] == highest:
		return CUT
	return FILL_BEFORE if keys[1] == highest else FILL_AFTER


static func _height_of(tile: HexTile) -> int:
	return tile.height if tile != null else -1


static func _arc(corner: Vector2, first: Vector2, second: Vector2) -> PackedVector2Array:
	var half := absf(first.angle_to(second)) / 2.0
	var reach := RADIUS / tan(half)
	var center := _center(corner, first, second)
	var from := corner + first * reach - center
	var to := corner + second * reach - center
	var sweep := from.angle_to(to)
	var points := PackedVector2Array()
	for step: int in STEPS + 1:
		points.append(center + from.rotated(sweep * step / STEPS))
	return points


static func _center(corner: Vector2, first: Vector2, second: Vector2) -> Vector2:
	var half := absf(first.angle_to(second)) / 2.0
	return corner + (first + second).normalized() * RADIUS / sin(half)


## O pedaço do arco do lado deste hexágono, até a reta que continua o lado entre ele e
## o parceiro: o canto, os pontos do arco e o ponto onde o arco cruza a reta.
static func _piece(corner: Vector2, arc: PackedVector2Array, split: Vector2) -> PackedVector2Array:
	var piece := PackedVector2Array([corner, arc[0]])
	var first_side := signf(split.cross(arc[0] - corner))
	for index: int in range(1, arc.size()):
		var side := split.cross(arc[index] - corner)
		if signf(side) != first_side:
			var previous := split.cross(arc[index - 1] - corner)
			piece.append(arc[index - 1].lerp(arc[index], previous / (previous - side)))
			return piece
		piece.append(arc[index])
	return piece


static func _add_segment(shape: Shape, from: Vector2, to: Vector2, center: Vector2, toward_center: bool, owner: Vector2i) -> void:
	var segment := Segment.new()
	segment.from = from
	segment.to = to
	var middle := (from + to) / 2.0
	segment.normal = (center - middle).normalized() if toward_center else (middle - center).normalized()
	segment.owner = owner
	shape.segments.append(segment)


static func _prepare() -> void:
	if not _third_edges.is_empty():
		return
	var corners := HexMapView.HEX_CORNERS
	for k: int in 6:
		var corner := corners[k]
		var shift := HexMapView._tile_origin(HexGrounds.EDGE_NEIGHBORS[(k + 5) % 6])
		var local := corner - shift
		var third := Vector2.ZERO
		for j: int in 6:
			if corners[j].is_equal_approx(local):
				for other: int in [(j + 5) % 6, (j + 1) % 6]:
					var end: Vector2 = corners[other] + shift
					if not end.is_equal_approx(corners[(k + 5) % 6]):
						third = (end - corner).normalized()
		_third_edges.append(third)
