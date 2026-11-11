class_name MapTamer
extends RefCounted

var id: int = 0
var coord := Vector2i.ZERO
var name_id: int = 0
var greeting_id: int = 0


static func from_dict(d: Dictionary) -> MapTamer:
	for key: String in ["id", "q", "r", "name_id", "greeting_id"]:
		if not d.has(key):
			return null
	var tamer := MapTamer.new()
	tamer.id = DictFields.get_int(d, "id")
	tamer.coord = Vector2i(DictFields.get_int(d, "q"), DictFields.get_int(d, "r"))
	tamer.name_id = DictFields.get_int(d, "name_id")
	tamer.greeting_id = DictFields.get_int(d, "greeting_id")
	return tamer

