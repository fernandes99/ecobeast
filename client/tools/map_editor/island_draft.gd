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
## As peças soltas (free-props/03), como o servidor manda: `prop_type_id`, `q`, `r`, `dx`,
## `dy`, `variant` e `mirrored`.
var props: Array = []
var areas: Array = []
## Os NPCs (island-npcs/02), como o servidor manda: `npc_id`, `q`, `r`, `still`, `tiles`,
## `dialogue` e `action_type_id`.
var npcs: Array = []
## Os traços de caminho, na ordem de desenho (free-trails/04).
var trails: Array[MapTrail] = []
## As paredes, na ordem (free-fences/01).
var walls: Array[MapWall] = []
var bridges: Array[MapBridge] = []


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
	for entry: Variant in DictFields.get_array(data, "bridges"):
		var bridge: MapBridge = MapBridge.from_dict(entry) if entry is Dictionary else null
		if bridge != null:
			draft.bridges.append(bridge)
	draft.props = DictFields.get_array(data, "props").duplicate(true)
	return draft


static func from_dict(data: Dictionary) -> IslandDraft:
	var draft := IslandDraft.new()
	draft.id = DictFields.get_int(data, "id")
	draft.name = DictFields.get_string(data, "name")
	draft._read_terrain(data)
	draft.actions = DictFields.get_array(data, "actions").duplicate(true)
	draft.props = DictFields.get_array(data, "props").duplicate(true)
	for entry: Variant in DictFields.get_array(data, "trails"):
		var trail: MapTrail = MapTrail.from_dict(entry) if entry is Dictionary else null
		if trail != null:
			draft.trails.append(trail)
	for entry: Variant in DictFields.get_array(data, "walls"):
		var wall: MapWall = MapWall.from_dict(entry) if entry is Dictionary else null
		if wall != null:
			draft.walls.append(wall)
	for entry: Variant in DictFields.get_array(data, "bridges"):
		var bridge: MapBridge = MapBridge.from_dict(entry) if entry is Dictionary else null
		if bridge != null:
			draft.bridges.append(bridge)
	draft.areas = DictFields.get_array(data, "areas").duplicate(true)
	draft.npcs = DictFields.get_array(data, "npcs").duplicate(true)
	return draft


func to_dict() -> Dictionary:
	var tile_list: Array[Dictionary] = []
	for tile: HexTile in tiles.values():
		var entry := {"q": tile.coord.x, "r": tile.coord.y, "biome": tile.biome, "height": tile.height, "variant": tile.variant}
		if not tile.ground.is_empty():
			entry["ground"] = tile.ground
		if tile.bare:
			entry["bare"] = true
		if not tile.zone.is_empty():
			entry["zone"] = tile.zone
		if tile_areas.has(tile.coord):
			entry["area"] = tile_areas[tile.coord]
		tile_list.append(entry)
	return {
		"name": name,
		"start": {"q": start.x, "r": start.y},
		"tiles": tile_list,
		"actions": actions,
		"props": props,
		"trails": trails.map(func(trail: MapTrail) -> Dictionary: return trail.to_dict()),
		"walls": walls.map(func(wall: MapWall) -> Dictionary: return wall.to_dict()),
		"bridges": bridges.map(func(bridge: MapBridge) -> Dictionary: return bridge.to_dict()),
		"areas": areas,
		"npcs": npcs,
	}


## Um hexágono para o desfazer: `[bioma, altura, variante, área, chão, sem decoração, zona]`,
## com área 0 e chão vazio quando ele não tem; vazio quando o hexágono não existe.
func snapshot(coord: Vector2i) -> Array:
	var tile: HexTile = tiles.get(coord)
	if tile == null:
		return []
	return [tile.biome, tile.height, tile.variant, tile_areas.get(coord, 0), tile.ground, tile.bare, tile.zone]


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
	tile.zone = state[6]
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
	for index: int in range(props.size() - 1, -1, -1):
		if prop_coord(index) == coord:
			props.remove_at(index)
			changed = true
	for index: int in range(npcs.size() - 1, -1, -1):
		var npc: Dictionary = npcs[index]
		if npc_coord(index) == coord:
			npcs.remove_at(index)
			changed = true
			continue
		var walk: Array = npc.get("tiles", [])
		for spot: int in range(walk.size() - 1, -1, -1):
			if int(walk[spot].get("q", 0)) == coord.x and int(walk[spot].get("r", 0)) == coord.y:
				walk.remove_at(spot)
				changed = true
	return changed


func npc_coord(index: int) -> Vector2i:
	var npc: Dictionary = npcs[index]
	return Vector2i(int(npc.get("q", 0)), int(npc.get("r", 0)))


func npc_at(coord: Vector2i) -> int:
	for index: int in npcs.size():
		if npc_coord(index) == coord:
			return index
	return -1


