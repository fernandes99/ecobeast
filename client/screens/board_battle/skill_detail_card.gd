class_name SkillDetailCard
extends PanelContainer

## O detalhe de uma Técnica, aberto ao segurar o ícone dela na luta (skill-cooldown/02).

const GAP := 12.0
const SCREEN_MARGIN := 16.0

@onready var _name_label: Label = %NameLabel
@onready var _badge: ElementBadge = %Badge
@onready var _info_label: Label = %InfoLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _usage_label: Label = %UsageLabel
@onready var _ready_label: Label = %ReadyLabel


func _ready() -> void:
	_info_label.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	_usage_label.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	_ready_label.add_theme_color_override(&"font_color", UiPalette.WARNING)


## Mostra a Técnica acima do retângulo do ícone (em coordenadas globais).
func open(slot: SkillSlot, anchor: Rect2) -> void:
	var skill := GameData.get_skill(slot.skill_id)
	_name_label.text = skill.name
	_badge.set_element(skill.element_id)
	var category: String = GameData.get_row("skill_categories", skill.skill_category_id).get("name", "")
	var power := "—" if skill.power == 0 else str(skill.power)
	var accuracy := "—" if skill.accuracy == 0 else str(skill.accuracy)
	_info_label.text = "%s · Poder %s · Precisão %s · Alcance %d" % [category, power, accuracy, skill.area_range]
	_description_label.text = skill.description
	var countdown := "sem countdown" if skill.cooldown == 0 else "countdown de %s" % _rounds(skill.cooldown)
	_usage_label.text = "PP %d/%d · %s" % [slot.current_pp, skill.max_pp, countdown]
	_ready_label.visible = slot.cooldown_left > 0
	_ready_label.text = "Volta em %s" % _rounds(slot.cooldown_left)
	show()
	reset_size()
	# O texto quebrado só tem altura certa depois de um quadro.
	await get_tree().process_frame
	reset_size()
	var screen := get_viewport_rect().size
	var x := clampf(anchor.get_center().x - size.x / 2.0, SCREEN_MARGIN, screen.x - size.x - SCREEN_MARGIN)
	global_position = Vector2(x, maxf(SCREEN_MARGIN, anchor.position.y - size.y - GAP))


func _rounds(count: int) -> String:
	return "%d rodada" % count if count == 1 else "%d rodadas" % count
