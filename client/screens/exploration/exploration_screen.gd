extends Control

const PortraitScene := preload("res://ui/components/creature_portrait.tscn")

const LOADING_TEXT := "Gerando mapa..."
const ISLAND_LOADING_TEXT := "Chegando na ilha..."
const ACTION_TINT_ALPHA := 0.45
const ACTION_SCREENS: Dictionary[String, StringName] = {
	"refuge": &"heal_station",
	"shop": &"shop",
}
const NOTHING_HERE_TEXT := "Nada por aqui."
const NO_PATH_TEXT := "Não dá para chegar lá."
const NO_TARGET := Vector2i(2147483647, 2147483647)
const ALMOST_LEVEL_UP_TEXT := "A equipe está a 1 XP do próximo nível."
const SPAWNED_TEXT := "%s apareceu aqui. Toque em Procurar."
const EXPLORE_MUSIC_FADE_IN := 1.0
## Pixels da arte por segundo ao subir ou descer de altura.
const RISE_SPEED := 160.0
## O plano é o da linha um pouco abaixo dos pés, para a linha da frente não cobri-los.
const FEET_DEPTH := 6.0
const ROUTE_DOT_SPACING := 16.0
## Até quanto o dedo pode correr, em pontos da tela lógica, para ainda ser um toque.
const MAX_TAP_TRAVEL := 24.0
const WHOLE_MAP_TEXT := "Debug: ver mapa inteiro"
const NORMAL_ZOOM_TEXT := "Debug: voltar ao zoom normal"
const DEBUG_SPECIES_HEIGHT := 112.0
const DEBUG_PORTRAIT_SIZE := 64
const DEBUG_NAME_FONT_SIZE := 18
const DEBUG_DISABLED_ALPHA := 0.35
const GOD_ON_TEXT := "God: ligado"
const GOD_OFF_TEXT := "God: desligado"
## Até onde os Ecobeasts existem como nós, em hexágonos: passa da tela com folga,
## para eles nascerem e saírem sem ninguém ver. A revisar.
const CREATURE_RADIUS := 16

var _island_id: int = 0
var _map: ExplorationMap = null
var _player_coord := Vector2i.ZERO
## O ponto dos pés no chão plano, sem a altura (wild-battle/15).
var _player_point := Vector2.ZERO
var _shown_rise := 0.0
var _loading: bool = true
var _walking: bool = false
var _next_point: Variant = null
var _route: Array[RouteMark] = []
var _press_position := Vector2.ZERO
var _showing_whole_map: bool = false
var _wild_sprites: Dictionary[int, CreatureSprite] = {}
var _tamer_sprites: Dictionary[int, TamerSprite] = {}
var _challenger: MapTamer = null
var _debug_spawn_ids: Array[int] = []
var _debug_tamer_ids: Array[int] = []

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
@onready var _greeting: TamerGreetingPanel = %TamerGreeting
@onready var _island_plate: Control = %IslandPlate
@onready var _island_name: Label = %IslandName
@onready var _building_names: BuildingNamesLayer = %BuildingNames


func setup(params: Dictionary) -> void:
	_island_id = int(params.get("island_id", 0))


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
	for size: int in [1, 2, 3]:
		(get_node("%%DebugTamer%dButton" % size) as Button).pressed.connect(_debug_tamer.bind(size))
	_greeting.tapped.connect(_fight_challenger)
	_refresh_god_button()
	resized.connect(_fit_view.call_deferred)
	visibility_changed.connect(_on_visibility_changed)
	_begin()


func handle_back() -> bool:
	return _loading or _challenger != null


func _exit_tree() -> void:
	Music.fade_out()


func _begin() -> void:
	_show_message(ISLAND_LOADING_TEXT if _island_id > 0 else LOADING_TEXT, &"SecondaryLabel")
	var result: Result = await Session.start_exploration(_island_id)
	_loading = false
	_back_button.disabled = false
	if not result.ok:
		_show_message(result.error, &"DangerLabel")
		return
	_map = result.data
	_player_coord = _map.start
	_player_point = HexMapView.flat_center(_player_coord)
	_map_view.random_decorations = _map.island_id <= 0
	_map_view.set_map(_map)
	_map_view.set_objects(_map.objects)
	_map_view.set_props(_map.props)
	_shown_rise = _rise_at(_player_coord)
	_map_view.set_current(_player_coord)
	_map_view.set_actor_depth(_marker, _player_point, _feet_row())
	_show_island()
	_refresh_wild_sprites()
	_map_view.show()
	_marker.show()
	_message.hide()
	Music.play_explore()
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
	if _map == null or _showing_whole_map or _challenger != null:
		return
	var art_point := (point - _map_view.position) / _map_view.pixel_scale()
	if _walking:
		_next_point = art_point
	else:
		_go_to(art_point)


