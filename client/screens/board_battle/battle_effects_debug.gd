class_name BattleEffectsDebug
extends PanelContainer

signal status_toggled(key: String, slug: String)
signal stage_changed(key: String, stat: String, delta: int)
signal mark_toggled(cell: Vector2i, ground_effect_id: int)
signal cleared
signal closed

const TITLE_TEXT := "Depuração (F3)"
const PICK_TEXT := "Toque num hexágono do tabuleiro."
const NO_CREATURE_TEXT := "Hexágono (%d, %d), sem Ecobeast"
const TARGET_TEXT := "%s, no hexágono (%d, %d)"
const CLEAR_TEXT := "Limpar tudo"
const CLOSE_TEXT := "×"
const PROTECT_TEXT := "Protegido"
const MIN_STAGE := -6
const MAX_STAGE := 6
const FONT_SIZE := 20
const STATUS_COLUMNS := 3
const GROUND_COLUMNS := 3
const BUTTON_HEIGHT := 44.0
const STAGE_NAME_WIDTH := 96.0
const STAGE_VALUE_WIDTH := 48.0
const STAGE_STATS: Array[String] = ["atk", "def", "sp_atk", "sp_def", "spd", "accuracy", "evasion"]

static var _last_tab := 0

var _key := ""
var _cell: Variant = null
var _target_label := Label.new()
var _status_buttons: Dictionary[String, Button] = {}
var _stage_buttons: Dictionary[String, Array] = {}
var _stage_labels: Dictionary[String, Label] = {}
var _mark_buttons: Dictionary[int, Button] = {}
var _mark_colors: Dictionary[int, Color] = {}
var _clear_button := Button.new()


func _init() -> void:
	theme_type_variation = &"SectionPanel"
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	add_child(column)
	column.add_child(_header())
	_target_label.text = PICK_TEXT
	_target_label.theme_type_variation = &"SecondaryLabel"
	_target_label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	column.add_child(_target_label)
	var tabs := DebugTabs.new()
	tabs.equal_heights = true
	column.add_child(tabs)
	_build_statuses(tabs.add_page("Estados"))
	_build_stages(tabs.add_page("Atributos"))
	_build_ground(tabs.add_page("Chão"))
	tabs.show_page(_last_tab)
	tabs.tab_changed.connect(func(index: int) -> void: _last_tab = index)
	select(null, "", "")


func _header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	var title := _label(TITLE_TEXT, &"BoldLabel")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)
	_clear_button.text = CLEAR_TEXT
	_clear_button.theme_type_variation = &"DangerButton"
	_clear_button.focus_mode = Control.FOCUS_NONE
	_clear_button.add_theme_font_size_override(&"font_size", FONT_SIZE)
	_clear_button.pressed.connect(cleared.emit)
	row.add_child(_clear_button)
	var close := _button(CLOSE_TEXT)
	close.custom_minimum_size.x = BUTTON_HEIGHT
	close.pressed.connect(closed.emit)
	row.add_child(close)
	return row


func _build_statuses(page: VBoxContainer) -> void:
	var grid := _grid(page, STATUS_COLUMNS)
	for slug: String in BattleStatuses.ORDER:
		var button := _button(PROTECT_TEXT if slug == "protect" else GameData.get_status_name(slug))
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.pressed.connect(func() -> void: status_toggled.emit(_key, slug))
		_status_buttons[slug] = button
		grid.add_child(button)


func _build_stages(page: VBoxContainer) -> void:
	page.add_theme_constant_override(&"separation", 4)
	for stat: String in STAGE_STATS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 8)
		page.add_child(row)
		var name_label := _label(_short_name(stat), &"")
		name_label.custom_minimum_size.x = STAGE_NAME_WIDTH
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(name_label)
		var minus := _button("−")
		minus.custom_minimum_size.x = BUTTON_HEIGHT * 1.5
		minus.pressed.connect(func() -> void: stage_changed.emit(_key, stat, -1))
		row.add_child(minus)
		var value := _label("0", &"BoldLabel")
		value.custom_minimum_size.x = STAGE_VALUE_WIDTH
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(value)
		var plus := _button("+")
		plus.custom_minimum_size.x = BUTTON_HEIGHT * 1.5
		plus.pressed.connect(func() -> void: stage_changed.emit(_key, stat, 1))
		row.add_child(plus)
		_stage_buttons[stat] = [minus, plus]
		_stage_labels[stat] = value


func _build_ground(page: VBoxContainer) -> void:
	var grid := _grid(page, GROUND_COLUMNS)
	for row: Dictionary in GameData.get_rows("ground_effects"):
		var ground_effect_id: int = row["id"]
		var button := _button(str(row["name"]))
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.pressed.connect(func() -> void:
			if _cell != null:
				mark_toggled.emit(_cell, ground_effect_id))
		_mark_buttons[ground_effect_id] = button
		_mark_colors[ground_effect_id] = GameData.get_ground_effect(ground_effect_id).color
		grid.add_child(button)


func _grid(page: VBoxContainer, columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override(&"h_separation", 6)
	grid.add_theme_constant_override(&"v_separation", 6)
	page.add_child(grid)
	return grid


# O ligado ganha o fundo na cor do efeito: o "apertado" do tema quase não aparece.
func _ready() -> void:
	for slug: String in _status_buttons:
		_paint_pressed(_status_buttons[slug], UiPalette.STATUS_COLORS.get(slug, UiPalette.WARNING))
	for ground_effect_id: int in _mark_buttons:
		_paint_pressed(_mark_buttons[ground_effect_id], _mark_colors[ground_effect_id])


func _paint_pressed(button: Button, color: Color) -> void:
	var box := button.get_theme_stylebox(&"pressed").duplicate() as StyleBoxFlat
	if box == null:
		return
	box.bg_color = color.darkened(0.35)
	box.border_color = color
	button.add_theme_stylebox_override(&"pressed", box)
	button.add_theme_stylebox_override(&"hover_pressed", box)


func select(cell: Variant, key: String, creature_name: String) -> void:
	_cell = cell
	_key = key
	if cell == null:
		_target_label.text = PICK_TEXT
	elif key.is_empty():
		_target_label.text = NO_CREATURE_TEXT % [cell.x, cell.y]
	else:
		_target_label.text = TARGET_TEXT % [creature_name, cell.x, cell.y]
	for button: Button in _status_buttons.values():
		button.disabled = key.is_empty()
	for pair: Array in _stage_buttons.values():
		for button: Button in pair:
			button.disabled = key.is_empty()
	for button: Button in _mark_buttons.values():
		button.disabled = cell == null


func show_state(slugs: Array[String], stages: Dictionary, mark_id: int) -> void:
	for slug: String in _status_buttons:
		_status_buttons[slug].set_pressed_no_signal(slugs.has(slug))
	for stat: String in _stage_labels:
		var level: int = stages.get(stat, 0)
		_stage_labels[stat].text = "%+d" % level if level != 0 else "0"
		_stage_buttons[stat][0].disabled = _key.is_empty() or level <= MIN_STAGE
		_stage_buttons[stat][1].disabled = _key.is_empty() or level >= MAX_STAGE
	for ground_effect_id: int in _mark_buttons:
		_mark_buttons[ground_effect_id].set_pressed_no_signal(ground_effect_id == mark_id)


func _short_name(stat: String) -> String:
	var stat_id := GameData.get_stat_id(stat)
	return str(GameData.get_row("stats", stat_id).get("short_name", stat))


func _label(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	if not variation.is_empty():
		label.theme_type_variation = variation
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = BUTTON_HEIGHT
	button.add_theme_font_size_override(&"font_size", FONT_SIZE)
	return button
