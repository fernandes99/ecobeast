class_name TamerEditor
extends VBoxContainer

## O nome (só quando falta) e as abas da aparência: o corpo, a pele e cada peça com a
## sua cor (liora-intro/03). A tela Aparência e a criação por cima do mapa usam este
## componente, cada uma com a sua prévia.

signal changed(appearance: TamerAppearance)
signal name_changed

const BODY_TAB := 0
const SWATCH_SIZE := Vector2(72, 72)
const SWATCH_COLUMNS := 6
const OPTION_COLUMNS := 2
const OPTION_HEIGHT := 72.0
const SELECTED_BORDER := 6
const TABS_HEIGHT := 80.0
const NAME_HINT := "De 2 a 16 letras ou números."
const NAME_PLACEHOLDER := "Nome do Domador"

var draft := TamerAppearance.standard()
var _slots: Array[Dictionary] = []
## 0 é Corpo; os outros são o índice + 1 em `_slots`.
var _tab: int = BODY_TAB
var _name_box := VBoxContainer.new()
var _name_edit := LineEdit.new()
var _name_hint := Label.new()
var _tabs_scroll := ScrollContainer.new()
var _tabs := HBoxContainer.new()
var _options := VBoxContainer.new()


func _init() -> void:
	add_theme_constant_override(&"separation", 12)
	_name_box.add_theme_constant_override(&"separation", 4)
	add_child(_name_box)
	_name_edit.placeholder_text = NAME_PLACEHOLDER
	_name_edit.max_length = 16
	_name_edit.custom_minimum_size.y = OPTION_HEIGHT
	_name_edit.text_changed.connect(func(_text: String) -> void:
		_update_name_hint()
		name_changed.emit())
	_name_box.add_child(_name_edit)
	_name_hint.text = NAME_HINT
	_name_hint.theme_type_variation = &"SecondaryLabel"
	_name_box.add_child(_name_hint)
	_name_box.visible = false

	_tabs_scroll.custom_minimum_size.y = TABS_HEIGHT
	_tabs_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_tabs_scroll)
	_tabs.add_theme_constant_override(&"separation", 8)
	_tabs_scroll.add_child(_tabs)
	var options_scroll := ScrollContainer.new()
	options_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	options_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(options_scroll)
	_options.size_flags_horizontal = SIZE_EXPAND_FILL
	_options.add_theme_constant_override(&"separation", 12)
	options_scroll.add_child(_options)


## Começa a editar uma cópia da aparência; com `ask_name`, mostra o campo de nome.
func open(appearance: TamerAppearance, ask_name: bool) -> void:
	draft = appearance.duplicate_appearance()
	_name_box.visible = ask_name
	_slots = GameData.get_rows("appearance_slots").duplicate()
	_slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["layer"] < b["layer"])
	for child: Node in _tabs.get_children():
		child.queue_free()
	var names: Array[String] = ["Corpo"]
	for slot: Dictionary in _slots:
		names.append(slot["name"])
	for index: int in names.size():
		var button := Button.new()
		button.text = names[index]
		button.custom_minimum_size.y = OPTION_HEIGHT
		button.pressed.connect(_select_tab.bind(index))
		_tabs.add_child(button)
	_tab = BODY_TAB
	_update_name_hint()
	_refresh()


func asks_name() -> bool:
	return _name_box.visible


## O nome digitado, normalizado.
func tamer_name() -> String:
	return Player.normalize_name(_name_edit.text)


## Pronto para gravar: sem pedir nome, sempre; pedindo, só com o nome válido.
func is_ready() -> bool:
	return not asks_name() or Player.is_valid_name(tamer_name())


func _update_name_hint() -> void:
	var typed := tamer_name()
	_name_hint.theme_type_variation = &"DangerLabel" if not typed.is_empty() and not Player.is_valid_name(typed) else &"SecondaryLabel"


func _select_tab(index: int) -> void:
	_tab = index
	_refresh()


func _refresh() -> void:
	draft.parts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _layer_of(a["part_id"]) < _layer_of(b["part_id"]))
	for index: int in _tabs.get_child_count():
		(_tabs.get_child(index) as Button).theme_type_variation = &"" if index == _tab else &"OutlineButton"
	if _tab < _tabs.get_child_count():
		_tabs_scroll.ensure_control_visible.call_deferred(_tabs.get_child(_tab))
	for child: Node in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
	if _tab == BODY_TAB:
		_build_body_options()
	else:
		_build_slot_options(_slots[_tab - 1])
	changed.emit(draft)


func _build_body_options() -> void:
	var bodies: Array[Dictionary] = []
	for body: Dictionary in GameData.get_rows("body_types"):
		bodies.append({"label": body["name"], "selected": body["id"] == draft.body_type_id, "action": _choose_body.bind(body["id"])})
	_add_section("Corpo", _option_grid(bodies))
	_add_section("Pele", _swatch_grid("skin", draft.skin_palette_id, _choose_skin))


