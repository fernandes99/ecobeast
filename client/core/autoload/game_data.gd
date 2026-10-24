extends Node
## Autoload GameData: o catálogo do jogo (espécies, técnicas, elementos…).
## Telas e serviços leem o catálogo só por aqui. Quem chama load_catalog()
## é o boot da cena raiz.

## Resultados de load_catalog().
const LOAD_OK := 0
## O servidor não respondeu (o jogo é só online).
const LOAD_OFFLINE := 1
## O catálogo chegou com erros; a lista fica em errors.
const LOAD_INVALID := 2

const BASE_URL_SETTING := "ecobeast/api/base_url"

var catalog := Catalog.new()
var errors: Array[String] = []


## Baixa, valida e monta o catálogo (.specs/backend-api/07-client-remote-catalog.md).
## Assíncrono: chame com await. Devolve LOAD_OK, LOAD_OFFLINE ou LOAD_INVALID.
func load_catalog() -> int:
	var source := HttpDataSource.new(ProjectSettings.get_setting(BASE_URL_SETTING))
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


func get_skill(id: int) -> Skill:
	return catalog.get_skill(id)


func get_trait(id: int) -> CreatureTrait:
	return catalog.get_trait(id)


func get_species_traits(species_id: int) -> Array[Dictionary]:
	return catalog.get_species_traits(species_id)


func get_temperament(id: int) -> Temperament:
	return catalog.get_temperament(id)


func get_temperaments() -> Array[Temperament]:
	return catalog.get_temperaments()


func get_growth_rate(id: int) -> GrowthRate:
	return catalog.get_growth_rate(id)


func get_stat_id(slug: String) -> int:
	return catalog.get_stat_id(slug)


func get_row(table_name: String, id: int) -> Dictionary:
	return catalog.get_row(table_name, id)
