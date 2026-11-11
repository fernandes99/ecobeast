class_name IslandSummary
extends RefCounted

var id: int = 0
var name: String = ""


static func from_dict(d: Dictionary) -> IslandSummary:
	var island := IslandSummary.new()
	island.id = DictFields.get_int(d, "id")
	island.name = DictFields.get_string(d, "name")
	return island if island.id > 0 and not island.name.is_empty() else null
