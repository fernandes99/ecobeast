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
## Numa ilha, os hexágonos que o Domador já tinha descoberto (fog-of-war/03).
var discovered: Array[Vector2i] = []
var island_name: String = ""
var actions: Array[MapAction] = []
var props: Array[MapProp] = []
var trails: Array[MapTrail] = []
## As paredes (free-fences): trocar a lista refaz o índice dos trechos por hexágono.
var walls: Array[MapWall] = []:
	set(value):
		walls = value
		_index_walls()
var npcs: Array[MapNpc] = []
## As pontes (bridges/01).
var bridges: Array[MapBridge] = []
## As linhas de bloqueio das peças no chão plano (free-objects/01), postas pela tela
## com `set_prop_lines`; o índice das paredes as leva junto.
var _prop_lines: Array[PackedVector2Array] = []
## As linhas de cada peça, na ordem de `props`.
var _lines_by_prop: Array = []
var _action_of: Dictionary[Vector2i, int] = {}
## Os trechos de parede `[a, b]` que passam perto de cada hexágono, no chão plano.
var _wall_cells: Dictionary[Vector2i, Array] = {}

## O pé do Domador não chega a menos disto de uma parede, em pixels da arte (free-fences/02).
const WALL_REACH := 3.0
const WALL_SAMPLE := 4.0
const CENTER_REACH := 8.0
## A água bloqueia fora do piso das pontes (bridges/04): o segmento é conferido de
## tanto em tanto.
const WATER_SAMPLE := 2.0
const NO_SEGMENTS: Array = []


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


## O caminho mais curto de `from` até o primeiro hexágono de `goals`, sem o `from`,
## sem passar entre dois centros por cima de uma parede.
## Com `from_point` do lado de uma parede sem o centro do hexágono, começa pelos
## vizinhos que ele alcança em reta. Vazio quando não há caminho ou `from` já é um deles.
func path_to_any(from: Vector2i, goals: Dictionary[Vector2i, bool], from_point := Vector2.INF, use_bridges := true) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if goals.is_empty() or goals.has(from):
		return path
	var came_from: Dictionary[Vector2i, Vector2i] = {from: from}
	var frontier: Array[Vector2i] = [from]
	var index := 0
	var links: Dictionary[Vector2i, Array] = {}
	if use_bridges:
		links = bridge_links()
	if from_point.is_finite() and (is_blocked_hex(from) or not is_clear(from_point, HexMapView.flat_center(from))):
		index = 1
		var starts: Array[Vector2i] = []
		for next: Vector2i in neighbors(from):
			if not is_blocked_hex(next) and is_clear(from_point, HexMapView.flat_center(next)):
				starts.append(next)
		var deck := deck_of(from_point)
		if deck >= 0:
			for end: Vector2 in [bridges[deck].from, bridges[deck].to]:
				var coord := HexMapView.grid_coord(end)
				if has(coord) and not is_blocked_hex(coord) and is_clear(end, HexMapView.flat_center(coord)):
					starts.append(coord)
		for next: Vector2i in starts:
			if came_from.has(next):
				continue
			came_from[next] = from
			if goals.has(next):
				return [next] as Array[Vector2i]
			frontier.append(next)
	while index < frontier.size():
		var coord := frontier[index]
		index += 1
		var nexts: Array[Vector2i] = []
		for next: Vector2i in neighbors(coord):
			if not is_blocked_hex(next) and not _wall_between(coord, next):
				nexts.append(next)
		for link: Array in links.get(coord, []):
			nexts.append(link[0])
		for next: Vector2i in nexts:
			if came_from.has(next):
				continue
			came_from[next] = coord
			if goals.has(next):
				while next != from:
					path.push_front(next)
					next = came_from[next]
				return path
			frontier.append(next)
	return path


