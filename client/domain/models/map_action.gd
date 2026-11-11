class_name MapAction
extends RefCounted

var action_type_id: int = 0
var tiles: Array[Vector2i] = []


static func from_dict(d: Dictionary) -> MapAction:
	var action := MapAction.new()
	action.action_type_id = DictFields.get_int(d, "action_type_id")
	for tile: Variant in DictFields.get_array(d, "tiles"):
		if tile is Dictionary and tile.has("q") and tile.has("r"):
			action.tiles.append(Vector2i(DictFields.get_int(tile, "q"), DictFields.get_int(tile, "r")))
	return action if action.action_type_id > 0 and not action.tiles.is_empty() else null
