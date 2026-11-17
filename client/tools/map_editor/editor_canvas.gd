class_name EditorCanvas
extends Control

signal hovered(coord: Vector2i, tile: HexTile)
signal stroke_started(coord: Vector2i, secondary: bool)
signal stroke_moved(coord: Vector2i)
signal stroke_ended
## O zoom ou o arrasto mudaram: o que acompanha o mapa se reposiciona.
signal view_changed
## O ponteiro andou com um botão apertado: o ponto no chão plano, para arrastar peças.
signal pointer_dragged(flat: Vector2)

const DETAIL_ZOOMS: Array[float] = [1.0, 2.0, 3.0, 4.0, 6.0]
const OVERVIEW_BELOW := 1.0
const OVERVIEW_STEP := 1.25
const MIN_ZOOM := 0.01
const OPEN_ZOOM := 2.0
const FIT_MARGIN := 24.0
const FLAG_HEIGHT := 22.0
const FLAG_WIDTH := 12.0
const OUTLINE_WIDTH := 2.0
## O traço da parede invisível, em pixels da tela (free-fences/01).
const WALL_DASH := 6.0
const CHUNK_COLUMNS := 16
## Até onde as linhas de bloqueio de uma peça vão a partir do hexágono dela, na arte.
const BLOCK_REACH := 160.0
## Numa pincelada rápida, um ponto a cada tanto da arte, para não pular hexágonos.
const STROKE_SPACING := 16.0
const AREA_ALPHA := 0.38
const ACTION_ALPHA := 0.62
const NAME_SIZE := 14
const FOCUS_DIM := Color(UiPalette.BACKGROUND_DEEP, 0.72)

var brush: Callable = Callable()
## Os hexágonos marcados para um carimbo, contornados.
var marked: Callable = Callable()
## A cor do contorno sob o ponteiro (Color.TRANSPARENT: a de sempre).
var brush_color: Callable = Callable()
var selected_prop := -1
var selected_trail := -1
## A parede escolhida pela Cerca, ou -1, e a que está sendo desenhada (free-fences/03).
var selected_wall := -1
var fence_preview := Callable()
## O bloqueio da peça escolhida em edição (free-objects/02): os pontos aparecem, e a
## linha em desenho (no chão plano) segue o ponteiro.
var editing_prop_block := false
## A ferramenta Bloqueios mostra os pontos das linhas de todas as peças (prop-depth-blocks/03).
var all_block_points := false:
	set(value):
		all_block_points = value
		if _blocks_layer != null:
			_blocks_layer.queue_redraw()
var block_preview := Callable()
var _mouse_flat := Vector2.ZERO
var action_colors: Dictionary[int, Color] = {}
var action_names: Dictionary[int, String] = {}
var selected_action := -1
var selected_npc := -1
## As marcas da cena aberta na ferramenta Cenas (story/04), de `ScenePanel.marks`.
var scene_marks: Callable = Callable()
var _npc_sprites: Array[NpcSprite] = []

var _map_view: HexMapView
var _overview: IslandOverview
var _overlay: Overlay
var _area_layer: HexTintLayer
var _area_stripes: HexTintLayer
var _action_layer: HexTintLayer
var _dim_layer: HexTintLayer
var _focus_key := 0
var _show_areas := true
var _show_actions := true
var _show_blocks := true
## Os bloqueios das peças por hexágono de peça, quantas peças bloqueiam cada hexágono e os
## hexágonos das paredes: mexer numa peça refaz só o hexágono dela (editor-performance/01).
var _block_cells: Dictionary[Vector2i, BlockCell] = {}
var _block_counts: Dictionary[Vector2i, int] = {}
var _wall_hexes: Dictionary[Vector2i, bool] = {}
var _blocks_layer: BlocksLayer
## A chave das peças de cada hexágono, para achar os que mudaram.
var _prop_tiles: Dictionary[Vector2i, int] = {}
## Cópias dos traços como estão desenhados, para achar o que mudou.
var _shown_trails: Array[MapTrail] = []
var _shown_walls: Array[MapWall] = []
var _shown_bridges: Array[MapBridge] = []
## A ponte escolhida pela Ponte, ou -1, e a primeira ponta da que está sendo desenhada
## (bridges/03).
var selected_bridge := -1
var bridge_preview := Callable()
var _draft: IslandDraft = null
var _map: ExplorationMap = null
var _zoom := OPEN_ZOOM
var _origin := Vector2.ZERO
var _force_overview := false
var _dragging := false
var _painting := false
var _last_art_point := Vector2.ZERO
var _last_coord := Vector2i.ZERO
var _hovered := Vector2i.ZERO
var _has_hover := false
var _pending: Dictionary[Vector2i, bool] = {}


## O desenho por cima do mapa, em pontos deste Control: não cresce com o zoom.
class Overlay extends Node2D:
	var canvas: EditorCanvas

	func _draw() -> void:
		canvas.draw_overlay(self)


