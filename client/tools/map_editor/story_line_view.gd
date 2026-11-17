class_name StoryLineView
extends Control

## A Linha da história do F2 (story/05): todas as cenas em colunas, ligadas pelos Marcos,
## com os avisos ao lado. Tocar numa caixa abre a cena na ferramenta Cenas.

signal scene_requested(slug: String)
signal closed

const BOX_SIZE := Vector2(190.0, 58.0)
const COLUMN_GAP := 90.0
const ROW_GAP := 22.0
const MARGIN := 40.0
const SIDE_WIDTH := 330.0
const MIN_ZOOM := 0.5
const MAX_ZOOM := 2.0
const ZOOM_STEP := 1.1
const ARROW_PICK := 6.0
const DASH := 6.0
const NAME_SIZE := 15
const ISLAND_SIZE := 12


class Board:
	extends Control

	var view: StoryLineView

	func _draw() -> void:
		view.draw_board(self)

	func _get_tooltip(at_position: Vector2) -> String:
		return view.tooltip_at(at_position)


var _graph: StoryGraph = null
var _island_names: Dictionary[int, String] = {}
var _boxes: Array[Rect2] = []
var _highlight: Array = []
var _offset := Vector2(MARGIN, MARGIN)
var _zoom := 1.0
var _dragging := false
var _board := Board.new()
var _warnings := VBoxContainer.new()


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var background := ColorRect.new()
	background.color = UiPalette.BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "Linha da história"
	title.theme_type_variation = &"TitleLabel"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var hint := Label.new()
	hint.text = "Arraste para mover, roda para o zoom, toque numa cena para abri-la."
	hint.theme_type_variation = &"SecondaryLabel"
	header.add_child(hint)
	var close_button := Button.new()
	close_button.text = "Fechar"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(func() -> void:
		hide()
		closed.emit())
	header.add_child(close_button)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(&"separation", 12)
	column.add_child(body)
	_board.view = self
	_board.clip_contents = true
	_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board.mouse_filter = Control.MOUSE_FILTER_STOP
	_board.tooltip_text = " "
	_board.gui_input.connect(_on_board_input)
	body.add_child(_board)
	var side := ScrollContainer.new()
	side.custom_minimum_size.x = SIDE_WIDTH
	side.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(side)
	_warnings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_warnings.add_theme_constant_override(&"separation", 6)
	side.add_child(_warnings)


func open(island_names: Dictionary[int, String]) -> void:
	_island_names = island_names
	_graph = StoryGraph.build(Story.library.scenes)
	_highlight = []
	_layout()
	_fill_warnings()
	show()
	_board.queue_redraw()


func _layout() -> void:
	_boxes.clear()
	var order: Array[int] = []
	for index: int in _graph.scenes.size():
		order.append(index)
	order.sort_custom(func(a: int, b: int) -> bool:
		var sa := _graph.scenes[a]
		var sb := _graph.scenes[b]
		if _graph.columns[a] != _graph.columns[b]:
			return _graph.columns[a] < _graph.columns[b]
		if sa.island_id != sb.island_id:
			return sa.island_id < sb.island_id
		return sa.slug < sb.slug)
	_boxes.resize(_graph.scenes.size())
	var rows: Dictionary[int, int] = {}
	for index: int in order:
		var column := _graph.columns[index]
		var row: int = rows.get(column, 0)
		rows[column] = row + 1
		_boxes[index] = Rect2(Vector2(column * (BOX_SIZE.x + COLUMN_GAP), row * (BOX_SIZE.y + ROW_GAP)), BOX_SIZE)


func _fill_warnings() -> void:
	for child: Node in _warnings.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "Avisos"
	title.theme_type_variation = &"BoldLabel"
	_warnings.add_child(title)
	if _graph.warnings.is_empty():
		var ok := Label.new()
		ok.text = "Tudo certo." if not _graph.scenes.is_empty() else "Nenhuma cena ainda."
		ok.theme_type_variation = &"SecondaryLabel"
		_warnings.add_child(ok)
	for index: int in _graph.warnings.size():
		var button := Button.new()
		button.text = _graph.warnings[index]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void:
			_highlight = _graph.warning_scenes[index]
			_board.queue_redraw())
		_warnings.add_child(button)


func _screen(rect: Rect2) -> Rect2:
	return Rect2(_offset + rect.position * _zoom, rect.size * _zoom)