## A arte de um objeto cobre os hexágonos de trás: o toque nela vale para o hexágono
## dele ao lado do Domador, o de ação primeiro; longe dele, para o mais perto do toque.
func _object_target(object: MapObject, art_point: Vector2) -> Vector2i:
	var best := NO_TARGET
	for coord: Vector2i in object.tiles:
		if not _map.neighbors(_player_coord).has(coord):
			continue
		if best == NO_TARGET or (_map.action_at(coord) >= 0 and _map.action_at(best) < 0):
			best = coord
		elif (_map.action_at(coord) >= 0) == (_map.action_at(best) >= 0) and _closer(coord, best, art_point):
			best = coord
	if best != NO_TARGET:
		return best
	for coord: Vector2i in object.tiles:
		if best == NO_TARGET or _closer(coord, best, art_point):
			best = coord
	return best


func _closer(coord: Vector2i, than: Vector2i, art_point: Vector2) -> bool:
	return _map_view.surface_center(coord).distance_to(art_point) < _map_view.surface_center(than).distance_to(art_point)


## Num livre, o Domador anda até o ponto tocado; num bloqueado, até o centro do lado
## livre mais perto, e executa a ação dele, se houver.
func _go_to(art_point: Vector2) -> void:
	var target := _map_view.coord_at(art_point)
	var object := _map_view.object_hit(art_point)
	if object != null:
		target = _object_target(object, art_point)
	if not _map.has(target):
		return
	var action := -1
	var goals: Dictionary[Vector2i, bool] = {target: true}
	var finish := art_point + Vector2(0.0, _rise_at(target))
	if HexMapView.grid_coord(finish) != target:
		finish = HexMapView.flat_center(target)
	if _map.is_blocked(target):
		action = _map.action_at(target)
		goals = _map.free_sides(target)
		if goals.has(_player_coord):
			if action >= 0:
				_run_action(action)
			return
	var hexes: Array[Vector2i] = [_player_coord]
	if not goals.has(_player_coord):
		var path := _map.path_to_any(_player_coord, goals)
		if path.is_empty():
			_show_message(NO_PATH_TEXT, &"SecondaryLabel")
			return
		hexes.append_array(path)
		if _map.is_blocked(target):
			finish = HexMapView.flat_center(path[path.size() - 1])
	if finish.distance_to(_player_point) < 1.0:
		return
	_walk(WalkRoute.points(_map, _player_point, hexes, finish), action)


## Quadro a quadro: o hexágono muda quando os pés cruzam a borda (wild-battle/15).
func _walk(route: PackedVector2Array, action: int) -> void:
	_walking = true
	_message.hide()
	_show_route(route)
	_marker.play_run()
	var total := WalkRoute.length(route)
	var traveled := 0.0
	var origin := _player_coord
	var tamer: MapTamer = null
	while traveled < total and _next_point == null and tamer == null:
		await get_tree().process_frame
		var delta := get_process_delta_time()
		traveled = minf(total, traveled + WalkRoute.WALK_SPEED * delta)
		var at := WalkRoute.point_at(route, traveled)
		if at != _player_point:
			_marker.face_toward(WalkRoute.world(at - _player_point))
		_player_point = at
		var coord := HexMapView.grid_coord(at)
		if coord != _player_coord and _map.has(coord):
			origin = _player_coord
			_player_coord = coord
			_map_view.set_current(coord)
			_refresh_wild_sprites()
			tamer = _map.tamer_at(coord)
		_place_player(delta)
		_trim_route(traveled)
	while _shown_rise != _rise_at(_player_coord):
		await get_tree().process_frame
		_place_player(get_process_delta_time())
	_clear_route()
	if _next_point == null or tamer != null:
		_marker.play_idle()
	_walking = false
	if tamer != null:
		_next_point = null
		_challenge(tamer)
	elif _next_point != null:
		var next: Vector2 = _next_point
		_next_point = null
		_go_to(next)
	elif action >= 0:
		_run_action(action)
	else:
		_enter_action(_map.action_at(origin), _map.action_at(_player_coord))


