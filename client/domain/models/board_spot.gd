class_name BoardSpot
extends RefCounted

var side: String = ""
var position: int = 0


static func create(spot_side: String, spot_position: int) -> BoardSpot:
	var spot := BoardSpot.new()
	spot.side = spot_side
	spot.position = spot_position
	return spot


static func from_dict(d: Dictionary) -> BoardSpot:
	return create(DictFields.get_string(d, "side"), DictFields.get_int(d, "position"))


func key() -> String:
	return "%s:%d" % [side, position]


func is_player() -> bool:
	return side == "player"
