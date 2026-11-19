class_name InteriorCanvas
extends Control

## O meio do modo Interiores (interiors/03): a sala pelo `InteriorView`, com zoom inteiro
## de 1 a 6 em volta do mouse, arrasto pelo botão do meio ou espaço + esquerdo, e por cima
## a grade, a borda, os NPCs, a porta, os bloqueios e a prévia da ferramenta.

signal stroke_started(cell: Vector2i, secondary: bool)
signal stroke_moved(cell: Vector2i)
signal stroke_ended
signal hovered(cell: Vector2i)

const MIN_ZOOM := 1
const MAX_ZOOM := 6
const OUT := Vector2i(-1000, -1000)

var show_blocks := false
var selected_rect := Rect2i()

var _draft: InteriorDraft = null
var _world := Node2D.new()
var _view := InteriorView.new()
var _marks := Node2D.new()
var _zoom := 3
var _panning := false
var _stroke := false
var _hover := OUT
var _preview_sheet := ""
var _preview_atlas := Vector2i.ZERO
var _preview_size := Vector2i.ZERO
var _centered := false


func _init() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_world.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_world)
	_world.add_child(_view)
	_world.add_child(_marks)
	_marks.draw.connect(_draw_marks)
	resized.connect(func() -> void:
		if not _centered:
			_center())


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.BACKGROUND_DEEP)


func set_draft(draft: InteriorDraft) -> void:
	_draft = draft
	_centered = false
	refresh_all()
	_center()


func refresh_all() -> void:
	if _draft == null:
		return
	_view.show_interior(_draft.interior)
	_marks.queue_redraw()


func refresh_cells(cells: Array[Vector2i]) -> void:
	_view.refresh_tiles(cells)
	_marks.queue_redraw()


func refresh_objects() -> void:
	_view.refresh_objects()
	_marks.queue_redraw()


func refresh_marks() -> void:
	_marks.queue_redraw()


## A prévia do que a ferramenta põe no quadrado do mouse; tamanho zero só marca o quadrado.
func set_preview(sheet: String, atlas: Vector2i, size_cells: Vector2i) -> void:
	_preview_sheet = sheet
	_preview_atlas = atlas
	_preview_size = size_cells
	_marks.queue_redraw()


func _center() -> void:
	if _draft == null or size.x <= 0.0 or size.y <= 0.0:
		return
	_centered = true
	var room := Vector2(_draft.interior.width, _draft.interior.height) * InteriorTiles.CELL
	_zoom = clampi(floori(minf(size.x / room.x, size.y / room.y)), MIN_ZOOM, MAX_ZOOM)
	_world.scale = Vector2.ONE * _zoom
	_world.position = ((size - room * _zoom) / 2.0).round()


func _cell_at(point: Vector2) -> Vector2i:
	return InteriorTiles.cell_of((point - _world.position) / _zoom)


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		_on_button(button)
		return
	var motion := event as InputEventMouseMotion
	if motion == null:
		return
	if _panning:
		_world.position += motion.relative
		return
	var cell := _cell_at(motion.position)
	if cell != _hover:
		_hover = cell
		hovered.emit(cell)
		_marks.queue_redraw()
		if _stroke:
			stroke_moved.emit(cell)


func _on_button(button: InputEventMouseButton) -> void:
	if button.pressed and (button.button_index == MOUSE_BUTTON_WHEEL_UP or button.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var level := clampi(_zoom + (1 if button.button_index == MOUSE_BUTTON_WHEEL_UP else -1), MIN_ZOOM, MAX_ZOOM)
		var art := (button.position - _world.position) / _zoom
		_zoom = level
		_world.scale = Vector2.ONE * _zoom
		_world.position = (button.position - art * _zoom).round()
		return
	var pan := button.button_index == MOUSE_BUTTON_MIDDLE or (button.button_index == MOUSE_BUTTON_LEFT and Input.is_key_pressed(KEY_SPACE))
	if pan:
		_panning = button.pressed
		return
	if button.button_index != MOUSE_BUTTON_LEFT and button.button_index != MOUSE_BUTTON_RIGHT:
		return
	if button.pressed and not _stroke:
		_stroke = true
		stroke_started.emit(_cell_at(button.position), button.button_index == MOUSE_BUTTON_RIGHT)
	elif not button.pressed and _stroke:
		_stroke = false
		stroke_ended.emit()


func _draw_marks() -> void:
	if _draft == null:
		return
	var room := _draft.interior
	var cell := float(InteriorTiles.CELL)
	var thin := 1.0 / _zoom
	var grid := Color(UiPalette.TEXT, 0.12)
	for x: int in room.width + 1:
		_marks.draw_line(Vector2(x * cell, 0.0), Vector2(x * cell, room.height * cell), grid, thin)
	for y: int in room.height + 1:
		_marks.draw_line(Vector2(0.0, y * cell), Vector2(room.width * cell, y * cell), grid, thin)
	_marks.draw_rect(Rect2(Vector2.ZERO, Vector2(room.width, room.height) * cell), UiPalette.ACCENT, false, thin * 2.0)
	if show_blocks:
		_draw_blocks()
	for npc: InteriorNpc in room.npcs:
		var icon := NpcSprite.icon_frame(npc.npc_id)
		var spot := Rect2(Vector2(npc.cell) * cell, Vector2(cell, cell))
		if icon != null:
			_marks.draw_texture_rect(icon, spot, false)
		else:
			_marks.draw_circle(spot.get_center(), cell * 0.35, UiPalette.ACCENT)
	_marks.draw_rect(Rect2(Vector2(room.door) * cell, Vector2(cell, cell)).grow(-thin), UiPalette.WARNING, false, thin * 2.0)
	if selected_rect.has_area():
		_marks.draw_rect(Rect2(Vector2(selected_rect.position) * cell, Vector2(selected_rect.size) * cell), UiPalette.ACCENT, false, thin * 2.0)
	if room.has_cell(_hover):
		if _preview_size != Vector2i.ZERO and not _preview_sheet.is_empty():
			var texture := InteriorTiles.sheet_texture(_preview_sheet)
			if texture != null:
				_marks.draw_texture_rect_region(texture, Rect2(Vector2(_hover) * cell, Vector2(_preview_size) * cell), Rect2(Vector2(_preview_atlas) * cell, Vector2(_preview_size) * cell), Color(1, 1, 1, 0.6))
		_marks.draw_rect(Rect2(Vector2(_hover) * cell, Vector2(cell, cell)), Color(UiPalette.TEXT, 0.8), false, thin * 2.0)


func _draw_blocks() -> void:
	var room := _draft.interior
	var cell := float(InteriorTiles.CELL)
	var no_floor := Color(UiPalette.TEXT_MUTED, 0.45)
	var hand := Color(UiPalette.DANGER, 0.35)
	var blocked := InteriorTiles.blocked(room)
	var hand_cells: Dictionary[Vector2i, bool] = {}
	for at: Vector2i in room.blocks:
		hand_cells[at] = true
	for at: Vector2i in blocked:
		var spot := Rect2(Vector2(at) * cell, Vector2(cell, cell))
		if hand_cells.has(at):
			_marks.draw_rect(spot, hand)
			_marks.draw_line(spot.position + Vector2(3, 3), spot.end - Vector2(3, 3), UiPalette.DANGER, 1.0 / _zoom)
			_marks.draw_line(Vector2(spot.end.x - 3, spot.position.y + 3), Vector2(spot.position.x + 3, spot.end.y - 3), UiPalette.DANGER, 1.0 / _zoom)
		else:
			_marks.draw_rect(spot, no_floor)
