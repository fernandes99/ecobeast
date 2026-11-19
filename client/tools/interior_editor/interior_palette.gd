class_name InteriorPalette
extends VBoxContainer

## A folha escolhida como paleta (interiors/03): um clique escolhe um tile, arrastar
## escolhe um retângulo de até 8×8. Qualquer aba serve a qualquer ferramenta.

signal picked(sheet: String, atlas: Vector2i, size: Vector2i)

const ZOOM := 2.0
const MAX_PICK := 8
const TABS: Array[Dictionary] = [
	{"sheet": "walls_floor", "name": "Chão e paredes"},
	{"sheet": "interior", "name": "Móveis"},
	{"sheet": "doors_windows", "name": "Portas e janelas"},
]
## Na folha das portas, um quadro da animação ocupa as 2 primeiras linhas.
const DOOR_FRAME_ROWS := 2

var sheet := "walls_floor"
var atlas := Vector2i(4, 9)
var size_cells := Vector2i.ONE

var _tab_buttons: Array[Button] = []
var _sheet_view: Control
var _dragging := false
var _drag_start := Vector2i.ZERO


func _init() -> void:
	add_theme_constant_override(&"separation", 6)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override(&"separation", 4)
	add_child(tabs)
	for tab: Dictionary in TABS:
		var button := Button.new()
		button.text = tab["name"]
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_show_sheet.bind(str(tab["sheet"])))
		tabs.add_child(button)
		_tab_buttons.append(button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	_sheet_view = Control.new()
	_sheet_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sheet_view.draw.connect(_draw_sheet)
	_sheet_view.gui_input.connect(_on_sheet_input)
	scroll.add_child(_sheet_view)
	_show_sheet(sheet)


func choice() -> Dictionary:
	return {"sheet": sheet, "atlas": atlas, "size": size_cells}


func _visible_cells() -> Vector2i:
	var cells := InteriorTiles.sheet_cells(sheet)
	if sheet == "doors_windows":
		cells.y = mini(cells.y, DOOR_FRAME_ROWS)
	return cells


func _show_sheet(slug: String) -> void:
	sheet = slug
	for index: int in TABS.size():
		_tab_buttons[index].set_pressed_no_signal(TABS[index]["sheet"] == slug)
	_sheet_view.custom_minimum_size = Vector2(_visible_cells() * InteriorTiles.CELL) * ZOOM
	_sheet_view.queue_redraw()


func _draw_sheet() -> void:
	var texture := InteriorTiles.sheet_texture(sheet)
	if texture == null:
		return
	var cells := _visible_cells()
	var cell_px := InteriorTiles.CELL * ZOOM
	_sheet_view.draw_rect(Rect2(Vector2.ZERO, Vector2(cells) * cell_px), UiPalette.BACKGROUND_DEEP)
	_sheet_view.draw_texture_rect_region(texture, Rect2(Vector2.ZERO, Vector2(cells) * cell_px), Rect2(Vector2.ZERO, Vector2(cells * InteriorTiles.CELL)))
	var line := Color(UiPalette.TEXT, 0.15)
	for x: int in cells.x + 1:
		_sheet_view.draw_line(Vector2(x * cell_px, 0.0), Vector2(x * cell_px, cells.y * cell_px), line)
	for y: int in cells.y + 1:
		_sheet_view.draw_line(Vector2(0.0, y * cell_px), Vector2(cells.x * cell_px, y * cell_px), line)
	if InteriorTiles.has_tile(sheet, atlas):
		_sheet_view.draw_rect(Rect2(Vector2(atlas) * cell_px, Vector2(size_cells) * cell_px), UiPalette.WARNING, false, 2.0)


func _cell_at(point: Vector2) -> Vector2i:
	var cells := _visible_cells()
	var cell := Vector2i((point / (InteriorTiles.CELL * ZOOM)).floor())
	return cell.clamp(Vector2i.ZERO, cells - Vector2i.ONE)


func _on_sheet_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_dragging = true
			_drag_start = _cell_at(button.position)
			_select(_drag_start, _drag_start)
		elif _dragging:
			_dragging = false
			picked.emit(sheet, atlas, size_cells)
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _dragging:
		_select(_drag_start, _cell_at(motion.position))


func _select(from: Vector2i, to: Vector2i) -> void:
	var low := Vector2i(mini(from.x, to.x), mini(from.y, to.y))
	var high := Vector2i(maxi(from.x, to.x), maxi(from.y, to.y))
	atlas = low
	size_cells = (high - low + Vector2i.ONE).clamp(Vector2i.ONE, Vector2i(MAX_PICK, MAX_PICK))
	_sheet_view.queue_redraw()
