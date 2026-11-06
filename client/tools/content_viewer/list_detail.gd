class_name ListDetail
extends HSplitContainer
## A lista à esquerda e o detalhe do item escolhido à direita, que as abas do
## visualizador usam (content-viewer/architecture.md, "O par lista e detalhe"). A aba
## diz as linhas, com `set_rows`, e monta o detalhe em `_build_detail`; o detalhe é
## montado de novo a cada escolha.

const LIST_WIDTH := 320
const ROW_HEIGHT := 30
const DOT_SIZE := 10
const ROW_HOVER := Color("#FFFFFF14")

## Uma linha da lista: o id, o texto, uma bolinha opcional (alpha 0 = sem) e um texto
## à direita, com a cor dele.
class Row:
	extends RefCounted
	var id: int
	var text: String
	var dot := Color(0, 0, 0, 0)
	var tail := ""
	var tail_color := UiPalette.TEXT_SECONDARY

	func _init(row_id: int, row_text: String) -> void:
		id = row_id
		text = row_text


var viewer: ContentViewer
var selected_id := -1
var _list: VBoxContainer
## Acima da lista, para um botão da aba (como a tabela dos Elementos).
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
	var list_scroll := ScrollContainer.new()
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override(&"separation", 0)
	list_scroll.add_child(_list)
	left.add_child(list_scroll)
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


## Troca as linhas e escolhe a primeira, ou a escolhida antes, se ainda existir.
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


## Escolhe o item e monta o detalhe dele.
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


## Põe um controle acima da lista.
func add_list_header(control: Control) -> void:
	_list_header.add_child(control)
	_list_header.visible = true


## Mostra no lugar do detalhe algo que não é um item da lista: nenhuma linha fica
## escolhida, e `build` monta o conteúdo dentro do detalhe.
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


## A aba monta o detalhe do item dentro de `box`.
func _build_detail(_id: int, _box: VBoxContainer) -> void:
	pass


func _row_button(row: Row) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.button_group = _group
	button.custom_minimum_size.y = ROW_HEIGHT
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
	if row.dot.a > 0.0:
		var dot := ColorRect.new()
		dot.color = row.dot
		dot.custom_minimum_size = Vector2(DOT_SIZE, DOT_SIZE)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(dot)
	var label := ContentViewer.text(row.text)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	line.add_child(label)
	if not row.tail.is_empty():
		line.add_child(ContentViewer.text(row.tail, 0, row.tail_color))
	button.add_child(line)
	return button
