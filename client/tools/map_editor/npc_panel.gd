class_name NpcPanel
extends VBoxContainer

## A ferramenta NPC (island-npcs/02): a lista do catálogo e o NPC escolhido no mapa.

signal edited(step: EditorHistory.Step, merge: bool)
signal selection_changed(index: int)

const ICON_SCALE := 3
const DIALOGUE_HEIGHT := 140.0
const NO_ACTION := 0
const DIALOGUE_STEP := "Diálogo do NPC"

var npc_id := 0
var selected := -1
var marking := false

var _draft: IslandDraft = null
var _npc_buttons: Dictionary[int, Button] = {}
var _selected_box: VBoxContainer
var _selected_label: Label
var _walk_button: Button
var _still_button: Button
var _mark_button: Button
var _dialogue: TextEdit
var _action_option: OptionButton


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	var hint := Label.new()
	hint.text = "NPC novo:"
	hint.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	add_child(hint)
	var list := VBoxContainer.new()
	list.add_theme_constant_override(&"separation", 6)
	add_child(list)
	var group := ButtonGroup.new()
	for row: Dictionary in GameData.get_rows("npcs"):
		var id := int(row.get("id", 0))
		var slug := str(row.get("sprite", ""))
		var button := EditorTools.tool_button("%s\n%s" % [row.get("name", ""), row.get("description", "")], group)
		button.icon = _icon(slug)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = button.icon == null
		if button.disabled:
			button.tooltip_text = "Sem as folhas assets/creatures/%s/explore/idle.png e walk.png." % slug
		button.pressed.connect(_pick_npc.bind(id))
		list.add_child(button)
		_npc_buttons[id] = button
		if npc_id == 0 and not button.disabled:
			npc_id = id

	_selected_box = VBoxContainer.new()
	_selected_box.add_theme_constant_override(&"separation", 6)
	add_child(_selected_box)
	_selected_box.add_child(HSeparator.new())
	_selected_label = Label.new()
	_selected_label.theme_type_variation = &"BoldLabel"
	_selected_box.add_child(_selected_label)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override(&"separation", 6)
	_selected_box.add_child(mode_row)
	var mode_group := ButtonGroup.new()
	_walk_button = EditorTools.tool_button("Passeia", mode_group)
	_walk_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_walk_button.pressed.connect(_set_still.bind(false))
	mode_row.add_child(_walk_button)
	_still_button = EditorTools.tool_button("Parado", mode_group)
	_still_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_still_button.pressed.connect(_set_still.bind(true))
	mode_row.add_child(_still_button)
	_mark_button = EditorTools.tool_button("Marcar passeio", null)
	_mark_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mark_button.tooltip_text = "Ligado, cada clique põe ou tira um hexágono do passeio."
	_mark_button.toggled.connect(func(on: bool) -> void:
		marking = on
		selection_changed.emit(selected))
	_selected_box.add_child(_mark_button)

	var dialogue_label := Label.new()
	dialogue_label.text = "Diálogo (opcional) · cada parágrafo é uma fala"
	dialogue_label.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	_selected_box.add_child(dialogue_label)
	_dialogue = TextEdit.new()
	_dialogue.custom_minimum_size.y = DIALOGUE_HEIGHT
	_dialogue.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_dialogue.placeholder_text = "Bem-vindo!\n\nO Refúgio fica ali."
	_dialogue.text_changed.connect(_on_dialogue_changed)
	_selected_box.add_child(_dialogue)

	var action_row := HBoxContainer.new()
	_selected_box.add_child(action_row)
	var action_label := Label.new()
	action_label.text = "Ação (opcional)"
	action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(action_label)
	_action_option = OptionButton.new()
	_action_option.focus_mode = Control.FOCUS_NONE
	_action_option.add_item("Sem ação", NO_ACTION)
	for row: Dictionary in GameData.get_rows("action_types"):
		_action_option.add_item(str(row.get("name", "")), int(row.get("id", 0)))
	_action_option.item_selected.connect(_on_action_changed)
	action_row.add_child(_action_option)

	var delete := Button.new()
	delete.text = "Apagar NPC  (Delete)"
	delete.theme_type_variation = &"DangerButton"
	delete.focus_mode = Control.FOCUS_NONE
	delete.pressed.connect(delete_selected)
	_selected_box.add_child(delete)
	refresh()


func set_draft(draft: IslandDraft) -> void:
	_draft = draft
	select(-1)


func select(index: int) -> void:
	if _draft == null or index >= _draft.npcs.size():
		index = -1
	if index != selected:
		marking = false
	selected = index
	refresh()
	selection_changed.emit(selected)


