class_name EvolutionRule
extends RefCounted
## Uma regra de Ascensão (tabela evolutions). Colunas nulas viram -1 ou "".

const OPTIONAL_COLUMNS: Array[String] = ["min_level", "item_id", "min_bond", "time_of_day", "zone_id"]

var id: int
var species_id: int
var evolved_species_id: int
var evolution_trigger_id: int
## slug do gatilho (level, item, bond…).
var trigger_slug: String
var min_level: int = -1
var item_id: int = -1
var min_bond: int = -1
## "day", "night" ou "".
var time_of_day: String = ""
var zone_id: int = -1


static func from_row(row: Dictionary, slug: String) -> EvolutionRule:
	var rule := EvolutionRule.new()
	rule.id = row["id"]
	rule.species_id = row["species_id"]
	rule.evolved_species_id = row["evolved_species_id"]
	rule.evolution_trigger_id = row["evolution_trigger_id"]
	rule.trigger_slug = slug
	for column: String in OPTIONAL_COLUMNS:
		if row[column] != null:
			rule.set(column, row[column])
	return rule
