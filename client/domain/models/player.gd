class_name Player
extends RefCounted

const NAME_PATTERN := "^[\\p{L}\\p{N} ]{2,16}$"
const PARTY_SIZE := 6

var id: String
var name: String
var level: int = 1
var coins: int = 0
var created_at: String
var party: Array[CreatureInstance] = []
var inventory: Array[InventorySlot] = []


func has_starter() -> bool:
	return not party.is_empty()


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
	player.coins = DictFields.get_int(d, "coins")
	player.created_at = DictFields.get_string(d, "created_at")
	for creature_dict: Variant in DictFields.get_array(d, "party"):
		if creature_dict is Dictionary:
			player.party.append(CreatureInstance.from_dict(creature_dict))
	for slot_dict: Variant in DictFields.get_array(d, "inventory"):
		if slot_dict is Dictionary:
			player.inventory.append(InventorySlot.from_dict(slot_dict))
	return player
