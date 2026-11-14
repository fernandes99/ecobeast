class_name ExplorationMap
extends RefCounted

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
]

var map_seed: int = 0
var start := Vector2i.ZERO
var tiles: Dictionary[Vector2i, HexTile] = {}
var creatures: Dictionary[int, MapCreature] = {}
var tamers: Dictionary[int, MapTamer] = {}
var island_id: int = 0
var island_name: String = ""
var actions: Array[MapAction] = []
var objects: Array[MapObject] = []
var props: Array[MapProp] = []
var _action_of: Dictionary[Vector2i, int] = {}
var _object_of: Dictionary[Vector2i, int] = {}
var _blocked: Dictionary[Vector2i, bool] = {}


static func distance(from: Vector2i, to: Vector2i) -> int:
	var delta := from - to
	@warning_ignore("integer_division")
	return (absi(delta.x) + absi(delta.y) + absi(delta.x + delta.y)) / 2


func has(coord: Vector2i) -> bool:
	return tiles.has(coord)


func tile_at(coord: Vector2i) -> HexTile:
	return tiles.get(coord)


func neighbors(coord: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction: Vector2i in DIRECTIONS:
		if has(coord + direction):
			result.append(coord + direction)
	return result


func has_creature(coord: Vector2i) -> bool:
	return creatures.values().any(func(creature: MapCreature) -> bool: return creature.coord == coord)


func tamer_at(coord: Vector2i) -> MapTamer:
	for tamer: MapTamer in tamers.values():
		if tamer.coord == coord:
			return tamer
	return null


func action_at(coord: Vector2i) -> int:
	return _action_of.get(coord, -1)


func object_at(coord: Vector2i) -> int:
	return _object_of.get(coord, -1)


func is_blocked(coord: Vector2i) -> bool:
	return _blocked.has(coord)


## O caminho mais curto de `from` até o primeiro hexágono de `goals`, sem o `from`,
## desviando dos bloqueados. Vazio quando não há caminho ou `from` já é um deles.
func path_to_any(from: Vector2i, goals: Dictionary[Vector2i, bool]) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if goals.has(from):
		return path
	var came_from: Dictionary[Vector2i, Vector2i] = {from: from}
	var frontier: Array[Vector2i] = [from]
	var index := 0
	while index < frontier.size():
		var coord := frontier[index]
		index += 1
		for next: Vector2i in neighbors(coord):
			if came_from.has(next) or is_blocked(next):
				continue
			came_from[next] = coord
			if goals.has(next):
				while next != from:
					path.push_front(next)
					next = came_from[next]
				return path
			frontier.append(next)
	return path


## Os hexágonos livres de onde o Domador alcança o bloqueado `coord`: os vizinhos dele,
## ou, se ele estiver cercado, os de qualquer hexágono do mesmo objeto.
func free_sides(coord: Vector2i) -> Dictionary[Vector2i, bool]:
	var sides: Dictionary[Vector2i, bool] = {}
	var around: Array[Vector2i] = [coord]
	for _pass: int in 2:
		for tile: Vector2i in around:
			for next: Vector2i in neighbors(tile):
				if not is_blocked(next):
					sides[next] = true
		if not sides.is_empty() or object_at(coord) < 0:
			break
		around = objects[object_at(coord)].tiles
	return sides


func set_objects(list: Array[MapObject]) -> void:
	objects.clear()
	_object_of.clear()
	_blocked.clear()
	for object: MapObject in list:
		add_object(object)


func add_object(object: MapObject) -> void:
	for coord: Vector2i in object.tiles:
		_object_of[coord] = objects.size()
	for coord: Vector2i in object.blocked_tiles():
		_blocked[coord] = true
	objects.append(object)


static func from_dict(d: Dictionary) -> ExplorationMap:
	var map := ExplorationMap.new()
	map.map_seed = DictFields.get_int(d, "seed")
	var start_dict := DictFields.get_dict(d, "start")
	map.start = Vector2i(DictFields.get_int(start_dict, "q"), DictFields.get_int(start_dict, "r"))
	for tile_dict: Variant in DictFields.get_array(d, "tiles"):
		var tile: HexTile = HexTile.from_dict(tile_dict) if tile_dict is Dictionary else null
		if tile != null:
			map.tiles[tile.coord] = tile
	for creature_dict: Variant in DictFields.get_array(d, "creatures"):
		var creature: MapCreature = MapCreature.from_dict(creature_dict) if creature_dict is Dictionary else null
		if creature != null:
			map.creatures[creature.id] = creature
	for tamer_dict: Variant in DictFields.get_array(d, "tamers"):
		var tamer: MapTamer = MapTamer.from_dict(tamer_dict) if tamer_dict is Dictionary else null
		if tamer != null:
			map.tamers[tamer.id] = tamer
	var island := DictFields.get_dict(d, "island")
	map.island_id = DictFields.get_int(island, "id")
	map.island_name = DictFields.get_string(island, "name")
	for action_dict: Variant in DictFields.get_array(d, "actions"):
		var action: MapAction = MapAction.from_dict(action_dict) if action_dict is Dictionary else null
		if action != null:
			for coord: Vector2i in action.tiles:
				map._action_of[coord] = map.actions.size()
			map.actions.append(action)
	for object_dict: Variant in DictFields.get_array(d, "objects"):
		var object: MapObject = MapObject.from_dict(object_dict) if object_dict is Dictionary else null
		if object != null:
			map.add_object(object)
	for prop_dict: Variant in DictFields.get_array(d, "props"):
		var prop: MapProp = MapProp.from_dict(prop_dict) if prop_dict is Dictionary else null
		if prop != null:
			map.props.append(prop)
	return map
