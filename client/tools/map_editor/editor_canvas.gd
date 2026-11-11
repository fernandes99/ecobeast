class_name EditorCanvas
extends Control

signal hovered(coord: Vector2i, tile: HexTile)
signal stroke_started(coord: Vector2i, secondary: bool)
signal stroke_moved(coord: Vector2i)
signal stroke_ended

const DETAIL_ZOOMS: Array[float] = [1.0, 2.0, 3.0, 4.0, 6.0]
const OVERVIEW_BELOW := 1.0
const OVERVIEW_STEP := 1.25
const MIN_ZOOM := 0.01
const OPEN_ZOOM := 2.0
const FIT_MARGIN := 24.0
const FLAG_HEIGHT := 22.0
const FLAG_WIDTH := 12.0
const OUTLINE_WIDTH := 2.0
const CHUNK_COLUMNS := 16
## Numa pincelada rápida, um ponto a cada tanto da arte, para não pular hexágonos.
const STROKE_SPACING := 16.0
const AREA_ALPHA := 0.38
const ACTION_ALPHA := 0.62
const NAME_SIZE := 14

var brush: Callable = Callable()
## A cor do contorno sob o ponteiro (Color.TRANSPARENT: a de sempre).
var brush_color: Callable = Callable()
var selected_object := -1
var action_colors: Dictionary[int, Color] = {}
var action_names: Dictionary[int, String] = {}
var selected_action := -1

var _map_view: HexMapView
var _overview: IslandOverview
var _overlay: Overlay
var _area_layer: HexTintLayer
var _area_stripes: HexTintLayer
var _action_layer: HexTintLayer
var _show_areas := true
var _show_actions := true
var _show_blocks := false
var _object_tiles: Dictionary[Vector2i, bool] = {}
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
	_area_layer = HexTintLayer.new(false, IslandDraft.MAX_TILES)
	add_child(_area_layer)
	_area_stripes = HexTintLayer.new(true, IslandDraft.MAX_TILES)
	add_child(_area_stripes)
	_action_layer = HexTintLayer.new(false, IslandDraft.MAX_TILES)
	add_child(_action_layer)
	_overlay = Overlay.new()
	_overlay.canvas = self
	add_child(_overlay)
	resized.connect(_apply_view)


func show_draft(draft: IslandDraft, fit: bool = true) -> void:
	_draft = draft
	_pending.clear()
	_map = draft.to_map() if draft != null else ExplorationMap.new()
	_map_view.set_map(_map)
	_map_view.set_objects(_map.objects)
	_object_tiles = _current_object_tiles()
	_overview.set_map(_map)
	refresh_marks()
	if fit and draft != null:
		fit_whole_island()
	_apply_view()


func update_tiles(coords: Array[Vector2i]) -> void:
	for coord: Vector2i in coords:
		_pending[coord] = true
	_overlay.queue_redraw()


## Os objetos mudaram no rascunho: troca a arte e refaz as decorações dos hexágonos
## que ganharam ou perderam objeto.
func refresh_objects() -> void:
	if _draft == null or _map == null:
		return
	_map.set_objects(_draft.map_objects())
	_map_view.set_objects(_map.objects)
	var now := _current_object_tiles()
	var changed: Array[Vector2i] = []
	for coord: Vector2i in now:
		if not _object_tiles.has(coord):
			changed.append(coord)
	for coord: Vector2i in _object_tiles:
		if not now.has(coord):
			changed.append(coord)
	_object_tiles = now
	update_tiles(changed)
	_overlay.queue_redraw()


func set_blocks(on: bool) -> void:
	_show_blocks = on
	_overlay.queue_redraw()


func _current_object_tiles() -> Dictionary[Vector2i, bool]:
	var result: Dictionary[Vector2i, bool] = {}
	for object: MapObject in _map.objects:
		for coord: Vector2i in object.tiles:
			result[coord] = true
	return result


func refresh_brush() -> void:
	_overlay.queue_redraw()


func refresh_marks(coords: Array[Vector2i] = []) -> void:
	if _draft == null:
		for layer: HexTintLayer in [_area_layer, _area_stripes, _action_layer]:
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
		for layer: HexTintLayer in [_area_layer, _area_stripes, _action_layer]:
			layer.clear_all()
		targets = []
		targets.assign(_draft.tile_areas.keys())
		targets.append_array(action_of.keys())
	for coord: Vector2i in targets:
		var tile: HexTile = _draft.tiles.get(coord)
		var key: int = _draft.tile_areas.get(coord, 0) if tile != null else 0
		_area_layer.clear_hex(coord)
		_area_stripes.clear_hex(coord)
		if area_color.has(key):
			var layer := _area_stripes if area_empty[key] else _area_layer
			layer.set_hex(coord, Color(area_color[key], AREA_ALPHA), tile.height)
		var action: int = action_of.get(coord, -1) if tile != null else -1
		if action >= 0:
			var type_id := int(_draft.actions[action].get("action_type_id", 0))
			_action_layer.set_hex(coord, Color(action_colors.get(type_id, UiPalette.TEXT), ACTION_ALPHA), tile.height)
		else:
			_action_layer.clear_hex(coord)
	_overlay.queue_redraw()


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
	for layer: HexTintLayer in [_area_layer, _area_stripes, _action_layer]:
		layer.position = _overview.position if overview else _map_view.position
		layer.scale = Vector2.ONE * _zoom
		layer.set_raised(not overview)
	_area_layer.visible = _show_areas
	_area_stripes.visible = _show_areas
	_action_layer.visible = _show_actions
	_overlay.queue_redraw()


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
	if selected_object >= 0:
		for coord: Vector2i in _draft.object_tiles(selected_object):
			_outline(node, coord, UiPalette.ACCENT)
	if _show_blocks:
		_draw_blocks(node)
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


## Um X vermelho em cada hexágono bloqueado.
func _draw_blocks(node: Node2D) -> void:
	var reach := Vector2(10.0, 7.0) * _zoom
	for object: MapObject in _map.objects:
		for coord: Vector2i in object.blocked_tiles():
			var center := _screen_origin(coord) + HexMapView.SURFACE_CENTER * _zoom
			node.draw_line(center - reach, center + reach, UiPalette.DANGER, OUTLINE_WIDTH + 1.0)
			node.draw_line(center + Vector2(-reach.x, reach.y), center + Vector2(reach.x, -reach.y), UiPalette.DANGER, OUTLINE_WIDTH + 1.0)


func _draw_actions(node: Node2D) -> void:
	var font := get_theme_font(&"font")
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
