class_name Skill
extends RefCounted
## Uma Técnica (tabela skills), com seus efeitos na ordem de aplicação.

var id: int
var slug: String
var name: String
var description: String
var element_id: int
var skill_category_id: int
var power: int
## 0 = nunca erra.
var accuracy: int
var max_pp: int
var priority: int
var crit_stage: int
var skill_target_id: int
var makes_contact: bool
var min_hits: int
var max_hits: int
var effects: Array[SkillEffect] = []


static func from_row(row: Dictionary) -> Skill:
	var skill := Skill.new()
	skill.id = row["id"]
	skill.slug = row["slug"]
	skill.name = row["name"]
	skill.description = row["description"]
	skill.element_id = row["element_id"]
	skill.skill_category_id = row["skill_category_id"]
	skill.power = row["power"]
	skill.accuracy = row["accuracy"]
	skill.max_pp = row["max_pp"]
	skill.priority = row["priority"]
	skill.crit_stage = row["crit_stage"]
	skill.skill_target_id = row["skill_target_id"]
	skill.makes_contact = row["makes_contact"]
	skill.min_hits = row["min_hits"]
	skill.max_hits = row["max_hits"]
	return skill