func npc_tiles(index: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if index < 0 or index >= npcs.size():
		return result
	for at: Variant in (npcs[index] as Dictionary).get("tiles", []):
		result.append(Vector2i(int((at as Dictionary).get("q", 0)), int((at as Dictionary).get("r", 0))))
	return result


func map_npcs() -> Array[MapNpc]:
	var result: Array[MapNpc] = []
	for entry: Variant in npcs:
		var npc: MapNpc = MapNpc.from_dict(entry) if entry is Dictionary else null
		if npc != null:
			result.append(npc)
	return result


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


## As linhas de bloqueio da peça (free-objects): as próprias, se ajustada, ou as padrão da
## variante dela (prop-depth-blocks/02).
func prop_lines(index: int) -> Array[Dictionary]:
	var prop: Dictionary = props[index]
	if prop.has("block"):
		return MapProp.lines_from(prop["block"])
	return GameData.get_prop_blocks(int(prop.get("prop_type_id", 0)), int(prop.get("variant", 1)))


func prop_is_custom(index: int) -> bool:
	return (props[index] as Dictionary).has("block")


## As linhas da peça no chão plano, com o espelho.
func prop_world_lines(index: int) -> Array[PackedVector2Array]:
	var prop := MapProp.from_dict(props[index])
	if prop == null:
		return []
	return prop.world_lines(GameData.get_prop_blocks(prop.prop_type_id, prop.variant))


## Um ponto do chão plano nas coordenadas das linhas da peça: a partir do pé, sem o espelho.
func prop_local(index: int, flat: Vector2) -> Vector2i:
	var local := flat - prop_foot(index)
	if bool((props[index] as Dictionary).get("mirrored", false)):
		local.x = -local.x
	return Vector2i(local.round()).clamp(Vector2i(-MapProp.MAX_COORD, -MapProp.MAX_COORD), Vector2i(MapProp.MAX_COORD, MapProp.MAX_COORD))


## Um ponto das linhas da peça no chão plano.
func prop_flat(index: int, local: Vector2i) -> Vector2:
	var point := Vector2(local)
	if bool((props[index] as Dictionary).get("mirrored", false)):
		point.x = -point.x
	return prop_foot(index) + point


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


static func copy_trails(list: Array) -> Array[MapTrail]:
	var copies: Array[MapTrail] = []
	for trail: MapTrail in list:
		copies.append(trail.copy())
	return copies


static func trails_state(list: Array) -> Array:
	return list.map(func(trail: MapTrail) -> Dictionary: return trail.to_dict())


static func copy_walls(list: Array) -> Array[MapWall]:
	var copies: Array[MapWall] = []
	for wall: MapWall in list:
		copies.append(wall.copy())
	return copies


static func copy_bridges(list: Array) -> Array[MapBridge]:
	var copies: Array[MapBridge] = []
	for bridge: MapBridge in list:
		copies.append(bridge.copy())
	return copies


## A ponte de cima cujo piso passa a até `reach` do ponto do chão plano, ou -1.
func bridge_at(flat: Vector2, reach: float) -> int:
	for index: int in range(bridges.size() - 1, -1, -1):
		var bridge := bridges[index]
		var gap := flat.distance_to(Geometry2D.get_closest_point_to_segment(flat, bridge.from, bridge.to))
		if gap <= bridge.width / 2.0 + reach:
			return index
	return -1


static func walls_state(list: Array) -> Array:
	return list.map(func(wall: MapWall) -> Dictionary: return wall.to_dict())


## Tira os pontos das paredes que caíram fora da ilha e apaga a parede que fica com
## menos de 2. Devolve quantas paredes mudaram.
func clip_walls() -> int:
	var changed := 0
	for index: int in range(walls.size() - 1, -1, -1):
		var wall := walls[index]
		var kept := PackedVector2Array()
		for point: Vector2 in wall.points:
			if tiles.has(HexMapView.grid_coord(point)):
				kept.append(point)
		if kept.size() == wall.points.size():
			continue
		changed += 1
		if kept.size() < 2:
			walls.remove_at(index)
		else:
			wall.points = kept
	return changed


## Apaga as pontes com uma ponta fora da ilha ou na água (bridges/01). Devolve quantas.
func clip_bridges() -> int:
	var removed := 0
	for index: int in range(bridges.size() - 1, -1, -1):
		var bridge := bridges[index]
		if bridge_end_ok(bridge.from) and bridge_end_ok(bridge.to):
			continue
		bridges.remove_at(index)
		removed += 1
	return removed


## Se uma ponta de ponte pode ficar no ponto: num hexágono da ilha que não é água.
func bridge_end_ok(flat: Vector2) -> bool:
	var tile: HexTile = tiles.get(HexMapView.grid_coord(flat))
	return tile != null and not tile.is_water()


## A parede de cima a até `reach` do ponto do chão plano, ou -1.
func wall_at(flat: Vector2, reach: float) -> int:
	for index: int in range(walls.size() - 1, -1, -1):
		var points := walls[index].points
		for at: int in range(1, points.size()):
			if flat.distance_to(Geometry2D.get_closest_point_to_segment(flat, points[at - 1], points[at])) <= reach:
				return index
	return -1


## O traço de cima que passa no ponto do chão plano, ou -1.
func trail_at(flat: Vector2) -> int:
	for index: int in range(trails.size() - 1, -1, -1):
		var trail := trails[index]
		if HexGrounds.trail_distance(trail, flat) <= maxf(trail.width / 2.0, 6.0) + 2.0:
			return index
	return -1


## Tira os pontos dos traços que caíram fora da ilha (um hexágono apagado) e apaga o
## traço que fica com menos de 2. Devolve quantos traços mudaram (free-trails/04).
func clip_trails() -> int:
	var changed := 0
	for index: int in range(trails.size() - 1, -1, -1):
		var trail := trails[index]
		var kept := PackedVector2Array()
		for point: Vector2 in trail.points:
			if tiles.has(HexMapView.grid_coord(point)):
				kept.append(point)
		if kept.size() == trail.points.size():
			continue
		changed += 1
		if kept.size() < 2:
			trails.remove_at(index)
		else:
			trail.points = kept
			trail.smoothed = PackedVector2Array()
	return changed


## O terreno como o `HexMapView` desenha. A seed só escolhe os escorridos dos
## paredões; com o id, cada ilha fica sempre igual.
func to_map() -> ExplorationMap:
	var map := ExplorationMap.new()
	map.map_seed = id
	map.start = start
	map.tiles = tiles
	map.props = map_props()
	map.trails = trails.duplicate()
	map.walls = walls.duplicate()
	map.bridges = bridges.duplicate()
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
