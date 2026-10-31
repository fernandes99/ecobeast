class_name BattleSkillButton
extends Button
## Uma Técnica na batalha (battle-screen/03, RF-15), ou "Vazio". Sem PP, fica
## desativada; a borda tem a cor do Elemento.

const STYLE_STATES: Array[StringName] = [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]
## Quanto a borda apaga com o botão desativado.
const DISABLED_BORDER_ALPHA := 0.4

var _slot: SkillSlot = null

@onready var _details: VBoxContainer = %Details
@onready var _name_label: Label = %NameLabel
@onready var _badge: ElementBadge = %Badge
@onready var _pp_label: Label = %PpLabel
@onready var _empty_label: Label = %EmptyLabel


func _ready() -> void:
	_empty_label.add_theme_color_override(&"font_color", UiPalette.TEXT_MUTED)
	_refresh()


## Pode ser chamado antes ou depois de o componente entrar na árvore.
func set_skill(slot: SkillSlot) -> void:
	_slot = slot
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	var skill: Skill = GameData.get_skill(_slot.skill_id) if _slot != null else null
	_details.visible = skill != null
	_empty_label.visible = skill == null
	disabled = skill == null or _slot.current_pp == 0
	if skill == null:
		return
	_name_label.text = skill.name
	_badge.set_element(skill.element_id)
	_pp_label.text = "PP %d/%d" % [_slot.current_pp, skill.max_pp]
	_paint_border(GameData.get_element(skill.element_id).color)


func _paint_border(color: Color) -> void:
	for state: StringName in STYLE_STATES:
		var style := get_theme_stylebox(state).duplicate() as StyleBoxFlat
		style.border_color = color
		if state == &"disabled":
			style.border_color.a = DISABLED_BORDER_ALPHA
		add_theme_stylebox_override(state, style)
