class_name ListDetail
extends HSplitContainer

const LIST_WIDTH := 320
const ROW_HEIGHT := 30
const DOT_SIZE := 10
const ICON_SIZE := 22
const ROW_HOVER := Color("#FFFFFF14")

class Row:
	extends RefCounted
	var id: int
	var text: String
	var dot := Color(0, 0, 0, 0)
	var icon: Texture2D = null
	var tail := ""
	var tail_color := UiPalette.TEXT_SECONDARY
	var lead: Control = null
	var below: Control = null
	var height := ROW_HEIGHT

	func _init(row_id: int, row_text: String) -> void:
		id = row_id
		text = row_text


var viewer: ContentViewer
var selected_id := -1
var _list: VBoxContainer
var _list_scroll: ScrollContainer
var _list_header: VBoxContainer
var _detail: VBoxContainer
var _detail_scroll: ScrollContainer
var _buttons: Dictionary[int, Button] = {}
var _group := ButtonGroup.new()


func _init(content_viewer: ContentViewer) -> void:
	viewer = content_viewer
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = LIST_WIDTH
	_list_header = VBoxContainer.new()
	_list_header.visible = false
	left.add_child(_list_header)
	_list_scroll = ScrollContainer.new()
	_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override(&"separation", 0)
	_list_scroll.add_child(_list)
	left.add_child(_list_scroll)
	add_child(left)

	_detail_scroll = ScrollContainer.new()
	_detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override(&"separation", 10)
	margin.add_child(_detail)
	_detail_scroll.add_child(margin)
	add_child(_detail_scroll)


func set_rows(rows: Array[Row]) -> void:
	for child: Node in _list.get_children():
		child.queue_free()
	_buttons.clear()
	for row: Row in rows:
		var button := _row_button(row)
		_list.add_child(button)
		_buttons[row.id] = button
	if _buttons.has(selected_id):
		select(selected_id)
	elif not rows.is_empty():
		select(rows[0].id)


func select(id: int) -> void:
	if not _buttons.has(id):
		return
	selected_id = id
	# Sem sinal, o ButtonGroup não solta o botão de antes: solta aqui.
	for button_id: int in _buttons:
		_buttons[button_id].set_pressed_no_signal(button_id == id)
	_clear_detail()
	_build_detail(id, _detail)
	_detail_scroll.scroll_vertical = 0
	# Logo depois de set_rows a linha ainda não tem posição: rola no próximo quadro.
	_scroll_to.call_deferred(id)


func _scroll_to(id: int) -> void:
	if _buttons.has(id) and is_instance_valid(_buttons[id]):
		_list_scroll.ensure_control_visible(_buttons[id])


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or (key.keycode != KEY_UP and key.keycode != KEY_DOWN):
		return
	if not is_visible_in_tree() or not _buttons.has(selected_id) or _typing():
		return
	var ids: Array[int] = []
	for button: Node in _list.get_children():
		var row_id: Variant = _buttons.find_key(button)
		if row_id != null and (button as Control).visible:
			ids.append(row_id)
	var next := ids.find(selected_id) + (1 if key.keycode == KEY_DOWN else -1)
	get_viewport().set_input_as_handled()
	if next >= 0 and next < ids.size():
		select(ids[next])


func _typing() -> bool:
	var focus := get_viewport().gui_get_focus_owner()
	return focus is LineEdit or focus is TextEdit


func add_list_header(control: Control) -> void:
	_list_header.add_child(control)
	_list_header.visible = true


func show_custom(build: Callable) -> void:
	selected_id = -1
	for button_id: int in _buttons:
		_buttons[button_id].set_pressed_no_signal(false)
	_clear_detail()
	build.call(_detail)
	_detail_scroll.scroll_vertical = 0


func _clear_detail() -> void:
	for child: Node in _detail.get_children():
		_detail.remove_child(child)
		child.queue_free()


func _build_detail(_id: int, _box: VBoxContainer) -> void:
	pass


func _row_button(row: Row) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.button_group = _group
	button.custom_minimum_size.y = row.height
	button.focus_mode = Control.FOCUS_NONE
	var clear := StyleBoxEmpty.new()
	var hover := StyleBoxFlat.new()
	hover.bg_color = ROW_HOVER
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = UiPalette.SURFACE_RAISED
	pressed.border_color = UiPalette.ACCENT
	pressed.border_width_left = 3
	for style_name: StringName in [&"normal", &"disabled", &"focus"]:
		button.add_theme_stylebox_override(style_name, clear)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"pressed", pressed)
	button.add_theme_stylebox_override(&"hover_pressed", pressed)
	button.pressed.connect(select.bind(row.id))

	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.offset_left = 10
	line.offset_right = -10
	line.add_theme_constant_override(&"separation", 8)
	if row.icon != null:
		var icon := TextureRect.new()
		icon.texture = row.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(icon)
	if row.dot.a > 0.0:
		var dot := ColorRect.new()
		dot.color = row.dot
		dot.custom_minimum_size = Vector2(DOT_SIZE, DOT_SIZE)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(dot)
	if row.lead != null:
		row.lead.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(row.lead)
	var label := ContentViewer.text(row.text)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if row.below != null:
		var stack := VBoxContainer.new()
		stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.alignment = BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override(&"separation", 1)
		stack.add_child(label)
		stack.add_child(row.below)
		line.add_child(stack)
	else:
		line.add_child(label)
	if not row.tail.is_empty():
		line.add_child(ContentViewer.text(row.tail, 0, row.tail_color))
	button.add_child(line)
	_pass_clicks(line)
	return button


func _pass_clicks(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_pass_clicks(child)