## Os bloqueios, por baixo do desenho de cima: o pincel segue o mouse a cada movimento, e
## os bloqueios só mudam com eles, a vista ou o terreno.
class BlocksLayer extends Node2D:
	var canvas: EditorCanvas

	func _draw() -> void:
		canvas.draw_blocks(self)


class BlockCell extends RefCounted:
	var lines: Array[PackedVector2Array] = []
	var custom: Array[bool] = []
	var hexes: Dictionary[Vector2i, bool] = {}


func _init() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_CLICK
	mouse_filter = Control.MOUSE_FILTER_STOP
	_map_view = HexMapView.new()
	_map_view.chunk_columns = CHUNK_COLUMNS
	_map_view.fixed_scale = _zoom
	add_child(_map_view)
	_overview = IslandOverview.new()
	add_child(_overview)
	_dim_layer = HexTintLayer.new(false, IslandDraft.MAX_TILES)
	add_child(_dim_layer)
	_area_layer = HexTintLayer.new(false, IslandDraft.MAX_TILES)
	add_child(_area_layer)
	_area_stripes = HexTintLayer.new(true, IslandDraft.MAX_TILES)
	add_child(_area_stripes)
	_action_layer = HexTintLayer.new(false, IslandDraft.MAX_TILES)
	add_child(_action_layer)
	_blocks_layer = BlocksLayer.new()
	_blocks_layer.canvas = self
	add_child(_blocks_layer)
	_overlay = Overlay.new()
	_overlay.canvas = self
	add_child(_overlay)
	resized.connect(_apply_view)


func show_draft(draft: IslandDraft, fit: bool = true) -> void:
	_draft = draft
	_pending.clear()
	_map = draft.to_map() if draft != null else ExplorationMap.new()
	_map_view.set_map(_map)
	_map_view.set_props(_map.props)
	_prop_tiles.clear()
	if draft != null:
		_prop_tiles = _current_prop_tiles()
	_overview.set_map(_map)
	_shown_trails.clear()
	if draft != null:
		_shown_trails = IslandDraft.copy_trails(draft.trails)
	_overview.set_trails(_map.trails)
	_shown_walls.clear()
	if draft != null:
		_shown_walls = IslandDraft.copy_walls(draft.walls)
	_overview.set_walls(_map.walls)
	_shown_bridges.clear()
	if draft != null:
		_shown_bridges = IslandDraft.copy_bridges(draft.bridges)
	_overview.set_bridges(_map.bridges)
	_refresh_blocks()
	refresh_npcs()
	refresh_marks()
	if fit and draft != null:
		fit_whole_island()
	_apply_view()


func update_tiles(coords: Array[Vector2i]) -> void:
	for coord: Vector2i in coords:
		_pending[coord] = true
	_overlay.queue_redraw()


## Os NPCs mudaram no rascunho (island-npcs/02): cada um parado no hexágono dele.
func refresh_npcs() -> void:
	for sprite: NpcSprite in _npc_sprites:
		sprite.queue_free()
	_npc_sprites.clear()
	if _draft == null:
		return
	for npc: MapNpc in _draft.map_npcs():
		if not _draft.tiles.has(npc.coord):
			continue
		var sprite := NpcSprite.make(npc)
		if sprite == null:
			continue
		sprite.place_on(_map_view, null)
		_npc_sprites.append(sprite)
	_overlay.queue_redraw()


## As peças soltas mudaram no rascunho: refaz os hexágonos que ganharam, perderam ou
## mudaram alguma.
func refresh_props() -> void:
	if _draft == null or _map == null:
		return
	var now := _current_prop_tiles()
	var changed: Array[Vector2i] = []
	for coord: Vector2i in now:
		if _prop_tiles.get(coord, 0) != now[coord]:
			changed.append(coord)
	for coord: Vector2i in _prop_tiles:
		if not now.has(coord):
			changed.append(coord)
	refresh_props_at(changed)
	_overlay.queue_redraw()


## Os traços mudaram no rascunho (free-trails/04): redesenha os que entraram, saíram
## ou mudaram, na versão de antes e na de agora.
func refresh_trails() -> void:
	if _draft == null or _map == null:
		return
	var before := IslandDraft.trails_state(_shown_trails)
	var now := IslandDraft.trails_state(_draft.trails)
	var changed: Array[MapTrail] = []
	for index: int in _shown_trails.size():
		if not now.has(before[index]):
			changed.append(_shown_trails[index])
	for index: int in _draft.trails.size():
		if not before.has(now[index]):
			changed.append(_draft.trails[index])
	_shown_trails = IslandDraft.copy_trails(_draft.trails)
	if not changed.is_empty() or before != now:
		_map_view.set_trails(_draft.trails.duplicate(), changed)
		_overview.set_trails(_map.trails)
	_overlay.queue_redraw()


