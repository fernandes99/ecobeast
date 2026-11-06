extends Control
## Mapa de exploração (wild-battle/03, TELAS.md #4): o jogador fica parado no
## centro da tela, e quem se move é o mapa. Ele anda um hexágono por vez, por
## toque, sem zoom nem arrastar. Quem gera o mapa e os Ecobeasts é o servidor, e ele
## confere a posição do Domador ao Procurar (biome-encounters/04).

const PortraitScene := preload("res://ui/components/creature_portrait.tscn")

const LOADING_TEXT := "Gerando mapa..."
const NOTHING_HERE_TEXT := "Nada por aqui."
const ALMOST_LEVEL_UP_TEXT := "A equipe está a 1 XP do próximo nível."
const SPAWNED_TEXT := "%s apareceu aqui. Toque em Procurar."
## Duração de um passo, em segundos: um ciclo inteiro da corrida do Domador.
const STEP_SECONDS := TamerSprite.RUN_SECONDS
## Até quanto o dedo pode correr, em pontos da tela lógica, para ainda ser um toque.
const MAX_TAP_TRAVEL := 24.0
const WHOLE_MAP_TEXT := "Debug: ver mapa inteiro"
const NORMAL_ZOOM_TEXT := "Debug: voltar ao zoom normal"
const DEBUG_SPECIES_HEIGHT := 112.0
const DEBUG_PORTRAIT_SIZE := 64
const DEBUG_NAME_FONT_SIZE := 18
## Quanto apaga o cartão de quem ainda não tem folhas.
const DEBUG_DISABLED_ALPHA := 0.35
const GOD_ON_TEXT := "God: ligado"
const GOD_OFF_TEXT := "God: desligado"
## Até onde os Ecobeasts existem como nós, em hexágonos: passa da tela com folga,
## para eles nascerem e saírem sem ninguém ver. A revisar.
const CREATURE_RADIUS := 16

## null até o servidor responder.
var _map: ExplorationMap = null
var _player_coord := Vector2i.ZERO
## O pedido do mapa ainda vai voltar para esta tela.
var _loading: bool = true
var _walking: bool = false
var _press_position := Vector2.ZERO
## Só em build de debug: o mapa inteiro na tela, sem andar.
var _showing_whole_map: bool = false
## Os Ecobeasts do mapa que têm nó agora, pelo id deles.
var _wild_sprites: Dictionary[int, CreatureSprite] = {}
## Só em build de debug: os ids dos Ecobeasts do spawn, que o servidor guarda junto
## com os do mapa (biome-encounters/05).
var _debug_spawn_ids: Array[int] = []

@onready var _map_area: Control = %MapArea
@onready var _map_view: HexMapView = %MapView
@onready var _marker: TamerSprite = %PlayerMarker
@onready var _controls_panel: Control = %ControlsPanel
@onready var _message: Label = %Message
@onready var _encounter_button: Button = %EncounterButton
@onready var _bag_button: Button = %BagButton
@onready var _back_button: Button = %BackButton
@onready var _debug_button: Button = %DebugButton
@onready var _debug_menu: Control = %DebugMenu
@onready var _debug_zoom_button: Button = %DebugZoomButton
@onready var _debug_species: Control = %DebugSpecies
@onready var _debug_clear_button: Button = %DebugClearButton
@onready var _debug_xp_button: Button = %DebugXpButton
@onready var _debug_main: Control = %DebugMain
@onready var _debug_spawn: Control = %DebugSpawn
@onready var _debug_spawn_button: Button = %DebugSpawnButton
@onready var _debug_spawn_back_button: Button = %DebugSpawnBackButton
@onready var _debug_god_button: Button = %DebugGodButton