## Se o segmento passa a menos de WALL_REACH de algum trecho de parede. Quem já está
## mais perto que isso (o fim de uma rota cortada) pode se afastar sem cruzar.
func crosses_wall(from: Vector2, to: Vector2) -> bool:
	if _wall_cells.is_empty():
		return false
	var seen: Dictionary[PackedVector2Array, bool] = {}
	var steps := maxi(1, ceili(from.distance_to(to) / WALL_SAMPLE))
	for step: int in steps + 1:
		var coord := HexMapView.grid_coord(from.lerp(to, float(step) / steps))
		for segment: PackedVector2Array in _wall_cells.get(coord, NO_SEGMENTS):
			if seen.has(segment):
				continue
			seen[segment] = true
			if _segment_distance(from, to, segment[0], segment[1]) >= WALL_REACH:
				continue
			var gap := _point_distance(from, segment)
			if gap < WALL_REACH and Geometry2D.segment_intersects_segment(from, to, segment[0], segment[1]) == null and _point_distance(to, segment) >= gap:
				continue
			return true
	return false


## O ponto mais longe de `from`, na reta até `to`, que se alcança sem cruzar parede nem
## entrar na água fora de uma ponte.
func clip_to_walls(from: Vector2, to: Vector2) -> Vector2:
	if is_clear(from, to):
		return to
	var low := 0.0
	var high := 1.0
	for _step: int in 12:
		var middle := (low + high) / 2.0
		if not is_clear(from, from.lerp(to, middle)):
			high = middle
		else:
			low = middle
	return from.lerp(to, low)


## Uma parede passa pelo centro do hexágono: ele não é alcançável pelo centro.
func is_center_walled(coord: Vector2i) -> bool:
	var center := HexMapView.flat_center(coord)
	for segment: PackedVector2Array in _wall_cells.get(coord, NO_SEGMENTS):
		if _point_distance(center, segment) < WALL_REACH:
			return true
	return false


## Os vizinhos livres de `target` por onde o Domador chega a `finish` quando uma parede
## passa pelo centro dele: os que alcançam o ponto em reta ou, sem nenhum, todos.
func approach_goals(target: Vector2i, finish: Vector2) -> Dictionary[Vector2i, bool]:
	var all: Dictionary[Vector2i, bool] = {}
	var facing: Dictionary[Vector2i, bool] = {}
	for next: Vector2i in neighbors(target):
		if not has(next) or is_center_walled(next):
			continue
		if is_blocked_hex(next):
			continue
		all[next] = true
		if is_clear(HexMapView.flat_center(next), finish):
			facing[next] = true
	return facing if not facing.is_empty() else all


## Se o segmento não cruza parede nem passa pela água fora do piso de uma ponte
## (bridges/04). Quem já está num ponto bloqueado pode sair dele.
func is_clear(from: Vector2, to: Vector2) -> bool:
	if crosses_wall(from, to):
		return false
	var leaving := is_blocked(from)
	var steps := maxi(1, ceili(from.distance_to(to) / WATER_SAMPLE))
	for step: int in range(1, steps + 1):
		if is_blocked(from.lerp(to, float(step) / steps)):
			if not leaving:
				return false
		else:
			leaving = false
	return true


## Um ponto na água, fora do piso das pontes.
func is_blocked(flat: Vector2) -> bool:
	return is_blocked_hex(HexMapView.grid_coord(flat)) and deck_of(flat) < 0


## Um hexágono onde não se anda: água que não é vau.
func is_blocked_hex(coord: Vector2i) -> bool:
	var tile := tile_at(coord)
	return tile != null and tile.blocks_walking()


## A ponte cujo piso tem o ponto, ou -1. O piso é o corredor reto entre as pontas, com a
## largura da arte menos a folga.
func deck_of(flat: Vector2) -> int:
	for index: int in bridges.size():
		var bridge := bridges[index]
		var along := bridge.to - bridge.from
		var length := along.length_squared()
		if length <= 0.0:
			continue
		var part := (flat - bridge.from).dot(along) / length
		if part < 0.0 or part > 1.0:
			continue
		if flat.distance_to(bridge.from + along * part) <= HexBridges.deck_reach(bridge):
			return index
	return -1


## Quanto o piso da ponte sobe no ponto: a altura das margens misturada pelo caminho.
func deck_lift(index: int, flat: Vector2) -> float:
	var bridge := bridges[index]
	var along := bridge.to - bridge.from
	var part := clampf((flat - bridge.from).dot(along) / maxf(along.length_squared(), 0.001), 0.0, 1.0)
	return roundf(lerpf(_level_rise(bridge.from), _level_rise(bridge.to), part))


