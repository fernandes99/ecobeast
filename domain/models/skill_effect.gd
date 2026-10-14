class_name SkillEffect
extends RefCounted
## Um efeito de Técnica (tabela skill_effects). Colunas nulas viram -1 (ids)
## ou 0 (números); has_param() diz se a coluna veio preenchida.

const PARAM_COLUMNS: Array[String] = [
	"skill_target_id", "status_condition_id", "stat_id", "stages",
	"percent", "value", "weather_id", "min_turns",
]

var id: int
var skill_id: int
var effect_type_id: int
## slug do tipo de efeito (apply_status, modify_stat, heal…).
var effect_slug: String
var sort_order: int
## 1–100; 100 = sempre.
var chance: int
var skill_target_id: int = -1
var status_condition_id: int = -1
var stat_id: int = -1
var stages: int = 0
var percent: int = 0
var value: int = 0
var weather_id: int = -1
var min_turns: int = 0

var _present: Dictionary = {}


func has_param(column: String) -> bool:
	return _present.has(column)


static func from_row(row: Dictionary, slug: String) -> SkillEffect:
	var effect := SkillEffect.new()
	effect.id = row["id"]
	effect.skill_id = row["skill_id"]
	effect.effect_type_id = row["effect_type_id"]
	effect.effect_slug = slug
	effect.sort_order = row["sort_order"]
	effect.chance = row["chance"]
	for column: String in PARAM_COLUMNS:
		if row[column] != null:
			effect.set(column, row[column])
			effect._present[column] = true
	return effect
