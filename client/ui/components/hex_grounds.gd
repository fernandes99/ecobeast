class_name HexGrounds
extends RefCounted
## Trilhas e pisos sobre o terreno das ilhas (.specs/island-villages/02-grounds.md).
## A trilha é uma faixa do centro até cada lado ligado, com o canto cheio entre dois
## lados ligados vizinhos; o piso cobre o hexágono. Dois hexágonos com chão se ligam
## em qualquer altura: com paredão, a faixa desce por ele; sem, a ponta se entorta
## para encontrar a do vizinho na tela.

const TEXTURE_PATH := "res://assets/terrain/grounds/%s.png"
const TRAIL := "trail"
const FLOOR := "floor"
const SHADER_PATH := "res://ui/components/hex_grounds.gdshader"
const TRAIL_CODE := 1
const FLOOR_CODE := 2
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


## Dois hexágonos com chão sempre se ligam, em qualquer altura.
static func linked(tile: HexTile, map: ExplorationMap, edge: int) -> bool:
	var neighbor := map.tile_at(tile.coord + EDGE_NEIGHBORS[edge])
	return neighbor != null and not neighbor.ground.is_empty()


## Se a divisa com o vizinho aparece inteira: na mesma altura, ou com o paredão do
## mais alto, que fica atrás, descendo até o mais baixo. Nos outros lados, o degrau
## não tem paredão desenhado, e o piso guarda a borda para marcá-lo.
static func seamless(tile: HexTile, map: ExplorationMap, edge: int) -> bool:
	var offset := EDGE_NEIGHBORS[edge]
	var neighbor := map.tile_at(tile.coord + offset)
	if neighbor.height == tile.height:
		return true
	if tile.height > neighbor.height:
		return HexMapView.LOWER_NEIGHBORS.has(offset)
	return HexMapView.LOWER_NEIGHBORS.has(-offset)


## Quanto a ponta do braço de um lado desce (positivo) ou sobe, em pixels, para
## encontrar a do vizinho na tela, nos lados sem paredão. Num lado de baixo com o
## vizinho mais alto, ele cobre a divisa, e a ponta sobe até o lado de cima dele. Nos
## lados retos (1 e 4), as duas pontas se encontram no meio do degrau.
static func arm_shift(tile: HexTile, map: ExplorationMap, edge: int) -> float:
	var neighbor := map.tile_at(tile.coord + EDGE_NEIGHBORS[edge])
	if neighbor == null or neighbor.ground.is_empty():
		return 0.0
	var step := HexMapView.LEVEL_HEIGHTS[tile.height] - HexMapView.LEVEL_HEIGHTS[neighbor.height]
	match edge:
		1, 4:
			return step / 2.0
		2, 3:
			return minf(step, 0.0)
	return 0.0


## Os triângulos de chão de uma textura. A forma da trilha e a borda saem do shader
## (`SHADER_PATH`), por dois dados de cada vértice. CUSTOM0: o ponto no hexágono, a
## partir do centro; os lados abertos (no piso, mais 6 bits para os ligados a uma
## trilha); e o tipo. CUSTOM1: o `arm_shift` dos lados 1 a 4.
class Batch:
	extends RefCounted
	var points := PackedVector2Array()
	var texture_points := PackedVector2Array()
	var colors := PackedColorArray()
	var custom := PackedFloat32Array()
	var shifts := PackedFloat32Array()

	func vertex(point: Vector2, shift: Vector2, color: Color, local: Vector2, links: int, kind: int, arms: PackedFloat32Array) -> void:
		points.append(point)
		texture_points.append(point + shift)
		colors.append(color)
		custom.append_array(PackedFloat32Array([local.x, local.y, links, kind]))
		shifts.append_array(arms)


## `raised` é o canto do hexágono na tela, já na altura; `flat` é o mesmo canto sem a
## altura, para o ponto da textura. `face_heights` tem, para os dois lados de baixo, a
## altura do paredão (0 sem paredão).
static func add_tile(mesh: Batch, tile: HexTile, map: ExplorationMap, raised: Vector2, flat: Vector2, face_heights: Dictionary[int, float]) -> void:
	var shift := flat - raised
	var kind := FLOOR_CODE if kind_of(tile.ground) == FLOOR else TRAIL_CODE
	var links := 0
	for edge: int in 6:
		if not linked(tile, map, edge):
			continue
		if kind == TRAIL_CODE or seamless(tile, map, edge):
			links |= 1 << edge
		if kind == FLOOR_CODE and kind_of(map.tile_at(tile.coord + EDGE_NEIGHBORS[edge]).ground) == TRAIL:
			links |= 1 << (edge + 6)
	var arms := PackedFloat32Array()
	for edge: int in range(1, 5):
		arms.append(arm_shift(tile, map, edge))
	var center := raised + HexMapView.SURFACE_CENTER
	var white := Color.WHITE
	for edge: int in 6:
		var a := raised + HexMapView.HEX_CORNERS[edge]
		var b := raised + HexMapView.HEX_CORNERS[(edge + 1) % 6]
		mesh.vertex(center, shift, white, Vector2.ZERO, links, kind, arms)
		mesh.vertex(a, shift, white, a - center, links, kind, arms)
		mesh.vertex(b, shift, white, b - center, links, kind, arms)
	for edge: int in face_heights:
		if face_heights[edge] > 0.0 and linked(tile, map, edge):
			_add_face(mesh, raised, center, edge, face_heights[edge], shift, links, kind, arms)


## O paredão do lado de baixo repete, em cada coluna, o ponto do lado em cima dela:
## a trilha desce reta até o pé, com a sombra do lado.
static func _add_face(mesh: Batch, raised: Vector2, center: Vector2, edge: int, height: float, shift: Vector2, links: int, kind: int, arms: PackedFloat32Array) -> void:
	var a := raised + HexMapView.HEX_CORNERS[edge]
	var b := raised + HexMapView.HEX_CORNERS[(edge + 1) % 6]
	var shade: Color = HexMapView.FACE_COLORS[HexMapView.LOWER_NEIGHBORS.find(EDGE_NEIGHBORS[edge])]
	var down := Vector2(0.0, height)
	for corner: Array in [[a, a], [b, b], [b + down, b], [a, a], [b + down, b], [a + down, a]]:
		mesh.vertex(corner[0], shift, shade, corner[1] - center, links, kind, arms)
