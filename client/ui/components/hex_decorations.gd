class_name HexDecorations
extends RefCounted

const TEXTURE_PATH := "res://assets/terrain/decorations/decorations.png"
const CELL_SIZE := Vector2i(48, 64)
const CELL_BASE := Vector2i(24, 60)
const VARIANTS := 4
const KIND_ROWS: Dictionary[String, int] = {
	"tree": 0,
	"pine": 1,
	"bush": 2,
	"dark_bush": 3,
	"tuft": 4,
	"flowers": 5,
	"fern": 6,
	"dry_shrub": 7,
	"dry_tuft": 8,
	"moss": 9,
	"pebbles": 10,
	"rock": 11,
	"mossy_rock": 12,
	"brown_rock": 13,
	"boulder": 14,
	"rock_pile": 15,
	"spire": 16,
}
## O espaço que cada tipo ocupa no chão, em pixels da arte. Ele também é a
## distância mínima do centro do hexágono, onde o jogador fica.
const KIND_RADIUS: Dictionary[String, float] = {
	"tree": 15.0,
	"pine": 12.0,
	"bush": 10.0,
	"dark_bush": 10.0,
	"dry_shrub": 10.0,
	"fern": 7.0,
	"flowers": 5.0,
	"tuft": 4.0,
	"dry_tuft": 4.0,
	"moss": 4.0,
	"pebbles": 5.0,
	"rock": 9.0,
	"mossy_rock": 9.0,
	"brown_rock": 10.0,
	"rock_pile": 12.0,
	"spire": 13.0,
	"boulder": 14.0,
}
const WIND_SHADER_PATH := "res://ui/components/plant_wind.gdshader"
## O vento em cada tipo: quantos pixels da arte o topo anda e a altura da planta, a
## partir do ponto de apoio. Quem não está aqui fica parado. O máximo precisa caber
## na folga da célula. A revisar.
const KIND_SWAY: Dictionary[String, Vector2] = {
	"tree": Vector2(2.0, 35.0),
	"pine": Vector2(2.0, 49.0),
	"bush": Vector2(1.0, 14.0),
	"dark_bush": Vector2(1.0, 13.0),
	"tuft": Vector2(2.0, 8.0),
	"flowers": Vector2(2.0, 11.0),
	"fern": Vector2(1.0, 10.0),
	"dry_shrub": Vector2(1.0, 14.0),
	"dry_tuft": Vector2(2.0, 10.0),
}
const NO_SWAY := Vector2(0.0, 1.0)
## Por superfície: tipo, chance de aparecer no hexágono, mínimo e máximo. Da
## decoração maior para a menor, para a grande achar lugar. A revisar.
const RECIPES: Dictionary = {
	"temperate": [["tree", 0.14, 1, 2], ["rock", 0.09, 1, 1], ["bush", 0.28, 1, 2], ["flowers", 0.24, 1, 3], ["pebbles", 0.14, 1, 2], ["tuft", 0.6, 2, 5]],
	"boreal": [["pine", 0.78, 2, 4], ["mossy_rock", 0.14, 1, 1], ["dark_bush", 0.36, 1, 2], ["fern", 0.55, 1, 3], ["pebbles", 0.07, 1, 1]],
	"hill": [["rock", 0.16, 1, 2], ["dry_shrub", 0.36, 1, 2], ["pebbles", 0.24, 1, 2], ["dry_tuft", 0.72, 2, 5]],
	"stone": [["spire", 0.2, 1, 1], ["boulder", 0.34, 1, 2], ["rock_pile", 0.3, 1, 2], ["moss", 0.2, 1, 2]],
	"mountain": [["brown_rock", 0.3, 1, 2], ["moss", 0.06, 1, 1]],
}
const PLACE_TRIES := 8
const MAX_X := 24
const MAX_Y := 20
const MAX_EDGE_DISTANCE := 22.0


class Decoration:
	extends RefCounted
	var kind: String
	var column: int
	var offset: Vector2i
	var flipped: bool
	var base: Vector2i


static func decorations_of(tile: HexTile, map_seed: int) -> Array[Decoration]:
	var decorations: Array[Decoration] = []
	var random := RandomNumberGenerator.new()
	random.seed = hash([map_seed, tile.coord])
	for entry: Array in RECIPES.get(tile.biome, []):
		if random.randf() >= (entry[1] as float):
			continue
		for _index: int in random.randi_range(entry[2], entry[3]):
			var decoration := _placed(entry[0], random, decorations)
			if decoration != null:
				decorations.append(decoration)
	return decorations


static func _placed(kind: String, random: RandomNumberGenerator, decorations: Array[Decoration]) -> Decoration:
	for _index: int in PLACE_TRIES:
		var spot := Vector2i(random.randi_range(-MAX_X, MAX_X), random.randi_range(-MAX_Y, MAX_Y))
		if _is_free(spot, kind, decorations):
			var decoration := Decoration.new()
			decoration.kind = kind
			decoration.column = random.randi_range(0, VARIANTS - 1)
			decoration.offset = spot
			decoration.flipped = random.randf() < 0.5
			return decoration
	return null


static func _is_free(spot: Vector2i, kind: String, decorations: Array[Decoration]) -> bool:
	var radius: float = KIND_RADIUS[kind]
	if absf(spot.x) / 2.0 + absf(spot.y) > MAX_EDGE_DISTANCE or Vector2(spot).length() < radius:
		return false
	for decoration: Decoration in decorations:
		if Vector2(spot - decoration.offset).length() < maxf(radius, KIND_RADIUS[decoration.kind]):
			return false
	return true