func _ready() -> void:
	_map_area.gui_input.connect(_on_map_input)
	_encounter_button.pressed.connect(_search)
	_bag_button.pressed.connect(Router.push.bind(&"bag"))
	_back_button.pressed.connect(Router.back)
	_debug_button.pressed.connect(_toggle_debug_menu)
	_debug_zoom_button.pressed.connect(_toggle_whole_map)
	_debug_clear_button.pressed.connect(_clear_creatures)
	_debug_xp_button.pressed.connect(_almost_level_up)
	_debug_spawn_button.pressed.connect(_show_debug_part.bind(true))
	_debug_spawn_back_button.pressed.connect(_show_debug_part.bind(false))
	_debug_god_button.pressed.connect(_toggle_god)
	%DebugTest2Button.pressed.connect(_open_board_test.bind(2))
	%DebugTest3Button.pressed.connect(_open_board_test.bind(3))
	_refresh_god_button()
	resized.connect(_fit_view.call_deferred)
	visibility_changed.connect(_on_visibility_changed)
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
	_refresh_wild_sprites()
	_map_view.show()
	_marker.show()
	_message.hide()
	_encounter_button.disabled = false
	_bag_button.disabled = false
	if OS.is_debug_build():
		_debug_button.show()
		_fill_debug_species()
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


## O servidor recusaria quem chegou agora, e o hexágono já é o de destino no meio
## do passo: enquanto o Domador anda, Procurar não faz nada.
func _search() -> void:
	if _walking:
		return
	if _map.has_creature(_player_coord):
		# A luta de Explorar zona é a do tabuleiro (board-battle/05).
		Router.push(&"board_battle", {"coord": _player_coord})
	else:
		_show_message(NOTHING_HERE_TEXT, &"SecondaryLabel")


## Depois da luta, ganhando, perdendo ou correndo, o Ecobeast já saiu do mapa.
func _on_visibility_changed() -> void:
	if visible and _map != null:
		var fought := Session.take_fought_spawn()
		_map.creatures.erase(fought)
		_debug_spawn_ids.erase(fought)
		_debug_clear_button.disabled = _debug_spawn_ids.is_empty()
		_refresh_wild_sprites()


func _step_to(target: Vector2i) -> void:
	_walking = true
	_message.hide()
	_marker.face(target - _player_coord)
	_marker.play_run()
	# Indo para a frente, ele muda de plano antes de sair: a linha nova cobriria os pés
	# dele. Voltando, é a linha de onde ele veio que cobriria, então muda ao chegar.
	if target.y > _player_coord.y:
		_map_view.set_actor_row(_marker, target.y)
	_player_coord = target
	_map_view.set_current(target)
	_refresh_wild_sprites()
	var step := create_tween()
	step.tween_method(_move_map, _map_view.position, _player_centered_position(), STEP_SECONDS)
	await step.finished
	_map_view.set_actor_row(_marker, target.y)
	_marker.play_idle()
	_walking = false


func _toggle_whole_map() -> void:
	if _walking:
		return
	_debug_menu.hide()
	_showing_whole_map = not _showing_whole_map
	_debug_zoom_button.text = NORMAL_ZOOM_TEXT if _showing_whole_map else WHOLE_MAP_TEXT
	_refresh_wild_sprites()
	_fit_view()


## O menu sempre abre na parte principal.
func _toggle_debug_menu() -> void:
	_show_debug_part(false)
	_debug_menu.visible = not _debug_menu.visible


## A lista do Spawn, ou os botões principais.
func _show_debug_part(spawn: bool) -> void:
	_debug_spawn.visible = spawn
	_debug_main.visible = not spawn


## O God vale para as lutas que começarem depois; o menu continua aberto.
func _toggle_god() -> void:
	Session.debug_god = not Session.debug_god
	_refresh_god_button()


func _refresh_god_button() -> void:
	_debug_god_button.text = GOD_ON_TEXT if Session.debug_god else GOD_OFF_TEXT


## A luta de teste no tabuleiro, contra Ecobeasts sorteados; o mapa não muda.
func _open_board_test(slots: int) -> void:
	if _walking:
		return
	_debug_menu.hide()
	Router.push(&"board_battle", {"test_slots": slots})


## Todos os Ecobeasts do catálogo, cada um com o retrato e o nome; quem ainda não
## tem folhas fica apagado e desativado.
func _fill_debug_species() -> void:
	for species: CreatureSpecies in GameData.get_all_species():
		var button := Button.new()
		button.theme_type_variation = &"OutlineButton"
		button.custom_minimum_size = Vector2(0.0, DEBUG_SPECIES_HEIGHT)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = not CreatureSprite.has_sheets(species.slug)
		button.pressed.connect(_spawn.bind(species))
		button.add_child(_species_card(species, button.disabled))
		_debug_species.add_child(button)


