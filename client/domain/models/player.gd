class_name Player
extends RefCounted

const NAME_PATTERN := "^[\\p{L}\\p{N} ]{2,16}$"
const PARTY_SIZE := 6

var id: String
var name: String
var level: int = 1
## O XP total do Domador e os limites do nível atual; -1 no próximo é o nível máximo (tamer-level/02).
var xp: int = 0
var level_xp: int = 0
var next_level_xp: int = -1
var coins: int = 0
var created_at: String
var party: Array[CreatureInstance] = []
var inventory: Array[InventorySlot] = []
var appearance := TamerAppearance.new()
## Os Marcos da história, em ordem alfabética (story/01).
var story_marks: Array[String] = []


func has_starter() -> bool:
	return not party.is_empty()


## O Domador nasce sem nome (`""`) e ganha o nome na introdução (liora-intro/01).
func has_name() -> bool:
	return not name.is_empty()


func is_max_level() -> bool:
	return next_level_xp < 0


func level_ratio() -> float:
	if is_max_level():
		return 1.0
	return clampf(float(xp - level_xp) / maxi(next_level_xp - level_xp, 1), 0.0, 1.0)


func quantity_of(item_id: int) -> int:
	for slot: InventorySlot in inventory:
		if slot.item_id == item_id:
			return slot.quantity
	return 0


static func normalize_name(raw_name: String) -> String:
	var spaces := RegEx.create_from_string("\\s+")
	return spaces.sub(raw_name.strip_edges(), " ", true)


static func is_valid_name(normalized_name: String) -> bool:
	return RegEx.create_from_string(NAME_PATTERN).search(normalized_name) != null


static func from_dict(d: Dictionary) -> Player:
	var player := Player.new()
	player.id = DictFields.get_string(d, "id")
	player.name = DictFields.get_string(d, "name")
	player.level = DictFields.get_int(d, "level", 1)
	player.xp = DictFields.get_int(d, "xp")
	player.level_xp = DictFields.get_int(d, "level_xp")
	player.next_level_xp = DictFields.get_id(d, "next_level_xp")
	player.coins = DictFields.get_int(d, "coins")
	player.created_at = DictFields.get_string(d, "created_at")
	for creature_dict: Variant in DictFields.get_array(d, "party"):
		if creature_dict is Dictionary:
			player.party.append(CreatureInstance.from_dict(creature_dict))
	for slot_dict: Variant in DictFields.get_array(d, "inventory"):
		if slot_dict is Dictionary:
			player.inventory.append(InventorySlot.from_dict(slot_dict))
	player.appearance = TamerAppearance.from_dict(DictFields.get_dict(d, "appearance"))
	player.story_marks = _strings(DictFields.get_array(d, "story_marks"))
	return player


static func _strings(items: Array) -> Array[String]:
	var result: Array[String] = []
	for item: Variant in items:
		if item is String:
			result.append(item)
	return result
