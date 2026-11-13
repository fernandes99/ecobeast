class_name HexFences
extends RefCounted
## A Cerca que se liga sozinha (.specs/island-villages/05-connected-fences.md): um
## poste no centro e um braço até o meio de cada lado cujo vizinho, na mesma altura,
## também tem cerca. Sozinha, ela tem os braços da esquerda e da direita. A Cerca da
## cidade (town-art/03) é montada do mesmo jeito, com a folha de peças dela.

const SLUG := "fence"
const PARTS_PATH := "res://assets/map_objects/fence/parts_%d.png"
const TOWN_PARTS_PATH := "res://assets/map_objects/town_fence/parts_%d.png"
const PARTS_PATHS := {SLUG: PARTS_PATH, "town_fence": TOWN_PARTS_PATH}
const CELL_SIZE := Vector2i(96, 72)
const CELL_CENTER := Vector2(48.0, 43.0)
## Os lados na ordem de HexGrounds.EDGE_NEIGHBORS, sem depender dela: ela usa o
## GameData, que o make_objects.gd não tem.
const EDGE_NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1),
]
## O meio de cada lado, a partir do centro.
const EDGE_MIDPOINTS: Array[Vector2] = [
	Vector2(16.0, -21.0),
	Vector2(32.0, 0.0),
	Vector2(16.0, 21.0),
	Vector2(-16.0, 21.0),
	Vector2(-32.0, 0.0),
	Vector2(-16.0, -21.0),
]
const STRAIGHT := (1 << 1) | (1 << 4)
const DRAW_ORDER: Array[int] = [5, 0, 4, 1, 3, 2]

static var _cells: Dictionary[String, Array] = {}
static var _textures: Dictionary[String, Texture2D] = {}


static func is_fence(slug: String) -> bool:
	return PARTS_PATHS.has(slug)


## Os lados ligados, um bit por lado: o vizinho tem um objeto do mesmo tipo e a mesma altura.
static func links(map: ExplorationMap, coord: Vector2i, type_id: int) -> int:
	var tile := map.tile_at(coord)
	if tile == null:
		return 0
	var mask := 0
	for edge: int in EDGE_NEIGHBORS.size():
		var side := coord + EDGE_NEIGHBORS[edge]
		var neighbor := map.tile_at(side)
		var index := map.object_at(side)
		if neighbor != null and neighbor.height == tile.height and index >= 0 and map.objects[index].object_type_id == type_id:
			mask |= 1 << edge
	return mask


## Junta as células: os braços de trás, os dos lados, os da frente e o poste por cima.
static func compose(cells: Array[Image], mask: int) -> Image:
	var drawn := mask if mask != 0 else STRAIGHT
	var image := Image.create(CELL_SIZE.x, CELL_SIZE.y, false, Image.FORMAT_RGBA8)
	var whole := Rect2i(Vector2i.ZERO, CELL_SIZE)
	for edge: int in DRAW_ORDER:
		if drawn & (1 << edge):
			image.blend_rect(cells[edge + 1], whole, Vector2i.ZERO)
	image.blend_rect(cells[0], whole, Vector2i.ZERO)
	return image


## A arte montada de uma cerca, variante e combinação de lados, ou `null` sem a folha.
static func texture(slug: String, variant: int, mask: int) -> Texture2D:
	var key := "%s/%d/%d" % [slug, variant, mask]
	if _textures.has(key):
		return _textures[key]
	var cells := _cells_of(slug, variant)
	if cells.is_empty():
		return null
	var art := ImageTexture.create_from_image(compose(cells, mask))
	_textures[key] = art
	return art


static func _cells_of(slug: String, variant: int) -> Array[Image]:
	var result: Array[Image] = []
	var key := "%s/%d" % [slug, variant]
	if _cells.has(key):
		result.assign(_cells[key])
		return result
	for candidate: int in range(variant, 0, -1):
		var path: String = PARTS_PATHS.get(slug, PARTS_PATH) % candidate
		if not ResourceLoader.exists(path):
			continue
		var sheet := (load(path) as Texture2D).get_image()
		if sheet.is_compressed():
			sheet.decompress()
		sheet.convert(Image.FORMAT_RGBA8)
		for index: int in 7:
			result.append(sheet.get_region(Rect2i(Vector2i(CELL_SIZE.x * index, 0), CELL_SIZE)))
		break
	_cells[key] = result
	return result
