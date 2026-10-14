class_name CatalogSchema
extends RefCounted
## Espelho em código das tabelas do catálogo (.specs/game-data/architecture.md).
## Quando uma tabela muda, os dois mudam no mesmo commit.
##
## Cada coluna tem "type" ("int", "float", "string", "bool") e, quando se aplica:
## "nullable", "unique", "fk" (tabela referenciada pelo id), "fk_future" (tabela
## que ainda não existe; o valor precisa ser null), "min", "max", "values"
## (valores permitidos) e "pattern" (expressão regular para strings).

const ID := {"type": "int", "min": 1}
const SLUG := {"type": "string", "unique": true, "pattern": "^[a-z0-9_]+$"}
const TEXT := {"type": "string"}

## Colunas de skill_effects que cada tipo de efeito usa. "required" precisa estar
## preenchida; "optional" pode estar; as demais colunas de parâmetro ficam null.
const EFFECT_PARAM_COLUMNS: Array[String] = SkillEffect.PARAM_COLUMNS
const EFFECT_PARAMS := {
	"apply_status": {"required": ["status_condition_id"], "optional": []},
	"modify_stat": {"required": ["skill_target_id", "stat_id", "stages"], "optional": []},
	"heal": {"required": ["percent"], "optional": []},
	"drain": {"required": ["percent"], "optional": []},
	"recoil": {"required": ["percent"], "optional": []},
	"flinch": {"required": [], "optional": []},
	"multi_turn": {"required": [], "optional": []},
	"fixed_damage": {"required": [], "optional": ["value"]},
	"set_weather": {"required": ["weather_id", "min_turns"], "optional": []},
	"protect": {"required": [], "optional": []},
	"switch": {"required": [], "optional": []},
}

