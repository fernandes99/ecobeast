class_name ExplorationScreen
extends Control

## A câmera da cena chegou (story/07).
signal camera_settled

const PortraitScene := preload("res://ui/components/creature_portrait.tscn")

const LOADING_TEXT := "Gerando mapa..."
const ISLAND_LOADING_TEXT := "Chegando na ilha..."
const TELEPORT_BLOCKED_TEXT := "Debug: não dá para ir para esse hexágono."
## O deslize até o degrau inteiro ao soltar a pinça e na roda (camera-zoom/03). A revisar.
const ZOOM_SETTLE_SECONDS := 0.15
## A voz dos Domadores NPC, que não têm NPC no catálogo (dialogue-voices/02).
const NPC_TAMER_VOICE := "medium"
const ACTION_TINT_ALPHA := 0.45
const MAP_MARKER_ACTIONS: Array[String] = ["refuge", "shop", "travel"]
const MENU_ICON := "res://ui/icons/person.svg"
## Na criação, o Domador fica no meio da parte de cima, acima do painel.
const CREATOR_CENTER := 0.24
## Na casa, o campo e a vila em volta do início já vêm descobertos (liora-intro/04). A revisar.
const HOME_KNOWN_RADIUS := 30
const NOTHING_HERE_TEXT := "Nada por aqui."
const NO_PATH_TEXT := "Não dá para chegar lá."
## Encostado numa peça: a até isto das linhas dela, em pixels da arte (free-objects/03).
const TOUCH_REACH := 8.0
const HIT_ALPHA := 0.5
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
## De quanto em quanto tempo os hexágonos descobertos de uma ilha vão para o servidor.
const DISCOVERY_SYNC_INTERVAL := 5.0
const WHOLE_MAP_TEXT := "Debug: ver mapa inteiro"
const NORMAL_ZOOM_TEXT := "Debug: voltar ao zoom normal"
const DEBUG_SPECIES_HEIGHT := 112.0
const DEBUG_PORTRAIT_SIZE := 64
const DEBUG_NAME_FONT_SIZE := 18
const DEBUG_DISABLED_ALPHA := 0.35
const GOD_ON_TEXT := "God: ligado"
const GOD_OFF_TEXT := "God: desligado"
const CONTOUR_ON_TEXT := "Contorno: ligado"
const CONTOUR_OFF_TEXT := "Contorno: desligado"
const ROUNDED_ON_TEXT := "Pontas: arredondadas"
const ROUNDED_OFF_TEXT := "Pontas: retas"
const LIPS_TEXT := "Beirada: %s"
const SHADOWS_TEXT := "Sombra no pé: %s"
const TINT_TEXT := "Tom por altura: %s"
## Até onde os Ecobeasts existem como nós, em hexágonos, no zoom de partida: passa
## da tela com folga, para eles nascerem e saírem sem ninguém ver. A revisar.
const CREATURE_RADIUS := 16
## A luz em volta do Domador à noite, em pixels da arte (day-night/03). A revisar.
const TAMER_LIGHT_LIFT := 10.0
const TAMER_LIGHT_RADIUS := 36.0
const TAMER_LIGHT_COLOR := Color("ffe8c0")
const DEBUG_SCENES_TEXT := "Debug: cenas da ilha"
const DEBUG_NO_SCENES_TEXT := "Esta ilha não tem cenas."
const DEBUG_BACK_TEXT := "Voltar"

var _island_id: int = 0
var _map: ExplorationMap = null
var _prop_lights: Array[MapLight] = []
var _swarms := PackedVector2Array()
var _swarm_coords: Array[Vector2i] = []
var _discovery := MapDiscovery.new()
var _sync_timer := Timer.new()
## Os nomes das construções: o texto, o ponto na arte e o hexágono do meio.
var _building_labels: Array[Dictionary] = []
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
var _npc_sprites: Array[NpcSprite] = []
var _npc_target: NpcSprite = null
## A peça com bloqueio ou ação até onde o Domador anda (free-objects/03), ou -1.
var _prop_target := -1
var _prop_images: Dictionary[String, Image] = {}
var _talking: NpcSprite = null
var _talk_lines: Array[String] = []
var _talk_index := 0
var _debug_spawn_ids: Array[int] = []
var _debug_tamer_ids: Array[int] = []
var _pinch := PinchZoom.new()
var _pinch_start_zoom := float(HexMapView.DEFAULT_ZOOM)
var _zoom_tween: Tween = null
## O degrau para onde o deslize do zoom vai (camera-zoom/03).
var _zoom_target := HexMapView.DEFAULT_ZOOM
var _minimap_image := MinimapImage.new()
var _markers: Array[MapMarker] = []
## Abrir o mapa grande no meio de uma caminhada a para onde o Domador está (minimap/02).
var _stop_walk := false
## A história (story/02 e 03).
var _story := StoryPlayer.new()
var _story_choices := StoryChoicePanel.new()
var _story_fade := ColorRect.new()
var _story_test := false
## A cena de área que espera a caminhada acabar.
var _area_scene: StoryScene = null
## O ponto da arte no centro da tela; INF é o Domador.
var _camera_focus := Vector2.INF
var _camera_tween: Tween = null
var _camera_target_zoom := 0.0
## A altura da tela onde o Domador fica, de 0 a 1 (a criação o sobe).
var _center_ratio := 0.5
var _creating := false
var _followers: Array[NpcSprite] = []
## Os hexágonos por onde o Domador passou, do mais recente ao mais antigo.
var _trail: Array[Vector2i] = []
var _teleporting := false
var _debug_scenes := VBoxContainer.new()

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
@onready var _debug_forget_button: Button = %DebugForgetButton
@onready var _debug_species: Control = %DebugSpecies
@onready var _debug_clear_button: Button = %DebugClearButton
@onready var _debug_xp_button: Button = %DebugXpButton
@onready var _debug_main: Control = %DebugMain
@onready var _debug_spawn: Control = %DebugSpawn
@onready var _debug_spawn_button: Button = %DebugSpawnButton
@onready var _debug_spawn_back_button: Button = %DebugSpawnBackButton
@onready var _debug_god_button: Button = %DebugGodButton
@onready var _debug_contour_button: Button = %DebugContourButton
@onready var _debug_rounded_button: Button = %DebugRoundedButton
@onready var _debug_lips_button: Button = %DebugLipsButton
@onready var _debug_shadows_button: Button = %DebugShadowsButton
@onready var _debug_tint_button: Button = %DebugTintButton
@onready var _greeting: TamerGreetingPanel = %TamerGreeting
@onready var _island_plate: Control = %IslandPlate
@onready var _island_name: Label = %IslandName
@onready var _building_names: BuildingNamesLayer = %BuildingNames
@onready var _day_light: DayLightLayer = %DayLight
@onready var _fog: FogLayer = %Fog
@onready var _minimap: Minimap = %Minimap
@onready var _top_row: HBoxContainer = %TopRow
@onready var _day_phase_badge: Control = %DayPhaseBadge
@onready var _minimap_space: Control = %MinimapSpace
@onready var _island_map: IslandMapPanel = %IslandMap