## A altura em pixels do chão no ponto: a do piso em cima de uma ponte, senão a do hexágono.
func rise_at(flat: Vector2) -> float:
	var deck := deck_of(flat)
	return deck_lift(deck, flat) if deck >= 0 else _level_rise(flat)


## O ponto do chão plano de um ponto da arte (com a altura) em cima do piso de uma ponte,
## ou INF fora de todas.
func deck_point_of_art(art: Vector2) -> Vector2:
	for index: int in bridges.size():
		var bridge := bridges[index]
		for lift: float in [_level_rise(bridge.from), _level_rise(bridge.to)]:
			var flat := art + Vector2(0.0, lift)
			if deck_of(flat) == index:
				return art + Vector2(0.0, deck_lift(index, flat))
	return Vector2.INF


## As ligações das pontes na busca: por hexágono de uma ponta, `[hexágono da outra,
## ponta daqui, ponta de lá]`. A ponta que não alcança o centro do hexágono dela não liga.
func bridge_links() -> Dictionary[Vector2i, Array]:
	var links: Dictionary[Vector2i, Array] = {}
	for bridge: MapBridge in bridges:
		var a := HexMapView.grid_coord(bridge.from)
		var b := HexMapView.grid_coord(bridge.to)
		if a == b or not has(a) or not has(b) or is_blocked_hex(a) or is_blocked_hex(b):
			continue
		if not is_clear(HexMapView.flat_center(a), bridge.from) or not is_clear(bridge.to, HexMapView.flat_center(b)):
			continue
		if not links.has(a):
			links[a] = []
		if not links.has(b):
			links[b] = []
		links[a].append([b, bridge.from, bridge.to])
		links[b].append([a, bridge.to, bridge.from])
	return links


## As pontas de ponte que levam do hexágono `from` ao `to`, ou nada sem ponte entre eles.
func bridge_hop(from: Vector2i, to: Vector2i) -> PackedVector2Array:
	for link: Array in bridge_links().get(from, []):
		if link[0] == to:
			return PackedVector2Array([link[1], link[2]])
	return PackedVector2Array()


## Os hexágonos de terra mais perto de um de água, para tocar na água levar à margem.
func shore_goals(target: Vector2i) -> Dictionary[Vector2i, bool]:
	var goals: Dictionary[Vector2i, bool] = {}
	var seen: Dictionary[Vector2i, bool] = {target: true}
	var ring: Array[Vector2i] = [target]
	while goals.is_empty() and not ring.is_empty():
		var next_ring: Array[Vector2i] = []
		for coord: Vector2i in ring:
			for next: Vector2i in neighbors(coord):
				if seen.has(next):
					continue
				seen[next] = true
				if is_blocked_hex(next):
					next_ring.append(next)
				else:
					goals[next] = true
		ring = next_ring
	return goals


func _level_rise(flat: Vector2) -> float:
	var tile := tile_at(HexMapView.grid_coord(flat))
	return HexMapView.LEVEL_HEIGHTS[tile.height] if tile != null else 0.0


## A reta entre dois centros vizinhos fica dentro dos dois hexágonos: só eles importam.
func _wall_between(from: Vector2i, to: Vector2i) -> bool:
	if not _wall_cells.has(from) and not _wall_cells.has(to):
		return false
	return crosses_wall(HexMapView.flat_center(from), HexMapView.flat_center(to))


## As linhas de bloqueio das peças: as próprias ou as padrão do tipo, por
## `type_lines["tipo:variante"]`, e sem elas as de `"tipo:0"` (prop-depth-blocks/02).
func set_prop_lines(type_lines: Dictionary) -> void:
	_prop_lines.clear()
	_lines_by_prop.clear()
	var none: Array[Dictionary] = []
	for prop: MapProp in props:
		var fallback: Array[Dictionary] = type_lines.get("%d:0" % prop.prop_type_id, none)
		var lines: Array[Dictionary] = type_lines.get("%d:%d" % [prop.prop_type_id, prop.variant], fallback)
		var world := prop.world_lines(lines)
		_lines_by_prop.append(world)
		_prop_lines.append_array(world)
	_index_walls()


