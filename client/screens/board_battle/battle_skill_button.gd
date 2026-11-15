class_name BattleSkillButton
extends Button

## Tocar e soltar escolhe a Técnica; segurar mostra o detalhe dela (skill-cooldown/02).
signal chosen
signal hold_started(button: BattleSkillButton)
signal hold_ended

const HOLD_SECONDS := 0.4
const STYLE_STATES: Array[StringName] = [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]
const DISABLED_BORDER_ALPHA := 0.4
const SELECTED_BORDER_WIDTH := 6

var _slot: SkillSlot = null
var _selected := false
var _held := false
var _hold_timer := Timer.new()

@onready var _details: VBoxContainer = %Details
@onready var _icon: TextureRect = %Icon
@onready var _pp_label: Label = %PpLabel
@onready var _veil: Panel = %Veil
@onready var _countdown_label: Label = %CountdownLabel
@onready var _empty_label: Label = %EmptyLabel


func _ready() -> void:
	_empty_label.add_theme_color_override(&"font_color", UiPalette.TEXT_MUTED)
	var veil_style := StyleBoxFlat.new()
	veil_style.bg_color = UiPalette.OVERLAY
	veil_style.set_corner_radius_all(BattleTheme.BUTTON_RADIUS)
	_veil.add_theme_stylebox_override(&"panel", veil_style)
	_hold_timer.one_shot = true
	_hold_timer.wait_time = HOLD_SECONDS
	_hold_timer.timeout.connect(_on_hold)
	add_child(_hold_timer)
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	pressed.connect(_on_pressed)
	_refresh()


func set_skill(slot: SkillSlot) -> void:
	_slot = slot
	if is_node_ready():
		_refresh()


func get_slot() -> SkillSlot:
	return _slot


func set_selected(selected: bool) -> void:
	if _selected == selected:
		return
	_selected = selected
	if is_node_ready():
		_refresh()


func is_usable() -> bool:
	return _slot != null and _slot.current_pp > 0 and _slot.cooldown_left == 0


func _refresh() -> void:
	var skill: Skill = GameData.get_skill(_slot.skill_id) if _slot != null else null
	_details.visible = skill != null
	_empty_label.visible = skill == null
	_veil.visible = skill != null and not is_usable()
	if skill == null:
		_paint_border(UiPalette.BORDER)
		return
	var icon_path := ContentFiles.SKILL_ICON_PATH % skill.slug
	_icon.texture = load(icon_path) as Texture2D if ResourceLoader.exists(icon_path) else null
	_pp_label.text = "%d/%d" % [_slot.current_pp, skill.max_pp]
	_countdown_label.text = str(_slot.cooldown_left) if _slot.cooldown_left > 0 else ""
	_paint_border(GameData.get_element(skill.element_id).color)


func _paint_border(color: Color) -> void:
	for state: StringName in STYLE_STATES:
		remove_theme_stylebox_override(state)
		var style := get_theme_stylebox(state).duplicate() as StyleBoxFlat
		if style == null:
			continue
		style.border_color = UiPalette.TEXT if _selected else color
		if _selected:
			style.set_border_width_all(SELECTED_BORDER_WIDTH)
		if state == &"disabled":
			style.border_color.a = DISABLED_BORDER_ALPHA
		add_theme_stylebox_override(state, style)


func _on_down() -> void:
	_held = false
	if _slot != null:
		_hold_timer.start()


func _on_hold() -> void:
	_held = true
	hold_started.emit(self)


func _on_up() -> void:
	_hold_timer.stop()
	if _held:
		hold_ended.emit()


func _on_pressed() -> void:
	# O "pressed" chega ao soltar: depois de segurar, ele só fecha o detalhe.
	if not _held and is_usable():
		chosen.emit()
