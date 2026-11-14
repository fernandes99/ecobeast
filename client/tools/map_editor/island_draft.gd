class_name IslandDraft
extends RefCounted

const MAX_TILES := 20000
const BLANK_BIOME := "temperate"
const BLANK_HEIGHT := 1
const FEW_VARIANT_BIOMES: Array[String] = ["hill", "mountain"]

var id := 0
var name := ""
var start := Vector2i.ZERO
var tiles: Dictionary[Vector2i, HexTile] = {}
var tile_areas: Dictionary[Vector2i, int] = {}
var actions: Array = []
var objects: Array = []
## As peças soltas (free-props/03), como o servidor manda: `prop_type_id`, `q`, `r`, `dx`,
## `dy`, `variant` e `mirrored`.
var props: Array = []
var areas: Array = []


static func max_variant(biome: String) -> int:
	return 3 if FEW_VARIANT_BIOMES.has(biome) else 6


static func roll_variant(biome: String, detail_chance: float, rng: RandomNumberGenerator) -> int:
	if max_variant(biome) > 3 and rng.randf() < detail_chance:
		return rng.randi_range(4, 6)
	return rng.randi_range(1, 3)


static func blank(island_name: String, radius: int, detail_chance: float, rng: RandomNumberGenerator) -> IslandDraft:
	var draft := IslandDraft.new()
	draft.name = island_name
	for q: int in range(-radius, radius + 1):
		for r: int in range(maxi(-radius, -q - radius), mini(radius, -q + radius) + 1):
			var tile := HexTile.new()
			tile.coord = Vector2i(q, r)
			tile.biome = BLANK_BIOME
			tile.height = BLANK_HEIGHT
			tile.variant = roll_variant(BLANK_BIOME, detail_chance, rng)
			draft.tiles[tile.coord] = tile
	return draft


static func generated(island_name: String, data: Dictionary) -> IslandDraft:
	var draft := IslandDraft.new()
	draft.name = island_name
	draft._read_terrain(data)
	return draft


static func from_dict(data: Dictionary) -> IslandDraft:
	var draft := IslandDraft.new()
	draft.id = DictFields.get_int(data, "id")
	draft.name = DictFields.get_string(data, "name")
	draft._read_terrain(data)
	draft.actions = DictFields.get_array(data, "actions").duplicate(true)
	draft.objects = DictFields.get_array(data, "objects").duplicate(true)
	draft.props = DictFields.get_array(data, "props").duplicate(true)
	draft.areas = DictFields.get_array(data, "areas").duplicate(true)
	return draft


func to_dict() -> Dictionary:
	var tile_list: Array[Dictionary] = []
	for tile: HexTile in tiles.values():
		var entry := {"q": tile.coord.x, "r": tile.coord.y, "biome": tile.biome, "height": tile.height, "variant": tile.variant}
		if not tile.ground.is_empty():
			entry["ground"] = tile.ground
		if tile.bare:
			entry["bare"] = true
		if tile_areas.has(tile.coord):
			entry["area"] = tile_areas[tile.coord]
		tile_list.append(entry)
	return {
		"name": name,
		"start": {"q": start.x, "r": start.y},
		"tiles": tile_list,
		"actions": actions,
		"objects": objects,
		"props": props,
		"areas": areas,
	}


## Um hexágono para o desfazer: `[bioma, altura, variante, área, chão, sem decoração]`,
## com área 0 e chão vazio quando ele não tem; vazio quando o hexágono não existe.
func snapshot(coord: Vector2i) -> Array:
	var tile: HexTile = tiles.get(coord)
	if tile == null:
		return []
	return [tile.biome, tile.height, tile.variant, tile_areas.get(coord, 0), tile.ground, tile.bare]


func restore(coord: Vector2i, state: Array) -> void:
	if state.is_empty():
		tiles.erase(coord)
		tile_areas.erase(coord)
		return
	var tile: HexTile = tiles.get(coord)
	if tile == null:
		tile = HexTile.new()
		tile.coord = coord
		tiles[coord] = tile
	tile.biome = state[0]
	tile.height = state[1]
	tile.variant = state[2]
	tile.ground = state[4]
	tile.bare = bool(state[5])
	if int(state[3]) > 0:
		tile_areas[coord] = int(state[3])
	else:
		tile_areas.erase(coord)


func add_tile(coord: Vector2i, biome: String, height: int, variant: int) -> bool:
	if tiles.has(coord) or tiles.size() >= MAX_TILES:
		return false
	var tile := HexTile.new()
	tile.coord = coord
	tile.biome = biome
	tile.height = height
	tile.variant = variant
	tiles[coord] = tile
	return true


