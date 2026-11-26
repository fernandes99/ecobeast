class_name WardrobeCanvas
extends Control
## O quadro escolhido da folha, ampliado em pixels inteiros, com a grade, as guias
## apagadas (o corpo e o quadro anterior), o pincel e a seleção (tamer-looks/05).
## A roda do mouse muda o zoom, o Ctrl+roda o tamanho do pincel e o botão do meio arrasta.

signal picked(color: Color)
signal view_changed

enum { PENCIL, ERASER, PICKER, SELECT }

const MIN_SCALE := 8
const MAX_SCALE := 20
const MIN_ZOOM := 4
const MAX_ZOOM := 48
const MAX_BRUSH := 8
const BODY_ALPHA := 0.35
const PREVIOUS_ALPHA := 0.25
# As cores do fundo xadrez, da grade e da seleção são da arte, não da interface; o
# xadrez é azulado para os cinzas-chave não sumirem nele.
const CHECKER_LIGHT := Color(0.66, 0.76, 0.88)
const CHECKER_DARK := Color(0.6, 0.7, 0.82)
const GRID := Color(0.0, 0.0, 0.0, 0.12)
const GRID_STRONG := Color(0.0, 0.0, 0.0, 0.3)
const HOVER := Color(1.0, 1.0, 1.0, 0.45)
const SELECTION_DARK := Color(0.0, 0.0, 0.0, 0.9)
const SELECTION_LIGHT := Color(1.0, 1.0, 1.0, 0.95)
const SELECTION_DASH := 4.0

## Os pixels copiados (relativos ao canto da seleção) valem entre folhas e peças.
static var _clipboard: Dictionary = {}
static var _clipboard_rect := Rect2i()

var sheet: WardrobeSheet:
	set = set_sheet
var guide: WardrobeSheet:
	set = set_guide
var cell := Vector2i.ZERO:
	set(value):
		if value != cell:
			commit()
		cell = value
		queue_redraw()
var tool: int = PENCIL:
	set(value):
		if value != SELECT:
			deselect()
		tool = value
		queue_redraw()
var color: Color = WardrobeSheet.OUTLINE
var brush := 1:
	set(value):
		brush = clampi(value, 1, MAX_BRUSH)
		view_changed.emit()
		queue_redraw()
## 0 é o maior zoom inteiro que cabe; outro valor é o escolhido na roda.
var zoom := 0
var selection := Rect2i()
var show_body := true:
	set(value):
		show_body = value
		queue_redraw()
var show_previous := true:
	set(value):
		show_previous = value
		queue_redraw()

var _texture: ImageTexture = null
var _guide_texture: ImageTexture = null
var _hover := Vector2i(-1, -1)
var _painting := Color.TRANSPARENT
var _stroking := false
var _last := Vector2i(-1, -1)
var _pan := Vector2.ZERO
var _panning := false
## Os pixels soltos da seleção (colados ou levantados para mover), relativos ao canto dela.
var _floating: Dictionary = {}
var _is_floating := false
var _selecting := false
var _select_from := Vector2i.ZERO
var _moving := false
var _move_from := Vector2i.ZERO
var _move_start := Vector2i.ZERO
var _dragged := false


func _init() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	mouse_filter = MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(func() -> void:
		view_changed.emit()
		queue_redraw())
	mouse_exited.connect(func() -> void:
		_hover = Vector2i(-1, -1)
		queue_redraw())


func set_sheet(value: WardrobeSheet) -> void:
	commit()
	if sheet != null and sheet.changed.is_connected(_on_sheet_changed):
		sheet.changed.disconnect(_on_sheet_changed)
	_finish_stroke()
	sheet = value
	_texture = ImageTexture.create_from_image(sheet.image) if sheet != null else null
	if sheet != null:
		sheet.changed.connect(_on_sheet_changed)
	queue_redraw()


