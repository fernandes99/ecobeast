class_name HexGrounds
extends RefCounted
## O chão das ilhas: trilhas e pisos por hexágono (.specs/island-villages/02-grounds.md)
## e traços livres (.specs/free-trails/). Tudo é desenhado na máscara (`GroundMask`):
## a trilha por hexágono é uma faixa do centro até cada lado com chão vizinho, com o
## canto cheio entre dois lados ligados vizinhos; o piso cobre o hexágono; o traço é
## uma linha pelos pontos suavizados. O shader lê a máscara e faz a borda e as emendas.

const TEXTURE_PATH := "res://assets/terrain/grounds/%s.png"
const TRAIL := "trail"
const FLOOR := "floor"
const SHADER_PATH := "res://ui/components/hex_grounds.gdshader"
const MASK_CODE := 3
const MAX_TYPES := 32
const TEXTURE_SIZE := 512
const SMOOTH_STEP := 6.0
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
static var _textures: Texture2DArray = null
static var _hardness := PackedFloat32Array()


static func kind_of(slug: String) -> String:
	if slug.is_empty():
		return ""
	if not _kinds.has(slug):
		for row: Dictionary in GameData.get_rows("ground_types"):
			_kinds[str(row.get("slug", ""))] = str(row.get("kind", TRAIL))
	return _kinds.get(slug, TRAIL)


static func allows_decoration(tile: HexTile, kind: String) -> bool:
	return allows_on(tile.ground, kind)


static func allows_on(ground: String, kind: String) -> bool:
	match kind_of(ground):
		"":
			return true
		FLOOR:
			return false
	return TRAIL_DECORATIONS.has(kind)


## O chão de cima num ponto do chão plano: o traço mais novo que o cobre ou, sem
## traço, o do hexágono.
static func ground_at(tile: HexTile, flat: Vector2, trails: Array[MapTrail]) -> String:
	for index: int in range(trails.size() - 1, -1, -1):
		var trail := trails[index]
		if GroundMask.trail_bounds(trail).has_point(flat) and trail_distance(trail, flat) <= trail.width / 2.0:
			return trail.ground
	return tile.ground


## Dois hexágonos com chão sempre se ligam, em qualquer altura.
static func linked(tile: HexTile, map: ExplorationMap, edge: int) -> bool:
	var neighbor := map.tile_at(tile.coord + EDGE_NEIGHBORS[edge])
	return neighbor != null and not neighbor.ground.is_empty()


## Se a divisa com o vizinho aparece inteira: na mesma altura, ou com o paredão do
## mais alto, que fica atrás, descendo até o mais baixo. Nos outros lados, o degrau
## não tem paredão desenhado, e o chão guarda a borda para marcá-lo.
static func seamless(tile: HexTile, map: ExplorationMap, edge: int) -> bool:
	var offset := EDGE_NEIGHBORS[edge]
	var neighbor := map.tile_at(tile.coord + offset)
	if neighbor == null or neighbor.height == tile.height:
		return true
	if tile.height > neighbor.height:
		return HexMapView.LOWER_NEIGHBORS.has(offset)
	return HexMapView.LOWER_NEIGHBORS.has(-offset)


## A textura de cada tipo na camada do id dele; a camada sem tipo é transparente.
static func texture_array() -> Texture2DArray:
	if _textures != null:
		return _textures
	var rows := GameData.get_rows("ground_types")
	var top := 0
	for row: Dictionary in rows:
		top = maxi(top, int(row.get("id", 0)))
	var images: Array[Image] = []
	for _layer: int in mini(top + 1, MAX_TYPES):
		images.append(Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8))
	for row: Dictionary in rows:
		var id := int(row.get("id", 0))
		var path := TEXTURE_PATH % str(row.get("slug", ""))
		if id <= 0 or id >= images.size() or not ResourceLoader.exists(path):
			continue
		var image := (load(path) as Texture2D).get_image()
		if image.is_compressed():
			image.decompress()
		image.clear_mipmaps()
		image.convert(Image.FORMAT_RGBA8)
		if image.get_size() != Vector2i(TEXTURE_SIZE, TEXTURE_SIZE):
			image.resize(TEXTURE_SIZE, TEXTURE_SIZE, Image.INTERPOLATE_NEAREST)
		images[id] = image
	_textures = Texture2DArray.new()
	_textures.create_from_images(images)
	return _textures


static func hardness() -> PackedFloat32Array:
	if _hardness.is_empty():
		_hardness.resize(MAX_TYPES)
		for row: Dictionary in GameData.get_rows("ground_types"):
			var id := int(row.get("id", 0))
			if id > 0 and id < MAX_TYPES:
				_hardness[id] = float(row.get("hardness", 1))
	return _hardness


static func _edge_middle(edge: int) -> Vector2:
	return (HexMapView.HEX_CORNERS[edge] + HexMapView.HEX_CORNERS[(edge + 1) % 6]) / 2.0 - HexMapView.SURFACE_CENTER