func _place_player(delta: float) -> void:
	_shown_rise = move_toward(_shown_rise, _rise_at(_player_coord), RISE_SPEED * delta)
	_map_view.set_actor_depth(_marker, _player_point, _feet_row())
	_move_map(_player_centered_position())


func _rise_at(coord: Vector2i) -> float:
	var tile := _map.tile_at(coord)
	return HexMapView.LEVEL_HEIGHTS[tile.height] if tile != null else 0.0


func _feet_row() -> int:
	return HexMapView.grid_coord(_player_point + Vector2(0.0, FEET_DEPTH)).y


func _player_art_point() -> Vector2:
	return _player_point - Vector2(0.0, _shown_rise)


## Um ponto a cada `ROUTE_DOT_SPACING`, na altura do hexágono embaixo dele; no fim, um anel.
func _show_route(route: PackedVector2Array) -> void:
	_clear_route()
	var total := WalkRoute.length(route)
	var count := maxi(1, floori(total / ROUTE_DOT_SPACING))
	for index: int in range(1, count + 1):
		var last := index == count
		var at := route[route.size() - 1] if last else WalkRoute.point_at(route, index * ROUTE_DOT_SPACING)
		var coord := HexMapView.grid_coord(at)
		var mark := RouteMark.new(index, last)
		mark.place(at - Vector2(0.0, _rise_at(coord)))
		_map_view.set_ground_overlay(mark, coord.y)
		_route.append(mark)


## Tira os pontos por onde o Domador já passou.
func _trim_route(traveled: float) -> void:
	while not _route.is_empty() and _route[0].order * ROUTE_DOT_SPACING <= traveled and _route.size() > 1:
		_route.pop_front().queue_free()


func _clear_route() -> void:
	for mark: RouteMark in _route:
		mark.queue_free()
	_route.clear()


func _search() -> void:
	if _walking or _challenger != null:
		return
	if _map.has_creature(_player_coord):
		_open_battle({"coord": _player_coord}, &"wild")
	else:
		_show_message(NOTHING_HERE_TEXT, &"SecondaryLabel")


## Depois da luta, ganhando, perdendo ou correndo, o Ecobeast já saiu do mapa, e o
## Domador também. Se a luta contra o Domador nem começou, ele fica, e o mapa destrava
## até o jogador sair do hexágono e entrar de novo.
func _on_visibility_changed() -> void:
	if visible and _map != null:
		Music.play_explore(EXPLORE_MUSIC_FADE_IN)
		var fought := Session.take_fought_spawn()
		_map.creatures.erase(fought)
		_debug_spawn_ids.erase(fought)
		var fought_tamer := Session.take_fought_tamer()
		_map.tamers.erase(fought_tamer)
		_debug_tamer_ids.erase(fought_tamer)
		_refresh_debug_clear()
		_release_challenge()
		_refresh_wild_sprites()


func _show_island() -> void:
	_island_plate.visible = _map.island_id > 0
	_island_name.text = _map.island_name
	_building_names.clear()
	# Uma camada por linha, para a linha seguinte e os atores ficarem por cima.
	var rows: Dictionary[int, Array] = {}
	for action: MapAction in _map.actions:
		var type := GameData.get_row("action_types", action.action_type_id)
		var color := Color.from_string(str(type.get("color_hex", "")), UiPalette.TEXT)
		color.a = ACTION_TINT_ALPHA
		for coord: Vector2i in action.tiles:
			if not rows.has(coord.y):
				rows[coord.y] = []
			rows[coord.y].append({"coord": coord, "color": color})
		var middle := BuildingNamesLayer.middle_of(action.tiles)
		_building_names.add_name(str(type.get("name", "")), _map_view.surface_center(middle))
	for row: int in rows:
		var layer := HexTintLayer.new(false, rows[row].size())
		layer.set_raised(true)
		for hex: Dictionary in rows[row]:
			var tile := _map.tile_at(hex["coord"])
			if tile != null:
				layer.set_hex(hex["coord"], hex["color"], tile.height)
		_map_view.set_ground_overlay(layer, row)


func _enter_action(from: int, to: int) -> void:
	if to >= 0 and to != from:
		_run_action(to)


