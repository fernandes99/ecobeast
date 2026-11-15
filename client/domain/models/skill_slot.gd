class_name SkillSlot
extends RefCounted

var skill_id: int
var current_pp: int
## Só na luta: rodadas que faltam para a Técnica voltar; 0 é livre.
var cooldown_left: int = 0


static func create(skill: int, pp: int) -> SkillSlot:
	var slot := SkillSlot.new()
	slot.skill_id = skill
	slot.current_pp = pp
	return slot


static func from_dict(d: Dictionary) -> SkillSlot:
	var slot := create(DictFields.get_int(d, "skill_id"), DictFields.get_int(d, "current_pp"))
	slot.cooldown_left = DictFields.get_int(d, "cooldown_left")
	return slot
