class_name InteriorTile
extends RefCounted

## Um tile de uma camada da sala (interiors/01): `atlas` é a coluna e a linha na folha.

var layer := ""
var cell := Vector2i.ZERO
var sheet := ""
var atlas := Vector2i.ZERO


static func make(tile_layer: String, at: Vector2i, tile_sheet: String, tile_atlas: Vector2i) -> InteriorTile:
	var tile := InteriorTile.new()
	tile.layer = tile_layer
	tile.cell = at
	tile.sheet = tile_sheet
	tile.atlas = tile_atlas
	return tile


static func from_dict(d: Dictionary) -> InteriorTile:
	return InteriorTile.make(
		DictFields.get_string(d, "layer"),
		Vector2i(DictFields.get_int(d, "x"), DictFields.get_int(d, "y")),
		DictFields.get_string(d, "sheet"),
		Vector2i(DictFields.get_int(d, "col"), DictFields.get_int(d, "row")))


func to_dict() -> Dictionary:
	return {"layer": layer, "x": cell.x, "y": cell.y, "sheet": sheet, "col": atlas.x, "row": atlas.y}