func _run_action(index: int) -> void:
	var type := GameData.get_row("action_types", _map.actions[index].action_type_id)
	var screen: StringName = ACTION_SCREENS.get(str(type.get("slug", "")), &"")
	if screen != &"":
		_debug_menu.hide()
		Router.push(screen)


func _challenge(tamer: MapTamer) -> void:
	_challenger = tamer
	_debug_menu.hide()
	_message.hide()
	_set_controls_enabled(false)
	_greeting.say("%s: %s" % [GameData.get_npc_tamer_name(tamer.name_id), GameData.get_npc_tamer_greeting(tamer.greeting_id)])


func _fight_challenger() -> void:
	if _challenger == null:
		return
	_open_battle({"tamer_coord": _challenger.coord}, &"tamer")


func _release_challenge() -> void:
	if _challenger == null:
		return
	_challenger = null
	_greeting.close()
	_set_controls_enabled(true)


func _set_controls_enabled(enabled: bool) -> void:
	_encounter_button.disabled = not enabled
	_bag_button.disabled = not enabled
	_back_button.disabled = not enabled
	_debug_button.disabled = not enabled


func _toggle_whole_map() -> void:
	if _walking or _challenger != null:
		return
	_debug_menu.hide()
	_showing_whole_map = not _showing_whole_map
	_debug_zoom_button.text = NORMAL_ZOOM_TEXT if _showing_whole_map else WHOLE_MAP_TEXT
	_refresh_wild_sprites()
	_fit_view()


func _toggle_debug_menu() -> void:
	_show_debug_part(false)
	_debug_menu.visible = not _debug_menu.visible


func _show_debug_part(spawn: bool) -> void:
	_debug_spawn.visible = spawn
	_debug_main.visible = not spawn


func _toggle_god() -> void:
	Session.debug_god = not Session.debug_god
	_refresh_god_button()


func _refresh_god_button() -> void:
	_debug_god_button.text = GOD_ON_TEXT if Session.debug_god else GOD_OFF_TEXT


func _open_board_test(slots: int) -> void:
	if _walking or _challenger != null:
		return
	_debug_menu.hide()
	_open_battle({"test_slots": slots}, &"wild")


func _open_battle(params: Dictionary, opponent: StringName) -> void:
	if not await BattleIntro.cover(_marker.get_global_transform_with_canvas().origin, opponent):
		return
	Router.push(&"board_battle", _battle_params(params))


func _battle_params(params: Dictionary) -> Dictionary:
	var tile: HexTile = _map.tile_at(_player_coord) if _map != null else null
	if tile != null:
		params["biome"] = tile.biome
		params["height"] = tile.height
	return params


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


func _spawn(species: CreatureSpecies) -> void:
	if _walking or _challenger != null:
		return
	var result: Result = await Session.debug_spawn(species.id, _player_coord)
	if not result.ok:
		_show_message(result.error, &"DangerLabel")
		return
	var creature: MapCreature = result.data
	_map.creatures[creature.id] = creature
	_debug_spawn_ids.append(creature.id)
	_refresh_wild_sprites()
	_refresh_debug_clear()
	_show_message(SPAWNED_TEXT % species.name, &"SecondaryLabel")


func _debug_tamer(size: int) -> void:
	if _walking or _challenger != null:
		return
	_debug_menu.hide()
	var result: Result = await Session.debug_tamer(_player_coord, size)
	if not result.ok:
		_show_message(result.error, &"DangerLabel")
		return
	var replaced := _map.tamer_at(_player_coord)
	if replaced != null:
		_map.tamers.erase(replaced.id)
		_debug_tamer_ids.erase(replaced.id)
	var tamer: MapTamer = result.data
	_map.tamers[tamer.id] = tamer
	_debug_tamer_ids.append(tamer.id)
	_refresh_wild_sprites()
	_refresh_debug_clear()
	_challenge(tamer)


func _clear_creatures() -> void:
	_debug_clear_button.disabled = true
	var result: Result = await Session.debug_clear_spawns()
	if not result.ok:
		_refresh_debug_clear()
		_show_message(result.error, &"DangerLabel")
		return
	var removed: Dictionary = result.data
	for id: int in removed["creature_ids"]:
		_map.creatures.erase(id)
	for id: int in removed["tamer_ids"]:
		_map.tamers.erase(id)
	_debug_spawn_ids.clear()
	_debug_tamer_ids.clear()
	_refresh_wild_sprites()