func setup(params: Dictionary) -> void:
	_island_id = int(params.get("island_id", 0))
	_story_test = bool(params.get("story_test", false))


func _ready() -> void:
	if Session.player != null:
		_marker.set_appearance(Session.player.appearance)
	Session.player_changed.connect(_refresh_team_controls)
	_map_view.zoom_level = ViewSettings.explore_zoom()
	_pinch.pinch_started.connect(_on_pinch_started)
	_pinch.pinched.connect(func(ratio: float, _center: Vector2) -> void: _show_zoom(_pinch_start_zoom * ratio))
	_pinch.pinch_ended.connect(func() -> void: _settle_zoom(roundi(_camera_zoom())))
	_map_area.gui_input.connect(_on_map_input)
	_encounter_button.pressed.connect(_search)
	_bag_button.pressed.connect(Router.push.bind(&"bag"))
	if _at_home():
		_back_button.text = "Menu"
		_back_button.icon = load(MENU_ICON) as Texture2D
		_back_button.pressed.connect(_open_menu)
	else:
		_back_button.pressed.connect(_leave)
	_debug_button.pressed.connect(_toggle_debug_menu)
	_debug_zoom_button.pressed.connect(_toggle_whole_map)
	_debug_forget_button.pressed.connect(_forget_island)
	_sync_timer.wait_time = DISCOVERY_SYNC_INTERVAL
	_sync_timer.timeout.connect(Session.send_island_discoveries)
	add_child(_sync_timer)
	_debug_clear_button.pressed.connect(_clear_creatures)
	_debug_xp_button.pressed.connect(_almost_level_up)
	%DebugHourButton.pressed.connect(_debug_next_hour)
	%DebugTimeSlider.value_changed.connect(_debug_set_time)
	%DebugRealTimeButton.pressed.connect(_debug_real_time)
	_debug_spawn_button.pressed.connect(_show_debug_part.bind(true))
	_debug_spawn_back_button.pressed.connect(_show_debug_part.bind(false))
	_debug_god_button.pressed.connect(_toggle_god)
	_debug_contour_button.pressed.connect(_toggle_contour)
	_debug_rounded_button.pressed.connect(_toggle_rounded)
	_debug_lips_button.pressed.connect(func() -> void: _toggle_height_cues(not HexMapView.height_lips, HexMapView.foot_shadows, HexMapView.height_tint))
	_debug_shadows_button.pressed.connect(func() -> void: _toggle_height_cues(HexMapView.height_lips, not HexMapView.foot_shadows, HexMapView.height_tint))
	_debug_tint_button.pressed.connect(func() -> void: _toggle_height_cues(HexMapView.height_lips, HexMapView.foot_shadows, not HexMapView.height_tint))
	%DebugTest2Button.pressed.connect(_open_board_test.bind(2))
	%DebugTest3Button.pressed.connect(_open_board_test.bind(3))
	for team_size: int in [1, 2, 3]:
		(get_node("%%DebugTamer%dButton" % team_size) as Button).pressed.connect(_debug_tamer.bind(team_size))
	_greeting.tapped.connect(_on_greeting_tapped)
	_build_story()
	_refresh_god_button()
	_refresh_contour_button()
	_refresh_rounded_button()
	_refresh_height_cue_buttons()
	resized.connect(_fit_view.call_deferred)
	_top_row.resized.connect(_fit_island_name)
	_minimap.tapped.connect(_open_island_map)
	_island_map.hex_tapped.connect(_teleport)
	visibility_changed.connect(_on_visibility_changed)
	WorldClock.sync()
	_begin()


func _debug_next_hour() -> void:
	WorldClock.debug_offset_minutes += 60.0
	_show_debug_time()


func _debug_set_time(minute: float) -> void:
	WorldClock.debug_set_minute(minute)
	_show_debug_time()


func _debug_real_time() -> void:
	WorldClock.debug_offset_minutes = 0.0
	_show_debug_time()


func _show_debug_time() -> void:
	var phase := WorldClock.phase()
	%DebugTimeLabel.text = WorldClock.clock_text()
	%DebugTimeSlider.set_value_no_signal(snappedf(WorldClock.minute_of_day(), 15.0))
	_show_message("%s — %s" % [WorldClock.clock_text(), phase.name if phase != null else "sem hora do servidor"], &"SecondaryLabel")


func handle_back() -> bool:
	if _island_map.visible:
		_island_map.close_panel()
		return true
	if _loading or _challenger != null or _talking != null or _story_busy():
		return true
	if _at_home():
		_open_menu()
		return true
	if not _story_test:
		_leave()
		return true
	return false


## Em casa, o Voltar vira o menu do Domador (home-island/02); o teste de cena do F2 sai como sempre.
func _at_home() -> bool:
	return Home.is_home(_island_id) and not _story_test


## Fora de casa, sair é voltar para ela (home-island/03); o teste de cena volta ao F2.
func _leave() -> void:
	if _story_test:
		Router.back()
	elif not _back_button.disabled:
		Home.go()


func _open_menu() -> void:
	if not _back_button.disabled:
		Router.push(&"hub")


func _exit_tree() -> void:
	if _story_test:
		Story.end_test()
	Music.fade_out()
	Session.send_island_discoveries()


func _begin() -> void:
	_show_message(ISLAND_LOADING_TEXT if _island_id > 0 else LOADING_TEXT, &"SecondaryLabel")
	var result: Result = await Session.start_exploration(_island_id)
	_loading = false
	_back_button.disabled = false
	if not result.ok:
		_show_message(result.error, &"DangerLabel")
		return
	_map = result.data
	_map.set_prop_lines(GameData.prop_blocks_by_key())
	_player_coord = _map.start
	_player_point = HexMapView.flat_center(_player_coord)
	_map_view.set_map(_map)
	_map_view.set_props(_map.props)
	_prop_lights = _map_view.prop_lights(_map.props)
	_swarms = _map_view.firefly_swarms()
	_swarm_coords = _map_view.firefly_swarm_tiles()
	_discovery = MapDiscovery.new()
	_discovery.add(_map.discovered)
	_reveal_home_field()
	Session.queue_island_discoveries(_map.island_id, _discovery.reveal_around(_map, _player_coord))
	_fog.set_map(_map, _discovery)
	_debug_forget_button.disabled = _map.island_id <= 0
	if _map.island_id > 0:
		_sync_timer.start()
	_shown_rise = _map.rise_at(_player_point)
	_map_view.set_current(_player_coord)
	_map_view.set_actor_depth(_marker, _player_point, _feet_row())
	_reveal_player()
	_show_island()
	_add_npcs()
	_markers = _build_markers()
	_rebuild_minimap()
	_minimap.show()
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
	Story.begin_entry()
	_refresh_team_controls()
	_start_story.call_deferred()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var area := _zoom_area()
	if _pinch.feed(event, area):
		get_viewport().set_input_as_handled()
		return
	var step := _pinch.wheel(event, area)
	if step != 0:
		get_viewport().set_input_as_handled()
		_settle_zoom((_zoom_target if _zoom_tween != null else _map_view.zoom_level) + step)


