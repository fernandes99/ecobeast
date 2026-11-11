class_name AreaPanel
extends VBoxContainer

signal edited(step: EditorHistory.Step, merge: bool)
signal delete_requested(key: int, area_name: String)
signal selection_changed(key: int)

const DEFAULT_WEIGHT := 10
const DEFAULT_MIN_LEVEL := 2
const DEFAULT_MAX_LEVEL := 5
const MAX_LEVEL := 100
const MAX_WEIGHT := 1000
const NUMBER_WIDTH := 52.0
const MAX_RESULTS := 6
const MIN_SPAWNS := 1
const MAX_SPAWNS := 200
const DEFAULT_SPAWNS := 10

var selected_key := 0

var _draft: IslandDraft = null
var _list: ItemList
var _keys: Array[int] = []
var _selected_box: VBoxContainer
var _name_edit: LineEdit
var _color_button: Button
var _color_popup: PopupPanel
var _spawn_field: EditorNumberField
var _count_label: Label
var _species_box: VBoxContainer
var _search: LineEdit
var _results: ItemList
var _result_ids: Array[int] = []


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	_list = ItemList.new()
	_list.custom_minimum_size.y = 96.0
	_list.auto_height = true
	_list.focus_mode = Control.FOCUS_NONE
	_list.item_selected.connect(func(index: int) -> void: select(_keys[index]))
	add_child(_list)
	var new_button := Button.new()
	new_button.text = "Nova área"
	new_button.focus_mode = Control.FOCUS_NONE
	new_button.pressed.connect(_new_area)
	add_child(new_button)

	_selected_box = VBoxContainer.new()
	_selected_box.add_theme_constant_override(&"separation", 6)
	add_child(_selected_box)
	_selected_box.add_child(HSeparator.new())
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override(&"separation", 6)
	_selected_box.add_child(name_row)
	_name_edit = LineEdit.new()
	_name_edit.max_length = 40
	_name_edit.placeholder_text = "Nome da área"
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.text_changed.connect(_on_name_changed)
	name_row.add_child(_name_edit)
	_color_button = Button.new()
	_color_button.focus_mode = Control.FOCUS_NONE
	_color_button.tooltip_text = "Cor da área no editor"
	_color_button.custom_minimum_size = Vector2(44.0, 0.0)
	_color_button.pressed.connect(_open_colors)
	name_row.add_child(_color_button)
	_color_popup = PopupPanel.new()
	var colors := GridContainer.new()
	colors.columns = 4
	_color_popup.add_child(colors)
	for color: Color in UiPalette.MAP_AREA_COLORS:
		var choice := Button.new()
		choice.icon = ActionPanel.color_chip(color, Vector2i(28, 28))
		choice.focus_mode = Control.FOCUS_NONE
		choice.pressed.connect(func() -> void:
			_color_popup.hide()
			_on_color_changed(color))
		colors.add_child(choice)
	add_child(_color_popup)
	var spawn_row := HBoxContainer.new()
	spawn_row.add_theme_constant_override(&"separation", 6)
	_selected_box.add_child(spawn_row)
	var spawn_caption := Label.new()
	spawn_caption.text = "Ecobeasts nesta área"
	spawn_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spawn_row.add_child(spawn_caption)
	_spawn_field = EditorNumberField.new(MIN_SPAWNS, MAX_SPAWNS, true, false)
	_spawn_field.set_field_width(NUMBER_WIDTH)
	_spawn_field.tooltip_text = "Quantos Ecobeasts nascem nela a cada entrada na ilha, de %d a %d" % [MIN_SPAWNS, MAX_SPAWNS]
	_spawn_field.changed.connect(_on_spawn_count_changed)
	spawn_row.add_child(_spawn_field)
	_count_label = Label.new()
	_count_label.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	_selected_box.add_child(_count_label)

	_species_box = VBoxContainer.new()
	_species_box.add_theme_constant_override(&"separation", 4)
	_selected_box.add_child(_species_box)

	_search = LineEdit.new()
	_search.placeholder_text = "Adicionar espécie: escreva o nome"
	_search.text_changed.connect(_on_search)
	_selected_box.add_child(_search)
	_results = ItemList.new()
	_results.auto_height = true
	_results.visible = false
	_results.item_activated.connect(_add_result)
	_results.item_clicked.connect(func(index: int, _at: Vector2, _button: int) -> void: _add_result(index))
	_selected_box.add_child(_results)

	var delete := Button.new()
	delete.text = "Apagar área"
	delete.theme_type_variation = &"DangerButton"
	delete.focus_mode = Control.FOCUS_NONE
	delete.pressed.connect(func() -> void:
		var area := _selected_area()
		if not area.is_empty():
			delete_requested.emit(selected_key, str(area.get("name", ""))))
	_selected_box.add_child(delete)
	refresh()


func set_draft(draft: IslandDraft) -> void:
	_draft = draft
	selected_key = 0
	if draft != null and not draft.areas.is_empty():
		selected_key = int(draft.areas[0].get("key", 0))
	refresh()
	selection_changed.emit(selected_key)


