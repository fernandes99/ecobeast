class_name ObjectPanel
extends VBoxContainer
## O bloco Objeto do editor (island-villages/03): o tipo, a variante e o espelho do
## objeto novo e, com um objeto escolhido, a variante, o espelho, o bloqueio e apagar.

signal edited(step: EditorHistory.Step)
signal selection_changed(index: int)
signal blocks_editing_changed(on: bool)

const COLUMNS := 3
const ICON_SIZE := Vector2(72.0, 72.0)

var type_id := 0
var variant := 1
var mirrored := false
var selected := -1
var editing_blocks := false

var _draft: IslandDraft = null
var _types: Array[Dictionary] = []
var _type_buttons: Dictionary[int, Button] = {}
var _variant_label: Label
var _mirror_button: Button
var _selected_box: VBoxContainer
var _selected_label: Label
var _blocks_button: Button


static func footprint(object_type_id: int, anchor: Vector2i, flip: bool) -> Array[Dictionary]:
	var tiles: Array[Dictionary] = []
	for row: Dictionary in GameData.get_rows("map_object_type_tiles"):
		if int(row.get("object_type_id", 0)) != object_type_id:
			continue
		var offset := Vector2i(int(row.get("dq", 0)), int(row.get("dr", 0)))
		tiles.append({"q": (anchor + mirror(offset, flip)).x, "r": (anchor + mirror(offset, flip)).y, "blocks": bool(row.get("blocks", true))})
	return tiles


## Espelhar na vertical, em coordenadas axiais: (dq, dr) vira (-dq - dr, dr).
static func mirror(offset: Vector2i, flip: bool) -> Vector2i:
	return Vector2i(-offset.x - offset.y, offset.y) if flip else offset


static func coords_of(tiles: Array) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for at: Variant in tiles:
		coords.append(Vector2i(int(at.get("q", 0)), int(at.get("r", 0))))
	return coords


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override(&"h_separation", 4)
	grid.add_theme_constant_override(&"v_separation", 4)
	add_child(grid)
	var group := ButtonGroup.new()
	for row: Dictionary in GameData.get_rows("map_object_types"):
		_types.append(row)
		var id := int(row.get("id", 0))
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.text = str(row.get("name", ""))
		button.tooltip_text = button.text
		button.clip_text = true
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.custom_minimum_size = ICON_SIZE + Vector2(0.0, 22.0)
		button.add_theme_font_size_override(&"font_size", 12)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var path := MapObjectSprite.art_path(str(row.get("slug", "")), 1)
		if not path.is_empty():
			button.icon = load(path) as Texture2D
		button.pressed.connect(_pick_type.bind(id))
		grid.add_child(button)
		_type_buttons[id] = button
	if not _types.is_empty():
		type_id = int(_types[0].get("id", 0))

	var variant_row := HBoxContainer.new()
	variant_row.add_theme_constant_override(&"separation", 6)
	add_child(variant_row)
	var variant_title := Label.new()
	variant_title.text = "Variante"
	variant_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	variant_row.add_child(variant_title)
	variant_row.add_child(_small_button("<", _change_variant.bind(-1)))
	_variant_label = Label.new()
	_variant_label.theme_type_variation = &"BoldLabel"
	_variant_label.custom_minimum_size.x = 48.0
	_variant_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	variant_row.add_child(_variant_label)
	variant_row.add_child(_small_button(">", _change_variant.bind(1)))
	_mirror_button = EditorTools.tool_button("Espelhar", null)
	_mirror_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mirror_button.toggled.connect(_on_mirror_toggled)
	add_child(_mirror_button)

	_selected_box = VBoxContainer.new()
	_selected_box.add_theme_constant_override(&"separation", 6)
	add_child(_selected_box)
	_selected_box.add_child(HSeparator.new())
	_selected_label = Label.new()
	_selected_label.theme_type_variation = &"BoldLabel"
	_selected_box.add_child(_selected_label)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 6)
	_selected_box.add_child(buttons)
	_blocks_button = EditorTools.tool_button("Editar bloqueio", null)
	_blocks_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_blocks_button.tooltip_text = "O clique esquerdo num hexágono do objeto troca o bloqueio dele."
	_blocks_button.toggled.connect(_on_blocks_toggled)
	buttons.add_child(_blocks_button)
	var delete := Button.new()
	delete.text = "Apagar"
	delete.theme_type_variation = &"DangerButton"
	delete.focus_mode = Control.FOCUS_NONE
	delete.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete.pressed.connect(_delete_selected)
	buttons.add_child(delete)
	refresh()