## As paredes mudaram no rascunho (free-fences/01): remonta as que entraram, saíram ou
## mudaram, na versão de antes e na de agora.
func refresh_walls() -> void:
	if _draft == null or _map == null:
		return
	var before := _state_counts(_shown_walls)
	var now := _state_counts(_draft.walls)
	var changed: Array[MapWall] = []
	for wall: MapWall in _shown_walls:
		if not now.has(JSON.stringify(wall.to_dict())):
			changed.append(wall)
	for wall: MapWall in _draft.walls:
		if not before.has(JSON.stringify(wall.to_dict())):
			changed.append(wall)
	_shown_walls = IslandDraft.copy_walls(_draft.walls)
	if not changed.is_empty():
		_map_view.set_walls(_draft.walls.duplicate(), changed)
		_overview.set_walls(_map.walls)
		_refresh_wall_blocks()
	_overlay.queue_redraw()


## As pontes mudaram no rascunho (bridges/03): remonta as que entraram, saíram ou mudaram.
func refresh_bridges() -> void:
	if _draft == null or _map == null:
		return
	var before: Dictionary[String, bool] = {}
	for bridge: MapBridge in _shown_bridges:
		before[JSON.stringify(bridge.to_dict())] = true
	var now: Dictionary[String, bool] = {}
	for bridge: MapBridge in _draft.bridges:
		now[JSON.stringify(bridge.to_dict())] = true
	var changed: Array[MapBridge] = []
	for bridge: MapBridge in _shown_bridges:
		if not now.has(JSON.stringify(bridge.to_dict())):
			changed.append(bridge)
	for bridge: MapBridge in _draft.bridges:
		if not before.has(JSON.stringify(bridge.to_dict())):
			changed.append(bridge)
	_shown_bridges = IslandDraft.copy_bridges(_draft.bridges)
	if not changed.is_empty():
		_map_view.set_bridges(_draft.bridges.duplicate(), changed)
		_overview.set_bridges(_map.bridges)
	_overlay.queue_redraw()


static func _state_counts(walls: Array[MapWall]) -> Dictionary[String, bool]:
	var states: Dictionary[String, bool] = {}
	for wall: MapWall in walls:
		states[JSON.stringify(wall.to_dict())] = true
	return states


## Enquanto um caminho é desenhado: só o pedaço novo.
func refresh_trail_piece(piece: MapTrail) -> void:
	if _draft == null or _map == null:
		return
	_map_view.set_trails(_draft.trails.duplicate(), [piece])
	_overview.set_trails(_map.trails)
	_overlay.queue_redraw()


## A chave vem do dicionário inteiro da peça, com o bloqueio ajustado, sem convertê-la.
func _current_prop_tiles() -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}
	for entry: Variant in _draft.props:
		var data := entry as Dictionary
		var coord := Vector2i(int(data.get("q", 0)), int(data.get("r", 0)))
		result[coord] = hash([result.get(coord, 0), data])
	return result


## Refaz as peças e os bloqueios só nos hexágonos de `coords` (vegetation-brush/02): numa
## ilha com milhares de peças, refazer a lista toda a cada passo pesa.
func refresh_props_at(coords: Array[Vector2i]) -> void:
	if _draft == null or _map == null or coords.is_empty():
		return
	var wanted: Dictionary[Vector2i, bool] = {}
	for coord: Vector2i in coords:
		wanted[coord] = true
	var typed := GameData.prop_block_types()
	var fresh: Array[MapProp] = []
	var keys: Dictionary[Vector2i, int] = {}
	var blocking: Dictionary[Vector2i, Array] = {}
	for index: int in _draft.props.size():
		var data: Dictionary = _draft.props[index]
		var coord := Vector2i(int(data.get("q", 0)), int(data.get("r", 0)))
		if not wanted.has(coord):
			continue
		keys[coord] = hash([keys.get(coord, 0), data])
		var prop := MapProp.from_dict(data)
		if prop != null:
			fresh.append(prop)
		if _blocks(data, typed):
			if not blocking.has(coord):
				blocking[coord] = []
			blocking[coord].append(index)
	var kept: Array[MapProp] = []
	for prop: MapProp in _map.props:
		if not wanted.has(prop.coord):
			kept.append(prop)
	kept.append_array(fresh)
	_map.props = kept
	_map_view.replace_props(wanted, fresh)
	for coord: Vector2i in wanted:
		if keys.has(coord):
			_prop_tiles[coord] = keys[coord]
		else:
			_prop_tiles.erase(coord)
		_set_block_cell(coord, blocking.get(coord, []))
	_blocks_layer.queue_redraw()
	update_tiles(coords)
	_overlay.queue_redraw()


## O ponto do ponteiro no chão plano, sem a altura do hexágono embaixo dele.
func pointer_flat() -> Vector2:
	return _flat_at(_last_art_point)


func _flat_at(art_point: Vector2) -> Vector2:
	if is_overview() or _draft == null:
		return art_point
	return art_point + Vector2(0.0, _draft.rise_at(_map_view.coord_at(art_point)))


## O retângulo, em pontos deste Control, da arte de uma peça solta.
func prop_rect(index: int) -> Rect2:
	if _draft == null or index < 0 or index >= _draft.props.size():
		return Rect2()
	var art := _draft.prop_rect(index)
	var base := _map_view.position if not is_overview() else _origin
	return Rect2(base + art.position * _zoom, art.size * _zoom)


