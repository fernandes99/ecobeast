class_name ItemCategory
extends RefCounted
## Uma categoria de item (tabela item_categories): uma aba da Loja.

var id: int
var slug: String
var name: String
var sort_order: int


static func from_row(row: Dictionary) -> ItemCategory:
	var category := ItemCategory.new()
	category.id = row["id"]
	category.slug = row["slug"]
	category.name = row["name"]
	category.sort_order = row["sort_order"]
	return category
