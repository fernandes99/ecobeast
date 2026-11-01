class_name StorageFilter
extends RefCounted
## A busca, o filtro e a ordem do Santuário (team-and-storage/02, RF-07 a RF-10).
## Só organiza o que o servidor mandou.

const ALL_ELEMENTS := -1
const ACCENTS: Dictionary[String, String] = {
	"á": "a", "à": "a", "â": "a", "ã": "a", "ä": "a",
	"é": "e", "ê": "e", "ë": "e",
	"í": "i", "ï": "i",
	"ó": "o", "ô": "o", "õ": "o", "ö": "o",
	"ú": "u", "ü": "u",
	"ç": "c",
}

var search: String = ""
var element_id: int = ALL_ELEMENTS
var highest_first: bool = true


func apply(creatures: Array[CreatureInstance]) -> Array[CreatureInstance]:
	var query := _normalized(search.strip_edges())
	var found: Array[CreatureInstance] = []
	for creature: CreatureInstance in creatures:
		if _matches(creature, query):
			found.append(creature)
	found.sort_custom(_comes_first)
	return found


func _matches(creature: CreatureInstance, query: String) -> bool:
	var species := GameData.get_species(creature.species_id)
	if element_id != ALL_ELEMENTS and not species.element_ids.has(element_id):
		return false
	# `contains` com texto vazio dá falso.
	if query.is_empty():
		return true
	return _normalized(creature.display_name(species)).contains(query) or _normalized(species.name).contains(query)


## Mesmo nível: a ordem não pode mudar a cada vez que a grade é refeita.
func _comes_first(first: CreatureInstance, second: CreatureInstance) -> bool:
	if first.level != second.level:
		return first.level > second.level if highest_first else first.level < second.level
	if first.species_id != second.species_id:
		return first.species_id < second.species_id
	return first.uid < second.uid


func _normalized(text: String) -> String:
	var result := text.to_lower()
	for accent: String in ACCENTS:
		result = result.replace(accent, ACCENTS[accent])
	return result
