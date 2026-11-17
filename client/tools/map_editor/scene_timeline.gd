class_name SceneTimeline
extends PanelContainer

## A faixa de passos da ferramenta Cenas, embaixo do mapa do F2 (story/06): os passos em
## cartões da esquerda para a direita e, ao abrir uma escolha ou um "se tiver o Marco",
## uma faixa por ramo, com o caminho e o Voltar no topo.

const CARD_WIDTH := 150.0
const LANE_HEIGHT := 74.0
const MAIN_HEIGHT := 150.0
const HEADER_HEIGHT := 34.0
const MAX_LANES_SHOWN := 4
const TAG_WIDTH := 130.0
const PLUS_WIDTH := 40.0
const CHIP_SIZE := 22.0
const SUMMARY_LINES := 3
const SUMMARY_LINES_LANE := 1

var _steps: SceneSteps = null
## Os níveis abertos: cada um é o passo (escolha ou "se tiver o Marco") cujos ramos
## aparecem, com o número dele na faixa de onde veio.
var _stack: Array[Dictionary] = []
## Cada cartão e o passo dele, para trocar o texto sem montar tudo de novo.
var _cards: Array[Dictionary] = []
var _box := VBoxContainer.new()
var _scroll := ScrollContainer.new()


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	var style := StyleBoxFlat.new()
	style.bg_color = UiPalette.SURFACE
	style.border_color = UiPalette.BORDER
	style.border_width_top = 1
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	add_theme_stylebox_override(&"panel", style)
	_box.add_theme_constant_override(&"separation", 6)
	add_child(_box)
	visible = false


func set_steps(steps: SceneSteps) -> void:
	_steps = steps
	steps.structure_changed.connect(rebuild)
	steps.selection_changed.connect(_refresh_selection)
	steps.changed.connect(_refresh_texts)


## Some sem cena aberta; o caminho dos ramos volta ao início quando a cena muda.
func show_scene(open: bool) -> void:
	visible = open and _steps != null and _steps.scene() != null
	if visible:
		rebuild()


func reset() -> void:
	_stack.clear()
	rebuild()


func rebuild() -> void:
	for child: Node in _box.get_children():
		_box.remove_child(child)
		child.queue_free()
	_cards.clear()
	if _steps == null or _steps.scene() == null:
		return
	_drop_stale_levels()
	if _stack.is_empty():
		custom_minimum_size.y = MAIN_HEIGHT
		_scroll = _lane_scroll(true)
		_box.add_child(_scroll)
		_scroll.get_child(0).add_child(_lane(_steps.scene().steps, SUMMARY_LINES))
	else:
		_box.add_child(_header())
		var lanes := _branches(_stack[-1]["step"])
		var shown := mini(lanes.size(), MAX_LANES_SHOWN)
		custom_minimum_size.y = HEADER_HEIGHT + shown * LANE_HEIGHT + 24.0
		_scroll = _lane_scroll(false)
		_box.add_child(_scroll)
		var column := VBoxContainer.new()
		column.add_theme_constant_override(&"separation", 4)
		_scroll.get_child(0).add_child(column)
		for branch: Dictionary in lanes:
			var row := HBoxContainer.new()
			row.add_theme_constant_override(&"separation", 6)
			row.add_child(_tag(branch))
			row.add_child(_lane(branch["list"], SUMMARY_LINES_LANE))
			column.add_child(row)


## Um ramo aberto pode ter sido apagado (ou a escolha mudado de lugar): fecha até o
## nível que ainda existe.
func _drop_stale_levels() -> void:
	var lists: Array[Array] = [_steps.scene().steps]
	var keep := 0
	for level: Dictionary in _stack:
		var found := false
		for list: Array in lists:
			for step: Variant in list:
				if is_same(step, level["step"]):
					found = true
		if not found:
			break
		keep += 1
		lists.clear()
		for branch: Dictionary in _branches(level["step"]):
			lists.append(branch["list"])
	_stack.resize(keep)