func select(key: int) -> void:
	selected_key = key
	refresh()
	selection_changed.emit(selected_key)


func refresh() -> void:
	_list.clear()
	_keys.clear()
	if _draft == null:
		_selected_box.visible = false
		return
	if _draft.area_by_key(selected_key).is_empty():
		selected_key = 0
	var counts := _draft.area_tile_counts()
	for area: Variant in _draft.areas:
		var key := int((area as Dictionary).get("key", 0))
		var empty := (area.get("species", []) as Array).is_empty()
		var color := Color.from_string(str(area.get("color_hex", "")), UiPalette.TEXT)
		var text := "%s  ·  %d hex%s" % [str(area.get("name", "")), counts.get(key, 0), "  ·  sem espécies" if empty else ""]
		var index := _list.add_item(text, ActionPanel.color_chip(color))
		_keys.append(key)
		if key == selected_key:
			_list.select(index)
	var area := _selected_area()
	_selected_box.visible = not area.is_empty()
	if area.is_empty():
		return
	if _name_edit.text != str(area.get("name", "")):
		_name_edit.text = str(area.get("name", ""))
	_paint_color_button(Color.from_string(str(area.get("color_hex", "")), UiPalette.TEXT))
	var spawn_count := int(area.get("spawn_count", DEFAULT_SPAWNS))
	if is_nan(_spawn_field.value()) or int(_spawn_field.value()) != spawn_count:
		_spawn_field.set_value(spawn_count)
	_spawn_field.mark_invalid(false)
	var species: Array = area.get("species", [])
	_count_label.text = "%d hexágonos  ·  %d espécies%s" % [counts.get(selected_key, 0), species.size(), "  ·  falta pôr espécies" if species.is_empty() else ""]
	_count_label.add_theme_color_override(&"font_color", UiPalette.WARNING if species.is_empty() else UiPalette.TEXT_SECONDARY)
	_rebuild_species(species)


func delete_area(key: int) -> void:
	if _draft == null or _draft.area_by_key(key).is_empty():
		return
	var step := _step("Apagar área")
	for coord: Vector2i in _draft.tile_areas.keys():
		if _draft.tile_areas[coord] == key:
			step.before[coord] = _draft.snapshot(coord)
			_draft.tile_areas.erase(coord)
			step.after[coord] = _draft.snapshot(coord)
	_draft.areas.erase(_draft.area_by_key(key))
	step.areas_after = _draft.areas.duplicate(true)
	select(0)
	edited.emit(step, false)


func _new_area() -> void:
	if _draft == null:
		return
	var step := _step("Nova área")
	var key := _draft.next_area_key()
	var colors := UiPalette.MAP_AREA_COLORS
	var color: Color = colors[(key - 1) % colors.size()]
	_draft.areas.append({"key": key, "name": "Área %d" % key, "color_hex": "#" + color.to_html(false), "spawn_count": DEFAULT_SPAWNS, "species": []})
	step.areas_after = _draft.areas.duplicate(true)
	select(key)
	edited.emit(step, false)


func _on_name_changed(text: String) -> void:
	var area := _selected_area()
	if area.is_empty() or text.strip_edges().is_empty():
		return
	var step := _step("Nome da área %d" % selected_key)
	area["name"] = text.strip_edges()
	step.areas_after = _draft.areas.duplicate(true)
	_refresh_list_only()
	edited.emit(step, true)


func _on_color_changed(color: Color) -> void:
	var area := _selected_area()
	if area.is_empty():
		return
	var step := _step("Cor da área %d" % selected_key)
	area["color_hex"] = "#" + color.to_html(false)
	step.areas_after = _draft.areas.duplicate(true)
	_refresh_list_only()
	edited.emit(step, true)


