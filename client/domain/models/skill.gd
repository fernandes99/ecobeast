class_name Skill
extends RefCounted

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
var area_shape: String = "single"
## Alcance em hexágonos, de 1 a 6 (coluna range). "single" com 1 é o corpo a
## corpo. Não se chama range para não esconder a função range() do GDScript.
var area_range: int = 1
var pierces: bool = false
var ground_effect_id: int = -1
var ground_turns: int = 0
var effects: Array[SkillEffect] = []


func has_ground_effect() -> bool:
	return ground_effect_id != -1


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
	skill.area_range = row["range"]
	skill.pierces = row["pierces"]
	if row["ground_effect_id"] != null:
		skill.ground_effect_id = row["ground_effect_id"]
		skill.ground_turns = row["ground_turns"]
	return skill
