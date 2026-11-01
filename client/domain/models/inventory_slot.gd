class_name InventorySlot
extends RefCounted
## Um item da Mochila, com a quantidade.

var item_id: int
var quantity: int


static func from_dict(d: Dictionary) -> InventorySlot:
	var slot := InventorySlot.new()
	slot.item_id = DictFields.get_int(d, "item_id")
	slot.quantity = DictFields.get_int(d, "quantity")
	return slot