func refresh() -> void:
	for id: int in _npc_buttons:
		_npc_buttons[id].set_pressed_no_signal(id == npc_id)
	if _draft == null or selected < 0 or selected >= _draft.npcs.size():
		selected = -1
		marking = false
		_selected_box.visible = false
		return
	_selected_box.visible = true
	var npc: Dictionary = _draft.npcs[selected]
	var row := GameData.get_npc(int(npc.get("npc_id", 0)))
	var coord := _draft.npc_coord(selected)
	var walk := _draft.npc_tiles(selected).size() + 1
	_selected_label.text = "%s  ·  (%d, %d)  ·  passeio de %d hexágonos" % [row.get("name", "?"), coord.x, coord.y, walk]
	var still := bool(npc.get("still", false))
	_walk_button.set_pressed_no_signal(not still)
	_still_button.set_pressed_no_signal(still)
	_mark_button.disabled = still
	_mark_button.set_pressed_no_signal(marking and not still)
	var text := str(npc.get("dialogue", ""))
	if _dialogue.text != text:
		_dialogue.text = text
	var action: Variant = npc.get("action_type_id")
	var action_id := int(action) if action != null else NO_ACTION
	_action_option.select(maxi(0, _action_option.get_item_index(action_id)))


## Põe o NPC escolhido na lista no hexágono, como Passeia, e o escolhe.
func place(coord: Vector2i) -> EditorHistory.Step:
	if _draft == null or npc_id <= 0:
		return null
	var step := _step("Pôr NPC")
	_draft.npcs.append({"npc_id": npc_id, "q": coord.x, "r": coord.y, "still": false, "tiles": [], "dialogue": "", "action_type_id": null})
	step.npcs_after = _draft.npcs.duplicate(true)
	select(_draft.npcs.size() - 1)
	return step


## Põe ou tira o hexágono do passeio do NPC escolhido; o de nascimento não sai.
func toggle_walk_tile(coord: Vector2i) -> EditorHistory.Step:
	if _draft == null or selected < 0 or coord == _draft.npc_coord(selected):
		return null
	var step := _step("Passeio do NPC")
	var walk: Array = _draft.npcs[selected].get("tiles", [])
	var found := -1
	for spot: int in walk.size():
		if int(walk[spot].get("q", 0)) == coord.x and int(walk[spot].get("r", 0)) == coord.y:
			found = spot
	if found >= 0:
		walk.remove_at(found)
	else:
		walk.append({"q": coord.x, "r": coord.y})
	_draft.npcs[selected]["tiles"] = walk
	step.npcs_after = _draft.npcs.duplicate(true)
	refresh()
	return step


func delete_selected() -> void:
	if _draft == null or selected < 0:
		return
	var step := _step("Apagar NPC")
	_draft.npcs.remove_at(selected)
	step.npcs_after = _draft.npcs.duplicate(true)
	select(-1)
	edited.emit(step, false)


func _pick_npc(id: int) -> void:
	npc_id = id
	refresh()


func _set_still(on: bool) -> void:
	if _draft == null or selected < 0:
		return
	var step := _step("NPC parado" if on else "NPC passeia")
	_draft.npcs[selected]["still"] = on
	step.npcs_after = _draft.npcs.duplicate(true)
	if on:
		marking = false
	refresh()
	edited.emit(step, false)


func _on_dialogue_changed() -> void:
	if _draft == null or selected < 0 or str(_draft.npcs[selected].get("dialogue", "")) == _dialogue.text:
		return
	var step := _step(DIALOGUE_STEP)
	_draft.npcs[selected]["dialogue"] = _dialogue.text
	step.npcs_after = _draft.npcs.duplicate(true)
	edited.emit(step, true)


func _on_action_changed(item: int) -> void:
	if _draft == null or selected < 0:
		return
	var id := _action_option.get_item_id(item)
	var step := _step("Ação do NPC")
	if id == NO_ACTION:
		_draft.npcs[selected]["action_type_id"] = null
	else:
		_draft.npcs[selected]["action_type_id"] = id
	step.npcs_after = _draft.npcs.duplicate(true)
	edited.emit(step, false)


## O primeiro quadro parado, só a parte desenhada, ampliado em pixels inteiros.
static func _icon(slug: String) -> Texture2D:
	var frame := NpcSprite.first_frame(slug)
	if frame == null:
		return null
	var image := frame.get_image()
	var used := image.get_used_rect()
	if used.has_area():
		image = image.get_region(used)
	image.resize(image.get_width() * ICON_SCALE, image.get_height() * ICON_SCALE, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)


func _step(label: String) -> EditorHistory.Step:
	var step := EditorHistory.Step.new()
	step.label = label
	step.npcs_before = _draft.npcs.duplicate(true)
	return step