## O mapa acima do painel de botões, quando o toque nele valeria; senão, nenhuma.
func _zoom_area() -> Rect2:
	if _map == null or _showing_whole_map or _challenger != null or _talking != null or _island_map.visible or _story_busy():
		return Rect2()
	var top := _map_area.get_global_rect().position
	return Rect2(top, Vector2(_map_area.size.x, _controls_panel.get_global_rect().position.y - top.y))


func _on_pinch_started(_center: Vector2) -> void:
	_stop_zoom_tween()
	_pinch_start_zoom = _camera_zoom()


## O zoom fracionário da pinça e do deslize, entre 1 e 4; o degrau mais perto vale para
## o raio dos seres (camera-zoom/03).
func _show_zoom(zoom: float) -> void:
	zoom = clampf(zoom, HexMapView.MIN_ZOOM, HexMapView.MAX_ZOOM)
	var level := roundi(zoom)
	if level != _map_view.zoom_level:
		_map_view.zoom_level = level
		_refresh_wild_sprites()
	_map_view.story_zoom = zoom
	_fit_view()


## Desliza até o degrau, que já fica guardado no aparelho.
func _settle_zoom(level: int) -> void:
	level = clampi(level, HexMapView.MIN_ZOOM, HexMapView.MAX_ZOOM)
	_stop_zoom_tween()
	_zoom_target = level
	ViewSettings.set_explore_zoom(level)
	var from := _camera_zoom()
	if is_equal_approx(from, level):
		_finish_zoom(level)
		return
	_zoom_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_zoom_tween.tween_method(_show_zoom, from, float(level), ZOOM_SETTLE_SECONDS)
	_zoom_tween.finished.connect(_finish_zoom.bind(level))


func _finish_zoom(level: int) -> void:
	_zoom_tween = null
	_map_view.story_zoom = 0.0
	if level != _map_view.zoom_level:
		_map_view.zoom_level = level
		_refresh_wild_sprites()
	_fit_view()


func _stop_zoom_tween() -> void:
	if _zoom_tween != null:
		_zoom_tween.kill()
		_zoom_tween = null


func _on_map_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT or _pinch.blocks_tap():
		return
	if mouse.pressed:
		_press_position = mouse.position
	elif mouse.position.distance_to(_press_position) <= MAX_TAP_TRAVEL:
		_tap(mouse.position)


func _tap(point: Vector2) -> void:
	if _map == null or _showing_whole_map or _challenger != null or _talking != null or _island_map.visible or _story_busy():
		return
	var art_point := (point - _map_view.position) / _map_view.pixel_scale()
	if _walking:
		_next_point = art_point
	else:
		_go_to(art_point)


## O Domador anda até o ponto tocado; com uma parede no centro do hexágono, chega por
## um vizinho.
func _go_to(art_point: Vector2) -> void:
	_npc_target = null
	_prop_target = -1
	var npc := _npc_hit(art_point)
	if npc != null:
		_go_to_npc(npc)
		return
	var piece := _prop_hit(art_point)
	if piece >= 0:
		_go_to_prop(piece)
		return
	var deck_point := _map.deck_point_of_art(art_point)
	var target := HexMapView.grid_coord(deck_point) if deck_point.is_finite() else _map_view.coord_at(art_point)
	if not _map.has(target):
		return
	var goals: Dictionary[Vector2i, bool] = {target: true}
	var finish := deck_point if deck_point.is_finite() else art_point + Vector2(0.0, _rise_at(target))
	if not deck_point.is_finite() and HexMapView.grid_coord(finish) != target:
		finish = HexMapView.flat_center(target)
	if deck_point.is_finite():
		# No piso de uma ponte (bridges/04): chega por uma ponta e anda pelo piso.
		var bridge := _map.bridges[_map.deck_of(deck_point)]
		goals = {HexMapView.grid_coord(bridge.from): true, HexMapView.grid_coord(bridge.to): true}
		if _map.is_clear(_player_point, finish):
			goals = {_player_coord: true}
	elif _map.is_blocked_hex(target):
		# Na água: vai até a terra mais perto e para rente a ela.
		goals = _map.shore_goals(target)
	elif target != _player_coord and _map.is_center_walled(target):
		# Uma parede passa pelo centro (free-fences/02): o Domador chega por um vizinho
		# e anda até o ponto tocado, parando rente a ela.
		goals = _map.approach_goals(target, finish)
	var hexes: Array[Vector2i] = [_player_coord]
	if not goals.has(_player_coord) and (target != _player_coord or _map.is_blocked_hex(target)):
		var path := _map.path_to_any(_player_coord, goals, _player_point)
		if path.is_empty():
			_show_message(NO_PATH_TEXT, &"SecondaryLabel")
			return
		hexes.append_array(path)
	if finish.distance_to(_player_point) < 1.0:
		return
	var route := WalkRoute.points(_map, _player_point, hexes, finish)
	if route.size() < 2 or route[route.size() - 1].distance_to(_player_point) < 1.0:
		return
	_walk(route)


## Quadro a quadro: o hexágono muda quando os pés cruzam a borda (wild-battle/15).
func _walk(route: PackedVector2Array) -> void:
	_walking = true
	_stop_walk = false
	_message.hide()
	_show_route(route)
	_marker.play_run()
	var total := WalkRoute.length(route)
	var traveled := 0.0
	var origin := _player_coord
	var tamer: MapTamer = null
	while traveled < total and _next_point == null and tamer == null and not _stop_walk:
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
			_discover()
			_refresh_wild_sprites()
			_lead_followers(origin)
			if not _story_busy():
				tamer = _map.tamer_at(coord)
				_area_scene = Story.scene_for_tile(_map.island_id, coord)
				if _area_scene != null:
					_stop_walk = true
		_place_player(delta)
		_trim_route(traveled)
	while _shown_rise != _map.rise_at(_player_point):
		await get_tree().process_frame
		_place_player(get_process_delta_time())
	_clear_route()
	if _next_point == null or tamer != null:
		_marker.play_idle()
	_walking = false
	if _story_busy():
		_stop_walk = false
		_next_point = null
		return
	if _stop_walk:
		_stop_walk = false
		_npc_target = null
		_prop_target = -1
		if _area_scene != null:
			var scene := _area_scene
			_area_scene = null
			_play_scene(scene)
		return
	if tamer != null:
		_next_point = null
		_npc_target = null
		_prop_target = -1
		_challenge(tamer)
	elif _next_point != null:
		var next: Vector2 = _next_point
		_next_point = null
		_go_to(next)
	elif _prop_target >= 0:
		var piece := _prop_target
		_prop_target = -1
		if _touching_prop(piece):
			_open_prop(piece)
	elif _npc_target != null:
		var npc := _npc_target
		_npc_target = null
		if ExplorationMap.distance(_player_coord, npc.coord) <= 1:
			_talk(npc)
	else:
		_enter_action(_map.action_at(origin), _map.action_at(_player_coord))


