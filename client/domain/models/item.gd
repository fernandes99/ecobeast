class_name Item
extends RefCounted

var id: int
var slug: String
var name: String
var description: String
var item_category_id: int
## 0: sem preço, fora da Loja (auralis/11).
var price: int = 0
var sort_order: int
var capture_bonus: float = 0.0
var heal_amount: int = 0
var cures_status: bool = false


func can_be_used() -> bool:
	return heal_amount > 0 or cures_status


func can_capture() -> bool:
	return capture_bonus > 0.0


func for_sale() -> bool:
	return price > 0


static func from_row(row: Dictionary) -> Item:
	var item := Item.new()
	item.id = row["id"]
	item.slug = row["slug"]
	item.name = row["name"]
	item.description = row["description"]
	item.item_category_id = row["item_category_id"]
	if row["price"] != null:
		item.price = row["price"]
	item.sort_order = row["sort_order"]
	if row["capture_bonus"] != null:
		item.capture_bonus = row["capture_bonus"]
	if row["heal_amount"] != null:
		item.heal_amount = row["heal_amount"]
	item.cures_status = row["cures_status"]
	return item
