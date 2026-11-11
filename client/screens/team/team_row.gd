class_name TeamRow
extends PanelContainer

signal tapped
signal hold_started(finger_y: float)

const ElementBadgeScene := preload("res://ui/components/element_badge.tscn")

const NO_STATUS := -1
const CHIP_FONT_SIZE := 18
const LIFTED_SHADOW := 18

var creature: CreatureInstance = null
## Segurar levanta a linha. Sem isso, um toque longo conta como toque.
var can_hold: bool = false

var _is_leader: bool = false
var _is_lifted: bool = false
var _is_pressing: bool = false
var _press_position := Vector2.ZERO
var _normal_style: StyleBoxFlat
var _leader_style: StyleBoxFlat
var _lifted_style: StyleBoxFlat
var _vacant_style: StyleBoxFlat

@onready var _filled_row: HBoxContainer = %FilledRow
@onready var _vacant_label: Label = %VacantLabel
@onready var _portrait: CreaturePortrait = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _leader_chip: PanelContainer = %LeaderChip
@onready var _leader_label: Label = %LeaderLabel
@onready var _tags: HBoxContainer = %Tags
@onready var _hp_bar: HpBar = %HpBar
@onready var _grip: TextureRect = %Grip
@onready var _hold_timer: Timer = %HoldTimer


func _ready() -> void:
	_normal_style = get_theme_stylebox(&"panel") as StyleBoxFlat
	_leader_style = _normal_style.duplicate()
	_leader_style.border_color = UiPalette.ACCENT
	_lifted_style = _leader_style.duplicate()
	_lifted_style.bg_color = UiPalette.SURFACE
	_lifted_style.shadow_size = LIFTED_SHADOW
	_vacant_style = _normal_style.duplicate()
	_vacant_style.bg_color = Color.TRANSPARENT
	_vacant_style.shadow_size = 0
	var chip_style := (_leader_chip.get_theme_stylebox(&"panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	chip_style.bg_color = UiPalette.ACCENT
	_leader_chip.add_theme_stylebox_override(&"panel", chip_style)
	_leader_label.add_theme_color_override(&"font_color", UiPalette.BACKGROUND)
	_grip.modulate = UiPalette.TEXT_MUTED
	_hold_timer.timeout.connect(_on_hold_timeout)
	_refresh()


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_press(button.position)
		elif _is_pressing:
			_end_press()
			if not button.canceled:
				tapped.emit()
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _is_pressing and motion.position.distance_to(_press_position) > TapPanel.TAP_SLOP:
		_end_press()


func set_creature(value: CreatureInstance) -> void:
	creature = value
	if is_node_ready():
		_refresh()


func set_leader(is_leader: bool) -> void:
	_is_leader = is_leader
	_leader_chip.visible = is_leader
	_paint_style()


func set_lifted(is_lifted: bool) -> void:
	_is_lifted = is_lifted
	z_index = 1 if is_lifted else 0
	_paint_style()


func _press(point: Vector2) -> void:
	_is_pressing = true
	_press_position = point
	self_modulate = UiPalette.PRESSED_TINT
	if can_hold:
		_hold_timer.start()


func _end_press() -> void:
	_is_pressing = false
	_hold_timer.stop()
	self_modulate = Color.WHITE


func _on_hold_timeout() -> void:
	_end_press()
	hold_started.emit(global_position.y + _press_position.y)


func _refresh() -> void:
	_filled_row.visible = creature != null
	_vacant_label.visible = creature == null
	_paint_style()
	if creature == null:
		return
	var species := GameData.get_species(creature.species_id)
	_portrait.set_species(species.id)
	_name_label.text = creature.display_name(species)
	_level_label.text = "Nv. %d" % creature.level
	_hp_bar.set_hp(creature.current_hp, creature.stats.hp)
	for tag: Node in _tags.get_children():
		_tags.remove_child(tag)
		tag.queue_free()
	for element_id: int in species.element_ids:
		var badge: ElementBadge = ElementBadgeScene.instantiate()
		badge.set_element(element_id)
		_tags.add_child(badge)
	if creature.status_condition_id != NO_STATUS:
		var status: Dictionary = GameData.catalog.get_row("status_conditions", creature.status_condition_id)
		_add_status_chip(status["name"])


func _add_status_chip(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"BoldLabel"
	label.add_theme_font_size_override(&"font_size", CHIP_FONT_SIZE)
	label.add_theme_color_override(&"font_color", UiPalette.WARNING)
	var chip := PanelContainer.new()
	chip.theme_type_variation = &"ElementPill"
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(label)
	_tags.add_child(chip)


func _paint_style() -> void:
	var style := _normal_style
	if creature == null:
		style = _vacant_style
	elif _is_lifted:
		style = _lifted_style
	elif _is_leader:
		style = _leader_style
	add_theme_stylebox_override(&"panel", style)