func _place_player(delta: float) -> void:
	_shown_rise = move_toward(_shown_rise, _map.rise_at(_player_point), RISE_SPEED * delta)
	_map_view.set_actor_depth(_marker, _player_point, _feet_row())
	_reveal_player()
	_move_map(_player_centered_position())
	_minimap.set_center(_player_point)


## O terreno das linhas da frente que cobre o Domador fica transparente (terrain-height/03).
func _reveal_player() -> void:
	var cell := Vector2(SheetSprite.CELL_SIZE) * _marker.scale
	var margin := HexMapView.REVEAL_MARGIN
	var feet := _player_art_point()
	_map_view.set_reveal(Rect2(feet - Vector2(cell.x / 2.0 + margin, cell.y + margin), Vector2(cell.x + margin * 2.0, cell.y + margin)), _feet_row())


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
		mark.place(at - Vector2(0.0, _map.rise_at(at)))
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
	if _walking or _challenger != null or not _has_team():
		return
	if _map.has_creature(_player_coord):
		_open_battle({"coord": _player_coord}, &"wild")
		return
	# A água bloqueia (bridges/04): o Ecobeast de um hexágono de água vizinho também
	# se enfrenta, o mais perto do pé.
	var nearest := Vector2i.ZERO
	var best := INF
	for next: Vector2i in _map.neighbors(_player_coord):
		if not _map.is_blocked_hex(next) or not _map.has_creature(next):
			continue
		var gap := HexMapView.flat_center(next).distance_to(_player_point)
		if gap < best:
			best = gap
			nearest = next
	if best < INF:
		_open_battle({"coord": nearest}, &"wild")
	else:
		_show_message(NOTHING_HERE_TEXT, &"SecondaryLabel")


## Depois da luta, ganhando, perdendo ou correndo, o Ecobeast já saiu do mapa, e o
## Domador também. Se a luta contra o Domador nem começou, ele fica, e o mapa destrava
## até o jogador sair do hexágono e entrar de novo.
func _on_visibility_changed() -> void:
	_pinch.cancel()
	if not visible:
		Session.send_island_discoveries()
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
	_fit_island_name.call_deferred()
	_building_labels.clear()
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
		_building_labels.append({"text": str(type.get("name", "")), "point": _map_view.surface_center(middle), "coord": middle})
	for row: int in rows:
		var layer := HexTintLayer.new(false, rows[row].size())
		layer.set_raised(true)
		for hex: Dictionary in rows[row]:
			var tile := _map.tile_at(hex["coord"])
			if tile != null:
				layer.set_hex(hex["coord"], hex["color"], tile.height)
		_map_view.set_ground_overlay(layer, row)
	_refresh_building_names()