func _refresh_debug_clear() -> void:
	_debug_clear_button.disabled = _debug_spawn_ids.is_empty() and _debug_tamer_ids.is_empty()


func _almost_level_up() -> void:
	_debug_xp_button.disabled = true
	var result: Result = await Session.debug_almost_level_up()
	_debug_xp_button.disabled = false
	_debug_menu.hide()
	if result.ok:
		_show_message(ALMOST_LEVEL_UP_TEXT, &"SecondaryLabel")
	else:
		_show_message(result.error, &"DangerLabel")


func _refresh_wild_sprites() -> void:
	_refresh_tamer_sprites()
	for id: int in _wild_sprites.keys():
		if not _map.creatures.has(id) or not _is_near(_map.creatures[id]):
			_wild_sprites[id].queue_free()
			_wild_sprites.erase(id)
	for creature: MapCreature in _map.creatures.values():
		if not _wild_sprites.has(creature.id) and _is_near(creature):
			var species := GameData.get_species(creature.species_id)
			if species != null and CreatureSprite.has_sheets(species.slug):
				_wild_sprites[creature.id] = _add_creature_sprite(species.slug, creature.coord)


func _refresh_tamer_sprites() -> void:
	for id: int in _tamer_sprites.keys():
		if not _map.tamers.has(id) or not _is_near_coord(_map.tamers[id].coord):
			_tamer_sprites[id].queue_free()
			_tamer_sprites.erase(id)
	for tamer: MapTamer in _map.tamers.values():
		if not _tamer_sprites.has(tamer.id) and _is_near_coord(tamer.coord):
			var sprite := TamerSprite.new()
			_place_wanderer(sprite, tamer.coord)
			_tamer_sprites[tamer.id] = sprite


func _is_near(creature: MapCreature) -> bool:
	return _is_near_coord(creature.coord)


func _is_near_coord(coord: Vector2i) -> bool:
	return _showing_whole_map or ExplorationMap.distance(coord, _player_coord) <= CREATURE_RADIUS


func _add_creature_sprite(slug: String, coord: Vector2i) -> CreatureSprite:
	var creature := CreatureSprite.new(slug)
	_place_wanderer(creature, coord)
	return creature


func _place_wanderer(sprite: WanderingSprite, coord: Vector2i) -> void:
	_map_view.add_child(sprite)
	_map_view.set_actor_row(sprite, coord.y)
	sprite.wander_in(coord, _map_view.surface_center(coord))
	sprite.scale = _marker.scale


func _fit_view() -> void:
	if _map == null:
		return
	if _showing_whole_map:
		var panel_top := _controls_panel.get_global_rect().position.y
		_map_view.show_whole_map(Rect2(0.0, 0.0, size.x, panel_top))
		_marker.position = _player_art_point()
	else:
		_map_view.show_pixel_art()
		_move_map(_player_centered_position())
	# Filhos do mapa, eles encolheriam junto com o mapa inteiro.
	_marker.scale = _map_view.art_scale() / _map_view.pixel_scale()
	for creature: CreatureSprite in _wild_sprites.values():
		creature.scale = _marker.scale
	for tamer: TamerSprite in _tamer_sprites.values():
		tamer.scale = _marker.scale
	_sync_building_names()


func _sync_building_names() -> void:
	_building_names.set_view(_map_view.position, _map_view.pixel_scale())


## Parte do centro já arredondado: em uma tela de tamanho ímpar, ele cai no meio de
## um pixel, e arredondar depois da conta deixaria o Domador fora do hexágono.
func _player_centered_position() -> Vector2:
	return _map_view.snapped_to_pixels(size / 2.0) - _player_art_point() * _map_view.pixel_scale()


## Sempre em pixels reais inteiros, para a pixel art não borrar no caminho. O Domador
## é filho do mapa: a posição dele desconta o mapa, e ele fica parado na tela.
func _move_map(value: Vector2) -> void:
	_map_view.position = _map_view.snapped_to_pixels(value)
	_marker.position = (_map_view.snapped_to_pixels(size / 2.0) - _map_view.position) / _map_view.pixel_scale()
	_sync_building_names()


func _show_message(text: String, variation: StringName) -> void:
	_message.text = text
	_message.theme_type_variation = variation
	_message.show()