func _build_slot_options(slot: Dictionary) -> void:
	var worn := _worn(slot["id"])
	var options: Array[Dictionary] = []
	if not slot["required"]:
		options.append({"label": "Nenhum", "selected": worn.is_empty(), "action": _take_off.bind(slot["id"])})
	for part: Dictionary in _parts_of(slot["id"]):
		options.append({"label": part["name"], "selected": worn.get("part_id", -1) == part["id"], "action": _wear.bind(part)})
	_add_section(slot["name"], _option_grid(options))
	var kind: Variant = slot["palette_kind"]
	if kind != null and not worn.is_empty():
		var slot_id: int = slot["id"]
		var choose := func(palette_id: int) -> void: _choose_color(palette_id, slot_id)
		_add_section("Cor", _swatch_grid(kind, worn["palette_id"], choose))


func _add_section(title: String, content: Control) -> void:
	var label := Label.new()
	label.text = title
	label.theme_type_variation = &"BoldLabel"
	_options.add_child(label)
	_options.add_child(content)


func _option_grid(options: Array[Dictionary]) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = OPTION_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for option: Dictionary in options:
		var button := Button.new()
		button.text = option["label"]
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.custom_minimum_size.y = OPTION_HEIGHT
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.theme_type_variation = &"" if option["selected"] else &"OutlineButton"
		button.pressed.connect(option["action"])
		grid.add_child(button)
	return grid


func _swatch_grid(kind: String, selected_id: int, choose: Callable) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = SWATCH_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for palette: Dictionary in _palettes_of(kind):
		var swatch := Button.new()
		swatch.custom_minimum_size = SWATCH_SIZE
		swatch.tooltip_text = palette["name"]
		var style := StyleBoxFlat.new()
		style.bg_color = Color.html(palette["color2_hex"])
		style.set_corner_radius_all(12)
		if palette["id"] == selected_id:
			style.set_border_width_all(SELECTED_BORDER)
			style.border_color = UiPalette.TEXT
		for state: StringName in [&"normal", &"hover", &"pressed", &"focus"]:
			swatch.add_theme_stylebox_override(state, style)
		swatch.pressed.connect(choose.bind(palette["id"]))
		grid.add_child(swatch)
	return grid


# --- escolhas ----------------------------------------------------------------

func _choose_body(body_id: int) -> void:
	draft.body_type_id = body_id
	draft.parts.assign(draft.parts.filter(func(part: Dictionary) -> bool: return _fits(GameData.get_row("appearance_parts", part["part_id"]))))
	for slot: Dictionary in _slots:
		if slot["required"] and _worn(slot["id"]).is_empty():
			var choices := _parts_of(slot["id"])
			if not choices.is_empty():
				_wear(choices[0], false)
	_refresh()


func _choose_skin(palette_id: int) -> void:
	draft.skin_palette_id = palette_id
	_refresh()


func _wear(part: Dictionary, refresh: bool = true) -> void:
	var slot := _slot(part["appearance_slot_id"])
	var palette_id := -1
	var kind: Variant = slot.get("palette_kind")
	if kind != null:
		palette_id = _worn(slot["id"]).get("palette_id", -1)
		if palette_id <= 0:
			var palettes := _palettes_of(kind)
			palette_id = palettes[0]["id"] if not palettes.is_empty() else -1
	_take_off(slot["id"], false)
	draft.parts.append({"part_id": part["id"], "palette_id": palette_id})
	if refresh:
		_refresh()


func _take_off(slot_id: int, refresh: bool = true) -> void:
	draft.parts.assign(draft.parts.filter(func(part: Dictionary) -> bool: return _slot_id_of(part["part_id"]) != slot_id))
	if refresh:
		_refresh()


func _choose_color(palette_id: int, slot_id: int) -> void:
	for part: Dictionary in draft.parts:
		if _slot_id_of(part["part_id"]) == slot_id:
			part["palette_id"] = palette_id
	_refresh()


# --- catálogo ----------------------------------------------------------------

func _worn(slot_id: int) -> Dictionary:
	for part: Dictionary in draft.parts:
		if _slot_id_of(part["part_id"]) == slot_id:
			return part
	return {}


func _parts_of(slot_id: int) -> Array[Dictionary]:
	var parts: Array[Dictionary] = []
	for part: Dictionary in GameData.get_rows("appearance_parts"):
		if part["appearance_slot_id"] == slot_id and _fits(part):
			parts.append(part)
	return parts


func _fits(part: Dictionary) -> bool:
	var body: Variant = part.get("body_type_id")
	return body == null or body == draft.body_type_id


func _palettes_of(kind: String) -> Array[Dictionary]:
	var palettes: Array[Dictionary] = []
	for palette: Dictionary in GameData.get_rows("palettes"):
		if palette["kind"] == kind:
			palettes.append(palette)
	return palettes


func _slot(slot_id: int) -> Dictionary:
	for slot: Dictionary in _slots:
		if slot["id"] == slot_id:
			return slot
	return {}


func _slot_id_of(part_id: int) -> int:
	return GameData.get_row("appearance_parts", part_id).get("appearance_slot_id", -1)


func _layer_of(part_id: int) -> int:
	return _slot(_slot_id_of(part_id)).get("layer", 0)