## O nome da ilha corta com reticências antes de chegar no minimapa (minimap/01).
func _fit_island_name() -> void:
	var font := _island_name.get_theme_font(&"font")
	var font_size := _island_name.get_theme_font_size(&"font_size")
	var wanted := font.get_string_size(_island_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var separation := _top_row.get_theme_constant(&"separation")
	var plate := _island_plate.get_theme_stylebox(&"panel").get_minimum_size().x
	var room := _top_row.size.x - _minimap_space.custom_minimum_size.x - _day_phase_badge.get_combined_minimum_size().x - separation * 2 - plate
	_island_name.custom_minimum_size.x = clampf(wanted, 0.0, maxf(room, 0.0))


func _open_island_map() -> void:
	if _map == null or _challenger != null or _talking != null:
		return
	if _walking:
		_stop_walk = true
		_next_point = null
	_debug_menu.hide()
	_island_map.open(_minimap_image, _markers, _discovery, _showing_whole_map, _player_point, _map.island_name)


## O teleporte de depuração do mapa grande (minimap/03).
func _teleport(coord: Vector2i) -> void:
	if _map == null or _teleporting or _story_busy() or _talking != null or _challenger != null:
		return
	if not _map.has(coord) or _map.is_blocked_hex(coord) or _map.is_walled_hex(coord):
		_island_map.close_panel()
		_show_message(TELEPORT_BLOCKED_TEXT, &"DangerLabel")
		return
	_teleporting = true
	var result: Result = await Session.set_exploration_position(coord)
	_teleporting = false
	if not result.ok:
		_island_map.close_panel()
		_show_message(result.error, &"DangerLabel")
		return
	while _walking:
		_stop_walk = true
		await get_tree().process_frame
	_island_map.close_panel()
	_clear_route()
	_next_point = null
	_npc_target = null
	_prop_target = -1
	_player_coord = coord
	_player_point = HexMapView.flat_center(coord)
	_shown_rise = _map.rise_at(_player_point)
	_marker.play_idle()
	_map_view.set_current(coord)
	_place_player(0.0)
	_discover()
	_refresh_wild_sprites()
	_place_followers()


func _place_followers() -> void:
	var spots: Array[Vector2i] = []
	for near: Vector2i in _map.neighbors(_player_coord):
		if _map.has(near) and not _map.is_blocked_hex(near) and not _map.is_walled_hex(near):
			spots.append(near)
	_trail.clear()
	for index: int in _followers.size():
		var spot := spots[index % spots.size()] if not spots.is_empty() else _player_coord
		_followers[index].jump_to(spot)
		_trail.append(spot)


func _rebuild_minimap() -> void:
	_minimap_image.build(_map, _discovery, _showing_whole_map)
	_minimap.set_source(_minimap_image, _markers, _discovery)
	_minimap.set_show_all(_showing_whole_map)
	_minimap.set_center(_player_point)


## O Refúgio e a Loja, das ações e das peças com ação, e os NPCs (minimap/architecture).
func _build_markers() -> Array[MapMarker]:
	var markers: Array[MapMarker] = []
	for action: MapAction in _map.actions:
		var kind := _marker_kind(action.action_type_id)
		if kind != &"":
			markers.append(MapMarker.make(kind, BuildingNamesLayer.middle_of(action.tiles)))
	for prop: MapProp in _map.props:
		var kind := _marker_kind(prop.action_type_id)
		if kind != &"":
			markers.append(MapMarker.make(kind, prop.coord, HexMapView.flat_center(prop.coord) + Vector2(prop.offset)))
	for sprite: NpcSprite in _npc_sprites:
		markers.append(MapMarker.following(sprite))
	return markers


func _marker_kind(action_type_id: int) -> StringName:
	if action_type_id <= 0:
		return &""
	var slug := str(GameData.get_row("action_types", action_type_id).get("slug", ""))
	return StringName(slug) if MAP_MARKER_ACTIONS.has(slug) else &""


func _refresh_building_names() -> void:
	_building_names.clear()
	for label: Dictionary in _building_labels:
		if _is_visible_hex(label["coord"]):
			_building_names.add_name(label["text"], label["point"])


## Descobre os hexágonos em volta do Domador e tira a névoa deles (fog-of-war/02).
func _discover() -> void:
	var found := _discovery.reveal_around(_map, _player_coord)
	if found.is_empty():
		return
	Session.queue_island_discoveries(_map.island_id, found)
	_fog.reveal(found)
	_minimap_image.reveal(found)
	_refresh_building_names()
	_refresh_lights()


func _is_visible_hex(coord: Vector2i) -> bool:
	return _showing_whole_map or _discovery.is_discovered(coord)


func _enter_action(from: int, to: int) -> void:
	if to >= 0 and to != from:
		_run_action(to)


func _run_action(index: int) -> void:
	_run_action_type(_map.actions[index].action_type_id)


func _run_action_type(type_id: int) -> void:
	if ActionScreens.screen_for(type_id) == &"":
		return
	_debug_menu.hide()
	var text := ActionScreens.open(type_id)
	if not text.is_empty():
		_show_message(text, &"SecondaryLabel")


## A peça com sala abre o interior (interiors/02); a outra roda a ação dela.
func _open_prop(index: int) -> void:
	var prop := _map.props[index]
	if prop.interior_id > 0:
		_debug_menu.hide()
		Router.push(&"interior", {"interior_id": prop.interior_id})
		return
	_run_action_type(prop.action_type_id)


func _challenge(tamer: MapTamer) -> void:
	_challenger = tamer
	_debug_menu.hide()
	_message.hide()
	_set_controls_enabled(false)
	_greeting.say("%s: %s" % [GameData.get_npc_tamer_name(tamer.name_id), GameData.get_npc_tamer_greeting(tamer.greeting_id)], GameData.voice_by_slug(NPC_TAMER_VOICE))


func _add_npcs() -> void:
	for npc: MapNpc in _map.npcs:
		var sprite := NpcSprite.make(npc)
		if sprite == null:
			continue
		sprite.place_on(_map_view, _map)
		sprite.scale = _marker.scale
		_npc_sprites.append(sprite)


func _npc_hit(art_point: Vector2) -> NpcSprite:
	for sprite: NpcSprite in _npc_sprites:
		if not sprite.visible or _followers.has(sprite) or not _discovery.is_discovered(sprite.coord) or not sprite.hits(art_point):
			continue
		if sprite.npc.has_talk() or Story.scene_for_npc(_map.island_id, sprite.npc.npc_id) != null:
			return sprite
	return null


## Perto, a conversa abre; longe, o Domador anda até o hexágono do NPC ou um vizinho,
## o mais perto, e ela abre ao chegar.
func _go_to_npc(npc: NpcSprite) -> void:
	if ExplorationMap.distance(_player_coord, npc.coord) <= 1:
		_talk(npc)
		return
	var goals: Dictionary[Vector2i, bool] = {}
	for coord: Vector2i in [npc.coord] + _map.neighbors(npc.coord):
		if _map.has(coord):
			goals[coord] = true
	var path := _map.path_to_any(_player_coord, goals, _player_point)
	if path.is_empty():
		_show_message(NO_PATH_TEXT, &"SecondaryLabel")
		return
	var hexes: Array[Vector2i] = [_player_coord]
	hexes.append_array(path)
	_npc_target = npc
	_walk(WalkRoute.points(_map, _player_point, hexes, HexMapView.flat_center(path[path.size() - 1])))


## A peça da frente com ação cuja arte tem um pixel desenhado em `art_point`, ou -1.
## As outras, mesmo com bloqueio, deixam o toque passar para o chão: tocar na copa de
## uma árvore anda até o ponto tocado, atrás dela (prop-depth-blocks/04).
func _prop_hit(art_point: Vector2) -> int:
	var best := -1
	for index: int in _map.props.size():
		var prop := _map.props[index]
		if (prop.action_type_id <= 0 and prop.interior_id <= 0) or not _discovery.is_discovered(prop.coord):
			continue
		if best >= 0 and prop.foot().y < _map.props[best].foot().y:
			continue
		var slug := PropArt.slug_of(prop.prop_type_id)
		var rect := PropArt.rect(slug, prop.variant)
		var local := art_point - (prop.foot() - Vector2(0.0, _rise_at(prop.coord)))
		if prop.mirrored:
			local.x = -local.x - 1.0
		if not rect.has_point(local):
			continue
		var image := _prop_image(slug, prop.variant)
		var pixel := Vector2i(local - rect.position)
		if image != null and image.get_pixelv(pixel.clamp(Vector2i.ZERO, image.get_size() - Vector2i.ONE)).a < HIT_ALPHA:
			continue
		best = index
	return best


func _prop_image(slug: String, variant: int) -> Image:
	var key := "%s/%d" % [slug, variant]
	if not _prop_images.has(key):
		var texture := PropArt.icon(slug, variant)
		_prop_images[key] = texture.get_image() if texture != null else null
	return _prop_images[key]


## Se o Domador está encostado na peça: a até TOUCH_REACH de uma linha dela, ou do pé,
## numa sem linhas.
func _touching_prop(index: int) -> bool:
	var lines := _map.prop_world_lines(index)
	if lines.is_empty():
		return _player_point.distance_to(_map.props[index].foot()) <= TOUCH_REACH * 2.0
	return ExplorationMap.nearest_on_lines(lines, _player_point).distance_to(_player_point) <= TOUCH_REACH


## O Domador anda até o ponto da peça mais perto dele e para rente ao bloqueio; a ação
## da peça acontece se ele chegar encostado. Já encostado, ela acontece sem andar.
func _go_to_prop(index: int) -> void:
	var prop := _map.props[index]
	if _touching_prop(index):
		_open_prop(index)
		return
	var lines := _map.prop_world_lines(index)
	var finish := prop.foot() if lines.is_empty() else ExplorationMap.nearest_on_lines(lines, _player_point)
	var target := HexMapView.grid_coord(finish)
	if not _map.has(target):
		_show_message(NO_PATH_TEXT, &"SecondaryLabel")
		return
	var goals: Dictionary[Vector2i, bool] = {target: true}
	if _map.is_center_walled(target):
		goals = _map.approach_goals(target, finish)
	var hexes: Array[Vector2i] = [_player_coord]
	if not goals.has(_player_coord):
		var path := _map.path_to_any(_player_coord, goals, _player_point)
		if path.is_empty():
			_show_message(NO_PATH_TEXT, &"SecondaryLabel")
			return
		hexes.append_array(path)
	_prop_target = index
	_walk(WalkRoute.points(_map, _player_point, hexes, finish))


func _talk(npc: NpcSprite) -> void:
	var scene := Story.scene_for_npc(_map.island_id, npc.npc.npc_id)
	if scene != null:
		npc.hold(true, _player_art_point())
		_marker.face_toward(npc.position - _player_art_point())
		_marker.play_idle()
		await _play_scene(scene, npc)
		if is_instance_valid(npc) and not _followers.has(npc):
			npc.resume()
		return
	var lines := npc.npc.lines()
	if lines.is_empty():
		_run_action_type(npc.npc.action_type_id)
		return
	_talking = npc
	_talk_lines = lines
	_talk_index = 0
	npc.hold(true, _player_art_point())
	_marker.face_toward(npc.position - _player_art_point())
	_marker.play_idle()
	_debug_menu.hide()
	_message.hide()
	_set_controls_enabled(false)
	_say_line()


func _say_line() -> void:
	var npc_name := str(GameData.get_npc(_talking.npc.npc_id).get("name", ""))
	_greeting.say("%s: %s" % [npc_name, _talk_lines[_talk_index]], GameData.npc_voice(_talking.npc.npc_id))


func _on_greeting_tapped() -> void:
	if _talking == null:
		_fight_challenger()
		return
	_talk_index += 1
	if _talk_index < _talk_lines.size():
		_say_line()
		return
	var npc := _talking
	_talking = null
	_greeting.close()
	_set_controls_enabled(true)
	npc.hold(false)
	_run_action_type(npc.npc.action_type_id)


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


func _forget_island() -> void:
	if _map == null or _map.island_id <= 0:
		return
	_debug_menu.hide()
	var result: Result = await Session.forget_island_discoveries(_map.island_id)
	if not result.ok:
		_show_message(result.error, &"DangerLabel")
		return
	_discovery.clear()
	_reveal_home_field()
	Session.queue_island_discoveries(_map.island_id, _discovery.reveal_around(_map, _player_coord))
	_fog.set_map(_map, _discovery)
	_fog.visible = not _showing_whole_map
	_rebuild_minimap()
	_refresh_building_names()
	_refresh_lights()


func _toggle_whole_map() -> void:
	if _walking or _challenger != null:
		return
	_debug_menu.hide()
	_showing_whole_map = not _showing_whole_map
	_debug_zoom_button.text = NORMAL_ZOOM_TEXT if _showing_whole_map else WHOLE_MAP_TEXT
	_fog.visible = not _showing_whole_map
	_rebuild_minimap()
	_refresh_building_names()
	_refresh_wild_sprites()
	_fit_view()


func _toggle_debug_menu() -> void:
	_show_debug_part(false)
	_debug_menu.visible = not _debug_menu.visible
	%DebugTimeLabel.text = WorldClock.clock_text()
	%DebugTimeSlider.set_value_no_signal(snappedf(WorldClock.minute_of_day(), 15.0))


func _show_debug_part(spawn: bool) -> void:
	_debug_spawn.visible = spawn
	_debug_main.visible = not spawn
	_debug_scenes.visible = false


func _toggle_god() -> void:
	Session.debug_god = not Session.debug_god
	_refresh_god_button()


func _refresh_god_button() -> void:
	_debug_god_button.text = GOD_ON_TEXT if Session.debug_god else GOD_OFF_TEXT


func _toggle_contour() -> void:
	_map_view.set_contour_visible(not HexMapView.contour_visible)
	_refresh_contour_button()


func _toggle_rounded() -> void:
	_map_view.set_rounded_corners(not HexMapView.rounded_corners)
	_refresh_rounded_button()


func _toggle_height_cues(lips: bool, shadows: bool, tint: bool) -> void:
	_map_view.set_height_cues(lips, shadows, tint)
	_refresh_height_cue_buttons()


func _refresh_height_cue_buttons() -> void:
	_debug_lips_button.text = LIPS_TEXT % ("ligada" if HexMapView.height_lips else "desligada")
	_debug_shadows_button.text = SHADOWS_TEXT % ("ligada" if HexMapView.foot_shadows else "desligada")
	_debug_tint_button.text = TINT_TEXT % ("ligado" if HexMapView.height_tint else "desligado")


func _refresh_rounded_button() -> void:
	_debug_rounded_button.text = ROUNDED_ON_TEXT if HexMapView.rounded_corners else ROUNDED_OFF_TEXT


func _refresh_contour_button() -> void:
	_debug_contour_button.text = CONTOUR_ON_TEXT if HexMapView.contour_visible else CONTOUR_OFF_TEXT


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


func _debug_tamer(team_size: int) -> void:
	if _walking or _challenger != null:
		return
	_debug_menu.hide()
	var result: Result = await Session.debug_tamer(_player_coord, team_size)
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
	return _showing_whole_map or ExplorationMap.distance(coord, _player_coord) <= _creature_radius()


func _creature_radius() -> int:
	return maxi(CREATURE_RADIUS, ceili(CREATURE_RADIUS * float(HexMapView.DEFAULT_ZOOM) / _map_view.zoom_level))


func _add_creature_sprite(slug: String, coord: Vector2i) -> CreatureSprite:
	var creature := CreatureSprite.new(slug)
	_place_wanderer(creature, coord)
	return creature


func _place_wanderer(sprite: WanderingSprite, coord: Vector2i) -> void:
	_map_view.add_child(sprite)
	sprite.depth_view = _map_view
	sprite.wander_in(coord, _map_view.surface_center(coord), _map)
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
	for npc: NpcSprite in _npc_sprites + _followers:
		npc.scale = _marker.scale
	_sync_view_layers()


func _sync_view_layers() -> void:
	_building_names.set_view(_map_view.position, _map_view.pixel_scale())
	_day_light.set_view(_map_view.position, _map_view.pixel_scale().x)
	_fog.set_view(_map_view.position, _map_view.pixel_scale().x)
	_refresh_lights()


## A luz do Domador e, depois, as das peças que tocam a tela, das mais perto dele para
## as mais longe, até o limite do filtro (day-night/03); os enxames de vagalumes do
## mesmo jeito, numa lista à parte (fireflies/01).
func _refresh_lights() -> void:
	if _map == null:
		return
	var art_scale := _map_view.pixel_scale().x
	var view := Rect2(-_map_view.position / art_scale, _map_area.size / art_scale)
	var player := _player_art_point()
	var near: Array[MapLight] = []
	for light: MapLight in _prop_lights:
		if _is_visible_hex(light.coord) and view.grow(light.radius).has_point(light.position):
			near.append(light)
	near.sort_custom(func(a: MapLight, b: MapLight) -> bool: return a.position.distance_squared_to(player) < b.position.distance_squared_to(player))
	var lights: Array[MapLight] = [MapLight.make(player - Vector2(0.0, TAMER_LIGHT_LIFT), TAMER_LIGHT_RADIUS, TAMER_LIGHT_COLOR)]
	lights.append_array(near.slice(0, DayLightLayer.MAX_LIGHTS - 1))
	_day_light.set_lights(lights)
	var swarms: Array[Vector2] = []
	var swarm_view := view.grow(DayLightLayer.SWARM_REACH)
	for index: int in _swarms.size():
		var swarm := _swarms[index]
		if _is_visible_hex(_swarm_coords[index]) and swarm_view.has_point(swarm):
			swarms.append(swarm)
	swarms.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(player) < b.distance_squared_to(player))
	_day_light.set_swarms(PackedVector2Array(swarms.slice(0, DayLightLayer.MAX_SWARMS)))


