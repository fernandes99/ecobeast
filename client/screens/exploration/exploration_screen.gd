extends Control
## Mapa de exploração (wild-battle/03, TELAS.md #4): o jogador fica parado no
## centro da tela, e quem se move é o mapa. Ele anda um hexágono por vez, por
## toque, sem zoom nem arrastar. Quem gera o mapa é o servidor; a posição fica
## só aqui até o terreno decidir alguma regra.

const LOADING_TEXT := "Gerando mapa..."
## Duração de um passo, em segundos. A revisar.
const STEP_SECONDS := 0.18
## Até quanto o dedo pode correr, em pontos da tela lógica, para ainda ser um toque.
const MAX_TAP_TRAVEL := 24.0

## null até o servidor responder.
var _map: ExplorationMap = null
var _player_coord := Vector2i.ZERO
## O pedido do mapa ainda vai voltar para esta tela.
var _loading: bool = true
var _walking: bool = false
var _press_position := Vector2.ZERO

@onready var _map_area: Control = %MapArea
@onready var _map_view: HexMapView = %MapView
@onready var _marker: CreaturePortrait = %PlayerMarker
@onready var _message: Label = %Message
@onready var _encounter_button: Button = %EncounterButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_map_area.gui_input.connect(_on_map_input)
	_encounter_button.pressed.connect(Router.push.bind(&"battle"))
	_back_button.pressed.connect(Router.back)
	resized.connect(_center_on_player.call_deferred)
	_marker.set_species(Session.player.party[0].species_id)
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
	_center_on_player()
	_map_view.show()
	_marker.show()
	_message.hide()
	_encounter_button.disabled = false


func _on_map_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse.pressed:
		_press_position = mouse.position
	elif mouse.position.distance_to(_press_position) <= MAX_TAP_TRAVEL:
		_tap(mouse.position)


func _tap(point: Vector2) -> void:
	if _map == null or _walking:
		return
	var art_point := (point - _map_view.position) / _map_view.pixel_scale()
	var target := _map_view.coord_at(art_point)
	if _map.neighbors(_player_coord).has(target):
		_step_to(target)


func _step_to(target: Vector2i) -> void:
	_walking = true
	_player_coord = target
	var step := create_tween()
	step.tween_method(_move_map, _map_view.position, _player_centered_position(), STEP_SECONDS)
	await step.finished
	_walking = false


func _center_on_player() -> void:
	if _map != null:
		_move_map(_player_centered_position())


func _player_centered_position() -> Vector2:
	return size / 2.0 - _map_view.surface_center(_player_coord) * _map_view.pixel_scale()


## Sempre em pixels reais inteiros, para a pixel art não borrar no caminho.
func _move_map(value: Vector2) -> void:
	_map_view.position = _map_view.snapped_to_pixels(value)


func _show_message(text: String, variation: StringName) -> void:
	_message.text = text
	_message.theme_type_variation = variation
	_message.show()
