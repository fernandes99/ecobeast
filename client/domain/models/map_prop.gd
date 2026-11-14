class_name MapProp
extends RefCounted

## Uma peça solta da ilha: só enfeite (free-props). O pé fica em `offset` pixels da
## arte a partir do centro plano de `coord`.
var prop_type_id: int = 0
var coord := Vector2i.ZERO
var offset := Vector2i.ZERO
var variant: int = 1
var mirrored := false


static func from_dict(d: Dictionary) -> MapProp:
	var prop := MapProp.new()
	prop.prop_type_id = DictFields.get_int(d, "prop_type_id")
	prop.coord = Vector2i(DictFields.get_int(d, "q"), DictFields.get_int(d, "r"))
	prop.offset = Vector2i(DictFields.get_int(d, "dx"), DictFields.get_int(d, "dy"))
	prop.variant = maxi(1, DictFields.get_int(d, "variant", 1))
	prop.mirrored = DictFields.get_bool(d, "mirrored")
	return prop if prop.prop_type_id > 0 else null
