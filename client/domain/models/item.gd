class_name Item
extends RefCounted
## Um item do jogo (tabela items). A tela só mostra: quem cobra e aplica o efeito
## é o servidor (.specs/inventory-shop/architecture.md).

var id: int
var slug: String
var name: String
var description: String
var item_category_id: int
var price: int
var sort_order: int
## 0 = não serve para capturar.
var capture_bonus: float = 0.0
## 0 = não cura HP.
var heal_amount: int = 0
var cures_status: bool = false


## Só decide se a tela oferece "Usar": quem confere o uso é o servidor.
func can_be_used() -> bool:
	return heal_amount > 0 or cures_status


static func from_row(row: Dictionary) -> Item:
	var item := Item.new()
	item.id = row["id"]
	item.slug = row["slug"]
	item.name = row["name"]
	item.description = row["description"]
	item.item_category_id = row["item_category_id"]
	item.price = row["price"]
	item.sort_order = row["sort_order"]
	if row["capture_bonus"] != null:
		item.capture_bonus = row["capture_bonus"]
	if row["heal_amount"] != null:
		item.heal_amount = row["heal_amount"]
	item.cures_status = row["cures_status"]
	return item
