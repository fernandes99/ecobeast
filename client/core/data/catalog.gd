class_name Catalog
extends RefCounted
## O catálogo carregado: converte as tabelas em modelos tipados, monta os
## índices e responde às consultas. Usado pelo autoload GameData.

var _tables: Dictionary = {}          # tabela -> Array[Dictionary] (normalizadas)
var _rows_by_id: Dictionary = {}      # tabela -> {id: linha}
var _stat_ids: Dictionary = {}        # slug -> id
var _stat_slugs: Dictionary = {}      # id -> slug
var _elements: Dictionary = {}        # id -> Element
var _element_list: Array[Element] = []
var _element_count: int = 0
var _efficacy := PackedFloat32Array()
var _growth_rates: Dictionary = {}    # id -> GrowthRate
var _traits: Dictionary = {}          # id -> CreatureTrait
var _temperaments: Dictionary = {}    # id -> Temperament
var _temperament_list: Array[Temperament] = []
var _species: Dictionary = {}         # id -> CreatureSpecies
var _species_list: Array[CreatureSpecies] = []
var _skills: Dictionary = {}          # id -> Skill
var _learnsets: Dictionary = {}       # species_id -> Array[LearnsetEntry]
var _evolutions: Dictionary = {}      # species_id -> Array[EvolutionRule]
var _species_traits: Dictionary = {}  # species_id -> Array[Dictionary]
var _starters: Array[CreatureSpecies] = []


## Carrega todas as tabelas do schema pela fonte, valida e monta o catálogo.
## Devolve a lista de erros; com erros, o catálogo fica vazio.
func load_from(source: DataSource) -> Array[String]:
	_clear()
	var names := CatalogSchema.table_names()
	var tables := source.load_tables(names)
	var errors: Array[String] = []
	errors.append_array(source.get_errors())
	errors.append_array(CatalogValidator.validate(tables))
	if not errors.is_empty():
		return errors

	for table_name: String in names:
		var normalized: Array[Dictionary] = []
		for row: Dictionary in tables[table_name]:
			normalized.append(CatalogSchema.normalize_row(table_name, row))
		_tables[table_name] = normalized
	_build()
	return errors


func table_count() -> int:
	return _tables.size()


func row_count() -> int:
	var total := 0
	for table_name: String in _tables:
		total += _rows(table_name).size()
	return total


# --- Consultas ------------------------------------------------------------------

func get_element(id: int) -> Element:
	return _lookup(_elements, id, "elemento")


func get_elements() -> Array[Element]:
	return _element_list


## Multiplicador de dano de um elemento atacante contra os elementos do defensor.
func get_efficacy(attacker_element_id: int, defender_element_ids: Array[int]) -> float:
	var result := 1.0
	for defender_id: int in defender_element_ids:
		if not _elements.has(attacker_element_id) or not _elements.has(defender_id):
			push_error("Catálogo: elemento inexistente em get_efficacy(%d, %s)" % [attacker_element_id, defender_element_ids])
			return 1.0
		result *= _efficacy[(attacker_element_id - 1) * _element_count + (defender_id - 1)]
	return result


func get_species(id: int) -> CreatureSpecies:
	return _lookup(_species, id, "espécie")


func get_all_species() -> Array[CreatureSpecies]:
	return _species_list


func get_starters() -> Array[CreatureSpecies]:
	return _starters


## Técnicas por nível e ao ascender, por nível (as de ascender, nível 0, primeiro).
func get_learnset(species_id: int) -> Array[LearnsetEntry]:
	var empty: Array[LearnsetEntry] = []
	return _learnsets.get(species_id, empty)


func get_evolutions(species_id: int) -> Array[EvolutionRule]:
	var empty: Array[EvolutionRule] = []
	return _evolutions.get(species_id, empty)


func get_skill(id: int) -> Skill:
	return _lookup(_skills, id, "técnica")


func get_trait(id: int) -> CreatureTrait:
	return _lookup(_traits, id, "traço")


## Linhas de species_traits da espécie, por slot.
func get_species_traits(species_id: int) -> Array[Dictionary]:
	var empty: Array[Dictionary] = []
	return _species_traits.get(species_id, empty)


func get_temperament(id: int) -> Temperament:
	return _lookup(_temperaments, id, "temperamento")


func get_temperaments() -> Array[Temperament]:
	return _temperament_list


func get_growth_rate(id: int) -> GrowthRate:
	return _lookup(_growth_rates, id, "curva de XP")


func get_stat_id(slug: String) -> int:
	if not _stat_ids.has(slug):
		push_error("Catálogo: stat '%s' não existe" % slug)
		return -1
	return _stat_ids[slug]


## Linha de uma tabela de referência sem modelo próprio (rarities, status_conditions…).
func get_row(table_name: String, id: int) -> Dictionary:
	var by_id: Dictionary = _rows_by_id.get(table_name, {})
	if not by_id.has(id):
		push_error("Catálogo: %s.json não tem id %d" % [table_name, id])
		return {}
	return by_id[id]


# --- Montagem -------------------------------------------------------------------

func _clear() -> void:
	_tables.clear()
	_rows_by_id.clear()
	_stat_ids.clear()
	_stat_slugs.clear()
	_elements.clear()
	_element_list.clear()
	_element_count = 0
	_efficacy.clear()
	_growth_rates.clear()
	_traits.clear()
	_temperaments.clear()
	_temperament_list.clear()
	_species.clear()
	_species_list.clear()
	_skills.clear()
	_learnsets.clear()
	_evolutions.clear()
	_species_traits.clear()
	_starters.clear()


