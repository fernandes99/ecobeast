class_name ExplorationMap
extends RefCounted
## O mapa de uma exploração (.specs/wild-battle/architecture.md): os hexágonos
## por coordenada axial. Quem gera é o servidor.

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
]

## `seed` já é uma função do GDScript.
var map_seed: int = 0
var start := Vector2i.ZERO
var tiles: Dictionary[Vector2i, HexTile] = {}
## Os Ecobeasts ainda no mapa, por id.
var creatures: Dictionary[int, MapCreature] = {}
## Os Domadores NPC ainda no mapa, por id (npc-tamers/04). Um por hexágono.
var tamers: Dictionary[int, MapTamer] = {}


## Quantos passos pela grade separam duas posições.
static func distance(from: Vector2i, to: Vector2i) -> int:
	var delta := from - to
	@warning_ignore("integer_division")
	return (absi(delta.x) + absi(delta.y) + absi(delta.x + delta.y)) / 2


func has(coord: Vector2i) -> bool:
	return tiles.has(coord)


## null fora do mapa.
func tile_at(coord: Vector2i) -> HexTile:
	return tiles.get(coord)


## As posições vizinhas que pertencem ao mapa.
func neighbors(coord: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction: Vector2i in DIRECTIONS:
		if has(coord + direction):
			result.append(coord + direction)
	return result


func has_creature(coord: Vector2i) -> bool:
	return creatures.values().any(func(creature: MapCreature) -> bool: return creature.coord == coord)


## O Domador NPC do hexágono, ou null.
func tamer_at(coord: Vector2i) -> MapTamer:
	for tamer: MapTamer in tamers.values():
		if tamer.coord == coord:
			return tamer
	return null


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
	return map
