class_name WardrobeFrames
extends Control
## As miniaturas da folha, a 2×, uma linha por ângulo; tocar numa escolhe o quadro.

signal cell_chosen(cell: Vector2i)

const ROW_NAMES: Array[String] = ["Frente", "Diagonal de baixo", "Lado", "Diagonal de cima", "Costas"]
const THUMB_SCALE := 2
const GAP := 4
const LABEL_WIDTH := 140
const FONT_SIZE := 13

var sheet: WardrobeSheet:
	set = set_sheet
var cell := Vector2i.ZERO:
	set(value):
		cell = value
		queue_redraw()

var _texture: ImageTexture = null


func _init() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	mouse_filter = MOUSE_FILTER_STOP


func set_sheet(value: WardrobeSheet) -> void:
	if sheet != null and sheet.changed.is_connected(_on_sheet_changed):
		sheet.changed.disconnect(_on_sheet_changed)
	sheet = value
	_texture = ImageTexture.create_from_image(sheet.image) if sheet != null else null
	if sheet != null:
		sheet.changed.connect(_on_sheet_changed)
	update_minimum_size()
	queue_redraw()


func _get_minimum_size() -> Vector2:
	var columns := sheet.columns() if sheet != null else 6
	return Vector2(LABEL_WIDTH + columns * _step(), WardrobeSheet.ROWS * _step())


func _step() -> int:
	return WardrobeSheet.CELL.x * THUMB_SCALE + GAP


func _on_sheet_changed() -> void:
	_texture.update(sheet.image)
	queue_redraw()


func _draw() -> void:
	if sheet == null:
		return
	var font := get_theme_default_font()
	var side := Vector2(WardrobeSheet.CELL * THUMB_SCALE)
	for row: int in WardrobeSheet.ROWS:
		var top := row * _step()
		var color := UiPalette.TEXT if row == cell.y else UiPalette.TEXT_SECONDARY
		draw_string(font, Vector2(0, top + side.y / 2.0 + FONT_SIZE / 2.0), ROW_NAMES[row], HORIZONTAL_ALIGNMENT_LEFT, LABEL_WIDTH - GAP, FONT_SIZE, color)
		for column: int in sheet.columns():
			var area := Rect2(Vector2(LABEL_WIDTH + column * _step(), top), side)
			draw_rect(area, UiPalette.SURFACE_RAISED)
			draw_texture_rect_region(_texture, area, Rect2(sheet.cell_rect(column, row)))
			if Vector2i(column, row) == cell:
				draw_rect(area.grow(1), UiPalette.ACCENT, false, 2.0)


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if sheet == null or button == null or not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	var column := floori((button.position.x - LABEL_WIDTH) / _step())
	var row := floori(button.position.y / _step())
	if column >= 0 and column < sheet.columns() and row >= 0 and row < WardrobeSheet.ROWS:
		cell_chosen.emit(Vector2i(column, row))
		accept_event()
