class_name HexTile
extends RefCounted
## Um hexágono do mapa de exploração (.specs/wild-battle/architecture.md): a
## posição em coordenadas axiais (x = q, y = r) e o terreno.

const SPRITE_PATH := "res://assets/terrain/%s_%s_%02d.png"

var coord: Vector2i
var biome: String
var shape: String
var variant: int


func sprite_path() -> String:
	return SPRITE_PATH % [biome, shape, variant]


## null se faltar a posição, o bioma ou a forma.
static func from_dict(d: Dictionary) -> HexTile:
	var biome_slug := DictFields.get_string(d, "biome")
	var shape_slug := DictFields.get_string(d, "shape")
	if not (d.has("q") and d.has("r")) or biome_slug.is_empty() or shape_slug.is_empty():
		return null
	var tile := HexTile.new()
	tile.coord = Vector2i(DictFields.get_int(d, "q"), DictFields.get_int(d, "r"))
	tile.biome = biome_slug
	tile.shape = shape_slug
	tile.variant = DictFields.get_int(d, "variant", 1)
	return tile