func _paint_color_button(color: Color) -> void:
	for state: StringName in [&"normal", &"hover", &"pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(8)
		style.border_color = UiPalette.TEXT if state == &"hover" else UiPalette.BORDER
		style.set_border_width_all(2)
		_color_button.add_theme_stylebox_override(state, style)


func _open_colors() -> void:
	var at := _color_button.get_screen_position() + Vector2(0.0, _color_button.size.y + 4.0)
	_color_popup.popup(Rect2i(Vector2i(at), Vector2i.ZERO))


func _on_search(text: String) -> void:
	_results.clear()
	_result_ids.clear()
	var query := text.strip_edges().to_lower()
	var area := _selected_area()
	if query.is_empty() or area.is_empty():
		_results.visible = false
		return
	var taken: Array[int] = []
	for entry: Variant in area.get("species", []):
		taken.append(int(entry.get("species_id", 0)))
	for row: Dictionary in GameData.get_rows("species"):
		var id := int(row.get("id", 0))
		var species_name := str(row.get("name", ""))
		if taken.has(id) or not species_name.to_lower().contains(query):
			continue
		_results.add_item("#%03d  %s" % [id, species_name])
		_result_ids.append(id)
		if _result_ids.size() >= MAX_RESULTS:
			break
	_results.visible = not _result_ids.is_empty()


func _add_result(index: int) -> void:
	var area := _selected_area()
	if area.is_empty() or index < 0 or index >= _result_ids.size():
		return
	var step := _step("Adicionar espécie")
	(area["species"] as Array).append({
		"species_id": _result_ids[index],
		"weight": DEFAULT_WEIGHT,
		"min_level": DEFAULT_MIN_LEVEL,
		"max_level": DEFAULT_MAX_LEVEL,
	})
	step.areas_after = _draft.areas.duplicate(true)
	_search.text = ""
	_results.visible = false
	refresh()
	edited.emit(step, false)


func _remove_species(species_id: int) -> void:
	var area := _selected_area()
	if area.is_empty():
		return
	var step := _step("Tirar espécie")
	var species: Array = area["species"]
	for index: int in range(species.size() - 1, -1, -1):
		if int(species[index].get("species_id", 0)) == species_id:
			species.remove_at(index)
	step.areas_after = _draft.areas.duplicate(true)
	refresh()
	edited.emit(step, false)


func _on_spawn_count_changed() -> void:
	var value := _spawn_field.value()
	_spawn_field.mark_invalid(is_nan(value))
	var area := _selected_area()
	if is_nan(value) or area.is_empty() or int(area.get("spawn_count", DEFAULT_SPAWNS)) == int(value):
		return
	var step := _step("Ecobeasts da área %d" % selected_key)
	area["spawn_count"] = int(value)
	step.areas_after = _draft.areas.duplicate(true)
	edited.emit(step, true)


func _on_species_number(field: EditorNumberField, species_id: int, key: String) -> void:
	var value := field.value()
	field.mark_invalid(is_nan(value))
	var area := _selected_area()
	if is_nan(value) or area.is_empty():
		return
	for entry: Variant in area.get("species", []):
		if int(entry.get("species_id", 0)) != species_id or int(entry.get(key, 0)) == int(value):
			continue
		var step := _step("Espécie %d: %s" % [species_id, key])
		entry[key] = int(value)
		step.areas_after = _draft.areas.duplicate(true)
		edited.emit(step, true)


func _rebuild_species(species: Array) -> void:
	for child: Node in _species_box.get_children():
		_species_box.remove_child(child)
		child.queue_free()
	for entry: Variant in species:
		var species_id := int(entry.get("species_id", 0))
		var card := PanelContainer.new()
		card.theme_type_variation = &"SectionPanel"
		_species_box.add_child(card)
		var lines := VBoxContainer.new()
		lines.add_theme_constant_override(&"separation", 4)
		card.add_child(lines)
		var top := HBoxContainer.new()
		lines.add_child(top)
		var label := Label.new()
		label.text = _species_name(species_id)
		label.clip_text = true
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(label)
		var remove := Button.new()
		remove.flat = true
		remove.text = "×"
		remove.tooltip_text = "Tirar a espécie da área"
		remove.focus_mode = Control.FOCUS_NONE
		remove.add_theme_color_override(&"font_color", UiPalette.DANGER)
		remove.pressed.connect(_remove_species.bind(species_id))
		top.add_child(remove)
		var numbers := HBoxContainer.new()
		numbers.add_theme_constant_override(&"separation", 6)
		lines.add_child(numbers)
		for key: String in ["weight", "min_level", "max_level"]:
			var caption := Label.new()
			caption.text = {"weight": "Peso", "min_level": "Nível", "max_level": "a"}[key]
			caption.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
			numbers.add_child(caption)
			var field := EditorNumberField.new(1, MAX_WEIGHT if key == "weight" else MAX_LEVEL, true, false)
			field.set_field_width(NUMBER_WIDTH)
			field.set_value(int(entry.get(key, 1)))
			field.changed.connect(_on_species_number.bind(field, species_id, key))
			numbers.add_child(field)


func _refresh_list_only() -> void:
	var counts := _draft.area_tile_counts()
	for index: int in _keys.size():
		var area := _draft.area_by_key(_keys[index])
		var empty := (area.get("species", []) as Array).is_empty()
		_list.set_item_text(index, "%s  ·  %d hex%s" % [str(area.get("name", "")), counts.get(_keys[index], 0), "  ·  sem espécies" if empty else ""])
		_list.set_item_icon(index, ActionPanel.color_chip(Color.from_string(str(area.get("color_hex", "")), UiPalette.TEXT)))


func _selected_area() -> Dictionary:
	return _draft.area_by_key(selected_key) if _draft != null else {}


func _step(label: String) -> EditorHistory.Step:
	var step := EditorHistory.Step.new()
	step.label = label
	step.areas_before = _draft.areas.duplicate(true)
	return step


func _species_name(species_id: int) -> String:
	for row: Dictionary in GameData.get_rows("species"):
		if int(row.get("id", 0)) == species_id:
			return "#%03d  %s" % [species_id, str(row.get("name", ""))]
	return "#%03d" % species_id
