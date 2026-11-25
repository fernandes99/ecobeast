class_name InteriorObject
extends RefCounted

## Um retângulo de tiles de uma folha, posto inteiro na sala (interiors/01): `cell` é o
## quadrado do canto de cima à esquerda e `atlas` o tile desse canto na folha.

var id: int = 0
var cell := Vector2i.ZERO
var sheet := ""
var atlas := Vector2i.ZERO
var size := Vector2i.ONE
## O tipo de ação do toque no objeto (interiors/04), 0 sem ação.
var action_type_id: int = 0


static func from_dict(d: Dictionary) -> InteriorObject:
	var item := InteriorObject.new()
	item.id = DictFields.get_int(d, "id")
	item.cell = Vector2i(DictFields.get_int(d, "x"), DictFields.get_int(d, "y"))
	item.sheet = DictFields.get_string(d, "sheet")
	item.atlas = Vector2i(DictFields.get_int(d, "col"), DictFields.get_int(d, "row"))
	item.size = Vector2i(maxi(1, DictFields.get_int(d, "width", 1)), maxi(1, DictFields.get_int(d, "height", 1)))
	item.action_type_id = maxi(0, DictFields.get_int(d, "action_type_id"))
	return item


func to_dict() -> Dictionary:
	return {
		"id": id, "x": cell.x, "y": cell.y, "sheet": sheet, "col": atlas.x, "row": atlas.y,
		"width": size.x, "height": size.y, "action_type_id": action_type_id if action_type_id > 0 else null,
	}


func rect() -> Rect2i:
	return Rect2i(cell, size)


## A linha da borda de baixo, em quadrados.
func foot_y() -> int:
	return cell.y + size.y