func set_draft(draft: IslandDraft) -> void:
	_draft = draft
	select(-1)


func select(index: int) -> void:
	if _draft == null or index >= _draft.objects.size():
		index = -1
	selected = index
	_set_editing_blocks(editing_blocks and selected >= 0)
	refresh()
	selection_changed.emit(selected)


func refresh() -> void:
	for id: int in _type_buttons:
		_type_buttons[id].set_pressed_no_signal(id == type_id)
	if _draft == null or selected < 0 or selected >= _draft.objects.size():
		selected = -1
		_selected_box.visible = false
		_variant_label.text = "%d / %d" % [variant, _variants(type_id)]
		_mirror_button.set_pressed_no_signal(mirrored)
		return
	_selected_box.visible = true
	var object: Dictionary = _draft.objects[selected]
	var id := int(object.get("object_type_id", 0))
	_selected_label.text = "%s  ·  %d hexágonos" % [_type_name(id), (object.get("tiles", []) as Array).size()]
	_variant_label.text = "%d / %d" % [int(object.get("variant", 1)), _variants(id)]
	_mirror_button.set_pressed_no_signal(bool(object.get("mirrored", false)))
	_blocks_button.set_pressed_no_signal(editing_blocks)


## O objeto novo num hexágono de apoio, com o bloqueio padrão do tipo.
func new_object(anchor: Vector2i) -> Dictionary:
	return {
		"object_type_id": type_id,
		"q": anchor.x,
		"r": anchor.y,
		"variant": variant,
		"mirrored": mirrored,
		"tiles": footprint(type_id, anchor, mirrored),
	}


func _pick_type(id: int) -> void:
	type_id = id
	variant = 1
	select(-1)


func _change_variant(delta: int) -> void:
	if selected < 0:
		variant = wrapi(variant - 1 + delta, 0, _variants(type_id)) + 1
		refresh()
		return
	var object: Dictionary = _draft.objects[selected]
	var count := _variants(int(object.get("object_type_id", 0)))
	var step := _step("Trocar a variante")
	object["variant"] = wrapi(int(object.get("variant", 1)) - 1 + delta, 0, count) + 1
	_finish(step)


func _on_mirror_toggled(on: bool) -> void:
	if selected < 0:
		mirrored = on
		return
	var object: Dictionary = _draft.objects[selected]
	var anchor := Vector2i(int(object.get("q", 0)), int(object.get("r", 0)))
	var flipped: Array[Dictionary] = []
	for at: Variant in object.get("tiles", []):
		var offset := Vector2i(int(at.get("q", 0)), int(at.get("r", 0))) - anchor
		var coord := anchor + mirror(offset, true)
		flipped.append({"q": coord.x, "r": coord.y, "blocks": bool(at.get("blocks", true))})
	if not _draft.object_fits(coords_of(flipped), selected):
		_mirror_button.set_pressed_no_signal(not on)
		return
	var step := _step("Espelhar objeto")
	object["mirrored"] = on
	object["tiles"] = flipped
	_finish(step)


func _on_blocks_toggled(on: bool) -> void:
	_set_editing_blocks(on and selected >= 0)
	refresh()


func _set_editing_blocks(on: bool) -> void:
	if editing_blocks == on:
		return
	editing_blocks = on
	blocks_editing_changed.emit(on)


func _delete_selected() -> void:
	if _draft == null or selected < 0:
		return
	var step := _step("Apagar objeto")
	_draft.objects.remove_at(selected)
	select(-1)
	_finish(step)


func _step(label: String) -> EditorHistory.Step:
	var step := EditorHistory.Step.new()
	step.label = label
	step.objects_before = _draft.objects.duplicate(true)
	return step


func _finish(step: EditorHistory.Step) -> void:
	step.objects_after = _draft.objects.duplicate(true)
	refresh()
	edited.emit(step)


func _variants(id: int) -> int:
	for row: Dictionary in _types:
		if int(row.get("id", 0)) == id:
			return maxi(1, int(row.get("variants", 1)))
	return 1


func _type_name(id: int) -> String:
	for row: Dictionary in _types:
		if int(row.get("id", 0)) == id:
			return str(row.get("name", ""))
	return "?"


func _small_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(32.0, 0.0)
	button.pressed.connect(action)
	return button
