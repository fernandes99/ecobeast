class_name SkillSlot
extends RefCounted
## Uma Técnica que a criatura conhece, com o PP que resta.

var skill_id: int
var current_pp: int


static func create(skill: int, pp: int) -> SkillSlot:
	var slot := SkillSlot.new()
	slot.skill_id = skill
	slot.current_pp = pp
	return slot


static func from_dict(d: Dictionary) -> SkillSlot:
	return create(DictFields.get_int(d, "skill_id"), DictFields.get_int(d, "current_pp"))