const TABLES := {
	# --- Referência -----------------------------------------------------------
	"elements": {
		"key": ["id"],
		"columns": {
			"id": ID,
			"slug": SLUG,
			"name": TEXT,
			"color_hex": {"type": "string", "pattern": "^#[0-9A-Fa-f]{6}$"},
			"is_rare": {"type": "bool"},
		},
	},
	"element_efficacy": {
		"key": ["attacker_element_id", "defender_element_id"],
		"columns": {
			"attacker_element_id": {"type": "int", "fk": "elements"},
			"defender_element_id": {"type": "int", "fk": "elements"},
			"multiplier": {"type": "float", "values": [0.0, 0.5, 2.0]},
		},
	},
	"stats": {
		"key": ["id"],
		"columns": {
			"id": ID,
			"slug": SLUG,
			"name": TEXT,
			"short_name": TEXT,
			"is_battle_only": {"type": "bool"},
		},
	},
	"growth_rates": {
		"key": ["id"],
		"columns": {
			"id": ID,
			"slug": SLUG,
			"name": TEXT,
			"xp_multiplier": {"type": "float", "min": 0.1, "max": 10.0},
		},
	},
	"rarities": {
		"key": ["id"],
		"columns": {
			"id": ID,
			"slug": SLUG,
			"name": TEXT,
			"sort_order": {"type": "int", "unique": true},
		},
	},
	"temperaments": {
		"key": ["id"],
		"columns": {
			"id": ID,
			"slug": SLUG,
			"name": TEXT,
			"increased_stat_id": {"type": "int", "fk": "stats"},
			"decreased_stat_id": {"type": "int", "fk": "stats"},
		},
	},
	"skill_categories": {
		"key": ["id"],
		"columns": {"id": ID, "slug": SLUG, "name": TEXT},
	},
	"skill_targets": {
		"key": ["id"],
		"columns": {"id": ID, "slug": SLUG, "name": TEXT},
	},
	"skill_learn_methods": {
		"key": ["id"],
		"columns": {"id": ID, "slug": SLUG, "name": TEXT},
	},
	"status_conditions": {
		"key": ["id"],
		"columns": {
			"id": ID,
			"slug": SLUG,
			"name": TEXT,
			"is_volatile": {"type": "bool"},
		},
	},
	"status_condition_immunities": {
		"key": ["status_condition_id", "element_id"],
		"columns": {
			"status_condition_id": {"type": "int", "fk": "status_conditions"},
			"element_id": {"type": "int", "fk": "elements"},
		},
	},
	"effect_types": {
		"key": ["id"],
		"columns": {"id": ID, "slug": SLUG, "name": TEXT},
	},
	"evolution_triggers": {
		"key": ["id"],
		"columns": {"id": ID, "slug": SLUG, "name": TEXT},
	},
	# --- Conteúdo -------------------------------------------------------------
	"species": {
		"key": ["id"],
		"columns": {
			"id": ID,
			"slug": SLUG,
			"name": TEXT,
			"description": TEXT,
			"growth_rate_id": {"type": "int", "fk": "growth_rates"},
			"rarity_id": {"type": "int", "fk": "rarities"},
			"base_xp_yield": {"type": "int", "min": 1},
			"capture_rate": {"type": "int", "min": 3, "max": 255},
			"gender_ratio": {"type": "float", "min": -1.0, "max": 1.0},
			"height_m": {"type": "float", "min": 0.0},
			"weight_kg": {"type": "float", "min": 0.0},
			"evolves_from_species_id": {"type": "int", "nullable": true, "fk": "species"},
		},
	},
	"species_elements": {
		"key": ["species_id", "slot"],
		"columns": {
			"species_id": {"type": "int", "fk": "species"},
			"slot": {"type": "int", "values": [1, 2]},
			"element_id": {"type": "int", "fk": "elements"},
		},
	},
	"species_stats": {
		"key": ["species_id", "stat_id"],
		"columns": {
			"species_id": {"type": "int", "fk": "species"},
			"stat_id": {"type": "int", "fk": "stats"},
			"base_value": {"type": "int", "min": 1, "max": 255},
			"training_yield": {"type": "int", "min": 0, "max": 3},
		},
	},
	"traits": {
		"key": ["id"],
		"columns": {"id": ID, "slug": SLUG, "name": TEXT, "description": TEXT},
	},
	"species_traits": {
		"key": ["species_id", "slot"],
		"columns": {
			"species_id": {"type": "int", "fk": "species"},
			"trait_id": {"type": "int", "fk": "traits"},
			"slot": {"type": "int", "values": [1, 2, 3]},
			"is_hidden": {"type": "bool"},
		},
	},
	"skills": {
		"key": ["id"],
		"columns": {
			"id": ID,
			"slug": SLUG,
			"name": TEXT,
			"description": TEXT,
			"element_id": {"type": "int", "fk": "elements"},
			"skill_category_id": {"type": "int", "fk": "skill_categories"},
			"power": {"type": "int", "min": 0, "max": 250},
			"accuracy": {"type": "int", "min": 0, "max": 100},
			"max_pp": {"type": "int", "min": 5, "max": 40},
			"priority": {"type": "int", "min": -7, "max": 5},
			"crit_stage": {"type": "int", "min": 0, "max": 3},
			"skill_target_id": {"type": "int", "fk": "skill_targets"},
			"makes_contact": {"type": "bool"},
			"min_hits": {"type": "int", "min": 1, "max": 10},
			"max_hits": {"type": "int", "min": 1, "max": 10},
		},
	},
	"skill_effects": {
		"key": ["id"],
		"columns": {
			"id": ID,
			"skill_id": {"type": "int", "fk": "skills"},
			"effect_type_id": {"type": "int", "fk": "effect_types"},
			"sort_order": {"type": "int", "min": 1},
			"chance": {"type": "int", "min": 1, "max": 100},
			"skill_target_id": {"type": "int", "nullable": true, "fk": "skill_targets"},
			"status_condition_id": {"type": "int", "nullable": true, "fk": "status_conditions"},
			"stat_id": {"type": "int", "nullable": true, "fk": "stats"},
			"stages": {"type": "int", "nullable": true, "min": -6, "max": 6},
			"percent": {"type": "int", "nullable": true, "min": 1, "max": 100},
			"value": {"type": "int", "nullable": true, "min": 1},
			"weather_id": {"type": "int", "nullable": true, "fk_future": "weathers"},
			"min_turns": {"type": "int", "nullable": true, "min": 1},
		},
	},
	"species_skills": {
		"key": ["species_id", "skill_id", "skill_learn_method_id"],
		"columns": {
			"species_id": {"type": "int", "fk": "species"},
			"skill_id": {"type": "int", "fk": "skills"},
			"skill_learn_method_id": {"type": "int", "fk": "skill_learn_methods"},
			"level": {"type": "int", "nullable": true, "min": 0, "max": 100},
		},
	},
	"evolutions": {
		"key": ["id"],
		"columns": {
			"id": ID,
			"species_id": {"type": "int", "fk": "species"},
			"evolved_species_id": {"type": "int", "fk": "species"},
			"evolution_trigger_id": {"type": "int", "fk": "evolution_triggers"},
			"min_level": {"type": "int", "nullable": true, "min": 1, "max": 100},
			"item_id": {"type": "int", "nullable": true, "fk_future": "items"},
			"min_bond": {"type": "int", "nullable": true, "min": 0, "max": 255},
			"time_of_day": {"type": "string", "nullable": true, "values": ["day", "night"]},
			"zone_id": {"type": "int", "nullable": true, "fk_future": "zones"},
		},
	},
	"starter_options": {
		"key": ["species_id"],
		"columns": {
			"species_id": {"type": "int", "fk": "species"},
			"sort_order": {"type": "int", "unique": true},
		},
	},
}


## Nomes das tabelas, na ordem em que aparecem no schema.
static func table_names() -> PackedStringArray:
	return PackedStringArray(TABLES.keys())


## Converte os valores de uma linha já validada para os tipos do schema
## (o JSON do Godot lê todo número como float).
static func normalize_row(table_name: String, row: Dictionary) -> Dictionary:
	var columns: Dictionary = TABLES[table_name]["columns"]
	var result: Dictionary = {}
	for column: String in columns:
		var value: Variant = row[column]
		if value != null:
			match String(columns[column]["type"]):
				"int":
					value = int(value)
				"float":
					value = float(value)
		result[column] = value
	return result