func set_height_cut(value: int) -> void:
	_map_view.height_cut = value
	_overlay.queue_redraw()


func set_contour(on: bool) -> void:
	_map_view.set_contour_visible(on)


func set_blocks(on: bool) -> void:
	_show_blocks = on
	_blocks_layer.queue_redraw()
	_overlay.queue_redraw()


func refresh_brush() -> void:
	_overlay.queue_redraw()


func refresh_marks(coords: Array[Vector2i] = []) -> void:
	if _draft == null:
		for layer: HexTintLayer in [_area_layer, _area_stripes, _action_layer, _dim_layer]:
			layer.clear_all()
		_overlay.queue_redraw()
		return
	var action_of := _action_index()
	var area_color: Dictionary[int, Color] = {}
	var area_empty: Dictionary[int, bool] = {}
	for area: Variant in _draft.areas:
		var key := int((area as Dictionary).get("key", 0))
		area_color[key] = Color.from_string(str(area.get("color_hex", "")), UiPalette.TEXT_MUTED)
		area_empty[key] = (area.get("species", []) as Array).is_empty()
	var targets: Array[Vector2i] = coords
	if targets.is_empty():
		for layer: HexTintLayer in [_area_layer, _area_stripes, _action_layer, _dim_layer]:
			layer.clear_all()
		targets = []
		if _focus_key > 0:
			targets.assign(_draft.tiles.keys())
		else:
			targets.assign(_draft.tile_areas.keys())
			targets.append_array(action_of.keys())
	for coord: Vector2i in targets:
		var tile: HexTile = _draft.tiles.get(coord)
		var key: int = _draft.tile_areas.get(coord, 0) if tile != null else 0
		_area_layer.clear_hex(coord)
		_area_stripes.clear_hex(coord)
		_dim_layer.clear_hex(coord)
		if _focus_key > 0 and tile != null and key != _focus_key:
			_dim_layer.set_hex(coord, FOCUS_DIM, tile.height)
		elif area_color.has(key):
			var layer := _area_stripes if area_empty[key] else _area_layer
			layer.set_hex(coord, Color(area_color[key], AREA_ALPHA), tile.height)
		var action: int = action_of.get(coord, -1) if tile != null else -1
		if action >= 0:
			var type_id := int(_draft.actions[action].get("action_type_id", 0))
			_action_layer.set_hex(coord, Color(action_colors.get(type_id, UiPalette.TEXT), ACTION_ALPHA), tile.height)
		else:
			_action_layer.clear_hex(coord)
	_overlay.queue_redraw()


## Escurece todo hexágono fora da área `key`; 0 tira o foco.
func set_area_focus(key: int) -> void:
	if key == _focus_key:
		return
	_focus_key = key
	refresh_marks()


func set_layers(areas: bool, actions: bool) -> void:
	_show_areas = areas
	_show_actions = actions
	_apply_view()


func _action_index() -> Dictionary[Vector2i, int]:
	var action_of: Dictionary[Vector2i, int] = {}
	for index: int in _draft.actions.size():
		for coord: Vector2i in _draft.action_tiles(index):
			action_of[coord] = index
	return action_of


func fit_whole_island() -> void:
	if _draft == null or _draft.tiles.is_empty() or size.x <= 0.0:
		return
	var bounds := _island_bounds()
	var area := size - Vector2.ONE * FIT_MARGIN * 2.0
	_zoom = maxf(MIN_ZOOM, minf(area.x / bounds.size.x, area.y / bounds.size.y))
	if _zoom >= OVERVIEW_BELOW:
		_zoom = _detail_zoom_at_most(_zoom)
	_origin = size / 2.0 - bounds.get_center() * _zoom


func toggle_overview() -> void:
	if is_overview():
		_force_overview = false
		if _zoom < OVERVIEW_BELOW:
			_zoom_around(size / 2.0, OVERVIEW_BELOW)
	else:
		_force_overview = true
	_apply_view()


func is_overview() -> bool:
	return _force_overview or _zoom < OVERVIEW_BELOW


