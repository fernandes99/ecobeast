class_name HexGrounds
extends RefCounted
## Trilhas e pisos sobre o terreno das ilhas (.specs/island-villages/02-grounds.md).
## A trilha é uma faixa do centro até cada lado ligado; o piso cobre o hexágono. Dois
## hexágonos com chão se ligam na mesma altura, ou por um lado de baixo do mais alto,
## onde há paredão.

const TEXTURE_PATH := "res://assets/terrain/grounds/%s.png"
const TRAIL := "trail"
const FLOOR := "floor"
const HALF_WIDTH := 11.0
const FRINGE := 3.0
const DISC_SIDES := 16
const BORDER_WIDTH := 2.0
const BORDER_COLOR := Color(0.6, 0.54, 0.48)
const TRAIL_DECORATIONS: Array[String] = ["tuft", "dry_tuft", "flowers", "pebbles", "moss"]
## Os lados na ordem dos cantos de HexMapView.HEX_CORNERS: o lado i vai do canto i
## ao canto i + 1.
const EDGE_NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1),
]

static var _kinds: Dictionary[String, String] = {}


static func kind_of(slug: String) -> String:
	if slug.is_empty():
		return ""
	if not _kinds.has(slug):
		for row: Dictionary in GameData.get_rows("ground_types"):
			_kinds[str(row.get("slug", ""))] = str(row.get("kind", TRAIL))
	return _kinds.get(slug, TRAIL)


static func allows_decoration(tile: HexTile, kind: String) -> bool:
	match kind_of(tile.ground):
		"":
			return true
		FLOOR:
			return false
	return TRAIL_DECORATIONS.has(kind)


static func linked(tile: HexTile, map: ExplorationMap, edge: int) -> bool:
	var offset := EDGE_NEIGHBORS[edge]
	var neighbor := map.tile_at(tile.coord + offset)
	if neighbor == null or neighbor.ground.is_empty():
		return false
	if neighbor.height == tile.height:
		return true
	if tile.height > neighbor.height:
		return HexMapView.LOWER_NEIGHBORS.has(offset)
	return HexMapView.LOWER_NEIGHBORS.has(-offset)


static func edge_middle(edge: int) -> Vector2:
	return (HexMapView.HEX_CORNERS[edge] + HexMapView.HEX_CORNERS[(edge + 1) % 6]) / 2.0


## Os triângulos de chão de uma textura, com a cor de cada vértice.
class Batch:
	extends RefCounted
	var points := PackedVector2Array()
	var texture_points := PackedVector2Array()
	var colors := PackedColorArray()

	func triangle(a: Vector2, b: Vector2, c: Vector2, shift: Vector2, ca: Color, cb: Color, cc: Color) -> void:
		points.append_array(PackedVector2Array([a, b, c]))
		texture_points.append_array(PackedVector2Array([a + shift, b + shift, c + shift]))
		colors.append_array(PackedColorArray([ca, cb, cc]))

	func quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, shift: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
		triangle(a, b, c, shift, ca, cb, cc)
		triangle(a, c, d, shift, ca, cc, cd)


## `raised` é o canto do hexágono na tela, já na altura; `flat` é o mesmo canto sem a
## altura, para o ponto da textura. `face_heights` tem, para os dois lados de baixo, a
## altura do paredão (0 sem paredão).
static func add_tile(mesh: Batch, tile: HexTile, map: ExplorationMap, raised: Vector2, flat: Vector2, face_heights: Dictionary[int, float]) -> void:
	var shift := flat - raised
	var kind := kind_of(tile.ground)
	var center := raised + HexMapView.SURFACE_CENTER
	if kind == FLOOR:
		_add_floor(mesh, tile, map, raised, center, shift)
	else:
		_add_trail(mesh, tile, map, raised, center, shift)
	for edge: int in face_heights:
		if face_heights[edge] > 0.0 and linked(tile, map, edge):
			_add_face_strip(mesh, raised, edge, face_heights[edge], shift, kind == FLOOR)


static func _add_floor(mesh: Batch, tile: HexTile, map: ExplorationMap, raised: Vector2, center: Vector2, shift: Vector2) -> void:
	var white := Color.WHITE
	for edge: int in 6:
		var a := raised + HexMapView.HEX_CORNERS[edge]
		var b := raised + HexMapView.HEX_CORNERS[(edge + 1) % 6]
		mesh.triangle(center, a, b, shift, white, white, white)
	for edge: int in 6:
		if linked(tile, map, edge):
			continue
		var a := raised + HexMapView.HEX_CORNERS[edge]
		var b := raised + HexMapView.HEX_CORNERS[(edge + 1) % 6]
		var inner_a := a + (center - a).normalized() * BORDER_WIDTH
		var inner_b := b + (center - b).normalized() * BORDER_WIDTH
		mesh.quad(a, b, inner_b, inner_a, shift, BORDER_COLOR, BORDER_COLOR, BORDER_COLOR, BORDER_COLOR)


static func _add_trail(mesh: Batch, tile: HexTile, map: ExplorationMap, raised: Vector2, center: Vector2, shift: Vector2) -> void:
	var solid := Color.WHITE
	var clear := Color(1.0, 1.0, 1.0, 0.0)
	var core := HALF_WIDTH - FRINGE
	for side: int in DISC_SIDES:
		var a := Vector2.from_angle(TAU * side / DISC_SIDES)
		var b := Vector2.from_angle(TAU * (side + 1) / DISC_SIDES)
		mesh.triangle(center, center + a * core, center + b * core, shift, solid, solid, solid)
		mesh.quad(center + a * core, center + b * core, center + b * HALF_WIDTH, center + a * HALF_WIDTH, shift, solid, solid, clear, clear)
	for edge: int in 6:
		if not linked(tile, map, edge):
			continue
		var end := raised + edge_middle(edge)
		var along := (end - center).normalized()
		var across := Vector2(-along.y, along.x)
		mesh.quad(center + across * core, end + across * core, end - across * core, center - across * core, shift, solid, solid, solid, solid)
		for side: float in [1.0, -1.0]:
			var inner := across * core * side
			var outer := across * HALF_WIDTH * side
			mesh.quad(center + inner, end + inner, end + outer, center + outer, shift, solid, solid, clear, clear)


## A faixa desce pelo paredão do lado de baixo até o pé dele, com a sombra do lado.
static func _add_face_strip(mesh: Batch, raised: Vector2, edge: int, height: float, shift: Vector2, whole: bool) -> void:
	var a := raised + HexMapView.HEX_CORNERS[edge]
	var b := raised + HexMapView.HEX_CORNERS[(edge + 1) % 6]
	var shade: Color = HexMapView.FACE_COLORS[HexMapView.LOWER_NEIGHBORS.find(EDGE_NEIGHBORS[edge])]
	var down := Vector2(0.0, height)
	if whole:
		mesh.quad(a, b, b + down, a + down, shift, shade, shade, shade, shade)
		return
	var middle := (a + b) / 2.0
	var along := (b - a).normalized()
	var core := HALF_WIDTH - FRINGE
	var clear := Color(shade, 0.0)
	mesh.quad(middle - along * core, middle + along * core, middle + along * core + down, middle - along * core + down, shift, shade, shade, shade, shade)
	for side: float in [1.0, -1.0]:
		var inner := along * core * side
		var outer := along * HALF_WIDTH * side
		mesh.quad(middle + inner, middle + outer, middle + outer + down, middle + inner + down, shift, shade, clear, clear, shade)
