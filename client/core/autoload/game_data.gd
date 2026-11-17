extends Node

## A variante das linhas de bloqueio que vale para todas (prop-depth-blocks/02).
const ALL_VARIANTS := 0
const LOAD_OK := 0
const LOAD_OFFLINE := 1
const LOAD_INVALID := 2

const BASE_URL_SETTING := "ecobeast/api/base_url"

var catalog := Catalog.new()
var errors: Array[String] = []


func load_catalog() -> int:
	var source := HttpDataSource.new(ProjectSettings.get_setting_with_override(BASE_URL_SETTING))
	var status: int = await _load_from(source)
	if status == LOAD_INVALID and source.used_cache:
		# A cópia guardada está estragada, e o servidor responderia 304 para ela
		# de novo. Apaga e baixa tudo, uma vez só.
		push_warning("Catálogo guardado com erros; baixando de novo.")
		source.clear_cache()
		status = await _load_from(source)
	return status


func _load_from(source: HttpDataSource) -> int:
	if not await source.fetch(self):
		errors = source.get_errors()
		return LOAD_OFFLINE
	errors = catalog.load_from(source)
	return LOAD_OK if errors.is_empty() else LOAD_INVALID


func get_element(id: int) -> Element:
	return catalog.get_element(id)


func get_elements() -> Array[Element]:
	return catalog.get_elements()


func get_efficacy(attacker_element_id: int, defender_element_ids: Array[int]) -> float:
	return catalog.get_efficacy(attacker_element_id, defender_element_ids)


func get_species(id: int) -> CreatureSpecies:
	return catalog.get_species(id)


func get_all_species() -> Array[CreatureSpecies]:
	return catalog.get_all_species()


func get_starters() -> Array[CreatureSpecies]:
	return catalog.get_starters()


func get_learnset(species_id: int) -> Array[LearnsetEntry]:
	return catalog.get_learnset(species_id)


func get_evolutions(species_id: int) -> Array[EvolutionRule]:
	return catalog.get_evolutions(species_id)


func get_evolution_line(species_id: int) -> Array[Dictionary]:
	return catalog.get_evolution_line(species_id)


func get_habitat_names(species_id: int) -> Array[String]:
	return catalog.get_habitat_names(species_id)


func get_skill(id: int) -> Skill:
	return catalog.get_skill(id)


func get_ground_effect(id: int) -> GroundEffect:
	return catalog.get_ground_effect(id)


func get_trait(id: int) -> CreatureTrait:
	return catalog.get_trait(id)


func get_species_traits(species_id: int) -> Array[Dictionary]:
	return catalog.get_species_traits(species_id)


func get_temperament(id: int) -> Temperament:
	return catalog.get_temperament(id)


func get_temperaments() -> Array[Temperament]:
	return catalog.get_temperaments()


func get_item(id: int) -> Item:
	return catalog.get_item(id)


func get_items() -> Array[Item]:
	return catalog.get_items()


func get_item_categories() -> Array[ItemCategory]:
	return catalog.get_item_categories()


func get_day_phases() -> Array[DayPhase]:
	return catalog.get_day_phases()


func get_growth_rate(id: int) -> GrowthRate:
	return catalog.get_growth_rate(id)


func get_stat_id(slug: String) -> int:
	return catalog.get_stat_id(slug)


func get_status_name(slug: String) -> String:
	return catalog.get_status_name(slug)


func get_stat_name(slug: String) -> String:
	return catalog.get_stat_name(slug)


func get_npc_tamer_name(id: int) -> String:
	return catalog.get_npc_tamer_name(id)


func get_npc_tamer_greeting(id: int) -> String:
	return catalog.get_npc_tamer_greeting(id)


## A linha do NPC no catálogo (`name`, `description`, `sprite`), ou vazia.
func get_npc(id: int) -> Dictionary:
	return catalog.get_row("npcs", id)


## A linha da voz (`slug`, `chars_per_second`, `letters_per_blip`, `pitch_variation`), ou vazia.
func get_voice(id: int) -> Dictionary:
	return catalog.get_voice(id)


func voice_by_slug(slug: String) -> Dictionary:
	return catalog.voice_by_slug(slug)


## A voz do NPC do catálogo, ou vazia.
func npc_voice(npc_id: int) -> Dictionary:
	return get_voice(int(get_npc(npc_id).get("voice_id", 0))) if npc_id > 0 else {}


func set_npc_voice(npc_id: int, voice_id: int) -> void:
	catalog.set_npc_voice(npc_id, voice_id)


func get_rows(table_name: String) -> Array[Dictionary]:
	return catalog.get_rows(table_name)


## As linhas de bloqueio padrão de uma variante de um tipo de peça, na ordem: as dela ou,
## sem elas, as da variante 0, que vale para todas (free-objects, prop-depth-blocks/02).
## `{"closed": bool, "points": Array[int]}`.
func get_prop_blocks(prop_type_id: int, variant: int = ALL_VARIANTS) -> Array[Dictionary]:
	var lines := variant_prop_blocks(prop_type_id, variant)
	if lines.is_empty() and variant != ALL_VARIANTS:
		lines = variant_prop_blocks(prop_type_id, ALL_VARIANTS)
	return lines


## Só as linhas guardadas para a variante, sem cair na 0.
func variant_prop_blocks(prop_type_id: int, variant: int) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	var rows := get_rows("prop_type_blocks").filter(func(row: Dictionary) -> bool: return int(row["prop_type_id"]) == prop_type_id and int(row.get("variant", ALL_VARIANTS)) == variant)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["position"]) < int(b["position"]))
	for row: Dictionary in rows:
		lines.append({"closed": row["closed"], "points": row["points"]})
	return lines


func set_prop_blocks(prop_type_id: int, variant: int, lines: Array[Dictionary]) -> void:
	catalog.replace_prop_blocks(prop_type_id, variant, lines)


## As linhas guardadas de cada tipo e variante que têm alguma, por `prop_block_key`.
func prop_blocks_by_key() -> Dictionary:
	var by_key := {}
	for row: Dictionary in get_rows("prop_type_blocks"):
		var type_id := int(row["prop_type_id"])
		var variant := int(row.get("variant", ALL_VARIANTS))
		var key := prop_block_key(type_id, variant)
		if not by_key.has(key):
			by_key[key] = variant_prop_blocks(type_id, variant)
	return by_key


## Os tipos de peça com alguma linha de bloqueio guardada, em qualquer variante.
func prop_block_types() -> Dictionary[int, bool]:
	var types: Dictionary[int, bool] = {}
	for row: Dictionary in get_rows("prop_type_blocks"):
		types[int(row["prop_type_id"])] = true
	return types


## Os pontos de luz da noite de cada tipo e variante que têm algum, por (tipo, variante),
## na ordem (day-night/03). A variante sem luzes próprias usa as da variante 0.
func prop_lights_by_key() -> Dictionary[Vector2i, Array]:
	var by_key: Dictionary[Vector2i, Array] = {}
	var rows := get_rows("prop_type_lights")
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["position"]) < int(b["position"]))
	for row: Dictionary in rows:
		var key := Vector2i(int(row["prop_type_id"]), int(row.get("variant", ALL_VARIANTS)))
		if not by_key.has(key):
			by_key[key] = []
		by_key[key].append(row)
	return by_key


static func prop_block_key(prop_type_id: int, variant: int) -> String:
	return "%d:%d" % [prop_type_id, variant]


func get_row(table_name: String, id: int) -> Dictionary:
	return catalog.get_row(table_name, id)
