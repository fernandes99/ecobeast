class_name HexTile
extends RefCounted

const WATER_BIOMES: Array[String] = ["wshallow", "wdeep"]
const MAX_HEIGHT := 4

var coord: Vector2i
var biome: String
var height: int
var variant: int


func is_water() -> bool:
	return WATER_BIOMES.has(biome)


static func from_dict(d: Dictionary) -> HexTile:
	var biome_slug := DictFields.get_string(d, "biome")
	if not (d.has("q") and d.has("r") and d.has("height")) or biome_slug.is_empty():
		return null
	var tile_height := DictFields.get_int(d, "height", -1)
	if tile_height < 0 or tile_height > MAX_HEIGHT:
		return null
	var tile := HexTile.new()
	tile.coord = Vector2i(DictFields.get_int(d, "q"), DictFields.get_int(d, "r"))
	tile.biome = biome_slug
	tile.height = tile_height
	tile.variant = DictFields.get_int(d, "variant", 1)
	return tile
