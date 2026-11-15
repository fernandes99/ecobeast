class_name BridgePanel
extends VBoxContainer
## O bloco da ferramenta Ponte (bridges/03): o estilo e a largura da próxima ponte e,
## com uma ponte escolhida, os dela (bridges/05).

signal edited(step: EditorHistory.Step)
signal changed

var type := ""
var width := MapBridge.DEFAULT_WIDTH
## A ponte escolhida no rascunho, ou -1.
var selected := -1

var _draft: IslandDraft = null
var _type_buttons: Dictionary[String, Button] = {}
var _info: Label
var _width_spin: SpinBox


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	var types := VBoxContainer.new()
	types.add_theme_constant_override(&"separation", 4)
	add_child(types)
	var group := ButtonGroup.new()
	for row: Dictionary in GameData.get_rows("bridge_types"):
		var slug := str(row.get("slug", ""))
		var button := EditorTools.tool_button(str(row.get("name", slug)), group)
		button.pressed.connect(pick_type.bind(slug))
		types.add_child(button)
		_type_buttons[slug] = button
		if type.is_empty():
			type = slug
	var width_row := HBoxContainer.new()
	width_row.add_theme_constant_override(&"separation", 8)
	var width_label := Label.new()
	width_label.text = "Largura (px)"
	width_row.add_child(width_label)
	_width_spin = SpinBox.new()
	_width_spin.min_value = HexBridges.MIN_WIDTH
	_width_spin.max_value = HexBridges.MAX_WIDTH
	_width_spin.step = 1
	_width_spin.value = width
	_width_spin.value_changed.connect(func(value: float) -> void: pick_width(int(value)))
	width_row.add_child(_width_spin)
	add_child(width_row)
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	_info.add_theme_font_size_override(&"font_size", 14)
	add_child(_info)
	refresh()


func set_draft(draft: IslandDraft) -> void:
	_draft = draft
	selected = -1
	refresh()


func select(index: int) -> void:
	selected = index if _draft != null and index >= 0 and index < _draft.bridges.size() else -1
	if selected >= 0:
		type = _draft.bridges[selected].type
		width = _draft.bridges[selected].width
	refresh()
	changed.emit()


func pick_type(slug: String) -> void:
	type = slug
	if selected >= 0 and _draft.bridges[selected].type != slug:
		var step := _new_step()
		_draft.bridges[selected].type = slug
		step.bridges_after = IslandDraft.copy_bridges(_draft.bridges)
		edited.emit(step)
	refresh()


func pick_width(value: int) -> void:
	width = value
	if selected >= 0 and _draft.bridges[selected].width != value:
		var step := _new_step()
		_draft.bridges[selected].width = value
		step.bridges_after = IslandDraft.copy_bridges(_draft.bridges)
		edited.emit(step)
	refresh()


func delete_selected() -> void:
	if selected < 0:
		return
	var step := _new_step()
	_draft.bridges.remove_at(selected)
	step.bridges_after = IslandDraft.copy_bridges(_draft.bridges)
	selected = -1
	refresh()
	edited.emit(step)
	changed.emit()


## Depois do desfazer: a escolha some se a ponte não existe mais.
func refresh() -> void:
	if _draft == null or selected >= _draft.bridges.size():
		selected = -1
	for slug: String in _type_buttons:
		_type_buttons[slug].set_pressed_no_signal(slug == type)
	_width_spin.set_value_no_signal(width)
	if selected >= 0:
		_info.text = "Ponte escolhida. O estilo e a largura trocam os dela; Delete apaga, Esc solta."
	else:
		_info.text = "Nenhuma ponte escolhida. O estilo e a largura valem para a próxima."


func _new_step() -> EditorHistory.Step:
	var step := EditorHistory.Step.new()
	step.label = "Ponte"
	step.bridges_before = IslandDraft.copy_bridges(_draft.bridges)
	return step
