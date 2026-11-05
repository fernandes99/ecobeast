class_name GroundEffect
extends RefCounted
## O que uma marca no chão do tabuleiro faz (tabela ground_effects,
## board-battle/01). Colunas nulas viram 0 (dano) ou -1 (status).

var id: int
var slug: String
var name: String
## Dano em % do HP máximo, depois de cada vez da fila; 0 sem dano.
var damage_percent: int = 0
## O status que a marca tenta aplicar, ou -1.
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