## Parte do centro já arredondado: em uma tela de tamanho ímpar, ele cai no meio de
## um pixel, e arredondar depois da conta deixaria o Domador fora do hexágono.
func _screen_center() -> Vector2:
	return Vector2(size.x / 2.0, size.y * _center_ratio)


func _player_centered_position() -> Vector2:
	var focus := _camera_focus if _camera_focus.is_finite() else _player_art_point()
	return _map_view.snapped_to_pixels(_screen_center()) - focus * _map_view.pixel_scale()


## Sempre em pixels reais inteiros, para a pixel art não borrar no caminho. O Domador
## é filho do mapa: a posição dele desconta o mapa, e ele fica parado na tela.
func _move_map(value: Vector2) -> void:
	_map_view.position = _map_view.snapped_to_pixels(value)
	if _camera_focus.is_finite():
		_marker.position = _player_art_point()
	else:
		_marker.position = (_map_view.snapped_to_pixels(_screen_center()) - _map_view.position) / _map_view.pixel_scale()
	_sync_view_layers()


func _show_message(text: String, variation: StringName) -> void:
	_message.text = text
	_message.theme_type_variation = variation
	_message.show()


# A história (story/02 e 03).

func _build_story() -> void:
	_story_fade.color = Color(UiPalette.BACKGROUND_DEEP, 0.0)
	_story_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_area.add_child(_story_fade)
	var column := _greeting.get_parent()
	column.add_child(_story_choices)
	column.move_child(_story_choices, _greeting.get_index())
	_story.setup(self, _greeting, _story_choices, _story_fade)
	add_child(_story)
	var scenes_button := Button.new()
	scenes_button.text = DEBUG_SCENES_TEXT
	scenes_button.pressed.connect(_show_debug_scenes)
	_debug_main.add_child(scenes_button)
	# No topo: a lista do menu é longa e o fim dela fica embaixo do painel de controles.
	_debug_main.move_child(scenes_button, 0)
	_debug_scenes.visible = false
	_debug_main.get_parent().add_child(_debug_scenes)


