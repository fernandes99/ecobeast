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
var buildings: Array[MapBuilding] = []
var _building_of: Dictionary[Vector2i, int] = {}


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


func building_at(coord: Vector2i) -> int:
	return _building_of.get(coord, -1)


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
	for building_dict: Variant in DictFields.get_array(d, "buildings"):
		var building: MapBuilding = MapBuilding.from_dict(building_dict) if building_dict is Dictionary else null
		if building != null:
			for coord: Vector2i in building.tiles:
				map._building_of[coord] = map.buildings.size()
			map.buildings.append(building)
	return map
