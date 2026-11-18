class_name NpcSprite
extends CreatureSprite

## Um NPC da ilha (island-npcs/03), com as folhas de explorar do Ecobeast, na escala do
## Domador: parado no hexágono dele, ou passeando de centro em centro pelos hexágonos do
## passeio, com pausas entre as viagens. O NPC pessoa (liora-intro/02) não tem folhas
## próprias e desenha um TamerSprite com a aparência dele.

const MIN_REST := 2.0
const MAX_REST := 5.0
const HIT_MARGIN := 3.0
## O que `walk_to` devolve (story/03).
const ARRIVED := 0
const WALKING := 1
const JUMPED := 2
## O passo de uma cena, em pixels da arte por segundo. A revisar.
const STORY_SPEED := 60.0
const PERSON_ICON := "res://ui/icons/person.svg"

signal arrived

var npc: MapNpc = null
var coord := Vector2i.ZERO

var _view: HexMapView = null
var _map: ExplorationMap = null
var _path: Array[Vector2i] = []
var _rest_left := 0.0
var _held := false
## Numa cena (story/03): não sorteia passeio e só anda por `walk_to`.
var scripted := false
var walk_speed := WALK_SPEED
var _look: TamerSprite = null


## O NPC no mapa, ou null quando ele não tem desenho (sem folhas e sem aparência).
static func make(map_npc: MapNpc) -> NpcSprite:
	if not can_draw(map_npc.npc_id):
		return null
	return NpcSprite.new(map_npc, slug_of(map_npc.npc_id))


static func can_draw(npc_id: int) -> bool:
	return TamerAppearance.for_npc(npc_id) != null or has_sheets(slug_of(npc_id))


## A pasta do Ecobeast do NPC; vazio para o NPC pessoa.
static func slug_of(npc_id: int) -> String:
	var sprite: Variant = GameData.get_npc(npc_id).get("sprite")
	return str(sprite) if sprite != null else ""


## Um quadro parado para as listas e as marcas do editor: o do Ecobeast ou, para a
## pessoa, o ícone de pessoa.
static func icon_frame(npc_id: int) -> Texture2D:
	if TamerAppearance.for_npc(npc_id) != null:
		return load(PERSON_ICON) as Texture2D
	return first_frame(slug_of(npc_id))


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
	var appearance := TamerAppearance.for_npc(map_npc.npc_id)
	if appearance != null:
		_look = TamerSprite.new()
		_look.set_appearance(appearance)
		add_child(_look)
		play_idle()


func play_idle() -> void:
	if _look == null:
		super()
		return
	_sync_look()
	_look.play_idle()


func play_walk() -> void:
	if _look == null:
		super()
		return
	_sync_look()
	_look.play_run()


func face_toward(direction: Vector2) -> void:
	super(direction)
	if _look != null:
		_sync_look()


func _sync_look() -> void:
	_look._row = _row
	_look.flip_h = flip_h


## Com `map` nulo (o editor), ele fica parado.
func place_on(view: HexMapView, map: ExplorationMap) -> void:
	_view = view
	_map = map
	view.add_child(self)
	_exact = view.surface_center(coord)
	position = _exact.round()
	_follow_depth()
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


## Anda até o hexágono pelo caminho dos NPCs; sem caminho, aparece lá.
func walk_to(target: Vector2i) -> int:
	_path.clear()
	if target == coord:
		return ARRIVED
	var goals: Dictionary[Vector2i, bool] = {target: true}
	_path = _map.path_to_any(coord, goals, Vector2.INF, false)
	if _path.is_empty():
		coord = target
		_exact = _view.surface_center(coord)
		position = _exact.round()
		_follow_depth()
		play_idle()
		return JUMPED
	face_toward(_view.surface_center(_path[0]) - _exact)
	play_walk()
	return WALKING


## Aparece no hexágono, parado, sem andar (o teleporte, minimap/03).
func jump_to(target: Vector2i) -> void:
	_path.clear()
	coord = target
	_exact = _view.surface_center(coord)
	position = _exact.round()
	_follow_depth()
	play_idle()


func is_walking() -> bool:
	return not _path.is_empty()


## Volta ao passeio da ilha depois de uma cena.
func resume() -> void:
	scripted = false
	walk_speed = WALK_SPEED
	_held = false
	_path.clear()
	_rest()


func _process(delta: float) -> void:
	if _view == null or _map == null or _held:
		return
	if _path.is_empty():
		if scripted or npc.still:
			return
		_rest_left -= delta
		if _rest_left <= 0.0:
			_start_trip()
		return
	var next := _path[0]
	var target := _view.surface_center(next)
	_exact = _exact.move_toward(target, walk_speed * delta)
	position = _exact.round()
	if coord != next and _exact.distance_to(target) < _exact.distance_to(_view.surface_center(coord)):
		coord = next
	_follow_depth()
	if _exact == target:
		_path.pop_front()
		if _path.is_empty() and scripted:
			play_idle()
			arrived.emit()
		elif _path.is_empty():
			_rest()
		else:
			face_toward(_view.surface_center(_path[0]) - _exact)
			play_walk()


## O pé no chão plano, pela altura do hexágono de agora (prop-depth-blocks/01).
func _follow_depth() -> void:
	_view.follow_depth(self, _exact + HexMapView.flat_center(coord) - _view.surface_center(coord), coord.y)


func _rest() -> void:
	play_idle()
	_rest_left = randf_range(MIN_REST, MAX_REST)


func _start_trip() -> void:
	var options: Array[Vector2i] = []
	for tile: Vector2i in npc.walk_tiles():
		if tile != coord and _map.has(tile):
			options.append(tile)
	if options.is_empty():
		_rest()
		return
	var goals: Dictionary[Vector2i, bool] = {options.pick_random(): true}
	# O NPC vai de centro em centro e não sabe andar pelo piso das pontes (bridges/04).
	_path = _map.path_to_any(coord, goals, Vector2.INF, false)
	if _path.is_empty():
		_rest()
		return
	face_toward(_view.surface_center(_path[0]) - _exact)
	play_walk()
