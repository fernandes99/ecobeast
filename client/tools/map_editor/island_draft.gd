class_name IslandDraft
extends RefCounted
## O rascunho de uma ilha no editor (map-editor/02): o terreno, a chegada, as
## construções e as áreas, no formato do contrato de `/v1/editor`
## (.specs/map-editor/architecture.md, "O rascunho").

const MAX_TILES := 20000
const BLANK_BIOME := "temperate"
const BLANK_SHAPE := "flat"

## 0 enquanto a ilha não foi criada no servidor.
var id := 0
var name := ""
var start := Vector2i.ZERO
var tiles: Dictionary[Vector2i, HexTile] = {}
## A `key` da área de cada hexágono que tem área.
var tile_areas: Dictionary[Vector2i, int] = {}
## As construções e as áreas como o contrato as descreve. A fase 04 as edita;
## até lá, o editor as guarda e devolve sem mexer.
var buildings: Array = []
var areas: Array = []


## A variante sorteada como o gerador faz: no plano, `detail_chance` escolhe entre
## 4 e 6 e o resto entre 1 e 3; nas outras formas, entre 1 e 3.
static func roll_variant(shape: String, detail_chance: float, rng: RandomNumberGenerator) -> int:
	if shape == BLANK_SHAPE and rng.randf() < detail_chance:
		return rng.randi_range(4, 6)
	return rng.randi_range(1, 3)


## Uma ilha nova: um hexágono de raio `radius` em volta de (0, 0), todo planície
## plana, com a chegada no centro.
static func blank(island_name: String, radius: int, detail_chance: float, rng: RandomNumberGenerator) -> IslandDraft:
	var draft := IslandDraft.new()
	draft.name = island_name
	for q: int in range(-radius, radius + 1):
		for r: int in range(maxi(-radius, -q - radius), mini(radius, -q + radius) + 1):
			var tile := HexTile.new()
			tile.coord = Vector2i(q, r)
			tile.biome = BLANK_BIOME
			tile.shape = BLANK_SHAPE
			tile.variant = roll_variant(BLANK_SHAPE, detail_chance, rng)
			draft.tiles[tile.coord] = tile
	return draft


## Uma ilha nova com o que o gerador devolveu (`{start, tiles}`).
static func generated(island_name: String, data: Dictionary) -> IslandDraft:
	var draft := IslandDraft.new()
	draft.name = island_name
	draft._read_terrain(data)
	return draft


## O rascunho como o servidor manda em `GET /v1/editor/islands/:id`.
static func from_dict(data: Dictionary) -> IslandDraft:
	var draft := IslandDraft.new()
	draft.id = DictFields.get_int(data, "id")
	draft.name = DictFields.get_string(data, "name")
	draft._read_terrain(data)
	draft.buildings = DictFields.get_array(data, "buildings").duplicate(true)
	draft.areas = DictFields.get_array(data, "areas").duplicate(true)
	return draft


## O corpo de criar e de salvar.
func to_dict() -> Dictionary:
	var tile_list: Array[Dictionary] = []
	for tile: HexTile in tiles.values():
		var entry := {"q": tile.coord.x, "r": tile.coord.y, "biome": tile.biome, "shape": tile.shape, "variant": tile.variant}
		if tile_areas.has(tile.coord):
			entry["area"] = tile_areas[tile.coord]
		tile_list.append(entry)
	return {
		"name": name,
		"start": {"q": start.x, "r": start.y},
		"tiles": tile_list,
		"buildings": buildings,
		"areas": areas,
	}


## O terreno como o `HexMapView` desenha. A seed só escolhe os escorridos dos
## paredões; com o id, cada ilha fica sempre igual.
func to_map() -> ExplorationMap:
	var map := ExplorationMap.new()
	map.map_seed = id
	map.start = start
	map.tiles = tiles
	return map


func _read_terrain(data: Dictionary) -> void:
	var start_dict := DictFields.get_dict(data, "start")
	start = Vector2i(DictFields.get_int(start_dict, "q"), DictFields.get_int(start_dict, "r"))
	for tile_dict: Variant in DictFields.get_array(data, "tiles"):
		if not tile_dict is Dictionary:
			continue
		var tile := HexTile.from_dict(tile_dict)
		if tile == null:
			continue
		tiles[tile.coord] = tile
		if (tile_dict as Dictionary).has("area"):
			tile_areas[tile.coord] = DictFields.get_int(tile_dict, "area")
