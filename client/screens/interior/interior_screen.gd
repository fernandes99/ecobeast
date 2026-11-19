extends Control

## O lado de dentro de um prédio (interiors/02), aberto por cima de Explorar: o Domador
## nasce na porta, anda por toque, fala com os NPCs parados e sai ao pisar na porta
## vindo de outro quadrado.

const LOADING_TEXT := "Entrando…"
const MAX_TAP_TRAVEL := 24.0

var _interior: Interior = null
var _interior_id := 0
var _view := InteriorView.new()
var _route: InteriorRoute = null
var _tamer: TamerSprite = null
var _point := Vector2.ZERO
var _cell := Vector2i.ZERO
var _path := PackedVector2Array()
var _leaving := false
var _press_position := Vector2.ZERO
var _npc_sprites: Array[NpcSprite] = []
var _npc_target: NpcSprite = null
var _talking: NpcSprite = null
var _talk_lines: Array[String] = []
var _talk_index := 0

@onready var _background: ColorRect = %Background
@onready var _room_area: Control = %RoomArea
@onready var _name_plate: PanelContainer = %NamePlate
@onready var _room_name: Label = %RoomName
@onready var _status_box: VBoxContainer = %StatusBox
@onready var _status_label: Label = %StatusLabel
@onready var _status_back: Button = %StatusBack
@onready var _message_panel: PanelContainer = %MessagePanel
@onready var _message: Label = %Message
@onready var _greeting: TamerGreetingPanel = %TamerGreeting


func setup(params: Dictionary) -> void:
	if params.get("interior") is Interior:
		_interior = params["interior"]
	_interior_id = int(params.get("interior_id", 0))


func _ready() -> void:
	_background.color = UiPalette.BACKGROUND
	_room_area.add_child(_view)
	_view.visible = false
	_room_area.gui_input.connect(_on_room_input)
	_room_area.resized.connect(_place_camera)
	_status_back.pressed.connect(Router.back)
	_greeting.tapped.connect(_on_greeting_tapped)
	if _interior != null:
		_show(_interior)
		return
	_status_label.text = LOADING_TEXT
	var result: Result = await Session.load_interior(_interior_id)
	if not is_inside_tree():
		return
	if not result.ok:
		_status_label.text = result.error
		_status_back.show()
		return
	_show(result.data)


## Com a conversa aberta, o voltar só a fecha, sem a ação do NPC.
func handle_back() -> bool:
	if _talking == null:
		return false
	_greeting.close()
	_talking.hold(false)
	_talking = null
	return true


## O ponto dos pés do Domador, em pixels da arte.
func player_point() -> Vector2:
	return _point


## O toque na sala, em pixels da arte (o mesmo caminho do toque na tela).
func tap_art(point: Vector2) -> void:
	if _route == null or _leaving or _talking != null:
		return
	_npc_target = null
	_show_message("")
	for sprite: NpcSprite in _npc_sprites:
		if sprite.hits(point):
			_go_to_npc(sprite)
			return
	_walk(_route.route(_point, point))


func _show(interior: Interior) -> void:
	_interior = interior
	_status_box.hide()
	_room_name.text = interior.name
	_name_plate.show()
	var npc_cells: Dictionary[Vector2i, bool] = {}
	for npc: InteriorNpc in interior.npcs:
		npc_cells[npc.cell] = true
	_route = InteriorRoute.new(interior, npc_cells)
	_view.show_interior(interior)
	_add_npcs(interior)
	_tamer = TamerSprite.new()
	if Session.player != null:
		_tamer.set_appearance(Session.player.appearance)
	_view.actors.add_child(_tamer)
	_point = InteriorTiles.cell_center(interior.door)
	_cell = interior.door
	_tamer.position = _point
	_tamer.face_toward(Vector2.UP)
	_tamer.play_idle()
	_view.visible = true
	_place_camera()


func _walk(path: PackedVector2Array) -> void:
	_path = path
	if _path.is_empty():
		_tamer.play_idle()
		return
	_tamer.face_toward(_path[0] - _point)
	_tamer.play_run()


