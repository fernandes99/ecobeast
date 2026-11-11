class_name EditorCanvas
extends Control
## O mapa do editor de ilhas (map-editor/02 e 03): a ilha no `HexMapView`, como no
## jogo, ou na visão de cima (`IslandOverview`), com o zoom na roda do mouse e o
## arrastar com o botão do meio (ou espaço e o botão esquerdo). O botão esquerdo
## pinta. Por cima, a bandeira da chegada e o contorno do pincel sob o ponteiro.

## O hexágono sob o ponteiro mudou; `tile` é null fora da ilha.
signal hovered(coord: Vector2i, tile: HexTile)
## Uma pincelada: começa ao apertar o botão esquerdo, passa por cada hexágono sob
## o ponteiro e acaba ao soltar.
signal stroke_started(coord: Vector2i)
signal stroke_moved(coord: Vector2i)
signal stroke_ended

## Pixels da tela por pixel da arte, no `HexMapView`: inteiros, para a pixel art.
const DETAIL_ZOOMS: Array[float] = [1.0, 2.0, 3.0, 4.0, 6.0]
## Abaixo deste zoom, só a visão de cima: o `HexMapView` montaria linhas demais.
const OVERVIEW_BELOW := 1.0
## Quanto cada passo da roda muda o zoom na visão de cima.
const OVERVIEW_STEP := 1.25
const MIN_ZOOM := 0.01
## O zoom de uma ilha aberta que cabe na tela de perto.
const OPEN_ZOOM := 2.0
## A folga em volta da ilha inteira, em pixels da tela.
const FIT_MARGIN := 24.0
const FLAG_HEIGHT := 22.0
const FLAG_WIDTH := 12.0
const OUTLINE_WIDTH := 2.0
## Pedaços de linha do HexMapView: pintar refaz só os pedaços tocados, e não a
## linha inteira de uma ilha larga.
const CHUNK_COLUMNS := 16
## Numa pincelada rápida, um ponto a cada tanto da arte, para não pular hexágonos.
const STROKE_SPACING := 16.0

## Os hexágonos que o pincel pega em volta de um centro; sem ele, só o centro.
var brush: Callable = Callable()

var _map_view: HexMapView
var _overview: IslandOverview
var _overlay: Overlay
var _draft: IslandDraft = null
var _map: ExplorationMap = null
## Pixels da tela por pixel da arte.
var _zoom := OPEN_ZOOM
## Onde o (0, 0) da arte fica, em pontos deste Control.
var _origin := Vector2.ZERO
## A visão de cima pedida com Tab, mesmo de perto.
var _force_overview := false
var _dragging := false
var _painting := false
## O último ponto da pincelada, em pixels da arte, e o último hexágono pintado.
var _last_art_point := Vector2.ZERO
var _last_coord := Vector2i.ZERO
var _hovered := Vector2i.ZERO
var _has_hover := false
## Os hexágonos que mudaram desde o último quadro: o mapa é refeito uma vez por quadro.
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
	_overlay = Overlay.new()
	_overlay.canvas = self
	add_child(_overlay)
	resized.connect(_apply_view)


## Mostra uma ilha. Com `fit`, ela cabe inteira na tela; senão, o zoom e o lugar ficam.
func show_draft(draft: IslandDraft, fit: bool = true) -> void:
	_draft = draft
	_pending.clear()
	_map = draft.to_map() if draft != null else ExplorationMap.new()
	_map_view.set_map(_map)
	_overview.set_map(_map)
	if fit and draft != null:
		fit_whole_island()
	_apply_view()


## Estes hexágonos mudaram no rascunho: entram no desenho no próximo quadro.
func update_tiles(coords: Array[Vector2i]) -> void:
	for coord: Vector2i in coords:
		_pending[coord] = true
	_overlay.queue_redraw()


## O contorno do pincel mudou (outra ferramenta ou outro tamanho).
func refresh_brush() -> void:
	_overlay.queue_redraw()


func fit_whole_island() -> void:
	if _draft == null or _draft.tiles.is_empty() or size.x <= 0.0:
		return
	var bounds := _island_bounds()
	var area := size - Vector2.ONE * FIT_MARGIN * 2.0
	_zoom = maxf(MIN_ZOOM, minf(area.x / bounds.size.x, area.y / bounds.size.y))
	if _zoom >= OVERVIEW_BELOW:
		_zoom = _detail_zoom_at_most(_zoom)
	_origin = size / 2.0 - bounds.get_center() * _zoom


## Da visão de cima, aproxima até o zoom 1 em volta do centro da tela.
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
		elif button.button_index == MOUSE_BUTTON_LEFT:
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
		stroke_started.emit(_last_coord)
	elif not button.pressed and _painting:
		_painting = false
		stroke_ended.emit()


## Do último ponto até o atual, sem pular hexágonos numa pincelada rápida.
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


## Um passo da roda: de perto, os zooms inteiros; de longe, ×1,25.
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


## Muda o zoom sem tirar do lugar o ponto da arte que está em `at`.
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


## O retângulo da ilha plana, em pixels da arte.
func _island_bounds() -> Rect2:
	var bounds := Rect2()
	for coord: Vector2i in _draft.tiles:
		var box := Rect2(HexMapView.flat_center(coord) - HexMapView.SURFACE_CENTER, HexMapView.TILE_SIZE)
		bounds = box if not bounds.has_area() else bounds.merge(box)
	return bounds


## O canto do hexágono em pontos deste Control, na altura em que ele aparece. Um
## hexágono que não existe fica na altura do chão.
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
	if _has_hover:
		var under: Array[Vector2i] = [_hovered]
		if brush.is_valid():
			under.assign(brush.call(_hovered))
		var faint := Color(UiPalette.TEXT, 0.45)
		for coord: Vector2i in under:
			_outline(node, coord, UiPalette.TEXT if coord == _hovered else faint)
	if _draft.tiles.has(_draft.start):
		var foot := _screen_origin(_draft.start) + HexMapView.SURFACE_CENTER * _zoom
		var top := foot - Vector2(0.0, FLAG_HEIGHT)
		node.draw_line(foot, top, UiPalette.TEXT, 2.0)
		node.draw_colored_polygon(PackedVector2Array([top, top + Vector2(FLAG_WIDTH, FLAG_HEIGHT * 0.25), top + Vector2(0.0, FLAG_HEIGHT * 0.5)]), UiPalette.WARNING)
