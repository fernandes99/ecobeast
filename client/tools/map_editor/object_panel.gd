class_name ObjectPanel
extends VBoxContainer
## O bloco Peças do editor (island-villages/03, map-editor/05, free-props/03): a prévia
## grande com as variantes, os tipos de grade e os soltos e, com uma peça escolhida, a
## variante, o espelho, o bloqueio (só dos de grade) e apagar dela. A barra no mapa
## (ObjectBar) e as teclas chamam os mesmos métodos.

signal edited(step: EditorHistory.Step)
signal selection_changed(index: int)
signal blocks_editing_changed(on: bool)

const PREVIEW_SIZE := Vector2(0.0, 170.0)
const TYPE_ICON_WIDTH := 40
const CHIP_SIZE := Vector2(34.0, 30.0)

var type_id := 0
var prop_type_id := 0
## O tipo novo escolhido é solto (peça) e não de grade (objeto).
var placing_prop := false
var variant := 1
var mirrored := false
var selected := -1
var selected_prop := -1
var editing_blocks := false

var _draft: IslandDraft = null
var _types: Array[Dictionary] = []
var _prop_types: Array[Dictionary] = []
var _type_buttons: Dictionary[int, Button] = {}
var _prop_buttons: Dictionary[int, Button] = {}
var _preview: TextureRect
var _caption: Label
var _variant_label: Label
var _chips: HFlowContainer
var _chip_group := ButtonGroup.new()
var _mirror_button: Button
var _selected_box: VBoxContainer
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
	var frame := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = UiPalette.BACKGROUND_DEEP
	frame_style.set_corner_radius_all(8)
	frame_style.set_content_margin_all(8.0)
	frame.add_theme_stylebox_override(&"panel", frame_style)
	add_child(frame)
	_preview = TextureRect.new()
	_preview.custom_minimum_size = PREVIEW_SIZE
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(_preview)
	_caption = Label.new()
	_caption.theme_type_variation = &"BoldLabel"
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.clip_text = true
	add_child(_caption)

	var variant_row := HBoxContainer.new()
	variant_row.add_theme_constant_override(&"separation", 6)
	add_child(variant_row)
	variant_row.add_child(_icon_button("chevron_left", "Variante anterior (←)", change_variant.bind(-1)))
	_variant_label = Label.new()
	_variant_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_variant_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	variant_row.add_child(_variant_label)
	variant_row.add_child(_icon_button("chevron_right", "Próxima variante (→)", change_variant.bind(1)))
	_chips = HFlowContainer.new()
	_chips.add_theme_constant_override(&"h_separation", 4)
	_chips.add_theme_constant_override(&"v_separation", 4)
	add_child(_chips)

	_mirror_button = EditorTools.tool_button("Espelhar  (M)", null)
	_mirror_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mirror_button.icon = load(MapEditor.ICONS % "mirror") as Texture2D
	_mirror_button.add_theme_constant_override(&"icon_max_width", MapEditor.ICON_WIDTH)
	_mirror_button.toggled.connect(_on_mirror_toggled)
	add_child(_mirror_button)

	_selected_box = VBoxContainer.new()
	_selected_box.add_theme_constant_override(&"separation", 6)
	add_child(_selected_box)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 6)
	_selected_box.add_child(buttons)
	_blocks_button = EditorTools.tool_button("Editar bloqueio", null)
	_blocks_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_blocks_button.icon = load(MapEditor.ICONS % "lock") as Texture2D
	_blocks_button.add_theme_constant_override(&"icon_max_width", MapEditor.ICON_WIDTH)
	_blocks_button.tooltip_text = "O clique esquerdo num hexágono do objeto troca o bloqueio dele."
	_blocks_button.toggled.connect(_on_blocks_toggled)
	buttons.add_child(_blocks_button)
	var delete := Button.new()
	delete.text = "Apagar"
	delete.icon = load(MapEditor.ICONS % "trash") as Texture2D
	delete.add_theme_constant_override(&"icon_max_width", MapEditor.ICON_WIDTH)
	delete.tooltip_text = "Apagar a peça (Delete)"
	delete.theme_type_variation = &"DangerButton"
	delete.focus_mode = Control.FOCUS_NONE
	delete.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete.pressed.connect(delete_selected)
	buttons.add_child(delete)
	var release := Button.new()
	release.text = "Voltar à peça nova  (Esc)"
	release.focus_mode = Control.FOCUS_NONE
	release.pressed.connect(select.bind(-1))
	_selected_box.add_child(release)

	var group := ButtonGroup.new()
	var grid_title := Label.new()
	grid_title.text = "Na grade (bloqueiam)"
	EditorTools.section_title(grid_title)
	add_child(grid_title)
	for row: Dictionary in GameData.get_rows("map_object_types"):
		_types.append(row)
		var id := int(row.get("id", 0))
		var tiles := footprint(id, Vector2i.ZERO, false).size()
		var button := EditorTools.tool_button("%s  ·  %d %s" % [str(row.get("name", "")), tiles, "hexágono" if tiles == 1 else "hexágonos"], group)
		button.add_theme_constant_override(&"icon_max_width", TYPE_ICON_WIDTH)
		var path := MapObjectSprite.art_path(str(row.get("slug", "")), 1)
		if not path.is_empty():
			button.icon = MapObjectSprite.first_frame(load(path) as Texture2D, coords_of(footprint(id, Vector2i.ZERO, false)))
		button.pressed.connect(_pick_type.bind(id))
		add_child(button)
		_type_buttons[id] = button
	var loose_title := Label.new()
	loose_title.text = "Soltas (só enfeite)"
	EditorTools.section_title(loose_title)
	add_child(loose_title)
	for row: Dictionary in GameData.get_rows("prop_types"):
		_prop_types.append(row)
		var id := int(row.get("id", 0))
		var button := EditorTools.tool_button(str(row.get("name", "")), group)
		button.add_theme_constant_override(&"icon_max_width", TYPE_ICON_WIDTH)
		button.icon = PropArt.icon(str(row.get("slug", "")), 1)
		button.pressed.connect(pick_prop_type.bind(id))
		add_child(button)
		_prop_buttons[id] = button
	if not _types.is_empty():
		type_id = int(_types[0].get("id", 0))
	if not _prop_types.is_empty():
		prop_type_id = int(_prop_types[0].get("id", 0))
	refresh()


