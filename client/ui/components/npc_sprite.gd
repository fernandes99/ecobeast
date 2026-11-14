class_name NpcSprite
extends CreatureSprite

## Um NPC da ilha (island-npcs/03), com as folhas de explorar do Ecobeast, na escala do
## Domador: parado no hexágono dele, ou passeando de centro em centro pelos hexágonos do
## passeio, com pausas entre as viagens.

const MIN_REST := 2.0
const MAX_REST := 5.0
const HIT_MARGIN := 3.0

var npc: MapNpc = null
var coord := Vector2i.ZERO

var _view: HexMapView = null
var _map: ExplorationMap = null
var _path: Array[Vector2i] = []
var _rest_left := 0.0
var _held := false


static func first_frame(slug: String) -> Texture2D:
	if not has_sheets(slug):
		return null
	var first := AtlasTexture.new()
	first.atlas = load(SHEET_PATH % [slug, IDLE]) as Texture2D
	first.region = Rect2(Vector2.ZERO, CELL_SIZE)
	return first


func _init(map_npc: MapNpc, slug: String) -> void:
	super(slug)
	npc = map_npc
	coord = map_npc.coord


## Com `map` nulo (o editor), ele fica parado.
func place_on(view: HexMapView, map: ExplorationMap) -> void:
	_view = view
	_map = map
	view.add_child(self)
	_exact = view.surface_center(coord)
	position = _exact.round()
	view.set_actor_row(self, coord.y)
	_rest()


func hold(on: bool, toward: Vector2 = Vector2.ZERO) -> void:
	_held = on
	if on:
		if toward != position:
			face_toward(toward - position)
		play_idle()
	elif not _path.is_empty():
		face_toward(_view.surface_center(_path[0]) - _exact)
		play_walk()


func hits(art_point: Vector2) -> bool:
	var cell := Vector2(CELL_SIZE) * scale
	return Rect2(position - Vector2(cell.x / 2.0, cell.y), cell).grow(HIT_MARGIN).has_point(art_point)


func _process(delta: float) -> void:
	if _view == null or _map == null or _held or npc.still:
		return
	if _path.is_empty():
		_rest_left -= delta
		if _rest_left <= 0.0:
			_start_trip()
		return
	var next := _path[0]
	var target := _view.surface_center(next)
	_exact = _exact.move_toward(target, WALK_SPEED * delta)
	position = _exact.round()
	if coord != next and _exact.distance_to(target) < _exact.distance_to(_view.surface_center(coord)):
		coord = next
		_view.set_actor_row(self, coord.y)
	if _exact == target:
		_path.pop_front()
		if _path.is_empty():
			_rest()
		else:
			face_toward(_view.surface_center(_path[0]) - _exact)
			play_walk()


func _rest() -> void:
	play_idle()
	_rest_left = randf_range(MIN_REST, MAX_REST)


func _start_trip() -> void:
	var options: Array[Vector2i] = []
	for tile: Vector2i in npc.walk_tiles():
		if tile != coord and _map.has(tile) and not _map.is_blocked(tile):
			options.append(tile)
	if options.is_empty():
		_rest()
		return
	var goals: Dictionary[Vector2i, bool] = {options.pick_random(): true}
	_path = _map.path_to_any(coord, goals)
	if _path.is_empty():
		_rest()
		return
	face_toward(_view.surface_center(_path[0]) - _exact)
	play_walk()