func _lane_scroll(horizontal_only: bool) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if horizontal_only else ScrollContainer.SCROLL_MODE_AUTO
	var holder := MarginContainer.new()
	holder.add_theme_constant_override(&"margin_top", 2)
	holder.add_theme_constant_override(&"margin_left", 2)
	holder.add_theme_constant_override(&"margin_bottom", 2)
	scroll.add_child(holder)
	return scroll


func _lane(list: Array, lines: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	for index: int in list.size():
		if list[index] is Dictionary:
			row.add_child(_card(list, index, lines))
	row.add_child(_plus(list))
	return row


func _card(list: Array, index: int, lines: int) -> Control:
	var step: Dictionary = list[index]
	var type := DictFields.get_string(step, "type")
	var card := PanelContainer.new()
	card.custom_minimum_size.x = CARD_WIDTH
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.add_theme_stylebox_override(&"panel", _card_style(_steps.is_chosen(list, index)))
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 3)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 6)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)
	top.add_child(_chip(type))
	var heading := Label.new()
	heading.text = "%d · %s" % [index + 1, SceneSteps.TYPE_NAMES.get(type, type)]
	heading.theme_type_variation = &"BoldLabel"
	heading.clip_text = true
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(heading)
	var summary := Label.new()
	summary.text = SceneSteps.summary(step)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.max_lines_visible = lines
	summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	summary.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(summary)
	if type == "choice" or type == "if_mark":
		var open := Button.new()
		open.text = "Abrir ramos"
		open.focus_mode = Control.FOCUS_NONE
		open.pressed.connect(func() -> void: _open(step, index))
		column.add_child(open)
	card.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			grab_focus()
			_steps.select({"list": list, "index": index})
			if click.double_click and (type == "choice" or type == "if_mark"):
				_open(step, index))
	_cards.append({"card": card, "list": list, "index": index, "summary": summary})
	return card


