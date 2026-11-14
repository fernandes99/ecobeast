class_name StampPanel
extends VBoxContainer
## O bloco Carimbo do editor (free-props/04): pôr um carimbo da pasta, espelhado ou
## não, ou escolher uma área da ilha e guardá-la como carimbo.

signal changed
signal mode_changed

enum Mode { PLACE, SELECT }

const MAX_NAME := 40

var mode := Mode.PLACE
var stamp: Dictionary = {}
var flip := false
var selection: Dictionary[Vector2i, bool] = {}

var _draft: IslandDraft = null
var _stamps: Array[Dictionary] = []
var _mode_buttons: Array[Button] = []
var _place_box: VBoxContainer
var _select_box: VBoxContainer
var _list: VBoxContainer
var _list_group := ButtonGroup.new()
var _mirror_button: Button
var _count_label: Label
var _name_edit: LineEdit
var _save_button: Button
var _feedback: Label


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override(&"separation", 6)
	add_child(modes)
	var mode_group := ButtonGroup.new()
	for entry: Array in [[Mode.PLACE, "Pôr"], [Mode.SELECT, "Escolher área"]]:
		var button := EditorTools.tool_button(entry[1], mode_group)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(set_mode.bind(entry[0]))
		modes.add_child(button)
		_mode_buttons.append(button)

	_place_box = VBoxContainer.new()
	_place_box.add_theme_constant_override(&"separation", 6)
	add_child(_place_box)
	_mirror_button = EditorTools.tool_button("Espelhar  (M)", null)
	_mirror_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mirror_button.icon = load(MapEditor.ICONS % "mirror") as Texture2D
	_mirror_button.add_theme_constant_override(&"icon_max_width", MapEditor.ICON_WIDTH)
	_mirror_button.toggled.connect(func(on: bool) -> void:
		flip = on
		changed.emit())
	_place_box.add_child(_mirror_button)
	var list_title := Label.new()
	list_title.text = "Carimbos"
	EditorTools.section_title(list_title)
	_place_box.add_child(list_title)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", 4)
	_place_box.add_child(_list)

	_select_box = VBoxContainer.new()
	_select_box.add_theme_constant_override(&"separation", 6)
	add_child(_select_box)
	_count_label = Label.new()
	_count_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_select_box.add_child(_count_label)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Nome do carimbo"
	_name_edit.max_length = MAX_NAME
	_name_edit.text_changed.connect(func(_text: String) -> void: _refresh())
	_select_box.add_child(_name_edit)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 6)
	_select_box.add_child(buttons)
	_save_button = Button.new()
	_save_button.text = "Guardar carimbo"
	_save_button.focus_mode = Control.FOCUS_NONE
	_save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_button.pressed.connect(save_selection)
	buttons.add_child(_save_button)
	var clear := Button.new()
	clear.text = "Limpar"
	clear.focus_mode = Control.FOCUS_NONE
	clear.pressed.connect(clear_selection)
	buttons.add_child(clear)

	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	add_child(_feedback)
	reload()


func set_draft(draft: IslandDraft) -> void:
	_draft = draft
	selection.clear()
	_feedback.text = ""
	_refresh()


func set_mode(value: Mode) -> void:
	mode = value
	_refresh()
	changed.emit()
	mode_changed.emit()


func toggle_mirror() -> void:
	_mirror_button.button_pressed = not _mirror_button.button_pressed


## Lê de novo os carimbos da pasta, mantendo o escolhido pelo nome.
func reload() -> void:
	var chosen := str(stamp.get("name", ""))
	_stamps = Stamp.list()
	stamp = {}
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	for entry: Dictionary in _stamps:
		var button := EditorTools.tool_button("%s  ·  %d %s" % [str(entry.get("name", "")), (entry.get("tiles", []) as Array).size(), "hexágono" if (entry.get("tiles", []) as Array).size() == 1 else "hexágonos"], _list_group)
		button.pressed.connect(_pick.bind(entry))
		_list.add_child(button)
		if str(entry.get("name", "")) == chosen:
			stamp = entry
			button.set_pressed_no_signal(true)
	if _stamps.is_empty():
		var empty := Label.new()
		empty.text = "Nenhum carimbo ainda. Escolha uma área e guarde."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
		_list.add_child(empty)
	_refresh()


func mark(coord: Vector2i, on: bool) -> bool:
	if on == selection.has(coord):
		return false
	if on:
		selection[coord] = true
	else:
		selection.erase(coord)
	return true


func refresh_count() -> void:
	_refresh()


func clear_selection() -> void:
	selection.clear()
	_refresh()
	changed.emit()


func save_selection() -> void:
	var stamp_name := _name_edit.text.strip_edges()
	if _draft == null or selection.is_empty() or stamp_name.is_empty():
		return
	var area: Array[Vector2i] = []
	area.assign(selection.keys())
	var captured := Stamp.capture(_draft, area, stamp_name)
	var error := Stamp.save(captured)
	if error != OK:
		_feedback.text = "Não deu para guardar: %s." % error_string(error)
		return
	_feedback.text = "Carimbo \"%s\" guardado." % stamp_name
	stamp = captured
	reload()


func _pick(entry: Dictionary) -> void:
	stamp = entry
	changed.emit()


func _refresh() -> void:
	for index: int in _mode_buttons.size():
		_mode_buttons[index].set_pressed_no_signal(index == mode)
	_place_box.visible = mode == Mode.PLACE
	_select_box.visible = mode == Mode.SELECT
	var count := selection.size()
	_count_label.text = "Pinte os hexágonos da área com o botão esquerdo; o direito tira. %d %s." % [count, "marcado" if count == 1 else "marcados"]
	_save_button.disabled = count == 0 or _name_edit.text.strip_edges().is_empty()
