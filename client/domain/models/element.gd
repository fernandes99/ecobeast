class_name Element
extends RefCounted
## Um dos 14 elementos (tabela elements).

var id: int
var slug: String
var name: String
var color: Color
var is_rare: bool


static func from_row(row: Dictionary) -> Element:
	var element := Element.new()
	element.id = row["id"]
	element.slug = row["slug"]
	element.name = row["name"]
	element.color = Color.html(row["color_hex"])
	element.is_rare = row["is_rare"]
	return element
