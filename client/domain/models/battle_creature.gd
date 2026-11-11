class_name BattleCreature
extends RefCounted

var uid: String = ""
var species_id: int = 0
var level: int = 1
var hp: int = 0
var max_hp: int = 0
var status: String = ""
var confused: bool = false
var stages: Dictionary[String, int] = {}
var skills: Array[SkillSlot] = []


func copy() -> BattleCreature:
	var creature := BattleCreature.new()
	creature.uid = uid
	creature.species_id = species_id
	creature.level = level
	creature.hp = hp
	creature.max_hp = max_hp
	creature.status = status
	creature.confused = confused
	creature.stages = stages.duplicate()
	creature.skills = skills.duplicate()
	return creature


static func from_dict(d: Dictionary) -> BattleCreature:
	var creature := BattleCreature.new()
	creature.uid = DictFields.get_string(d, "uid")
	creature.species_id = DictFields.get_int(d, "species_id")
	creature.level = DictFields.get_int(d, "level", 1)
	creature.hp = DictFields.get_int(d, "hp")
	creature.max_hp = DictFields.get_int(d, "max_hp")
	creature.status = DictFields.get_string(d, "status")
	creature.confused = DictFields.get_bool(d, "confused")
	var stages_dict := DictFields.get_dict(d, "stages")
	for slug: Variant in stages_dict:
		creature.stages[str(slug)] = DictFields.get_int(stages_dict, str(slug))
	for skill_dict: Variant in DictFields.get_array(d, "skills"):
		if skill_dict is Dictionary:
			creature.skills.append(SkillSlot.from_dict(skill_dict))
	return creature