## Ao entrar: a cena de teste do editor, ou a de área do hexágono de chegada, ou a `auto`.
func _start_story() -> void:
	if _map == null or _map.island_id <= 0:
		return
	if _story_test and Story.is_testing():
		if _playable(Story.test_scene()):
			await _story.play(Story.test_scene())
		Story.end_test()
		_story_test = false
		return
	var scene := Story.scene_for_tile(_map.island_id, _player_coord)
	if scene != null:
		_play_scene(scene)
	else:
		_play_auto()


func _play_scene(scene: StoryScene, touched: NpcSprite = null) -> void:
	if _story_busy() or scene == null or not _playable(scene):
		return
	await _story.play(scene, touched)
	_play_auto()


func _play_auto() -> void:
	if _map == null or _story_busy():
		return
	var scene := Story.scene_for_auto(_map.island_id)
	if scene != null:
		Story.note_auto_played(scene)
		_play_scene(scene)
	elif Home.is_home(_map.island_id) and Session.player != null and not Session.player.has_name():
		_open_creation()


## Os passos da introdução só tocam na ilha casa; fora dela, a cena não toca.
func _playable(scene: StoryScene) -> bool:
	var errors := StoryValidator.home_errors(scene, Session.home_island_id)
	for error: String in errors:
		push_warning(error)
	return errors.is_empty()


func _reveal_home_field() -> void:
	if Home.is_home(_map.island_id):
		Session.queue_island_discoveries(_map.island_id, _discovery.reveal_around(_map, _map.start, HOME_KNOWN_RADIUS))


func _story_busy() -> bool:
	return _story.playing or _creating


func _has_team() -> bool:
	return Session.player != null and Session.player.has_starter()


## Sem equipe (liora-intro/03): sem Procurar e sem o Menu; voltam quando o inicial chega.
func _refresh_team_controls() -> void:
	var team := _has_team()
	_encounter_button.visible = team
	if _at_home():
		_back_button.visible = team


## Na casa sem nome e sem cena para dar o nome, a criação abre sozinha.
func _open_creation() -> void:
	_creating = true
	story_began()
	await story_create_tamer()
	_creating = false
	story_ended()
	_play_auto()


func _show_debug_scenes() -> void:
	for child: Node in _debug_scenes.get_children():
		child.queue_free()
	var scenes := Story.library.for_island(_map.island_id if _map != null else 0)
	if scenes.is_empty():
		var label := Label.new()
		label.text = DEBUG_NO_SCENES_TEXT
		_debug_scenes.add_child(label)
	for scene: StoryScene in scenes:
		var button := Button.new()
		button.text = "%s (%s)" % [scene.name, scene.slug]
		button.pressed.connect(_debug_play_scene.bind(scene))
		_debug_scenes.add_child(button)
	var back := Button.new()
	back.text = DEBUG_BACK_TEXT
	back.pressed.connect(_show_debug_part.bind(false))
	_debug_scenes.add_child(back)
	_debug_main.hide()
	_debug_spawn.hide()
	_debug_scenes.show()


## Toca a cena sem gravar nada, com os Marcos que ela exige (story/02, RF-15).
func _debug_play_scene(scene: StoryScene) -> void:
	_debug_menu.hide()
	if _story_busy() or _walking:
		return
	Story.begin_test(scene, scene.requires)
	await _story.play(scene)
	Story.end_test()


func story_began() -> void:
	if _zoom_tween != null:
		_stop_zoom_tween()
		_finish_zoom(_zoom_target)
	_npc_target = null
	_prop_target = -1
	_debug_menu.hide()
	_message.hide()
	_controls_panel.hide()
	_minimap.hide()
	# A câmera da cena mostra o mapa inteiro; a névoa volta, como estava, quando ela termina.
	_fog.visible = false


