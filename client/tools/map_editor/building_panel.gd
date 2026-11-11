class_name BuildingPanel
extends VBoxContainer
## As construções no painel do editor de ilhas (map-editor/04): o tipo que o pincel
## pinta (Refúgio, Loja, Arena, Casa, do catálogo `building_types`) e a construção
## escolhida, com o tipo, o tamanho, tirar hexágonos dela e apagá-la.

## Uma mudança no rascunho, já feita, para o desfazer.
signal edited(step: EditorHistory.Step)
## A construção escolhida mudou (-1 sem nenhuma).
signal selection_changed(index: int)

const CHIP_SIZE := Vector2(14.0, 14.0)

## O tipo que o pincel pinta numa construção nova.
var type_id := 0
## A construção escolhida, pelo índice em `IslandDraft.buildings`; -1 sem nenhuma.
var selected := -1
## O pincel tira hexágonos da construção escolhida, em vez de pintar.
var removing := false

var _draft: IslandDraft = null
var _types: Array[Dictionary] = []
var _type_buttons: Dictionary[int, Button] = {}
var _selected_box: VBoxContainer
var _selected_label: Label
var _type_option: OptionButton
var _remove_button: Button


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	var hint := Label.new()
	hint.text = "Tipo da construção nova:"
	hint.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	add_child(hint)
	var types_grid := GridContainer.new()
	types_grid.columns = 2
	types_grid.add_theme_constant_override(&"h_separation", 6)
	types_grid.add_theme_constant_override(&"v_separation", 6)
	add_child(types_grid)
	var group := ButtonGroup.new()
	for row: Dictionary in GameData.get_rows("building_types"):
		_types.append(row)
		var id := int(row.get("id", 0))
		var button := EditorTools.tool_button(str(row.get("name", "")), group)
		button.icon = color_chip(Color.from_string(str(row.get("color_hex", "")), UiPalette.TEXT))
		button.pressed.connect(_pick_type.bind(id))
		types_grid.add_child(button)
		_type_buttons[id] = button
	if not _types.is_empty():
		type_id = int(_types[0].get("id", 0))

	_selected_box = VBoxContainer.new()
	_selected_box.add_theme_constant_override(&"separation", 6)
	add_child(_selected_box)
	_selected_box.add_child(HSeparator.new())
	_selected_label = Label.new()
	_selected_label.theme_type_variation = &"BoldLabel"
	_selected_box.add_child(_selected_label)
	var type_row := HBoxContainer.new()
	_selected_box.add_child(type_row)
	var type_label := Label.new()
	type_label.text = "Tipo"
	type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	type_row.add_child(type_label)
	_type_option = OptionButton.new()
	_type_option.focus_mode = Control.FOCUS_NONE
	for row: Dictionary in _types:
		_type_option.add_item(str(row.get("name", "")), int(row.get("id", 0)))
	_type_option.item_selected.connect(_on_type_changed)
	type_row.add_child(_type_option)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override(&"separation", 6)
	_selected_box.add_child(actions)
	_remove_button = EditorTools.tool_button("Tirar hexágonos", null)
	_remove_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_remove_button.tooltip_text = "O pincel tira hexágonos só desta construção."
	_remove_button.toggled.connect(func(on: bool) -> void: removing = on)
	actions.add_child(_remove_button)
	var delete := Button.new()
	delete.text = "Apagar construção"
	delete.theme_type_variation = &"DangerButton"
	delete.focus_mode = Control.FOCUS_NONE
	delete.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete.pressed.connect(_delete_selected)
	actions.add_child(delete)
	refresh()


func set_draft(draft: IslandDraft) -> void:
	_draft = draft
	select(-1)


## Escolhe uma construção (ou nenhuma, com -1).
func select(index: int) -> void:
	if _draft == null or index >= _draft.buildings.size():
		index = -1
	selected = index
	removing = false
	refresh()
	selection_changed.emit(selected)


## Mostra o tipo escolhido e a construção escolhida como estão no rascunho.
func refresh() -> void:
	for id: int in _type_buttons:
		_type_buttons[id].set_pressed_no_signal(id == type_id)
	if _draft == null or selected < 0 or selected >= _draft.buildings.size():
		selected = -1
		_selected_box.visible = false
		return
	_selected_box.visible = true
	var building: Dictionary = _draft.buildings[selected]
	var id := int(building.get("building_type_id", 0))
	_selected_label.text = "%s  ·  %d hexágonos" % [_type_name(id), (building.get("tiles", []) as Array).size()]
	_type_option.select(_type_option.get_item_index(id))
	_remove_button.set_pressed_no_signal(removing)


func _pick_type(id: int) -> void:
	type_id = id
	refresh()


func _on_type_changed(item: int) -> void:
	if _draft == null or selected < 0:
		return
	var id := _type_option.get_item_id(item)
	var step := _step("Trocar o tipo da construção")
	_draft.buildings[selected]["building_type_id"] = id
	step.buildings_after = _draft.buildings.duplicate(true)
	refresh()
	edited.emit(step)


func _delete_selected() -> void:
	if _draft == null or selected < 0:
		return
	var step := _step("Apagar construção")
	_draft.buildings.remove_at(selected)
	step.buildings_after = _draft.buildings.duplicate(true)
	select(-1)
	edited.emit(step)


func _step(label: String) -> EditorHistory.Step:
	var step := EditorHistory.Step.new()
	step.label = label
	step.buildings_before = _draft.buildings.duplicate(true)
	return step


func _type_name(id: int) -> String:
	for row: Dictionary in _types:
		if int(row.get("id", 0)) == id:
			return str(row.get("name", ""))
	return "?"


## Um quadradinho de cor, para ícone de botão e de lista.
static func color_chip(color: Color, chip_size: Vector2i = Vector2i(CHIP_SIZE)) -> Texture2D:
	var image := Image.create(chip_size.x, chip_size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
