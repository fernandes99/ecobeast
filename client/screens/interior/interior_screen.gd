extends Control

## O lado de dentro de um prédio (interiors/02), aberto por cima de Explorar: o Domador
## nasce na porta, anda por toque, fala com os NPCs parados e sai ao pisar na porta
## vindo de outro quadrado.

const LOADING_TEXT := "Entrando…"
const MAX_TAP_TRAVEL := 24.0
## A máquina de cura: o objeto com a ação `refuge` (interiors/04).
const MACHINE_ACTION := "refuge"
const HEALED_TEXT := "Sua equipe está curada!"
const HEAL_PULSES := 3
const HEAL_SECONDS := 1.2
const HEAL_GLOW := Color(1.8, 1.8, 2.1)
const HEAL_SOUND := preload("res://assets/sounds/refuge/heal.wav")

var _interior: Interior = null
var _interior_id := 0
## Os NPCs Domadores da ilha, que lutam depois da última fala (auralis/05).
var _tamer_npc_ids: Array[int] = []
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
## O objeto com ação para onde o Domador anda, ou -1.
var _object_target := -1
var _heal_sound := AudioStreamPlayer.new()
## A conversa com o NPC, com a missão dele (auralis/10).
var _choices := StoryChoicePanel.new()
var _conversation: QuestConversation = null
var _conversing := false
## O NPC cujas falas de missão estão na caixa, ou esperando o servidor (auralis/06).

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
	var tamers: Variant = params.get("tamer_npc_ids", [])
	if tamers is Array:
		for id: Variant in tamers:
			_tamer_npc_ids.append(int(id))


func _ready() -> void:
	_background.color = UiPalette.BACKGROUND
	_heal_sound.stream = HEAL_SOUND
	_heal_sound.bus = AudioSettings.SFX_BUS
	add_child(_heal_sound)
	_room_area.add_child(_view)
	_view.visible = false
	_room_area.gui_input.connect(_on_room_input)
	_room_area.resized.connect(_place_camera)
	_status_back.pressed.connect(Router.back)
	var column := _greeting.get_parent()
	column.add_child(_choices)
	column.move_child(_choices, _greeting.get_index())
	_conversation = QuestConversation.new(_greeting, _choices)
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


## Com a conversa aberta, o voltar não sai da sala.
func handle_back() -> bool:
	return _conversing


## O ponto dos pés do Domador, em pixels da arte.
func player_point() -> Vector2:
	return _point


## O toque na sala, em pixels da arte (o mesmo caminho do toque na tela).
func tap_art(point: Vector2) -> void:
	if _route == null or _leaving or _conversing:
		return
	_npc_target = null
	_object_target = -1
	_show_message("")
	for sprite: NpcSprite in _npc_sprites:
		if sprite.hits(point):
			_go_to_npc(sprite)
			return
	var touched := _object_with_action_at(point)
	if touched >= 0:
		_go_to_object(touched)
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
		elif _object_target >= 0:
			var index := _object_target
			_object_target = -1
			_use_object(index)


func _add_npcs(interior: Interior) -> void:
	for npc: InteriorNpc in interior.npcs:
		var map_npc := npc.to_map_npc()
		map_npc.tamer = _tamer_npc_ids.has(npc.npc_id)
		var sprite := NpcSprite.make(map_npc)
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
	_conversing = true
	var npc := sprite.npc
	await _conversation.run(npc)
	if not is_inside_tree():
		return
	_conversing = false
	if is_instance_valid(sprite):
		sprite.hold(false)
	_finish_talk(npc)


## O Domador da ilha luta no lugar da ação; perder volta ao Hub (auralis/05).
func _finish_talk(npc: MapNpc) -> void:
	if not npc.tamer:
		_run_action(npc.action_type_id)
		return
	if await BattleIntro.cover(_tamer.get_global_transform_with_canvas().origin, &"tamer"):
		Router.push(&"board_battle", {"island_tamer": npc.npc_id})


## O objeto com ação de pé mais baixo cuja arte cobre o ponto, ou -1.
func _object_with_action_at(point: Vector2) -> int:
	var best := -1
	for index: int in _interior.objects.size():
		var item := _interior.objects[index]
		if item.action_type_id <= 0:
			continue
		var art := Rect2(Vector2(item.cell * InteriorTiles.CELL), Vector2(item.size * InteriorTiles.CELL))
		if art.has_point(point) and (best < 0 or item.foot_y() > _interior.objects[best].foot_y()):
			best = index
	return best


## Encostado (um quadrado de lado de um quadrado do objeto), a ação acontece; senão, o
## Domador anda até o quadrado livre ao lado de caminho mais curto.
func _go_to_object(index: int) -> void:
	var rect := _interior.objects[index].rect()
	var mine := InteriorTiles.cell_of(_point)
	var best := InteriorRoute.NONE
	var best_path := PackedVector2Array()
	var best_length := INF
	for y: int in range(rect.position.y - 1, rect.end.y + 1):
		for x: int in range(rect.position.x - 1, rect.end.x + 1):
			var cell := Vector2i(x, y)
			var beside := (x >= rect.position.x and x < rect.end.x) != (y >= rect.position.y and y < rect.end.y)
			if not beside or _route.is_blocked(cell):
				continue
			if cell == mine:
				_path.clear()
				_use_object(index)
				return
			var path := _route.route_to_cell(_point, cell)
			if path.is_empty():
				continue
			var length := _point.distance_to(path[0])
			for step: int in range(1, path.size()):
				length += path[step - 1].distance_to(path[step])
			if length < best_length:
				best = cell
				best_path = path
				best_length = length
	if best == InteriorRoute.NONE:
		return
	_object_target = index
	_walk(best_path)


func _use_object(index: int) -> void:
	var item := _interior.objects[index]
	var center := Vector2(item.cell * InteriorTiles.CELL) + Vector2(item.size * InteriorTiles.CELL) / 2.0
	_tamer.face_toward(center - _point)
	_tamer.play_idle()
	var slug := str(GameData.get_row("action_types", item.action_type_id).get("slug", ""))
	if slug == MACHINE_ACTION:
		_heal_machine(index)
	else:
		_run_action(item.action_type_id)


## A máquina pisca e toca o som enquanto o servidor cura; com a equipe curada, a caixa
## de fala avisa com a voz da narração.
func _heal_machine(index: int) -> void:
	if Session.player == null or not Session.player.has_starter():
		_show_message(ActionScreens.NO_TEAM_HEAL_TEXT)
		return
	_conversing = true
	var sprite := _view.object_nodes[index]
	var tween := create_tween()
	var half := HEAL_SECONDS / HEAL_PULSES / 2.0
	for _pulse: int in HEAL_PULSES:
		tween.tween_property(sprite, "modulate", HEAL_GLOW, half)
		tween.tween_property(sprite, "modulate", Color.WHITE, half)
	_heal_sound.play()
	var result: Result = await Session.heal_team()
	if tween.is_running():
		await tween.finished
	if not is_inside_tree():
		return
	if not result.ok:
		_conversing = false
		_show_message(result.error)
		return
	_greeting.say(HEALED_TEXT, GameData.voice_by_slug(StoryPlayer.NARRATION_VOICE))
	await _greeting.tapped
	if not is_inside_tree():
		return
	_greeting.close()
	_conversing = false


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
