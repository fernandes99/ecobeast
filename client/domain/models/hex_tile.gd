class_name HexTile
extends RefCounted
## Um hexágono do mapa de exploração (.specs/wild-battle/architecture.md): a
## posição em coordenadas axiais (x = q, y = r) e o terreno.

const WATER_BIOMES: Array[String] = ["wshallow", "wdeep"]

var coord: Vector2i
var biome: String
var shape: String
var variant: int


## A textura que este hexágono mostra: colina e montanha têm a sua, em qualquer
## bioma; o resto usa a do bioma.
func surface() -> String:
	return shape if shape == "hill" or shape == "mont" else biome


## A altura: 0 é água, 1 é terra, 2 é colina, 3 é pedra, e 4 é montanha. Uma ilha
## segue a forma, e a colina da região de pedra fica na altura da pedra.
func level() -> int:
	if shape == "mont":
		return 4
	if biome == "stone":
		return 3
	if shape == "hill":
		return 2
	return 0 if WATER_BIOMES.has(biome) else 1


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
