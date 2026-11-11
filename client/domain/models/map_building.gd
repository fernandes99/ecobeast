class_name MapBuilding
extends RefCounted
## Uma construção de uma ilha (islands/03): o tipo do catálogo (`building_types`)
## e os hexágonos dela.

var building_type_id: int = 0
var tiles: Array[Vector2i] = []


## null se faltar o tipo ou os hexágonos.
static func from_dict(d: Dictionary) -> MapBuilding:
	var building := MapBuilding.new()
	building.building_type_id = DictFields.get_int(d, "building_type_id")
	for tile: Variant in DictFields.get_array(d, "tiles"):
		if tile is Dictionary and tile.has("q") and tile.has("r"):
			building.tiles.append(Vector2i(DictFields.get_int(tile, "q"), DictFields.get_int(tile, "r")))
	return building if building.building_type_id > 0 and not building.tiles.is_empty() else null