static func draw_trail_tile(canvas: CanvasItem, tile: HexTile, map: ExplorationMap, color: Color) -> void:
	var center := HexMapView.flat_center(tile.coord)
	var half := GroundMask.TRAIL_WIDTH / 2.0
	canvas.draw_circle(center, half, color)
	for edge: int in 6:
		if not linked(tile, map, edge):
			continue
		canvas.draw_line(center, center + _edge_middle(edge), color, GroundMask.TRAIL_WIDTH)
		var next := (edge + 1) % 6
		if linked(tile, map, next):
			var corner := HexMapView.HEX_CORNERS[next] - HexMapView.SURFACE_CENTER
			canvas.draw_colored_polygon(PackedVector2Array([center, center + _edge_middle(edge), center + corner, center + _edge_middle(next)]), color)


static func draw_floor_tile(canvas: CanvasItem, tile: HexTile, color: Color) -> void:
	var origin := HexMapView.flat_center(tile.coord) - HexMapView.SURFACE_CENTER
	var corners := PackedVector2Array()
	for corner: Vector2 in HexMapView.HEX_CORNERS:
		corners.append(origin + corner)
	canvas.draw_colored_polygon(corners, color)


static func draw_trail(canvas: CanvasItem, trail: MapTrail, color: Color) -> void:
	var points := smoothed(trail)
	var half := trail.width / 2.0
	for index: int in points.size():
		canvas.draw_circle(points[index], half, color)
		if index > 0:
			canvas.draw_line(points[index - 1], points[index], color, trail.width)


## Os pontos do traço por uma curva de Catmull-Rom, um a cada `SMOOTH_STEP` pixels.
static func smoothed(trail: MapTrail) -> PackedVector2Array:
	if not trail.smoothed.is_empty():
		return trail.smoothed
	var points := trail.points
	var out := PackedVector2Array()
	for index: int in points.size() - 1:
		var p0 := points[maxi(index - 1, 0)]
		var p1 := points[index]
		var p2 := points[index + 1]
		var p3 := points[mini(index + 2, points.size() - 1)]
		var steps := maxi(1, ceili(p1.distance_to(p2) / SMOOTH_STEP))
		for step: int in steps:
			var t := float(step) / steps
			out.append(0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t))
	out.append(points[points.size() - 1])
	trail.smoothed = out
	return out


static func trail_distance(trail: MapTrail, point: Vector2) -> float:
	var points := smoothed(trail)
	var best := INF
	for index: int in points.size():
		if index == 0:
			best = point.distance_to(points[0])
			continue
		var closest := Geometry2D.get_closest_point_to_segment(point, points[index - 1], points[index])
		best = minf(best, point.distance_to(closest))
	return best


## Os triângulos da malha de chão, uma por página. O shader lê a máscara pelo ponto
## plano: CUSTOM0 é o ponto a partir da origem da página, os lados com degrau sem
## paredão e o código; CUSTOM1 é o centro plano do hexágono na página e a página.
class Batch:
	extends RefCounted
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var custom := PackedFloat32Array()
	var extra := PackedFloat32Array()

	func vertex(point: Vector2, color: Color, local: Vector2, steps: int, center: Vector2, page: Vector2i) -> void:
		points.append(point)
		colors.append(color)
		custom.append_array(PackedFloat32Array([local.x, local.y, steps, MASK_CODE]))
		extra.append_array(PackedFloat32Array([center.x, center.y, page.x, page.y]))


## `raised` é o canto do hexágono na tela, já na altura; `flat` é o mesmo canto sem a
## altura. `face_heights` tem, para os dois lados de baixo, a altura do paredão.
static func add_tile(mesh: Batch, tile: HexTile, map: ExplorationMap, raised: Vector2, flat: Vector2, face_heights: Dictionary[int, float], page: Vector2i) -> void:
	var origin := GroundMask.page_origin(page)
	var steps := 0
	for edge: int in 6:
		if not seamless(tile, map, edge):
			steps |= 1 << edge
	var center := flat + HexMapView.SURFACE_CENTER - origin
	var raised_center := raised + HexMapView.SURFACE_CENTER
	var white := Color.WHITE
	for edge: int in 6:
		var a := HexMapView.HEX_CORNERS[edge]
		var b := HexMapView.HEX_CORNERS[(edge + 1) % 6]
		mesh.vertex(raised_center, white, center, steps, center, page)
		mesh.vertex(raised + a, white, flat + a - origin, steps, center, page)
		mesh.vertex(raised + b, white, flat + b - origin, steps, center, page)
	for edge: int in face_heights:
		if face_heights[edge] <= 0.0 or not linked(tile, map, edge):
			continue
		var a := HexMapView.HEX_CORNERS[edge]
		var b := HexMapView.HEX_CORNERS[(edge + 1) % 6]
		var shade: Color = HexMapView.FACE_COLORS[HexMapView.LOWER_NEIGHBORS.find(EDGE_NEIGHBORS[edge])]
		var down := Vector2(0.0, face_heights[edge])
		for corner: Array in [[a, a], [b, b], [b + down, b], [a, a], [b + down, b], [a + down, a]]:
			mesh.vertex(raised + corner[0], shade, flat + (corner[1] as Vector2) - origin, 0, center, page)
