class_name Player
extends RefCounted
## O Domador (.specs/onboarding/architecture.md, "Modelos").
## to_dict/from_dict é o formato do save e da API.

## Nome já normalizado: 2 a 16 letras, números ou espaços.
const NAME_PATTERN := "^[\\p{L}\\p{N} ]{2,16}$"

var id: String
var name: String
var level: int = 1
var coins: int = 0
## ISO 8601 em UTC.
var created_at: String
## Na ordem dos slots da equipe.
var party: Array[CreatureInstance] = []


func has_starter() -> bool:
	return not party.is_empty()


## Tira os espaços das pontas e troca sequências de espaços por um só.
static func normalize_name(raw_name: String) -> String:
	var spaces := RegEx.create_from_string("\\s+")
	return spaces.sub(raw_name.strip_edges(), " ", true)


## Recebe o nome já normalizado.
static func is_valid_name(normalized_name: String) -> bool:
	return RegEx.create_from_string(NAME_PATTERN).search(normalized_name) != null


func to_dict() -> Dictionary:
	var party_dicts: Array[Dictionary] = []
	for creature: CreatureInstance in party:
		party_dicts.append(creature.to_dict())
	return {
		"id": id,
		"name": name,
		"level": level,
		"coins": coins,
		"created_at": created_at,
		"party": party_dicts,
	}


static func from_dict(d: Dictionary) -> Player:
	var player := Player.new()
	player.id = DictFields.get_string(d, "id")
	player.name = DictFields.get_string(d, "name")
	player.level = DictFields.get_int(d, "level", 1)
	player.coins = DictFields.get_int(d, "coins")
	player.created_at = DictFields.get_string(d, "created_at")
	for creature_dict: Variant in DictFields.get_array(d, "party"):
		if creature_dict is Dictionary:
			player.party.append(CreatureInstance.from_dict(creature_dict))
	return player