func _chip(type: String) -> Control:
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = SceneSteps.type_color(type)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(3)
	chip.add_theme_stylebox_override(&"panel", style)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = SceneSteps.type_icon(type)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(CHIP_SIZE - 6.0, CHIP_SIZE - 6.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(icon)
	return chip


func _plus(list: Array) -> Control:
	var plus := MenuButton.new()
	plus.text = "+"
	plus.flat = false
	plus.tooltip_text = "Pôr um passo no fim desta faixa."
	plus.custom_minimum_size.x = PLUS_WIDTH
	plus.focus_mode = Control.FOCUS_NONE
	SceneSteps.fill_type_menu(plus.get_popup(), func(type: String) -> void: _steps.add_step(type, list, list.size()))
	return plus


func _card_style(chosen: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UiPalette.SURFACE_RAISED
	style.border_color = UiPalette.ACCENT if chosen else UiPalette.BORDER
	style.set_border_width_all(2 if chosen else 1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	return style


# Os ramos.

func _open(step: Dictionary, index: int) -> void:
	_stack.append({"step": step, "index": index})
	grab_focus()
	rebuild()


func _back(levels: int = 1) -> void:
	_stack.resize(maxi(_stack.size() - levels, 0))
	rebuild()


## Os ramos de uma escolha (as opções) ou de um "se tiver o Marco" (Então e Senão).
func _branches(step: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if DictFields.get_string(step, "type") == "choice":
		var options := DictFields.get_array(step, "options")
		for index: int in options.size():
			var option: Dictionary = options[index]
			if not option.get("steps") is Array:
				option["steps"] = []
			result.append({"label": "Opção %d\n%s" % [index + 1, DictFields.get_string(option, "text")], "list": option["steps"], "option": option, "options": options})
	else:
		for key: String in ["then", "else"]:
			if not step.get(key) is Array:
				step[key] = []
			result.append({"label": "Então (tem %s)" % DictFields.get_string(step, "mark") if key == "then" else "Senão", "list": step[key]})
	return result


func _header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	row.custom_minimum_size.y = HEADER_HEIGHT - 6.0
	var back := Button.new()
	back.text = "← Voltar"
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(_back)
	row.add_child(back)
	var root := Button.new()
	root.text = "Cena"
	root.flat = true
	root.focus_mode = Control.FOCUS_NONE
	root.pressed.connect(_back.bind(_stack.size()))
	row.add_child(root)
	for level: int in _stack.size():
		var step: Dictionary = _stack[level]["step"]
		var arrow := Label.new()
		arrow.text = "›"
		arrow.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
		row.add_child(arrow)
		var crumb := Button.new()
		var type := DictFields.get_string(step, "type")
		crumb.text = "%s (passo %d)" % [SceneSteps.TYPE_NAMES.get(type, type), int(_stack[level]["index"]) + 1]
		crumb.flat = level < _stack.size() - 1
		crumb.focus_mode = Control.FOCUS_NONE
		crumb.pressed.connect(_back.bind(_stack.size() - 1 - level))
		row.add_child(crumb)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var current: Dictionary = _stack[-1]["step"]
	if DictFields.get_string(current, "type") == "choice":
		var add := Button.new()
		add.text = "+ Opção"
		add.focus_mode = Control.FOCUS_NONE
		add.disabled = DictFields.get_array(current, "options").size() >= StoryValidator.MAX_OPTIONS
		add.pressed.connect(func() -> void: _steps.add_option(current))
		row.add_child(add)
	return row


func _tag(branch: Dictionary) -> Control:
	var tag := Button.new()
	tag.text = str(branch["label"])
	tag.custom_minimum_size = Vector2(TAG_WIDTH, LANE_HEIGHT - 8.0)
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tag.alignment = HORIZONTAL_ALIGNMENT_LEFT
	tag.focus_mode = Control.FOCUS_NONE
	tag.toggle_mode = true
	tag.button_pressed = branch.has("option") and is_same(_steps.chosen.get("option"), branch["option"])
	tag.disabled = not branch.has("option")
	if branch.has("option"):
		tag.tooltip_text = "Escolher a opção para mudar o texto ou apagá-la."
		tag.pressed.connect(func() -> void:
			grab_focus()
			_steps.select({"option": branch["option"], "options": branch["options"], "list": branch["list"]}))
	return tag


# A escolha e o texto, sem montar de novo.

func _refresh_selection() -> void:
	for entry: Dictionary in _cards:
		var card: PanelContainer = entry["card"]
		card.add_theme_stylebox_override(&"panel", _card_style(_steps.is_chosen(entry["list"], entry["index"])))
	if not _stack.is_empty():
		rebuild()
		return
	_scroll_to_chosen.call_deferred()


func _refresh_texts() -> void:
	for entry: Dictionary in _cards:
		var list: Array = entry["list"]
		var index: int = entry["index"]
		if index < list.size() and list[index] is Dictionary:
			(entry["summary"] as Label).text = SceneSteps.summary(list[index])


func _scroll_to_chosen() -> void:
	for entry: Dictionary in _cards:
		if _steps.is_chosen(entry["list"], entry["index"]):
			_scroll.ensure_control_visible(entry["card"])


# O teclado, com o foco na faixa.

func _gui_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	var handled := true
	match key.keycode:
		KEY_LEFT, KEY_RIGHT:
			var offset := -1 if key.keycode == KEY_LEFT else 1
			if key.ctrl_pressed:
				_steps.move_chosen(offset)
			else:
				_step_selection(offset)
		KEY_DELETE, KEY_BACKSPACE:
			_steps.delete_chosen()
		KEY_ENTER, KEY_KP_ENTER:
			var step := _steps.chosen_step()
			var type := DictFields.get_string(step, "type")
			if type == "choice" or type == "if_mark":
				_open(step, int(_steps.chosen["index"]))
		KEY_ESCAPE:
			handled = not _stack.is_empty()
			if handled:
				_back()
		_:
			handled = false
	if handled:
		accept_event()


func _step_selection(offset: int) -> void:
	if not _steps.chosen.has("index"):
		var first: Array = _steps.scene().steps if _stack.is_empty() else _branches(_stack[-1]["step"])[0]["list"]
		if not first.is_empty():
			_steps.select({"list": first, "index": 0})
		return
	var list: Array = _steps.chosen["list"]
	var target := int(_steps.chosen["index"]) + offset
	if target >= 0 and target < list.size():
		_steps.select({"list": list, "index": target})
