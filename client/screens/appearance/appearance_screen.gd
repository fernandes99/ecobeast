extends Control
## A tela Aparência (tamer-appearance/03): o corpo, a pele e cada peça com a sua cor,
## numa prévia que gira. Na entrada, salvar segue para a escolha do inicial; pelo Hub,
## volta para ele.

const BODY_TAB := 0
const PREVIEW_SCALE := 8.0
const PREVIEW_FOOT_GAP := 24.0
const SWATCH_SIZE := Vector2(72, 72)
const SWATCH_COLUMNS := 6
const OPTION_COLUMNS := 2
const OPTION_HEIGHT := 72.0
const SELECTED_BORDER := 6
## As linhas da folha, na ordem do giro, e se cada uma é espelhada.
const TURNS: Array[Array] = [
	[SheetSprite.FRONT_ROW, false],
	[SheetSprite.LOWER_ROW, false],
	[SheetSprite.SIDE_ROW, false],
	[SheetSprite.UPPER_ROW, false],
	[SheetSprite.BACK_ROW, false],
	[SheetSprite.UPPER_ROW, true],
	[SheetSprite.SIDE_ROW, true],
	[SheetSprite.LOWER_ROW, true],
]
const SAVE_TEXT := "Salvar"
const SAVING_TEXT := "Salvando..."

var _onboarding: bool = false
var _saving: bool = false
var _draft := TamerAppearance.standard()
var _slots: Array[Dictionary] = []
## 0 é Corpo; os outros são o índice + 1 em `_slots`.
var _tab: int = BODY_TAB
var _turn: int = 0

@onready var _preview_area: Control = %PreviewArea
@onready var _preview: TamerSprite = %Preview
@onready var _turn_button: Button = %TurnButton
@onready var _tabs_scroll: ScrollContainer = %TabsScroll
@onready var _tabs: HBoxContainer = %Tabs
@onready var _options: VBoxContainer = %Options
@onready var _message: Label = %Message
@onready var _save_button: Button = %SaveButton
@onready var _back_button: Button = %BackButton


func setup(params: Dictionary) -> void:
	_onboarding = params.get("onboarding", false)


func _ready() -> void:
	if Session.player != null:
		_draft = Session.player.appearance.duplicate_appearance()
	_slots = GameData.get_rows("appearance_slots").duplicate()
	_slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["layer"] < b["layer"])
	_preview.scale = Vector2.ONE * PREVIEW_SCALE
	_preview_area.resized.connect(_place_preview)
	_turn_button.pressed.connect(_turn_preview)
	_save_button.pressed.connect(_save)
	_back_button.pressed.connect(Router.back)
	_back_button.visible = not _onboarding
	_build_tabs()
	_refresh()
	_place_preview()


func handle_back() -> bool:
	return _saving or _onboarding


func _place_preview() -> void:
	_preview.position = Vector2(_preview_area.size.x / 2.0, _preview_area.size.y - PREVIEW_FOOT_GAP).round()


func _turn_preview() -> void:
	_turn = (_turn + 1) % TURNS.size()
	_preview.face_row(TURNS[_turn][0], TURNS[_turn][1])


func _build_tabs() -> void:
	var names: Array[String] = ["Corpo"]
	for slot: Dictionary in _slots:
		names.append(slot["name"])
	for index: int in names.size():
		var button := Button.new()
		button.text = names[index]
		button.custom_minimum_size.y = OPTION_HEIGHT
		button.pressed.connect(_select_tab.bind(index))
		_tabs.add_child(button)


func _select_tab(index: int) -> void:
	_tab = index
	_refresh()


func _refresh() -> void:
	_draft.parts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _layer_of(a["part_id"]) < _layer_of(b["part_id"]))
	_preview.set_appearance(_draft)
	for index: int in _tabs.get_child_count():
		(_tabs.get_child(index) as Button).theme_type_variation = &"" if index == _tab else &"OutlineButton"
	_tabs_scroll.ensure_control_visible.call_deferred(_tabs.get_child(_tab))
	for child: Node in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
	if _tab == BODY_TAB:
		_build_body_options()
	else:
		_build_slot_options(_slots[_tab - 1])


func _build_body_options() -> void:
	var bodies: Array[Dictionary] = []
	for body: Dictionary in GameData.get_rows("body_types"):
		bodies.append({"label": body["name"], "selected": body["id"] == _draft.body_type_id, "action": _choose_body.bind(body["id"])})
	_add_section("Corpo", _option_grid(bodies))
	_add_section("Pele", _swatch_grid("skin", _draft.skin_palette_id, _choose_skin))


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
	_draft.body_type_id = body_id
	_draft.parts.assign(_draft.parts.filter(func(part: Dictionary) -> bool: return _fits(GameData.get_row("appearance_parts", part["part_id"]))))
	for slot: Dictionary in _slots:
		if slot["required"] and _worn(slot["id"]).is_empty():
			var choices := _parts_of(slot["id"])
			if not choices.is_empty():
				_wear(choices[0], false)
	_refresh()


func _choose_skin(palette_id: int) -> void:
	_draft.skin_palette_id = palette_id
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
	_draft.parts.append({"part_id": part["id"], "palette_id": palette_id})
	if refresh:
		_refresh()


func _take_off(slot_id: int, refresh: bool = true) -> void:
	_draft.parts.assign(_draft.parts.filter(func(part: Dictionary) -> bool: return _slot_id_of(part["part_id"]) != slot_id))
	if refresh:
		_refresh()


func _choose_color(palette_id: int, slot_id: int) -> void:
	for part: Dictionary in _draft.parts:
		if _slot_id_of(part["part_id"]) == slot_id:
			part["palette_id"] = palette_id
	_refresh()


func _save() -> void:
	if _saving:
		return
	_saving = true
	_message.hide()
	_save_button.disabled = true
	_back_button.disabled = true
	_save_button.text = SAVING_TEXT
	var result: Result = await Session.update_appearance(_draft)
	_saving = false
	_save_button.disabled = false
	_back_button.disabled = false
	_save_button.text = SAVE_TEXT
	if not result.ok:
		_message.text = result.error
		_message.show()
		return
	if _onboarding:
		Router.go_to(&"starter_select")
	else:
		Router.back()


# --- catálogo ----------------------------------------------------------------

func _worn(slot_id: int) -> Dictionary:
	for part: Dictionary in _draft.parts:
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
	return body == null or body == _draft.body_type_id


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
