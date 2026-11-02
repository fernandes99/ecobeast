extends Control
## Mapa de exploração (wild-battle/03, TELAS.md #4): o jogador fica parado no
## centro da tela, e quem se move é o mapa. Ele anda um hexágono por vez, por
## toque, sem zoom nem arrastar. Quem gera o mapa é o servidor; a posição fica
## só aqui até o terreno decidir alguma regra.

const LOADING_TEXT := "Gerando mapa..."
## Duração de um passo, em segundos: um ciclo inteiro da corrida do Domador.
const STEP_SECONDS := TamerSprite.RUN_SECONDS
## Até quanto o dedo pode correr, em pontos da tela lógica, para ainda ser um toque.
const MAX_TAP_TRAVEL := 24.0
const WHOLE_MAP_TEXT := "Debug: ver mapa inteiro"
const NORMAL_ZOOM_TEXT := "Debug: voltar ao zoom normal"

## null até o servidor responder.
var _map: ExplorationMap = null
var _player_coord := Vector2i.ZERO
## O pedido do mapa ainda vai voltar para esta tela.
var _loading: bool = true
var _walking: bool = false
var _press_position := Vector2.ZERO
## Só em build de debug: o mapa inteiro na tela, sem andar.
var _showing_whole_map: bool = false

@onready var _map_area: Control = %MapArea
@onready var _map_view: HexMapView = %MapView
@onready var _marker: TamerSprite = %PlayerMarker
@onready var _controls_panel: Control = %ControlsPanel
@onready var _message: Label = %Message
@onready var _encounter_button: Button = %EncounterButton
@onready var _bag_button: Button = %BagButton
@onready var _back_button: Button = %BackButton
@onready var _debug_zoom_button: Button = %DebugZoomButton


func _ready() -> void:
	_map_area.gui_input.connect(_on_map_input)
	_encounter_button.pressed.connect(Router.push.bind(&"battle"))
	_bag_button.pressed.connect(Router.push.bind(&"bag"))
	_back_button.pressed.connect(Router.back)
	_debug_zoom_button.pressed.connect(_toggle_whole_map)
	resized.connect(_fit_view.call_deferred)
	_begin()


## A resposta do servidor volta para esta tela: ela não fecha antes disso.
func handle_back() -> bool:
	return _loading


func _begin() -> void:
	_show_message(LOADING_TEXT, &"SecondaryLabel")
	var result: Result = await Session.start_exploration()
	_loading = false
	_back_button.disabled = false
	if not result.ok:
		_show_message(result.error, &"DangerLabel")
		return
	_map = result.data
	_player_coord = _map.start
	_map_view.set_map(_map)
	_map_view.set_current(_player_coord)
	_map_view.set_actor_row(_marker, _player_coord.y)
	_map_view.show()
	_marker.show()
	_message.hide()
	_encounter_button.disabled = false
	_bag_button.disabled = false
	_debug_zoom_button.visible = OS.is_debug_build()
	# O botão de debug muda a altura do painel.
	_fit_view.call_deferred()


func _on_map_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse.pressed:
		_press_position = mouse.position
	elif mouse.position.distance_to(_press_position) <= MAX_TAP_TRAVEL:
		_tap(mouse.position)


func _tap(point: Vector2) -> void:
	if _map == null or _walking or _showing_whole_map:
		return
	var art_point := (point - _map_view.position) / _map_view.pixel_scale()
	var target := _map_view.coord_at(art_point)
	if _map.neighbors(_player_coord).has(target):
		_step_to(target)


func _step_to(target: Vector2i) -> void:
	_walking = true
	_marker.face(target - _player_coord)
	_marker.play_run()
	# Indo para a frente, ele muda de plano antes de sair: a linha nova cobriria os pés
	# dele. Voltando, é a linha de onde ele veio que cobriria, então muda ao chegar.
	if target.y > _player_coord.y:
		_map_view.set_actor_row(_marker, target.y)
	_player_coord = target
	_map_view.set_current(target)
	var step := create_tween()
	step.tween_method(_move_map, _map_view.position, _player_centered_position(), STEP_SECONDS)
	await step.finished
	_map_view.set_actor_row(_marker, target.y)
	_marker.play_idle()
	_walking = false


func _toggle_whole_map() -> void:
	if _walking:
		return
	_showing_whole_map = not _showing_whole_map
	_debug_zoom_button.text = NORMAL_ZOOM_TEXT if _showing_whole_map else WHOLE_MAP_TEXT
	_fit_view()


func _fit_view() -> void:
	if _map == null:
		return
	if _showing_whole_map:
		var panel_top := _controls_panel.get_global_rect().position.y
		_map_view.show_whole_map(Rect2(0.0, 0.0, size.x, panel_top))
		_marker.position = _map_view.surface_center(_player_coord)
	else:
		_map_view.show_pixel_art()
		_move_map(_player_centered_position())
	# Filho do mapa, ele encolheria junto com o mapa inteiro.
	_marker.scale = _map_view.art_scale() / _map_view.pixel_scale()


## Parte do centro já arredondado: em uma tela de tamanho ímpar, ele cai no meio de
## um pixel, e arredondar depois da conta deixaria o Domador fora do hexágono.
func _player_centered_position() -> Vector2:
	return _map_view.snapped_to_pixels(size / 2.0) - _map_view.surface_center(_player_coord) * _map_view.pixel_scale()


## Sempre em pixels reais inteiros, para a pixel art não borrar no caminho. O Domador
## é filho do mapa: a posição dele desconta o mapa, e ele fica parado na tela.
func _move_map(value: Vector2) -> void:
	_map_view.position = _map_view.snapped_to_pixels(value)
	_marker.position = (_map_view.snapped_to_pixels(size / 2.0) - _map_view.position) / _map_view.pixel_scale()


func _show_message(text: String, variation: StringName) -> void:
	_message.text = text
	_message.theme_type_variation = variation
	_message.show()