func draw_board(node: Control) -> void:
	if _graph == null:
		return
	for edge: Vector2i in _graph.edges:
		var from := _screen(_boxes[edge.x])
		var to := _screen(_boxes[edge.y])
		var start := Vector2(from.end.x, from.get_center().y)
		var end := Vector2(to.position.x, to.get_center().y)
		node.draw_line(start, end, UiPalette.TEXT_SECONDARY, 2.0, true)
		var back := (start - end).normalized() * 10.0 * _zoom
		node.draw_line(end, end + back.rotated(0.45), UiPalette.TEXT_SECONDARY, 2.0, true)
		node.draw_line(end, end + back.rotated(-0.45), UiPalette.TEXT_SECONDARY, 2.0, true)
	var font := get_theme_default_font()
	var islands := _island_order()
	for index: int in _graph.scenes.size():
		var scene := _graph.scenes[index]
		var box := _screen(_boxes[index])
		var colors := UiPalette.MAP_AREA_COLORS
		var fill: Color = colors[islands.find(scene.island_id) % colors.size()] if not colors.is_empty() else UiPalette.SURFACE_RAISED
		node.draw_rect(box, Color(fill, 0.35))
		var border := UiPalette.WARNING if _highlight.has(index) else UiPalette.BORDER
		var width := 3.0 if _highlight.has(index) else 2.0
		if scene.repeatable:
			for side: Array in [[box.position, Vector2(box.end.x, box.position.y)], [Vector2(box.end.x, box.position.y), box.end], [box.end, Vector2(box.position.x, box.end.y)], [Vector2(box.position.x, box.end.y), box.position]]:
				node.draw_dashed_line(side[0], side[1], border, width, DASH)
		else:
			node.draw_rect(box, border, false, width)
		var name_size := maxi(8, roundi(NAME_SIZE * _zoom))
		var island_size := maxi(7, roundi(ISLAND_SIZE * _zoom))
		var inner := box.size.x - 12.0 * _zoom
		node.draw_string(font, box.position + Vector2(6.0, 8.0 + name_size) * Vector2(_zoom, 1.0), scene.name, HORIZONTAL_ALIGNMENT_LEFT, inner, name_size, UiPalette.TEXT)
		node.draw_string(font, Vector2(box.position.x + 6.0 * _zoom, box.end.y - 8.0), _island_names.get(scene.island_id, "Ilha %d" % scene.island_id), HORIZONTAL_ALIGNMENT_LEFT, inner, island_size, UiPalette.TEXT_SECONDARY)


func _island_order() -> Array[int]:
	var ids: Array[int] = []
	for scene: StoryScene in _graph.scenes:
		if not ids.has(scene.island_id):
			ids.append(scene.island_id)
	ids.sort()
	return ids


func tooltip_at(point: Vector2) -> String:
	if _graph == null:
		return ""
	for edge: Vector2i in _graph.edges:
		var from := _screen(_boxes[edge.x])
		var to := _screen(_boxes[edge.y])
		var start := Vector2(from.end.x, from.get_center().y)
		var end := Vector2(to.position.x, to.get_center().y)
		if Geometry2D.get_closest_point_to_segment(point, start, end).distance_to(point) <= ARROW_PICK:
			return "Marcos: " + ", ".join(_graph.edge_marks[edge])
	for index: int in _boxes.size():
		if _screen(_boxes[index]).has_point(point):
			var scene := _graph.scenes[index]
			return "%s (%s)" % [scene.name, scene.slug]
	return ""


func _on_board_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		if button.pressed and (button.button_index == MOUSE_BUTTON_WHEEL_UP or button.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var factor := ZOOM_STEP if button.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / ZOOM_STEP
			var zoom := clampf(_zoom * factor, MIN_ZOOM, MAX_ZOOM)
			_offset = button.position - (button.position - _offset) * (zoom / _zoom)
			_zoom = zoom
			_board.queue_redraw()
			return
		if button.button_index == MOUSE_BUTTON_LEFT and not button.pressed and not _dragging:
			for index: int in _boxes.size():
				if _screen(_boxes[index]).has_point(button.position):
					hide()
					scene_requested.emit(_graph.scenes[index].slug)
					return
		if button.button_index == MOUSE_BUTTON_LEFT or button.button_index == MOUSE_BUTTON_MIDDLE:
			if button.pressed:
				_dragging = false
		return
	var motion := event as InputEventMouseMotion
	if motion != null and (motion.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_MIDDLE)) != 0:
		if motion.relative.length() > 0.0:
			_dragging = _dragging or motion.relative.length() > 1.0
			_offset += motion.relative
			_board.queue_redraw()