func set_guide(value: WardrobeSheet) -> void:
	guide = value
	_guide_texture = ImageTexture.create_from_image(guide.image) if guide != null else null
	queue_redraw()


func pixel_scale() -> int:
	if zoom > 0:
		return zoom
	var fit := floori(minf(size.x, size.y) / WardrobeSheet.CELL.x)
	return clampi(fit, MIN_SCALE, MAX_SCALE)


func fit_view() -> void:
	zoom = 0
	_pan = Vector2.ZERO
	view_changed.emit()
	queue_redraw()


# --- seleção -------------------------------------------------------------------

func has_selection() -> bool:
	return selection.has_area()


func is_floating() -> bool:
	return _is_floating


func has_clipboard() -> bool:
	return _clipboard_rect.has_area()


## Assenta os pixels soltos no quadro, numa pincelada só com o que foi levantado.
func commit() -> void:
	if not _is_floating or sheet == null:
		return
	for rel: Vector2i in _floating:
		sheet.paint(cell.x, cell.y, selection.position + rel, _floating[rel])
	sheet.end_stroke()
	_floating = {}
	_is_floating = false
	queue_redraw()


func deselect() -> void:
	commit()
	selection = Rect2i()
	queue_redraw()


func select_all() -> void:
	commit()
	selection = Rect2i(Vector2i.ZERO, WardrobeSheet.CELL)
	queue_redraw()


func copy() -> bool:
	if not has_selection() or sheet == null:
		return false
	if _is_floating:
		_clipboard = _floating.duplicate()
	else:
		_clipboard = {}
		for y: int in selection.size.y:
			for x: int in selection.size.x:
				var rel := Vector2i(x, y)
				var pixel := sheet.pixel(cell.x, cell.y, selection.position + rel)
				if pixel.a > 0.0:
					_clipboard[rel] = pixel
	_clipboard_rect = selection
	return true


func cut() -> bool:
	if not copy():
		return false
	delete_selection()
	return true


## Apaga o que está dentro da seleção (ou descarta os pixels soltos).
func delete_selection() -> void:
	if not has_selection() or sheet == null:
		return
	if _is_floating:
		_floating = {}
		commit()
		return
	sheet.begin_stroke()
	for y: int in selection.size.y:
		for x: int in selection.size.x:
			sheet.paint(cell.x, cell.y, selection.position + Vector2i(x, y), Color.TRANSPARENT)
	sheet.end_stroke()


## Cola no mesmo lugar de onde copiou, solto para arrastar até assentar.
func paste() -> bool:
	if not has_clipboard() or sheet == null:
		return false
	commit()
	_finish_stroke()
	sheet.begin_stroke()
	_floating = _clipboard.duplicate()
	_is_floating = true
	selection = _clipboard_rect
	queue_redraw()
	return true


func nudge(delta: Vector2i) -> void:
	if not has_selection():
		return
	if not _is_floating:
		_lift()
	selection.position += delta
	queue_redraw()


func _lift() -> void:
	_finish_stroke()
	sheet.begin_stroke()
	_floating = {}
	for y: int in selection.size.y:
		for x: int in selection.size.x:
			var rel := Vector2i(x, y)
			var pixel := sheet.pixel(cell.x, cell.y, selection.position + rel)
			if pixel.a > 0.0:
				_floating[rel] = pixel
				sheet.paint(cell.x, cell.y, selection.position + rel, Color.TRANSPARENT)
	_is_floating = true


# --- desenho -------------------------------------------------------------------

func _centered(scale_now: int) -> Vector2:
	var side := Vector2(WardrobeSheet.CELL * scale_now)
	return ((size - side) / 2.0).floor()


func _origin() -> Vector2:
	return _centered(pixel_scale()) + _pan


func _on_sheet_changed() -> void:
	_texture.update(sheet.image)
	queue_redraw()


