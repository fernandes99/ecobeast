class_name MapObject
extends RefCounted

var object_type_id: int = 0
var coord := Vector2i.ZERO
var variant: int = 1
var mirrored := false
var tiles: Array[Vector2i] = []
var blocks: Dictionary[Vector2i, bool] = {}


static func from_dict(d: Dictionary) -> MapObject:
	var object := MapObject.new()
	object.object_type_id = DictFields.get_int(d, "object_type_id")
	object.coord = Vector2i(DictFields.get_int(d, "q"), DictFields.get_int(d, "r"))
	object.variant = maxi(1, DictFields.get_int(d, "variant", 1))
	object.mirrored = DictFields.get_bool(d, "mirrored")
	for tile: Variant in DictFields.get_array(d, "tiles"):
		if tile is Dictionary and tile.has("q") and tile.has("r"):
			var at := Vector2i(DictFields.get_int(tile, "q"), DictFields.get_int(tile, "r"))
			object.tiles.append(at)
			object.blocks[at] = DictFields.get_bool(tile, "blocks")
	return object if object.object_type_id > 0 and not object.tiles.is_empty() else null


func blocked_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for at: Vector2i in tiles:
		if blocks.get(at, false):
			result.append(at)
	return result
