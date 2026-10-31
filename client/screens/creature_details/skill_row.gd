class_name SkillRow
extends PanelContainer
## Uma linha da aba Técnicas (creature-details/02, RF-10): a Técnica, ou "Vazio".

const NEVER_MISSES := "Nunca erra"

var _slot: SkillSlot = null

@onready var _details: VBoxContainer = %Details
@onready var _name_label: Label = %NameLabel
@onready var _pp_label: Label = %PpLabel
@onready var _badge: ElementBadge = %Badge
@onready var _category_label: Label = %CategoryLabel
@onready var _power_label: Label = %PowerLabel
@onready var _accuracy_label: Label = %AccuracyLabel
@onready var _empty_label: Label = %EmptyLabel


func _ready() -> void:
	_empty_label.add_theme_color_override(&"font_color", UiPalette.TEXT_MUTED)
	_refresh()


## Pode ser chamado antes ou depois de o componente entrar na árvore.
func set_skill(slot: SkillSlot) -> void:
	_slot = slot
	if is_node_ready():
		_refresh()


## Pode ser chamado antes ou depois de o componente entrar na árvore.
func set_empty() -> void:
	set_skill(null)


func _refresh() -> void:
	_details.visible = _slot != null
	_empty_label.visible = _slot == null
	if _slot == null:
		return
	var skill := GameData.get_skill(_slot.skill_id)
	_name_label.text = skill.name
	_pp_label.text = "PP %d/%d" % [_slot.current_pp, skill.max_pp]
	_badge.set_element(skill.element_id)
	_category_label.text = GameData.get_row("skill_categories", skill.skill_category_id)["name"]
	_power_label.visible = skill.power > 0
	_power_label.text = "Poder %d" % skill.power
	_accuracy_label.text = "Prec. %d" % skill.accuracy if skill.accuracy > 0 else NEVER_MISSES