func _build() -> void:
	for table_name: String in _tables:
		var by_id: Dictionary = {}
		for row: Dictionary in _rows(table_name):
			if row.has("id"):
				by_id[row["id"]] = row
		_rows_by_id[table_name] = by_id

	for row: Dictionary in _rows("stats"):
		_stat_ids[row["slug"]] = row["id"]
		_stat_slugs[row["id"]] = row["slug"]

	_build_elements()

	for row: Dictionary in _rows("growth_rates"):
		_growth_rates[row["id"]] = GrowthRate.from_row(row)
	for row: Dictionary in _rows("traits"):
		_traits[row["id"]] = CreatureTrait.from_row(row)
	for row: Dictionary in _sorted(_rows("temperaments"), "id"):
		var temperament := Temperament.from_row(row)
		temperament.increased_stat_slug = _stat_slugs[temperament.increased_stat_id]
		temperament.decreased_stat_slug = _stat_slugs[temperament.decreased_stat_id]
		_temperaments[temperament.id] = temperament
		_temperament_list.append(temperament)

	_build_species()
	_build_skills()
	_build_learnsets()

	for row: Dictionary in _rows("evolutions"):
		var trigger_slug: String = _rows_by_id["evolution_triggers"][row["evolution_trigger_id"]]["slug"]
		_append_to(_evolutions, row["species_id"], EvolutionRule.from_row(row, trigger_slug), [] as Array[EvolutionRule])

	for row: Dictionary in _sorted(_rows("species_traits"), "slot"):
		_append_to(_species_traits, row["species_id"], row, [] as Array[Dictionary])

	for row: Dictionary in _sorted(_rows("starter_options"), "sort_order"):
		_starters.append(_species[row["species_id"]])


func _build_elements() -> void:
	for row: Dictionary in _sorted(_rows("elements"), "id"):
		var element := Element.from_row(row)
		_elements[element.id] = element
		_element_list.append(element)
		_element_count = maxi(_element_count, element.id)
	_efficacy.resize(_element_count * _element_count)
	_efficacy.fill(1.0)
	for row: Dictionary in _rows("element_efficacy"):
		var index: int = (row["attacker_element_id"] - 1) * _element_count + (row["defender_element_id"] - 1)
		_efficacy[index] = row["multiplier"]


func _build_species() -> void:
	for row: Dictionary in _sorted(_rows("species"), "id"):
		var species := CreatureSpecies.from_row(row)
		_species[species.id] = species
		_species_list.append(species)
	for row: Dictionary in _sorted(_rows("species_elements"), "slot"):
		var species: CreatureSpecies = _species[row["species_id"]]
		species.element_ids.append(row["element_id"])
	for row: Dictionary in _rows("species_stats"):
		var species: CreatureSpecies = _species[row["species_id"]]
		var slug: String = _stat_slugs[row["stat_id"]]
		species.base_stats.set_value(slug, row["base_value"])
		species.training_yield.set_value(slug, row["training_yield"])


func _build_skills() -> void:
	for row: Dictionary in _rows("skills"):
		_skills[row["id"]] = Skill.from_row(row)
	for row: Dictionary in _sorted(_rows("skill_effects"), "sort_order"):
		var effect_slug: String = _rows_by_id["effect_types"][row["effect_type_id"]]["slug"]
		var skill: Skill = _skills[row["skill_id"]]
		skill.effects.append(SkillEffect.from_row(row, effect_slug))


func _build_learnsets() -> void:
	var file_order: Dictionary = {}  # LearnsetEntry -> posição no arquivo, para desempate
	var rows := _rows("species_skills")
	for i: int in rows.size():
		var row := rows[i]
		var method_slug: String = _rows_by_id["skill_learn_methods"][row["skill_learn_method_id"]]["slug"]
		if method_slug != "level_up" and method_slug != "evolution":
			continue
		var entry := LearnsetEntry.create(row["skill_id"], row["level"], method_slug)
		file_order[entry] = i
		_append_to(_learnsets, row["species_id"], entry, [] as Array[LearnsetEntry])
	for species_id: int in _learnsets:
		var entries: Array[LearnsetEntry] = _learnsets[species_id]
		entries.sort_custom(func(a: LearnsetEntry, b: LearnsetEntry) -> bool:
			if a.level != b.level:
				return a.level < b.level
			return file_order[a] < file_order[b])


# --- Utilitários ----------------------------------------------------------------

func _rows(table_name: String) -> Array[Dictionary]:
	var empty: Array[Dictionary] = []
	return _tables.get(table_name, empty)


## Cópia das linhas ordenada por uma coluna inteira.
func _sorted(rows: Array[Dictionary], column: String) -> Array[Dictionary]:
	var result := rows.duplicate()
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a[column] < b[column])
	return result


func _append_to(groups: Dictionary, key: Variant, item: Variant, empty: Array) -> void:
	if not groups.has(key):
		groups[key] = empty
	groups[key].append(item)


func _lookup(index: Dictionary, id: int, label: String) -> Variant:
	if not index.has(id):
		push_error("Catálogo: %s %d não existe" % [label, id])
		return null
	return index[id]