func _process(delta: float) -> void:
	if _path.is_empty() or _leaving:
		return
	var step := WalkRoute.WALK_SPEED * delta
	while step > 0.0 and not _path.is_empty():
		var next := _path[0]
		var distance := _point.distance_to(next)
		if distance <= step:
			_point = next
			step -= distance
			_path.remove_at(0)
			if not _path.is_empty():
				_tamer.face_toward(_path[0] - _point)
		else:
			_point = _point.move_toward(next, step)
			step = 0.0
		if _enter_cell(InteriorTiles.cell_of(_point)):
			return
	_tamer.position = _point.round()
	_place_camera()
	if _path.is_empty():
		_tamer.play_idle()
		if _npc_target != null:
			var npc := _npc_target
			_npc_target = null
			_talk(npc)


func _add_npcs(interior: Interior) -> void:
	for npc: InteriorNpc in interior.npcs:
		var sprite := NpcSprite.make(npc.to_map_npc())
		if sprite == null:
			continue
		sprite.position = InteriorTiles.cell_center(npc.cell)
		_view.actors.add_child(sprite)
		sprite.face_toward(Vector2.DOWN)
		sprite.play_idle()
		_npc_sprites.append(sprite)


## Encostado (um quadrado de lado), a conversa abre; senão, o Domador anda até o quadrado
## livre ao lado de caminho mais curto, e ela abre ao chegar.
func _go_to_npc(sprite: NpcSprite) -> void:
	var cell := sprite.npc.coord
	var mine := InteriorTiles.cell_of(_point)
	if absi(mine.x - cell.x) + absi(mine.y - cell.y) == 1:
		_path.clear()
		_talk(sprite)
		return
	var side := _route.approach(_point, cell)
	if side == InteriorRoute.NONE:
		return
	var path := _route.route_to_cell(_point, side)
	if path.is_empty():
		_talk(sprite)
		return
	_npc_target = sprite
	_walk(path)


func _talk(sprite: NpcSprite) -> void:
	_tamer.face_toward(sprite.position - _point)
	_tamer.play_idle()
	sprite.hold(true, _point)
	var lines := sprite.npc.lines()
	if lines.is_empty():
		sprite.hold(false)
		_run_action(sprite.npc.action_type_id)
		return
	_talking = sprite
	_talk_lines = lines
	_talk_index = 0
	_say_line()


func _say_line() -> void:
	var npc_id := _talking.npc.npc_id
	var npc_name := str(GameData.get_npc(npc_id).get("name", ""))
	_greeting.say("%s: %s" % [npc_name, _talk_lines[_talk_index]], GameData.npc_voice(npc_id))


func _on_greeting_tapped() -> void:
	if _talking == null:
		return
	_talk_index += 1
	if _talk_index < _talk_lines.size():
		_say_line()
		return
	var sprite := _talking
	_talking = null
	_greeting.close()
	sprite.hold(false)
	_run_action(sprite.npc.action_type_id)


func _run_action(type_id: int) -> void:
	_show_message(ActionScreens.open(type_id))


## Pisar na porta vindo de outro quadrado sai da sala.
func _enter_cell(cell: Vector2i) -> bool:
	if cell == _cell:
		return false
	var from := _cell
	_cell = cell
	if cell == _interior.door and from != _interior.door:
		_leaving = true
		_path.clear()
		Router.back()
		return true
	return false


func _on_room_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse.pressed:
		_press_position = mouse.position
	elif mouse.position.distance_to(_press_position) <= MAX_TAP_TRAVEL and _view.visible:
		tap_art((mouse.position - _view.position) / _view.scale)


## A escala é o degrau de zoom de Explorar, em pixels inteiros da janela; a câmera segue
## o Domador e para na borda da sala, ou centra a sala que cabe na tela.
func _place_camera() -> void:
	if _interior == null or _tamer == null or not is_inside_tree() or get_viewport_rect().size.x <= 0.0:
		return
	var window_scale := Vector2(get_window().size) / get_viewport_rect().size
	var pixels := maxi(1, roundi(window_scale.y * ViewSettings.explore_zoom()))
	var art_scale := Vector2(pixels, pixels) / window_scale
	_view.scale = art_scale
	var area := _room_area.size
	var room := Vector2(_interior.width, _interior.height) * InteriorTiles.CELL * art_scale
	var wanted := area / 2.0 - _tamer.position * art_scale
	var placed := Vector2.ZERO
	for axis: int in 2:
		if room[axis] > area[axis]:
			placed[axis] = clampf(wanted[axis], area[axis] - room[axis], 0.0)
		else:
			placed[axis] = (area[axis] - room[axis]) / 2.0
	_view.position = (placed * window_scale).round() / window_scale


func _show_message(text: String) -> void:
	_message.text = text
	_message_panel.visible = not text.is_empty()
