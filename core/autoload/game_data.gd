extends Node
## Autoload GameData: o catálogo do jogo (espécies, técnicas, elementos…).
## Telas e serviços leem o catálogo só por aqui. Quem chama load_catalog()
## é o boot da cena raiz.

var catalog := Catalog.new()
var errors: Array[String] = []


## Carrega e valida o catálogo. Em caso de falha, os motivos ficam em errors.
func load_catalog() -> bool:
	errors = catalog.load_from(StaticJsonDataSource.new())
	return errors.is_empty()


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