func _draw() -> void:
	if sheet == null:
		return
	var zoom_now := pixel_scale()
	var origin := _origin()
	var cells := WardrobeSheet.CELL
	for y: int in cells.y:
		for x: int in cells.x:
			var light := ((x >> 2) + (y >> 2)) % 2 == 0
			draw_rect(Rect2(origin + Vector2(x, y) * zoom_now, Vector2(zoom_now, zoom_now)), CHECKER_LIGHT if light else CHECKER_DARK)
	var area := Rect2(origin, Vector2(cells * zoom_now))
	if show_body and _guide_texture != null:
		draw_texture_rect_region(_guide_texture, area, Rect2(guide.cell_rect(cell.x, mini(cell.y, WardrobeSheet.ROWS - 1))), Color(1, 1, 1, BODY_ALPHA))
	if show_previous and sheet.columns() > 1:
		var previous := posmod(cell.x - 1, sheet.columns())
		draw_texture_rect_region(_texture, area, Rect2(sheet.cell_rect(previous, cell.y)), Color(1, 1, 1, PREVIOUS_ALPHA))
	draw_texture_rect_region(_texture, area, Rect2(sheet.cell_rect(cell.x, cell.y)))
	for rel: Vector2i in _floating:
		var at: Vector2i = selection.position + rel
		if Rect2i(Vector2i.ZERO, cells).has_point(at):
			draw_rect(Rect2(origin + Vector2(at) * zoom_now, Vector2(zoom_now, zoom_now)), _floating[rel])
	for line: int in range(1, cells.x):
		var strong := line % 8 == 0
		var x := origin.x + line * zoom_now
		draw_line(Vector2(x, origin.y), Vector2(x, area.end.y), GRID_STRONG if strong else GRID)
		var y := origin.y + line * zoom_now
		draw_line(Vector2(origin.x, y), Vector2(area.end.x, y), GRID_STRONG if strong else GRID)
	draw_rect(area, GRID_STRONG, false)
	if has_selection():
		_draw_selection(Rect2(origin + Vector2(selection.position) * zoom_now, Vector2(selection.size) * zoom_now))
	if _inside(_hover) and not _moving and not _selecting:
		var footprint := _brush_rect(_hover) if tool == PENCIL or tool == ERASER else Rect2i(_hover, Vector2i.ONE)
		draw_rect(Rect2(origin + Vector2(footprint.position) * zoom_now, Vector2(footprint.size) * zoom_now), HOVER, false, 2.0)


func _draw_selection(box: Rect2) -> void:
	draw_rect(box, SELECTION_DARK, false, 1.0)
	var corners: Array[Vector2] = [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]
	for index: int in corners.size():
		draw_dashed_line(corners[index], corners[(index + 1) % corners.size()], SELECTION_LIGHT, 1.0, SELECTION_DASH)


# --- mouse ---------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if sheet == null:
		return
	var button := event as InputEventMouseButton
	if button != null:
		_on_button(button)
		return
	var motion := event as InputEventMouseMotion
	if motion != null:
		_on_motion(motion)


func _on_button(button: InputEventMouseButton) -> void:
	var at := _pixel_at(button.position)
	match button.button_index:
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
			if button.pressed:
				var step := 1 if button.button_index == MOUSE_BUTTON_WHEEL_UP else -1
				if button.ctrl_pressed or button.meta_pressed:
					brush += step
				else:
					_zoom_at(button.position, step)
			accept_event()
		MOUSE_BUTTON_MIDDLE:
			_panning = button.pressed
			accept_event()
		MOUSE_BUTTON_LEFT:
			if button.pressed:
				_press_left(at)
			else:
				_release_left()
			accept_event()
		MOUSE_BUTTON_RIGHT:
			if button.pressed:
				_start_stroke(Color.TRANSPARENT, at)
			else:
				_finish_stroke()
			accept_event()


