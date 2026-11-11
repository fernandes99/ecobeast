class_name EditorCanvas
extends Control
## O mapa do editor de ilhas (map-editor/02): a ilha no `HexMapView`, como no jogo,
## ou na visão de cima (`IslandOverview`), com o zoom na roda do mouse e o arrastar
## com o botão do meio (ou espaço e o botão esquerdo). Por cima, a bandeira da
## chegada e o contorno do hexágono sob o ponteiro.

## O hexágono sob o ponteiro mudou; `tile` é null fora da ilha.
signal hovered(coord: Vector2i, tile: HexTile)

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

var _map_view: HexMapView
var _overview: IslandOverview
var _overlay: Overlay
var _draft: IslandDraft = null
## Pixels da tela por pixel da arte.
var _zoom := OPEN_ZOOM
## Onde o (0, 0) da arte fica, em pontos deste Control.
var _origin := Vector2.ZERO
## A visão de cima pedida com Tab, mesmo de perto.
var _force_overview := false
var _dragging := false
var _hovered := Vector2i.ZERO
var _has_hover := false


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
	var map := draft.to_map() if draft != null else ExplorationMap.new()
	_map_view.set_map(map)
	_overview.set_map(map)
	if fit and draft != null:
		fit_whole_island()
	_apply_view()


## O desenho mudou fora daqui (o nome não conta): remonta as duas visões.
func refresh() -> void:
	show_draft(_draft, false)


func fit_whole_island() -> void:
	if _draft == null or _draft.tiles.is_empty() or size.x <= 0.0:
		return
	var bounds := _island_bounds()
	var area := size - Vector2.ONE * FIT_MARGIN * 2.0
	_zoom = maxf(MIN_ZOOM, minf(area.x / bounds.size.x, area.y / bounds.size.y))
	if _zoom >= OVERVIEW_BELOW:
		_zoom = _detail_zoom_at_most(_zoom)
	_origin = size / 2.0 - bounds.get_center() * _zoom


## A visão de cima e o `HexMapView`, à mão (Tab).
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


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		if button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_step_zoom(button.position, 1)
			accept_event()
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_step_zoom(button.position, -1)
			accept_event()
		elif _is_drag_button(button):
			_dragging = button.pressed
			accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion != null:
		if _dragging:
			_origin += motion.relative
			_apply_view()
		_update_hover(motion.position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and _has_hover:
		_has_hover = false
		_overlay.queue_redraw()
		hovered.emit(_hovered, null)


func _is_drag_button(button: InputEventMouseButton) -> bool:
	if button.button_index == MOUSE_BUTTON_MIDDLE:
		return true
	return button.button_index == MOUSE_BUTTON_LEFT and (Input.is_key_pressed(KEY_SPACE) or not button.pressed)


## Um passo da roda: de perto, os zooms inteiros; de longe, ×1,25.
func _step_zoom(at: Vector2, direction: int) -> void:
	var target := _zoom
	if _zoom >= OVERVIEW_BELOW:
		var index := DETAIL_ZOOMS.find(_detail_zoom_at_most(_zoom)) + direction
		target = DETAIL_ZOOMS[index] if index >= 0 and index < DETAIL_ZOOMS.size() else (_zoom / OVERVIEW_STEP if index < 0 else _zoom)
	else:
		target = _zoom * OVERVIEW_STEP if direction > 0 else maxf(MIN_ZOOM, _zoom / OVERVIEW_STEP)
		if target >= OVERVIEW_BELOW:
			target = OVERVIEW_BELOW
	_zoom_around(at, target)
	_apply_view()
	_update_hover(at)


## Muda o zoom sem tirar do lugar o ponto da arte que está em `at`.
func _zoom_around(at: Vector2, target: float) -> void:
	var art_point := (at - _origin) / _zoom
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
	var art_point := (at - _origin) / _zoom
	var coord := HexMapView.grid_coord(art_point) if is_overview() else _map_view.coord_at(art_point)
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


## O canto do hexágono em pontos deste Control, na altura em que ele aparece.
func _screen_origin(coord: Vector2i) -> Vector2:
	var art := HexMapView.flat_center(coord) if is_overview() else _map_view.surface_center(coord)
	return _origin + (art - HexMapView.SURFACE_CENTER) * _zoom


func draw_overlay(node: Node2D) -> void:
	if _draft == null:
		return
	if _has_hover and _draft.tiles.has(_hovered):
		var corners := PackedVector2Array()
		var top_left := _screen_origin(_hovered)
		for corner: Vector2 in HexMapView.HEX_CORNERS:
			corners.append(top_left + corner * _zoom)
		corners.append(corners[0])
		node.draw_polyline(corners, UiPalette.TEXT, OUTLINE_WIDTH)
	if _draft.tiles.has(_draft.start):
		var foot := _screen_origin(_draft.start) + HexMapView.SURFACE_CENTER * _zoom
		var top := foot - Vector2(0.0, FLAG_HEIGHT)
		node.draw_line(foot, top, UiPalette.TEXT, 2.0)
		node.draw_colored_polygon(PackedVector2Array([top, top + Vector2(FLAG_WIDTH, FLAG_HEIGHT * 0.25), top + Vector2(0.0, FLAG_HEIGHT * 0.5)]), UiPalette.WARNING)
