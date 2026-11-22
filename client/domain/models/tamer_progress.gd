class_name TamerProgress
extends RefCounted

var xp_gained: int = 0
var level_before: int = 1
var level_after: int = 1
## Cada nível subido: `level`, `reward_coins`, `reward_item_id` (-1 sem item) e `reward_item_quantity`.
var levels: Array[Dictionary] = []


func leveled_up() -> bool:
	return not levels.is_empty()


func reward_coins() -> int:
	var total := 0
	for row: Dictionary in levels:
		total += int(row["reward_coins"])
	return total


## O id do item e a quantidade somada de todos os níveis subidos.
func reward_items() -> Dictionary:
	var items := {}
	for row: Dictionary in levels:
		var item_id: int = row["reward_item_id"]
		if item_id < 0:
			continue
		items[item_id] = int(items.get(item_id, 0)) + int(row["reward_item_quantity"])
	return items


static func from_dict(d: Dictionary) -> TamerProgress:
	var progress := TamerProgress.new()
	progress.xp_gained = DictFields.get_int(d, "xp_gained")
	progress.level_before = DictFields.get_int(d, "level_before", 1)
	progress.level_after = DictFields.get_int(d, "level_after", 1)
	for row: Variant in DictFields.get_array(d, "levels"):
		if row is Dictionary:
			progress.levels.append({
				"level": DictFields.get_int(row, "level"),
				"reward_coins": DictFields.get_int(row, "reward_coins"),
				"reward_item_id": DictFields.get_id(row, "reward_item_id"),
				"reward_item_quantity": DictFields.get_int(row, "reward_item_quantity"),
			})
	return progress
