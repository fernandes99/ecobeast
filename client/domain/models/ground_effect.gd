class_name GroundEffect
extends RefCounted

var id: int
var slug: String
var name: String
var damage_percent: int = 0
var status_condition_id: int = -1
var color: Color


static func from_row(row: Dictionary) -> GroundEffect:
	var effect := GroundEffect.new()
	effect.id = row["id"]
	effect.slug = row["slug"]
	effect.name = row["name"]
	if row["damage_percent"] != null:
		effect.damage_percent = row["damage_percent"]
	if row["status_condition_id"] != null:
		effect.status_condition_id = row["status_condition_id"]
	effect.color = Color(row["color_hex"])
	return effect