func set_draft(draft: IslandDraft) -> void:
	_draft = draft
	select(-1)


func select(index: int) -> void:
	if _draft == null or index >= _draft.objects.size():
		index = -1
	selected = index
	selected_prop = -1
	_set_editing_blocks(editing_blocks and selected >= 0)
	refresh()
	selection_changed.emit(selected)


func select_prop(index: int) -> void:
	if _draft == null or index >= _draft.props.size():
		index = -1
	selected = -1
	selected_prop = index
	_set_editing_blocks(false)
	refresh()
	selection_changed.emit(-1)


func refresh() -> void:
	if _draft == null or selected >= _draft.objects.size():
		selected = -1
	if _draft == null or selected_prop >= _draft.props.size():
		selected_prop = -1
	var prop := placing_prop
	var shown_type := prop_type_id if placing_prop else type_id
	var shown_variant := variant
	var shown_mirror := mirrored
	if selected >= 0:
		var object: Dictionary = _draft.objects[selected]
		prop = false
		shown_type = int(object.get("object_type_id", 0))
		shown_variant = int(object.get("variant", 1))
		shown_mirror = bool(object.get("mirrored", false))
	elif selected_prop >= 0:
		var piece: Dictionary = _draft.props[selected_prop]
		prop = true
		shown_type = int(piece.get("prop_type_id", 0))
		shown_variant = int(piece.get("variant", 1))
		shown_mirror = bool(piece.get("mirrored", false))
	for id: int in _type_buttons:
		_type_buttons[id].set_pressed_no_signal(not prop and id == shown_type)
	for id: int in _prop_buttons:
		_prop_buttons[id].set_pressed_no_signal(prop and id == shown_type)
	var count := _variants(shown_type, prop)
	if prop:
		_preview.texture = PropArt.icon(_slug(shown_type, true), shown_variant)
	else:
		var path := MapObjectSprite.art_path(_slug(shown_type, false), shown_variant)
		var art: Texture2D = load(path) as Texture2D if not path.is_empty() else null
		_preview.texture = MapObjectSprite.first_frame(art, coords_of(footprint(shown_type, Vector2i.ZERO, false))) if art != null else null
	_preview.flip_h = shown_mirror
	var chosen := selected >= 0 or selected_prop >= 0
	_caption.text = ("Escolhida: %s" if chosen else "Nova: %s") % _type_name(shown_type, prop)
	_variant_label.text = "Variante %d de %d" % [shown_variant, count]
	_rebuild_chips(count, shown_variant)
	_mirror_button.set_pressed_no_signal(shown_mirror)
	_selected_box.visible = chosen
	_blocks_button.visible = selected >= 0
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


## A peça solta nova, com o pé `offset` pixels da arte a partir do centro de `coord`.
func new_prop(coord: Vector2i, offset: Vector2i) -> Dictionary:
	return {
		"prop_type_id": prop_type_id,
		"q": coord.x,
		"r": coord.y,
		"dx": offset.x,
		"dy": offset.y,
		"variant": variant,
		"mirrored": mirrored,
	}


