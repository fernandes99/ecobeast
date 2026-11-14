class_name BattleEffectsDebug
extends PanelContainer

signal status_toggled(key: String, slug: String)
signal stage_changed(key: String, stat: String, delta: int)
signal mark_toggled(cell: Vector2i, ground_effect_id: int)
signal cleared

const TITLE_TEXT := "Depuração dos efeitos (F3)"
const PICK_TEXT := "Toque num hexágono do tabuleiro."
const NO_CREATURE_TEXT := "Hexágono (%d, %d), sem Ecobeast"
const TARGET_TEXT := "%s, no hexágono (%d, %d)"
const CREATURE_TEXT := "Ecobeast"
const STAGES_TEXT := "Atributos"
const GROUND_TEXT := "Chão"
const CLEAR_TEXT := "Limpar tudo"
const PROTECT_TEXT := "Protegido"
const MIN_STAGE := -6
const MAX_STAGE := 6
const FONT_SIZE := 20
const STAGE_STATS: Array[String] = ["atk", "def", "sp_atk", "sp_def", "spd", "accuracy", "evasion"]

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
	column.add_theme_constant_override(&"separation", 6)
	add_child(column)
	column.add_child(_label(TITLE_TEXT, &"BoldLabel"))
	_target_label.text = PICK_TEXT
	_target_label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	column.add_child(_target_label)

	column.add_child(_label(CREATURE_TEXT, &"SecondaryLabel"))
	var statuses := GridContainer.new()
	statuses.columns = 3
	column.add_child(statuses)
	for slug: String in BattleStatuses.ORDER:
		var button := _button(PROTECT_TEXT if slug == "protect" else GameData.get_status_name(slug))
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: status_toggled.emit(_key, slug))
		_status_buttons[slug] = button
		statuses.add_child(button)

	column.add_child(_label(STAGES_TEXT, &"SecondaryLabel"))
	var stages := GridContainer.new()
	stages.columns = 8
	column.add_child(stages)
	for stat: String in STAGE_STATS:
		var name_label := _label(_short_name(stat), &"")
		name_label.custom_minimum_size.x = 64.0
		stages.add_child(name_label)
		var minus := _button("−")
		minus.pressed.connect(func() -> void: stage_changed.emit(_key, stat, -1))
		stages.add_child(minus)
		var value := _label("0", &"")
		value.custom_minimum_size.x = 32.0
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stages.add_child(value)
		var plus := _button("+")
		plus.pressed.connect(func() -> void: stage_changed.emit(_key, stat, 1))
		stages.add_child(plus)
		_stage_buttons[stat] = [minus, plus]
		_stage_labels[stat] = value

	column.add_child(_label(GROUND_TEXT, &"SecondaryLabel"))
	var ground := HBoxContainer.new()
	column.add_child(ground)
	for row: Dictionary in GameData.get_rows("ground_effects"):
		var ground_effect_id: int = row["id"]
		var button := _button(str(row["name"]))
		button.toggle_mode = true
		button.pressed.connect(func() -> void:
			if _cell != null:
				mark_toggled.emit(_cell, ground_effect_id))
		_mark_buttons[ground_effect_id] = button
		_mark_colors[ground_effect_id] = GameData.get_ground_effect(ground_effect_id).color
		ground.add_child(button)

	_clear_button.text = CLEAR_TEXT
	_clear_button.theme_type_variation = &"DangerButton"
	_clear_button.pressed.connect(cleared.emit)
	column.add_child(_clear_button)
	select(null, "", "")


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
	button.add_theme_font_size_override(&"font_size", FONT_SIZE)
	return button
