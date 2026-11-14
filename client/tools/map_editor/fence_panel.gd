class_name FencePanel
extends VBoxContainer
## O bloco da ferramenta Cerca (free-fences/03): o tipo da próxima parede e, com uma
## parede escolhida, o dela.

signal edited(step: EditorHistory.Step)
signal changed

var type := ""
## A parede escolhida no rascunho, ou -1.
var selected := -1

var _draft: IslandDraft = null
var _type_buttons: Dictionary[String, Button] = {}
var _info: Label


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	var types := VBoxContainer.new()
	types.add_theme_constant_override(&"separation", 4)
	add_child(types)
	var group := ButtonGroup.new()
	for row: Dictionary in GameData.get_rows("wall_types"):
		var slug := str(row.get("slug", ""))
		var button := EditorTools.tool_button(str(row.get("name", slug)), group)
		button.pressed.connect(pick_type.bind(slug))
		types.add_child(button)
		_type_buttons[slug] = button
		if type.is_empty():
			type = slug
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
	selected = index if _draft != null and index >= 0 and index < _draft.walls.size() else -1
	if selected >= 0:
		type = _draft.walls[selected].type
	refresh()
	changed.emit()


func pick_type(slug: String) -> void:
	type = slug
	if selected >= 0 and _draft.walls[selected].type != slug:
		var step := _new_step()
		_draft.walls[selected].type = slug
		step.walls_after = IslandDraft.copy_walls(_draft.walls)
		edited.emit(step)
	refresh()


func delete_selected() -> void:
	if selected < 0:
		return
	var step := _new_step()
	_draft.walls.remove_at(selected)
	step.walls_after = IslandDraft.copy_walls(_draft.walls)
	selected = -1
	refresh()
	edited.emit(step)
	changed.emit()


## Depois do desfazer: a escolha some se a parede não existe mais.
func refresh() -> void:
	if _draft == null or selected >= _draft.walls.size():
		selected = -1
	for slug: String in _type_buttons:
		_type_buttons[slug].set_pressed_no_signal(slug == type)
	if selected >= 0:
		_info.text = "Parede escolhida. Os tipos trocam o dela; Delete apaga, Esc solta."
	else:
		_info.text = "Nenhuma parede escolhida. O tipo vale para a próxima."


func _new_step() -> EditorHistory.Step:
	var step := EditorHistory.Step.new()
	step.label = "Cerca"
	step.walls_before = IslandDraft.copy_walls(_draft.walls)
	return step