func _press_left(at: Vector2i) -> void:
	match tool:
		PICKER:
			if _inside(at):
				picked.emit(sheet.pixel(cell.x, cell.y, at))
		SELECT:
			_dragged = false
			if has_selection() and selection.has_point(at):
				if not _is_floating:
					_lift()
				_moving = true
				_move_from = at
				_move_start = selection.position
			else:
				commit()
				_selecting = true
				_select_from = _clamped(at)
				selection = Rect2i(_select_from, Vector2i.ONE)
			queue_redraw()
		_:
			_start_stroke(Color.TRANSPARENT if tool == ERASER else color, at)


func _release_left() -> void:
	# Um clique sem arrastar, dentro ou fora, tira a seleção (assentando o que estava solto).
	if (_selecting or _moving) and not _dragged:
		_selecting = false
		_moving = false
		deselect()
	_selecting = false
	_moving = false
	_finish_stroke()
	queue_redraw()


func _on_motion(motion: InputEventMouseMotion) -> void:
	if _panning:
		_pan += motion.relative
		queue_redraw()
		return
	var at := _pixel_at(motion.position)
	if at != _hover:
		_hover = at
		queue_redraw()
	if _moving:
		var target := _move_start + (at - _move_from)
		if target != selection.position:
			_dragged = true
			selection.position = target
			queue_redraw()
	elif _selecting:
		var corner := _clamped(at)
		if corner != _select_from:
			_dragged = true
		var low := Vector2i(mini(_select_from.x, corner.x), mini(_select_from.y, corner.y))
		var high := Vector2i(maxi(_select_from.x, corner.x), maxi(_select_from.y, corner.y))
		selection = Rect2i(low, high - low + Vector2i.ONE)
		queue_redraw()
	elif _stroking:
		_paint_line(_last, at)
		_last = at


## Muda o zoom um degrau, mantendo o pixel debaixo do mouse no lugar.
func _zoom_at(mouse: Vector2, step: int) -> void:
	var before := pixel_scale()
	var after := clampi(before + step * maxi(1, before >> 2), MIN_ZOOM, MAX_ZOOM)
	if after == before:
		return
	var under := (mouse - _origin()) / before
	zoom = after
	_pan = (mouse - under * after - _centered(after)).round()
	view_changed.emit()
	queue_redraw()


# --- pincel --------------------------------------------------------------------

func _start_stroke(paint_color: Color, at: Vector2i) -> void:
	commit()
	_painting = paint_color
	_stroking = true
	_last = at
	sheet.begin_stroke()
	_paint_brush(at)


func _finish_stroke() -> void:
	if _stroking and sheet != null:
		sheet.end_stroke()
	_stroking = false


## Bresenham entre dois pixels, para o arrasto rápido não deixar buracos.
func _paint_line(from: Vector2i, to: Vector2i) -> void:
	var delta := (to - from).abs()
	var step := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	var error := delta.x - delta.y
	var p := from
	while true:
		_paint_brush(p)
		if p == to:
			break
		var twice := 2 * error
		if twice > -delta.y:
			error -= delta.y
			p.x += step.x
		if twice < delta.x:
			error += delta.x
			p.y += step.y


func _paint_brush(at: Vector2i) -> void:
	var area := _brush_rect(at)
	for y: int in area.size.y:
		for x: int in area.size.x:
			sheet.paint(cell.x, cell.y, area.position + Vector2i(x, y), _painting)


## O quadrado do pincel com o pixel do mouse no meio (no tamanho par, um pouco acima e à esquerda).
func _brush_rect(at: Vector2i) -> Rect2i:
	var back := (brush - 1) >> 1
	return Rect2i(at - Vector2i(back, back), Vector2i(brush, brush))


func _pixel_at(at: Vector2) -> Vector2i:
	return Vector2i(((at - _origin()) / pixel_scale()).floor())


func _clamped(at: Vector2i) -> Vector2i:
	return at.clamp(Vector2i.ZERO, WardrobeSheet.CELL - Vector2i.ONE)


func _inside(at: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, WardrobeSheet.CELL).has_point(at)