func _process(_delta: float) -> void:
	if _pending.is_empty() or _map == null:
		return
	var coords: Array[Vector2i] = []
	coords.assign(_pending.keys())
	_pending.clear()
	_map_view.update_tiles(coords)
	_overview.update_tiles(coords, _map)
	refresh_marks(coords)
	# A altura do hexágono move os bloqueios desenhados nele.
	_blocks_layer.queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		if button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_step_zoom(button.position, 1)
			accept_event()
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_step_zoom(button.position, -1)
			accept_event()
		elif button.button_index == MOUSE_BUTTON_MIDDLE or (button.button_index == MOUSE_BUTTON_LEFT and (Input.is_key_pressed(KEY_SPACE) or _dragging)):
			_dragging = button.pressed
			accept_event()
		elif button.button_index == MOUSE_BUTTON_LEFT or button.button_index == MOUSE_BUTTON_RIGHT:
			_paint_button(button)
			accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion != null:
		if _dragging:
			_origin += motion.relative
			_apply_view()
		elif _painting:
			_continue_stroke(motion.position)
		var drawing := fence_preview.is_valid() and not (fence_preview.call() as PackedVector2Array).is_empty()
		drawing = drawing or (block_preview.is_valid() and not (block_preview.call() as PackedVector2Array).is_empty())
		drawing = drawing or (bridge_preview.is_valid() and not (bridge_preview.call() as PackedVector2Array).is_empty())
		if _draft != null and drawing:
			_mouse_flat = _flat_at(_art_point(motion.position))
			_overlay.queue_redraw()
		_update_hover(motion.position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and _has_hover:
		_has_hover = false
		_overlay.queue_redraw()
		hovered.emit(_hovered, null)


func _paint_button(button: InputEventMouseButton) -> void:
	if _draft == null:
		return
	if button.pressed and not _painting:
		_painting = true
		_last_art_point = _art_point(button.position)
		_last_coord = _coord_at_art(_last_art_point)
		stroke_started.emit(_last_coord, button.button_index == MOUSE_BUTTON_RIGHT)
	elif not button.pressed and _painting:
		_painting = false
		stroke_ended.emit()


func _continue_stroke(at: Vector2) -> void:
	var art_point := _art_point(at)
	pointer_dragged.emit(_flat_at(art_point))
	var distance := _last_art_point.distance_to(art_point)
	var steps := maxi(1, ceili(distance / STROKE_SPACING))
	for index: int in range(1, steps + 1):
		var coord := _coord_at_art(_last_art_point.lerp(art_point, float(index) / steps))
		if coord != _last_coord:
			_last_coord = coord
			stroke_moved.emit(coord)
	_last_art_point = art_point


func _art_point(at: Vector2) -> Vector2:
	return (at - _origin) / _zoom


func _coord_at_art(art_point: Vector2) -> Vector2i:
	return HexMapView.grid_coord(art_point) if is_overview() else _map_view.coord_at(art_point)


func _step_zoom(at: Vector2, direction: int) -> void:
	var target := _zoom
	if _zoom >= OVERVIEW_BELOW:
		var index := DETAIL_ZOOMS.find(_detail_zoom_at_most(_zoom)) + direction
		if index < 0:
			target = _zoom / OVERVIEW_STEP
		elif index < DETAIL_ZOOMS.size():
			target = DETAIL_ZOOMS[index]
	else:
		target = _zoom * OVERVIEW_STEP if direction > 0 else maxf(MIN_ZOOM, _zoom / OVERVIEW_STEP)
		if target >= OVERVIEW_BELOW:
			target = OVERVIEW_BELOW
	_zoom_around(at, target)
	_apply_view()
	_update_hover(at)


func _zoom_around(at: Vector2, target: float) -> void:
	var art_point := _art_point(at)
	_zoom = target
	_origin = at - art_point * _zoom


func _detail_zoom_at_most(value: float) -> float:
	var best := DETAIL_ZOOMS[0]
	for zoom: float in DETAIL_ZOOMS:
		if zoom <= value + 0.001:
			best = zoom
	return best


func _apply_view() -> void:
	var overview := is_overview()
	_overview.visible = overview
	_overview.position = _origin
	_overview.scale = Vector2.ONE * _zoom
	_map_view.visible = not overview
	# Escondido, o HexMapView não monta linhas: de longe, seriam a ilha inteira.
	_map_view.process_mode = Node.PROCESS_MODE_DISABLED if overview else Node.PROCESS_MODE_INHERIT
	if not overview:
		_map_view.fixed_scale = _zoom
		_map_view.position = _origin.round()
	for layer: HexTintLayer in [_area_layer, _area_stripes, _action_layer, _dim_layer]:
		layer.position = _overview.position if overview else _map_view.position
		layer.scale = Vector2.ONE * _zoom
		layer.set_raised(not overview)
	_area_layer.visible = _show_areas
	_area_stripes.visible = _show_areas
	_action_layer.visible = _show_actions
	_blocks_layer.queue_redraw()
	_overlay.queue_redraw()
	view_changed.emit()


func _update_hover(at: Vector2) -> void:
	if _draft == null:
		return
	var coord := _coord_at_art(_art_point(at))
	if _has_hover and coord == _hovered:
		return
	_has_hover = true
	_hovered = coord
	_overlay.queue_redraw()
	hovered.emit(coord, _draft.tiles.get(coord))


func _island_bounds() -> Rect2:
	var bounds := Rect2()
	for coord: Vector2i in _draft.tiles:
		var box := Rect2(HexMapView.flat_center(coord) - HexMapView.SURFACE_CENTER, HexMapView.TILE_SIZE)
		bounds = box if not bounds.has_area() else bounds.merge(box)
	return bounds


func _screen_origin(coord: Vector2i) -> Vector2:
	var detail := not is_overview() and _draft.tiles.has(coord)
	var art := _map_view.surface_center(coord) if detail else HexMapView.flat_center(coord)
	return _origin + (art - HexMapView.SURFACE_CENTER) * _zoom


func _outline(node: Node2D, coord: Vector2i, color: Color) -> void:
	var corners := PackedVector2Array()
	var top_left := _screen_origin(coord)
	for corner: Vector2 in HexMapView.HEX_CORNERS:
		corners.append(top_left + corner * _zoom)
	corners.append(corners[0])
	node.draw_polyline(corners, color, OUTLINE_WIDTH)


func draw_overlay(node: Node2D) -> void:
	if _draft == null:
		return
	if _show_actions:
		_draw_actions(node)
	if marked.is_valid():
		for coord: Vector2i in marked.call():
			_outline(node, coord, UiPalette.ACCENT)
	if selected_npc >= 0 and selected_npc < _draft.npcs.size():
		if not bool(_draft.npcs[selected_npc].get("still", false)):
			for coord: Vector2i in _draft.npc_tiles(selected_npc):
				_outline(node, coord, UiPalette.WARNING)
		_outline(node, _draft.npc_coord(selected_npc), UiPalette.ACCENT)
	if scene_marks.is_valid():
		_draw_scene_marks(node, scene_marks.call())
	if selected_trail >= 0 and selected_trail < _draft.trails.size():
		_draw_trail(node, _draft.trails[selected_trail])
	_draw_invisible_walls(node)
	if selected_wall >= 0 and selected_wall < _draft.walls.size():
		_draw_wall_line(node, _draft.walls[selected_wall].points, Vector2.INF)
	if fence_preview.is_valid():
		var drawing: PackedVector2Array = fence_preview.call()
		if not drawing.is_empty():
			_draw_wall_line(node, drawing, _mouse_flat)
	if selected_bridge >= 0 and selected_bridge < _draft.bridges.size():
		var chosen := _draft.bridges[selected_bridge]
		_draw_wall_line(node, PackedVector2Array([chosen.from, chosen.to]), Vector2.INF)
	if bridge_preview.is_valid():
		var started: PackedVector2Array = bridge_preview.call()
		if not started.is_empty():
			_draw_wall_line(node, started, _mouse_flat)
	if selected_prop >= 0:
		var rect := prop_rect(selected_prop)
		if rect.has_area():
			node.draw_rect(rect, UiPalette.ACCENT, false, OUTLINE_WIDTH)
	if _show_blocks:
		_draw_block_edit(node)
	if _has_hover:
		var under: Array[Vector2i] = [_hovered]
		if brush.is_valid():
			under.assign(brush.call(_hovered))
		var faint := Color(UiPalette.TEXT, 0.45)
		var tint: Color = brush_color.call(_hovered) if brush_color.is_valid() else Color.TRANSPARENT
		for coord: Vector2i in under:
			var color := UiPalette.TEXT if coord == _hovered else faint
			_outline(node, coord, color if tint.a == 0.0 else tint)
	if _draft.tiles.has(_draft.start):
		var foot := _screen_origin(_draft.start) + HexMapView.SURFACE_CENTER * _zoom
		var top := foot - Vector2(0.0, FLAG_HEIGHT)
		node.draw_line(foot, top, UiPalette.TEXT, 2.0)
		node.draw_colored_polygon(PackedVector2Array([top, top + Vector2(FLAG_WIDTH, FLAG_HEIGHT * 0.25), top + Vector2(0.0, FLAG_HEIGHT * 0.5)]), UiPalette.WARNING)


## O caminho escolhido: a linha do meio e os pontos guardados, na altura do chão.
func _draw_trail(node: Node2D, trail: MapTrail) -> void:
	var line := PackedVector2Array()
	for point: Vector2 in HexGrounds.smoothed(trail):
		line.append(_screen_point(point))
	if line.size() >= 2:
		node.draw_polyline(line, UiPalette.ACCENT, OUTLINE_WIDTH)
	for point: Vector2 in trail.points:
		node.draw_circle(_screen_point(point), 3.0, UiPalette.ACCENT)


## O ponto do mouse para a prévia da cerca, logo depois de um clique.
func set_fence_mouse(flat: Vector2) -> void:
	_mouse_flat = flat
	_overlay.queue_redraw()


## Uma parede realçada e, desenhando, a reta do último ponto até o mouse.
func _draw_wall_line(node: Node2D, points: PackedVector2Array, mouse: Vector2) -> void:
	var line := PackedVector2Array()
	for point: Vector2 in points:
		line.append(_screen_point(point))
	if mouse.is_finite():
		line.append(_screen_point(mouse))
	if line.size() >= 2:
		node.draw_polyline(line, UiPalette.ACCENT, OUTLINE_WIDTH)
	for point: Vector2 in points:
		node.draw_circle(_screen_point(point), 3.0, UiPalette.ACCENT)


## A parede invisível só aparece no editor, tracejada (free-fences/01).
func _draw_invisible_walls(node: Node2D) -> void:
	for wall: MapWall in _draft.walls:
		if HexWalls.is_visible(wall.type):
			continue
		for index: int in range(1, wall.points.size()):
			node.draw_dashed_line(_screen_point(wall.points[index - 1]), _screen_point(wall.points[index]), UiPalette.DANGER, OUTLINE_WIDTH, WALL_DASH)


func _screen_point(flat: Vector2) -> Vector2:
	if is_overview():
		return _origin + flat * _zoom
	return _origin + (flat - Vector2(0.0, _draft.rise_at(HexMapView.grid_coord(flat)))) * _zoom


## A conta inteira, só ao abrir a ilha: depois, o `refresh_props_at` refaz os hexágonos
## mexidos e o `refresh_walls`, as paredes.
func _refresh_blocks() -> void:
	_block_cells.clear()
	_block_counts.clear()
	if _draft != null:
		var typed := GameData.prop_block_types()
		var blocking: Dictionary[Vector2i, Array] = {}
		for index: int in _draft.props.size():
			var data: Dictionary = _draft.props[index]
			if not _blocks(data, typed):
				continue
			var coord := _draft.prop_coord(index)
			if not blocking.has(coord):
				blocking[coord] = []
			blocking[coord].append(index)
		for coord: Vector2i in blocking:
			_set_block_cell(coord, blocking[coord])
	_refresh_wall_blocks()


static func _blocks(data: Dictionary, typed: Dictionary[int, bool]) -> bool:
	return data.has("block") or typed.has(int(data.get("prop_type_id", 0)))


## Troca os bloqueios das peças de um hexágono pelos das peças `indices` do rascunho.
func _set_block_cell(coord: Vector2i, indices: Array) -> void:
	var old: BlockCell = _block_cells.get(coord)
	if old != null:
		for hex: Vector2i in old.hexes:
			var left: int = _block_counts[hex] - 1
			if left > 0:
				_block_counts[hex] = left
			else:
				_block_counts.erase(hex)
		_block_cells.erase(coord)
	var cell := BlockCell.new()
	for index: int in indices:
		var custom := _draft.prop_is_custom(index)
		for line: PackedVector2Array in _draft.prop_world_lines(index):
			cell.lines.append(line)
			cell.custom.append(custom)
	if cell.lines.is_empty():
		return
	cell.hexes = IslandBlocks.blocked_hexes(cell.lines)
	for hex: Vector2i in cell.hexes:
		_block_counts[hex] = _block_counts.get(hex, 0) + 1
	_block_cells[coord] = cell


func _refresh_wall_blocks() -> void:
	var lines: Array[PackedVector2Array] = []
	if _draft != null:
		for wall: MapWall in _draft.walls:
			lines.append(wall.points)
	_wall_hexes = IslandBlocks.blocked_hexes(lines)
	_blocks_layer.queue_redraw()


## Um X vermelho em cada hexágono que o servidor conta como bloqueado, e as linhas de
## bloqueio das peças, tracejadas: as do tipo numa cor, as ajustadas noutra. Só o que
## cai na tela.
func draw_blocks(node: Node2D) -> void:
	if _draft == null or not _show_blocks:
		return
	# O corte é pelo chão plano, sem a altura: só o que passa dele procura a altura.
	var screen := Rect2(Vector2.ZERO, size)
	var near := screen.grow(HexMapView.STEP_X * _zoom)
	var reach := Vector2(10.0, 7.0) * _zoom
	var mark := Color(UiPalette.DANGER, 0.55)
	var near_flat := _flat_screen_area(near)
	for coord: Vector2i in _block_counts:
		_draw_block_mark(node, coord, near, near_flat, reach, mark)
	for coord: Vector2i in _wall_hexes:
		if not _block_counts.has(coord):
			_draw_block_mark(node, coord, near, near_flat, reach, mark)
	var wide := _flat_screen_area(screen.grow(BLOCK_REACH * _zoom))
	for coord: Vector2i in _block_cells:
		if not wide.has_point(HexMapView.flat_center(coord)):
			continue
		var cell := _block_cells[coord]
		for index: int in cell.lines.size():
			var line := cell.lines[index]
			var color := UiPalette.ACCENT if cell.custom[index] else UiPalette.WARNING
			for at: int in range(1, line.size()):
				node.draw_dashed_line(_screen_point(line[at - 1]), _screen_point(line[at]), color, OUTLINE_WIDTH, WALL_DASH)
			if all_block_points:
				for point: Vector2 in line:
					node.draw_circle(_screen_point(point), 2.5, color)


## Um retângulo da tela no chão plano, crescido para baixo pela altura máxima: um
## hexágono alto aparece acima do ponto dele.
func _flat_screen_area(screen: Rect2) -> Rect2:
	var flat := Rect2((screen.position - _origin) / _zoom, screen.size / _zoom)
	return flat.grow_individual(0.0, 0.0, 0.0, HexMapView.LEVEL_HEIGHTS[-1])


func _draw_block_mark(node: Node2D, coord: Vector2i, near: Rect2, near_flat: Rect2, reach: Vector2, color: Color) -> void:
	if not near_flat.has_point(HexMapView.flat_center(coord)) or not _draft.tiles.has(coord):
		return
	var center := _screen_origin(coord) + HexMapView.SURFACE_CENTER * _zoom
	if not near.has_point(center):
		return
	node.draw_line(center - reach, center + reach, color, OUTLINE_WIDTH)
	node.draw_line(center + Vector2(-reach.x, reach.y), center + Vector2(reach.x, -reach.y), color, OUTLINE_WIDTH)


## Os pontos do bloqueio da peça em edição e a linha em desenho, que seguem o ponteiro.
func _draw_block_edit(node: Node2D) -> void:
	if editing_prop_block and selected_prop >= 0 and selected_prop < _draft.props.size():
		for line: PackedVector2Array in _draft.prop_world_lines(selected_prop):
			for point: Vector2 in line:
				node.draw_circle(_screen_point(point), 4.0, UiPalette.TEXT)
				node.draw_circle(_screen_point(point), 2.5, UiPalette.ACCENT)
		var drawing: PackedVector2Array = block_preview.call() if block_preview.is_valid() else PackedVector2Array()
		if not drawing.is_empty():
			_draw_wall_line(node, drawing, _mouse_flat)


func _draw_actions(node: Node2D) -> void:
	var font := get_theme_font(&"font")
	# As peças com ação (free-objects/03): o nome da ação acima do pé.
	for index: int in _draft.props.size():
		var piece_type := int((_draft.props[index] as Dictionary).get("action_type_id", 0))
		if piece_type <= 0:
			continue
		var piece_label: String = action_names.get(piece_type, "?")
		var piece_at := _screen_point(_draft.prop_foot(index)) + Vector2(0.0, -NAME_SIZE)
		var piece_width := font.get_string_size(piece_label, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x
		var piece_base := piece_at + Vector2(-piece_width / 2.0, 0.0)
		node.draw_string_outline(font, piece_base, piece_label, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, 4, UiPalette.BACKGROUND_DEEP)
		node.draw_string(font, piece_base, piece_label, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, action_colors.get(piece_type, UiPalette.TEXT))
	for index: int in _draft.actions.size():
		var coords := _draft.action_tiles(index)
		if coords.is_empty():
			continue
		if index == selected_action:
			for coord: Vector2i in coords:
				_outline(node, coord, UiPalette.ACCENT)
		var center := Vector2.ZERO
		for coord: Vector2i in coords:
			center += HexMapView.flat_center(coord)
		center /= coords.size()
		var middle := coords[0]
		for coord: Vector2i in coords:
			if HexMapView.flat_center(coord).distance_to(center) < HexMapView.flat_center(middle).distance_to(center):
				middle = coord
		var type_id := int(_draft.actions[index].get("action_type_id", 0))
		var label: String = action_names.get(type_id, "?")
		var at := _screen_origin(middle) + HexMapView.SURFACE_CENTER * _zoom
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x
		var baseline := at + Vector2(-width / 2.0, NAME_SIZE / 2.0)
		node.draw_string_outline(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, 4, UiPalette.BACKGROUND_DEEP)
		node.draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, UiPalette.TEXT)


## A área do gatilho, os atores com hexágono e o destino do passo escolhido, com a
## seta de onde o ator está até lá (story/04).
func _draw_scene_marks(node: Node2D, marks: Dictionary) -> void:
	for coord: Vector2i in marks.get("area", []):
		_outline(node, coord, UiPalette.ACCENT)
	for actor: Dictionary in marks.get("actors", []):
		var coord: Vector2i = actor["coord"]
		var texture := NpcSprite.icon_frame(int(actor["npc_id"]))
		var foot := _screen_origin(coord) + HexMapView.SURFACE_CENTER * _zoom
		if texture != null:
			var drawn := texture.get_size() * _zoom
			var tint := Color(1.0, 1.0, 1.0, 0.45 if bool(actor["hidden"]) else 1.0)
			node.draw_texture_rect(texture, Rect2(foot - Vector2(drawn.x / 2.0, drawn.y), drawn), false, tint)
		_outline(node, coord, UiPalette.WARNING)
	var target: Variant = marks.get("target")
	if target is Vector2i:
		_outline(node, target, UiPalette.HP_HIGH)
		var from: Variant = marks.get("from")
		if from is Vector2i and from != target:
			var start := _screen_origin(from) + HexMapView.SURFACE_CENTER * _zoom
			var end := _screen_origin(target) + HexMapView.SURFACE_CENTER * _zoom
			node.draw_line(start, end, UiPalette.HP_HIGH, OUTLINE_WIDTH)
			var back := (start - end).normalized() * 10.0
			node.draw_line(end, end + back.rotated(0.5), UiPalette.HP_HIGH, OUTLINE_WIDTH)
			node.draw_line(end, end + back.rotated(-0.5), UiPalette.HP_HIGH, OUTLINE_WIDTH)