func remove_tile(coord: Vector2i) -> bool:
	tiles.erase(coord)
	tile_areas.erase(coord)
	var changed := false
	for index: int in range(actions.size() - 1, -1, -1):
		var action: Dictionary = actions[index]
		var occupied: Array = action.get("tiles", [])
		for spot: int in range(occupied.size() - 1, -1, -1):
			var at: Dictionary = occupied[spot]
			if int(at.get("q", 0)) == coord.x and int(at.get("r", 0)) == coord.y:
				occupied.remove_at(spot)
				changed = true
		if occupied.is_empty():
			actions.remove_at(index)
	var holder := object_at(coord)
	if holder >= 0:
		objects.remove_at(holder)
		changed = true
	for index: int in range(props.size() - 1, -1, -1):
		if prop_coord(index) == coord:
			props.remove_at(index)
			changed = true
	return changed


func touches_actions(coords: Array[Vector2i]) -> bool:
	for action: Variant in actions:
		for at: Variant in (action as Dictionary).get("tiles", []):
			if coords.has(Vector2i(int(at.get("q", 0)), int(at.get("r", 0)))):
				return true
	return false


func action_at(coord: Vector2i) -> int:
	for index: int in actions.size():
		for at: Variant in (actions[index] as Dictionary).get("tiles", []):
			if int(at.get("q", 0)) == coord.x and int(at.get("r", 0)) == coord.y:
				return index
	return -1


func action_tiles(index: int) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	if index < 0 or index >= actions.size():
		return coords
	for at: Variant in (actions[index] as Dictionary).get("tiles", []):
		coords.append(Vector2i(int(at.get("q", 0)), int(at.get("r", 0))))
	return coords


func object_at(coord: Vector2i) -> int:
	for index: int in objects.size():
		if object_tiles(index).has(coord):
			return index
	return -1


func object_tiles(index: int) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	if index < 0 or index >= objects.size():
		return coords
	for at: Variant in (objects[index] as Dictionary).get("tiles", []):
		coords.append(Vector2i(int(at.get("q", 0)), int(at.get("r", 0))))
	return coords


## Se um objeto caberia nesses hexágonos: todos existem e nenhum é de outro objeto
## (menos o `ignore`, para espelhar um objeto no lugar).
func object_fits(coords: Array[Vector2i], ignore: int = -1) -> bool:
	for coord: Vector2i in coords:
		if not tiles.has(coord):
			return false
		var holder := object_at(coord)
		if holder >= 0 and holder != ignore:
			return false
	return true


func map_objects() -> Array[MapObject]:
	var list: Array[MapObject] = []
	for entry: Variant in objects:
		var object := MapObject.from_dict(entry as Dictionary)
		if object != null:
			list.append(object)
	return list


func map_props() -> Array[MapProp]:
	var list: Array[MapProp] = []
	for entry: Variant in props:
		var prop := MapProp.from_dict(entry as Dictionary)
		if prop != null:
			list.append(prop)
	return list


func prop_coord(index: int) -> Vector2i:
	var prop: Dictionary = props[index]
	return Vector2i(int(prop.get("q", 0)), int(prop.get("r", 0)))


## O pé da peça no chão plano, sem a altura.
func prop_foot(index: int) -> Vector2:
	var prop: Dictionary = props[index]
	return HexMapView.flat_center(prop_coord(index)) + Vector2(int(prop.get("dx", 0)), int(prop.get("dy", 0)))


## O pé da peça como ele aparece, na altura do hexágono dela.
func prop_art_foot(index: int) -> Vector2:
	return prop_foot(index) - Vector2(0.0, rise_at(prop_coord(index)))


func prop_rect(index: int) -> Rect2:
	var prop: Dictionary = props[index]
	var art := PropArt.rect(PropArt.slug_of(int(prop.get("prop_type_id", 0))), int(prop.get("variant", 1)))
	return Rect2(prop_art_foot(index) + art.position, art.size)


## A peça da frente cuja arte cobre `art_point` (com a altura), ou -1.
func prop_at(art_point: Vector2) -> int:
	var best := -1
	for index: int in props.size():
		if prop_rect(index).has_point(art_point) and (best < 0 or prop_foot(index).y >= prop_foot(best).y):
			best = index
	return best


func rise_at(coord: Vector2i) -> float:
	var tile: HexTile = tiles.get(coord)
	return HexMapView.LEVEL_HEIGHTS[tile.height] if tile != null else 0.0


func area_by_key(key: int) -> Dictionary:
	for area: Variant in areas:
		if int((area as Dictionary).get("key", 0)) == key:
			return area
	return {}


func next_area_key() -> int:
	var highest := 0
	for area: Variant in areas:
		highest = maxi(highest, int((area as Dictionary).get("key", 0)))
	return highest + 1


func area_tile_counts() -> Dictionary[int, int]:
	var counts: Dictionary[int, int] = {}
	for key: int in tile_areas.values():
		counts[key] = counts.get(key, 0) + 1
	return counts


## O terreno como o `HexMapView` desenha. A seed só escolhe os escorridos dos
## paredões; com o id, cada ilha fica sempre igual.
func to_map() -> ExplorationMap:
	var map := ExplorationMap.new()
	map.map_seed = id
	map.start = start
	map.tiles = tiles
	map.set_objects(map_objects())
	map.props = map_props()
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
