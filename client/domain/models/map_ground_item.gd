class_name MapGroundItem
extends RefCounted

## Um item no chão de uma ilha que o Domador ainda pode pegar (auralis/09); o servidor
## já tirou os pegos.

var key := 0
var item_id := 0
var coord := Vector2i.ZERO
var quantity := 1
var hidden := false


static func from_dict(d: Dictionary) -> MapGroundItem:
	var item := MapGroundItem.new()
	item.key = DictFields.get_int(d, "key")
	item.item_id = DictFields.get_int(d, "item_id")
	item.coord = Vector2i(DictFields.get_int(d, "q"), DictFields.get_int(d, "r"))
	item.quantity = DictFields.get_int(d, "quantity", 1)
	item.hidden = DictFields.get_bool(d, "hidden")
	return item


static func list_from(rows: Array) -> Array[MapGroundItem]:
	var items: Array[MapGroundItem] = []
	for row: Variant in rows:
		if row is Dictionary and DictFields.get_int(row, "key") > 0:
			items.append(from_dict(row))
	return items