func change_variant(delta: int) -> void:
	var piece := _selected_piece()
	if piece.is_empty():
		set_variant(wrapi(variant - 1 + delta, 0, _variants(prop_type_id if placing_prop else type_id, placing_prop)) + 1)
		return
	var count := _variants(_piece_type(piece), selected_prop >= 0)
	set_variant(wrapi(int(piece.get("variant", 1)) - 1 + delta, 0, count) + 1)


func set_variant(value: int) -> void:
	var piece := _selected_piece()
	if piece.is_empty():
		variant = value
		refresh()
		return
	if int(piece.get("variant", 1)) == value:
		return
	var step := _step("Trocar a variante")
	piece["variant"] = value
	_finish(step)


func toggle_mirror() -> void:
	_on_mirror_toggled(not _mirror_button.button_pressed)


func toggle_blocks() -> void:
	_on_blocks_toggled(not editing_blocks)


func delete_selected() -> void:
	if _draft == null or (selected < 0 and selected_prop < 0):
		return
	var step := _step("Apagar peça")
	if selected >= 0:
		_draft.objects.remove_at(selected)
		select(-1)
	else:
		_draft.props.remove_at(selected_prop)
		select_prop(-1)
	_finish(step)


func variant_text() -> String:
	var piece := _selected_piece()
	if piece.is_empty():
		return ""
	return "%d / %d" % [int(piece.get("variant", 1)), _variants(_piece_type(piece), selected_prop >= 0)]


func is_mirrored() -> bool:
	return _mirror_button.button_pressed


func pick_prop_type(id: int) -> void:
	placing_prop = true
	prop_type_id = id
	variant = 1
	select(-1)


func _pick_type(id: int) -> void:
	placing_prop = false
	type_id = id
	variant = 1
	select(-1)


func _selected_piece() -> Dictionary:
	if _draft == null:
		return {}
	if selected >= 0:
		return _draft.objects[selected]
	if selected_prop >= 0:
		return _draft.props[selected_prop]
	return {}


func _piece_type(piece: Dictionary) -> int:
	return int(piece.get("prop_type_id", piece.get("object_type_id", 0)))


func _on_mirror_toggled(on: bool) -> void:
	if selected_prop >= 0:
		var prop_step := _step("Espelhar peça")
		_draft.props[selected_prop]["mirrored"] = on
		_finish(prop_step)
		return
	if selected < 0:
		mirrored = on
		refresh()
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


func _rebuild_chips(count: int, current: int) -> void:
	if _chips.get_child_count() != count:
		for chip: Node in _chips.get_children():
			chip.queue_free()
			_chips.remove_child(chip)
		for value: int in range(1, count + 1):
			var chip := EditorTools.tool_button(str(value), _chip_group)
			chip.alignment = HORIZONTAL_ALIGNMENT_CENTER
			chip.custom_minimum_size = CHIP_SIZE
			chip.size_flags_horizontal = Control.SIZE_FILL
			chip.pressed.connect(set_variant.bind(value))
			_chips.add_child(chip)
	for index: int in _chips.get_child_count():
		(_chips.get_child(index) as Button).set_pressed_no_signal(index + 1 == current)


func _step(label: String) -> EditorHistory.Step:
	var step := EditorHistory.Step.new()
	step.label = label
	step.objects_before = _draft.objects.duplicate(true)
	step.props_before = _draft.props.duplicate(true)
	return step


func _finish(step: EditorHistory.Step) -> void:
	step.objects_after = _draft.objects.duplicate(true)
	step.props_after = _draft.props.duplicate(true)
	refresh()
	edited.emit(step)


func _row(id: int, prop: bool) -> Dictionary:
	for row: Dictionary in (_prop_types if prop else _types):
		if int(row.get("id", 0)) == id:
			return row
	return {}


func _variants(id: int, prop: bool) -> int:
	return maxi(1, int(_row(id, prop).get("variants", 1)))


func _type_name(id: int, prop: bool) -> String:
	return str(_row(id, prop).get("name", "?"))


func _slug(id: int, prop: bool) -> String:
	return str(_row(id, prop).get("slug", ""))


func _icon_button(icon_name: String, tip: String, action: Callable) -> Button:
	var button := Button.new()
	button.icon = load(MapEditor.ICONS % icon_name) as Texture2D
	button.add_theme_constant_override(&"icon_max_width", MapEditor.ICON_WIDTH)
	button.tooltip_text = tip
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button