func _species_card(species: CreatureSpecies, disabled: bool) -> Control:
	var card := VBoxContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.modulate.a = DEBUG_DISABLED_ALPHA if disabled else 1.0
	var portrait: CreaturePortrait = PortraitScene.instantiate()
	portrait.portrait_size = DEBUG_PORTRAIT_SIZE
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(portrait)
	portrait.set_species(species.id)
	var label := Label.new()
	label.text = species.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override(&"font_size", DEBUG_NAME_FONT_SIZE)
	card.add_child(label)
	return card


## O servidor põe o Ecobeast no hexágono do Domador (biome-encounters/05): Procurar
## enfrenta ele como um do mapa, e depois da luta ele some como os outros.
func _spawn(species: CreatureSpecies) -> void:
	if _walking:
		return
	var result: Result = await Session.debug_spawn(species.id, _player_coord)
	if not result.ok:
		_show_message(result.error, &"DangerLabel")
		return
	var creature: MapCreature = result.data
	_map.creatures[creature.id] = creature
	_debug_spawn_ids.append(creature.id)
	_refresh_wild_sprites()
	_debug_clear_button.disabled = false
	_show_message(SPAWNED_TEXT % species.name, &"SecondaryLabel")


## Tira do servidor e do mapa só os Ecobeasts do spawn.
func _clear_creatures() -> void:
	_debug_clear_button.disabled = true
	var result: Result = await Session.debug_clear_spawns()
	if not result.ok:
		_debug_clear_button.disabled = false
		_show_message(result.error, &"DangerLabel")
		return
	for id: int in result.data:
		_map.creatures.erase(id)
	_debug_spawn_ids.clear()
	_refresh_wild_sprites()


## Só para testar a progressão (progression/04): cada um da equipe fica a 1 XP do
## próximo nível, e a próxima vitória sobe. O servidor só aceita com a rota de
## teste ligada.
func _almost_level_up() -> void:
	_debug_xp_button.disabled = true
	var result: Result = await Session.debug_almost_level_up()
	_debug_xp_button.disabled = false
	_debug_menu.hide()
	if result.ok:
		_show_message(ALMOST_LEVEL_UP_TEXT, &"SecondaryLabel")
	else:
		_show_message(result.error, &"DangerLabel")


## Deixa com nó só os Ecobeasts perto do Domador. Quem sai e volta fica no mesmo
## hexágono, porque o lugar dele mora no mapa, e não no nó.
func _refresh_wild_sprites() -> void:
	for id: int in _wild_sprites.keys():
		if not _map.creatures.has(id) or not _is_near(_map.creatures[id]):
			_wild_sprites[id].queue_free()
			_wild_sprites.erase(id)
	for creature: MapCreature in _map.creatures.values():
		if not _wild_sprites.has(creature.id) and _is_near(creature):
			var species := GameData.get_species(creature.species_id)
			if species != null and CreatureSprite.has_sheets(species.slug):
				_wild_sprites[creature.id] = _add_creature_sprite(species.slug, creature.coord)


func _is_near(creature: MapCreature) -> bool:
	return _showing_whole_map or ExplorationMap.distance(creature.coord, _player_coord) <= CREATURE_RADIUS


func _add_creature_sprite(slug: String, coord: Vector2i) -> CreatureSprite:
	var creature := CreatureSprite.new(slug)
	_map_view.add_child(creature)
	_map_view.set_actor_row(creature, coord.y)
	creature.wander_in(coord, _map_view.surface_center(coord))
	creature.scale = _marker.scale
	return creature


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
	# Filhos do mapa, eles encolheriam junto com o mapa inteiro.
	_marker.scale = _map_view.art_scale() / _map_view.pixel_scale()
	for creature: CreatureSprite in _wild_sprites.values():
		creature.scale = _marker.scale


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