## O centro do hexágono a até 8 px de uma parede ou linha de peça, ou dentro de uma linha
## fechada: a conta do servidor (prop-depth-blocks/02). O teleporte não para ali (minimap/03).
func is_walled_hex(coord: Vector2i) -> bool:
	var center := HexMapView.flat_center(coord)
	for segment: PackedVector2Array in _wall_cells.get(coord, NO_SEGMENTS):
		if center.distance_to(Geometry2D.get_closest_point_to_segment(center, segment[0], segment[1])) <= CENTER_REACH:
			return true
	for line: PackedVector2Array in _prop_lines:
		if line.size() >= 4 and line[0] == line[line.size() - 1] and Geometry2D.is_point_in_polygon(center, line.slice(0, line.size() - 1)):
			return true
	return false


func prop_world_lines(index: int) -> Array[PackedVector2Array]:
	var none: Array[PackedVector2Array] = []
	return _lines_by_prop[index] if index < _lines_by_prop.size() else none


## O ponto das linhas mais perto de `point`, e a distância até ele (INF sem linhas).
static func nearest_on_lines(lines: Array[PackedVector2Array], point: Vector2) -> Vector2:
	var best := Vector2.INF
	for line: PackedVector2Array in lines:
		for index: int in range(1, line.size()):
			var at := Geometry2D.get_closest_point_to_segment(point, line[index - 1], line[index])
			if not best.is_finite() or at.distance_to(point) < best.distance_to(point):
				best = at
	return best


func _index_walls() -> void:
	_wall_cells.clear()
	var margin := WALL_REACH + 1.0
	var spread: Array[Vector2] = [Vector2.ZERO, Vector2(margin, 0.0), Vector2(-margin, 0.0), Vector2(0.0, margin), Vector2(0.0, -margin)]
	var lines: Array[PackedVector2Array] = []
	for wall: MapWall in walls:
		lines.append(wall.points)
	lines.append_array(_prop_lines)
	for line: PackedVector2Array in lines:
		for index: int in range(1, line.size()):
			var segment := PackedVector2Array([line[index - 1], line[index]])
			var steps := maxi(1, ceili(segment[0].distance_to(segment[1]) / WALL_SAMPLE))
			var cells: Dictionary[Vector2i, bool] = {}
			for step: int in steps + 1:
				var at := segment[0].lerp(segment[1], float(step) / steps)
				for shift: Vector2 in spread:
					cells[HexMapView.grid_coord(at + shift)] = true
			for coord: Vector2i in cells:
				if not _wall_cells.has(coord):
					_wall_cells[coord] = []
				_wall_cells[coord].append(segment)


static func _point_distance(point: Vector2, segment: PackedVector2Array) -> float:
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point, segment[0], segment[1]))


static func _segment_distance(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> float:
	if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
		return 0.0
	return minf(
		minf(a.distance_to(Geometry2D.get_closest_point_to_segment(a, c, d)), b.distance_to(Geometry2D.get_closest_point_to_segment(b, c, d))),
		minf(c.distance_to(Geometry2D.get_closest_point_to_segment(c, a, b)), d.distance_to(Geometry2D.get_closest_point_to_segment(d, a, b))))


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
	for prop_dict: Variant in DictFields.get_array(d, "props"):
		var prop: MapProp = MapProp.from_dict(prop_dict) if prop_dict is Dictionary else null
		if prop != null:
			map.props.append(prop)
	for trail_dict: Variant in DictFields.get_array(d, "trails"):
		var trail: MapTrail = MapTrail.from_dict(trail_dict) if trail_dict is Dictionary else null
		if trail != null:
			map.trails.append(trail)
	var wall_list: Array[MapWall] = []
	for wall_dict: Variant in DictFields.get_array(d, "walls"):
		var wall: MapWall = MapWall.from_dict(wall_dict) if wall_dict is Dictionary else null
		if wall != null:
			wall_list.append(wall)
	map.walls = wall_list
	for bridge_dict: Variant in DictFields.get_array(d, "bridges"):
		var bridge: MapBridge = MapBridge.from_dict(bridge_dict) if bridge_dict is Dictionary else null
		if bridge != null:
			map.bridges.append(bridge)
	for npc_dict: Variant in DictFields.get_array(d, "npcs"):
		var npc: MapNpc = MapNpc.from_dict(npc_dict) if npc_dict is Dictionary else null
		if npc != null:
			map.npcs.append(npc)
	return map