func story_ended() -> void:
	_controls_panel.show()
	_minimap.show()
	_fog.visible = not _showing_whole_map
	_fit_view.call_deferred()


func story_island_npc(npc_id: int, touched: NpcSprite) -> NpcSprite:
	if touched != null and touched.npc.npc_id == npc_id:
		return touched
	for sprite: NpcSprite in _followers + _npc_sprites:
		if sprite.npc.npc_id == npc_id:
			return sprite
	return null


func story_add_actor(npc_id: int, coord: Variant) -> NpcSprite:
	if not coord is Vector2i or not NpcSprite.can_draw(npc_id) or not _map.has(coord):
		return null
	var npc := MapNpc.new()
	npc.npc_id = npc_id
	npc.coord = coord
	npc.still = true
	var sprite := NpcSprite.make(npc)
	sprite.place_on(_map_view, _map)
	sprite.scale = _marker.scale
	return sprite


## Ao fim da cena: quem segue fica; o NPC da ilha volta a passear; o resto sai do mapa.
func story_release(sprite: NpcSprite, _created: bool) -> void:
	if _followers.has(sprite):
		return
	if _npc_sprites.has(sprite):
		sprite.resume()
	else:
		sprite.queue_free()


func story_set_follow(sprite: NpcSprite, on: bool) -> void:
	if on and not _followers.has(sprite):
		_followers.append(sprite)
		sprite.scripted = true
		sprite.walk_speed = WalkRoute.WALK_SPEED
	elif not on and _followers.has(sprite):
		_followers.erase(sprite)
		sprite.walk_speed = NpcSprite.STORY_SPEED


## Cada seguidor anda até onde o da frente estava: o primeiro, até o hexágono que o
## Domador acabou de deixar.
func _lead_followers(left: Vector2i) -> void:
	_trail.push_front(left)
	_trail.resize(mini(_trail.size(), maxi(_followers.size(), 1)))
	for index: int in _followers.size():
		if index < _trail.size():
			_followers[index].walk_to(_trail[index])


func story_walk_tamer(coord: Vector2i) -> void:
	while _walking:
		_stop_walk = true
		await get_tree().process_frame
	var goals: Dictionary[Vector2i, bool] = {coord: true}
	var hexes: Array[Vector2i] = [_player_coord]
	if coord != _player_coord:
		var path := _map.path_to_any(_player_coord, goals, _player_point)
		if path.is_empty():
			push_warning("Cena: o Domador não acha caminho até (%d, %d)." % [coord.x, coord.y])
			return
		hexes.append_array(path)
	var finish := HexMapView.flat_center(coord)
	if finish.distance_to(_player_point) < 1.0:
		return
	var route := WalkRoute.points(_map, _player_point, hexes, finish)
	if route.size() < 2:
		return
	await _walk(route)


func story_tamer_point() -> Vector2:
	return _player_art_point()


func story_hex_point(coord: Vector2i) -> Vector2:
	return HexMapView.flat_center(coord) - Vector2(0.0, _rise_at(coord))


func story_face_tamer(point: Vector2) -> void:
	if point != _player_art_point():
		_marker.face_toward(point - _player_art_point())


## `zoom` 0 mantém o zoom para onde a câmera vai, que sempre é um degrau inteiro (story/07).
func story_camera_to(coord: Vector2i, seconds: float, zoom: int = 0) -> void:
	var target_zoom := float(zoom) if zoom > 0 else (_camera_target_zoom if _camera_tween != null else float(_map_view.zoom_level))
	_slide_camera(story_hex_point(coord), target_zoom, seconds, false)
	await camera_settled


## Volta ao Domador e ao zoom do jogador.
func story_camera_back(seconds: float) -> void:
	var zoom := float(ViewSettings.explore_zoom())
	if _camera_tween == null and not _camera_focus.is_finite() and is_equal_approx(_camera_zoom(), zoom):
		return
	_slide_camera(_player_art_point(), zoom, seconds, true)
	await camera_settled


func story_camera_idle() -> void:
	if _camera_tween != null:
		await camera_settled


func _camera_zoom() -> float:
	return _map_view.story_zoom if _map_view.story_zoom > 0.0 else float(_map_view.zoom_level)


## Um movimento novo para o anterior e parte de onde a câmera está, sem saltar.
func _slide_camera(target: Vector2, zoom: float, seconds: float, back: bool) -> void:
	if _camera_tween != null:
		_camera_tween.kill()
	_camera_target_zoom = zoom
	var start := _camera_focus if _camera_focus.is_finite() else _player_art_point()
	_camera_focus = start
	_camera_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_method(_camera_frame.bind(start, target, _camera_zoom(), zoom), 0.0, 1.0, maxf(seconds, 0.01))
	_camera_tween.finished.connect(_camera_arrived.bind(zoom, back))


## O foco e a escala saem do mesmo valor, para o mapa não escorregar enquanto aproxima.
func _camera_frame(weight: float, start: Vector2, target: Vector2, from_zoom: float, to_zoom: float) -> void:
	_camera_focus = start.lerp(target, weight)
	if is_equal_approx(from_zoom, to_zoom):
		_move_map(_player_centered_position())
		return
	_map_view.story_zoom = lerpf(from_zoom, to_zoom, weight)
	_fit_view()


func _camera_arrived(zoom: float, back: bool) -> void:
	_camera_tween = null
	var level := roundi(zoom)
	if _map_view.story_zoom > 0.0 or level != _map_view.zoom_level:
		_map_view.zoom_level = level
		_map_view.story_zoom = 0.0
		_refresh_wild_sprites()
		_fit_view()
	if back:
		_camera_focus = Vector2.INF
		_move_map(_player_centered_position())
	camera_settled.emit()


## O passo `create_tamer`: a criação por cima do mapa, com o Domador maior e acima do painel.
func story_create_tamer() -> void:
	var panel := TamerCreatorPanel.new()
	panel.appearance_changed.connect(_marker.set_appearance)
	add_child(panel)
	var zoom := _map_view.zoom_level
	_map_view.zoom_level = HexMapView.MAX_ZOOM
	_center_ratio = CREATOR_CENTER
	_fit_view()
	await panel.done
	panel.queue_free()
	_map_view.zoom_level = zoom
	_center_ratio = 0.5
	if Session.player != null:
		_marker.set_appearance(Session.player.appearance)
	_refresh_wild_sprites()
	_fit_view()


## O passo `choose_starter`: a escolha do inicial, sem Voltar; quem já tem inicial pula.
func story_choose_starter() -> void:
	if _has_team():
		return
	await story_open_screen(&"starter_select", {"story": true})
	_refresh_team_controls()


func story_open_screen(screen: StringName, params: Dictionary = {}) -> void:
	Router.push(screen, params)
	await get_tree().process_frame
	while not is_visible_in_tree():
		await visibility_changed
