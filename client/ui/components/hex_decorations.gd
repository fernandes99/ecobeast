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
	"cactus": 17,
	"sand_rock": 18,
	"snow_pine": 19,
	"snow_rock": 20,
	"snow_bush": 21,
	"snow_tuft": 22,
	"birch": 23,
	"oak": 24,
	"fir": 25,
	"fallen_branch": 26,
	"log": 27,
	"stump": 28,
	"mushrooms": 29,
	"tall_grass": 30,
	"wildflowers": 31,
	"clover": 32,
	"berry_bush": 33,
	"thistle": 34,
	"dry_branch": 35,
	"yellow_flowers": 36,
	"slab": 37,
	"lichen_rock": 38,
	"tumbleweed": 39,
	"desert_flower": 40,
	"bleached_branch": 41,
	"dune_grass": 42,
	"frozen_branch": 43,
	"ice_shards": 44,
	"winter_berry": 45,
	"snow_log": 46,
	"shells": 47,
	"starfish": 48,
	"driftwood": 49,
	"beach_rock": 50,
	"seagrass": 51,
	"kelp": 52,
	"algae_patch": 53,
	"sea_rock": 54,
	"sunken_rock": 55,
	"sea_stack": 56,
	"floating_weed": 57,
	"bottle": 58,
	"can": 59,
	"plastic_bag": 60,
	"old_boot": 61,
	"tire": 62,
	"jug": 63,
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
	"cactus": 8.0,
	"sand_rock": 10.0,
	"snow_pine": 12.0,
	"snow_rock": 9.0,
	"snow_bush": 10.0,
	"snow_tuft": 4.0,
	"birch": 13.0,
	"oak": 15.0,
	"fir": 10.0,
	"fallen_branch": 7.0,
	"log": 11.0,
	"stump": 7.0,
	"mushrooms": 4.0,
	"tall_grass": 5.0,
	"wildflowers": 6.0,
	"clover": 5.0,
	"berry_bush": 10.0,
	"thistle": 5.0,
	"dry_branch": 7.0,
	"yellow_flowers": 5.0,
	"slab": 11.0,
	"lichen_rock": 9.0,
	"tumbleweed": 7.0,
	"desert_flower": 4.0,
	"bleached_branch": 7.0,
	"dune_grass": 4.0,
	"frozen_branch": 7.0,
	"ice_shards": 7.0,
	"winter_berry": 10.0,
	"snow_log": 11.0,
	"shells": 6.0,
	"starfish": 5.0,
	"driftwood": 11.0,
	"beach_rock": 9.0,
	"seagrass": 7.0,
	"kelp": 10.0,
	"algae_patch": 8.0,
	"sea_rock": 9.0,
	"sunken_rock": 8.0,
	"sea_stack": 11.0,
	"floating_weed": 8.0,
	"bottle": 8.0,
	"can": 6.0,
	"plastic_bag": 7.0,
	"old_boot": 6.0,
	"tire": 8.0,
	"jug": 5.0,
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
	"snow_pine": Vector2(2.0, 49.0),
	"snow_bush": Vector2(1.0, 13.0),
	"snow_tuft": Vector2(2.0, 8.0),
	"birch": Vector2(2.0, 36.0),
	"oak": Vector2(2.0, 36.0),
	"fir": Vector2(2.0, 46.0),
	"tall_grass": Vector2(2.0, 14.0),
	"wildflowers": Vector2(2.0, 10.0),
	"clover": Vector2(1.0, 5.0),
	"berry_bush": Vector2(1.0, 13.0),
	"thistle": Vector2(2.0, 14.0),
	"yellow_flowers": Vector2(2.0, 10.0),
	"tumbleweed": Vector2(1.0, 10.0),
	"desert_flower": Vector2(1.0, 8.0),
	"dune_grass": Vector2(2.0, 10.0),
	"winter_berry": Vector2(1.0, 13.0),
	"seagrass": Vector2(1.0, 12.0),
	"kelp": Vector2(1.0, 8.0),
	"algae_patch": Vector2(1.0, 4.0),
	"floating_weed": Vector2(1.0, 4.0),
	"plastic_bag": Vector2(1.0, 6.0),
}
const NO_SWAY := Vector2(0.0, 1.0)
## Por superfície: tipo, chance de aparecer no hexágono, mínimo e máximo. Da
## decoração maior para a menor, para a grande achar lugar; os tipos da nature-variety
## vêm no fim, para não mudar o sorteio dos de antes. A revisar.
const RECIPES: Dictionary = {
	"temperate": [["tree", 0.14, 1, 2], ["rock", 0.09, 1, 1], ["bush", 0.28, 1, 2], ["flowers", 0.24, 1, 3], ["pebbles", 0.14, 1, 2], ["tuft", 0.6, 2, 5], ["oak", 0.05, 1, 1], ["birch", 0.06, 1, 2], ["log", 0.05, 1, 1], ["stump", 0.05, 1, 1], ["fallen_branch", 0.12, 1, 1], ["wildflowers", 0.14, 1, 2], ["mushrooms", 0.06, 1, 2], ["tall_grass", 0.2, 1, 2], ["clover", 0.2, 1, 2]],
	"boreal": [["pine", 0.78, 2, 4], ["mossy_rock", 0.14, 1, 1], ["dark_bush", 0.36, 1, 2], ["fern", 0.55, 1, 3], ["pebbles", 0.07, 1, 1], ["fir", 0.3, 1, 2], ["birch", 0.1, 1, 1], ["log", 0.1, 1, 1], ["stump", 0.08, 1, 1], ["berry_bush", 0.14, 1, 1], ["fallen_branch", 0.14, 1, 1], ["mushrooms", 0.2, 1, 3]],
	"hill": [["rock", 0.16, 1, 2], ["dry_shrub", 0.36, 1, 2], ["pebbles", 0.24, 1, 2], ["dry_tuft", 0.72, 2, 5], ["stump", 0.04, 1, 1], ["thistle", 0.18, 1, 2], ["dry_branch", 0.12, 1, 1], ["yellow_flowers", 0.16, 1, 2]],
	"stone": [["spire", 0.2, 1, 1], ["boulder", 0.34, 1, 2], ["rock_pile", 0.3, 1, 2], ["moss", 0.2, 1, 2], ["slab", 0.14, 1, 1], ["lichen_rock", 0.16, 1, 1]],
	"mountain": [["brown_rock", 0.3, 1, 2], ["moss", 0.06, 1, 1], ["slab", 0.1, 1, 1], ["dry_branch", 0.05, 1, 1]],
	"desert": [["cactus", 0.22, 1, 2], ["sand_rock", 0.14, 1, 1], ["dry_shrub", 0.18, 1, 1], ["pebbles", 0.12, 1, 2], ["dry_tuft", 0.3, 1, 3], ["tumbleweed", 0.12, 1, 1], ["bleached_branch", 0.1, 1, 1], ["desert_flower", 0.12, 1, 2], ["dune_grass", 0.3, 1, 3]],
	"snow": [["snow_pine", 0.4, 1, 3], ["snow_rock", 0.14, 1, 1], ["snow_bush", 0.24, 1, 2], ["snow_tuft", 0.4, 1, 3], ["snow_log", 0.08, 1, 1], ["winter_berry", 0.14, 1, 1], ["frozen_branch", 0.12, 1, 1], ["ice_shards", 0.1, 1, 1]],
	"beach": [["driftwood", 0.08, 1, 1], ["beach_rock", 0.1, 1, 1], ["dune_grass", 0.3, 1, 2], ["shells", 0.3, 1, 2], ["starfish", 0.08, 1, 1]],
	# As zonas (biome-zones/02); a Comum de cada bioma é a receita dele, acima.
	"temperate_woods": [["oak", 0.5, 1, 2], ["tree", 0.5, 1, 2], ["birch", 0.4, 1, 2], ["bush", 0.2, 1, 1], ["log", 0.1, 1, 1], ["stump", 0.08, 1, 1], ["fallen_branch", 0.2, 1, 1], ["mushrooms", 0.2, 1, 2], ["tuft", 0.4, 1, 3]],
	"temperate_shrubland": [["bush", 0.8, 2, 4], ["berry_bush", 0.2, 1, 1], ["pebbles", 0.1, 1, 1], ["flowers", 0.1, 1, 1], ["tall_grass", 0.3, 1, 2], ["tuft", 0.5, 1, 3]],
	"temperate_clearing": [["tuft", 0.35, 1, 2], ["clover", 0.15, 1, 1]],
	"temperate_meadow": [["flowers", 0.8, 2, 4], ["wildflowers", 0.7, 1, 3], ["yellow_flowers", 0.4, 1, 2], ["tall_grass", 0.2, 1, 1], ["clover", 0.3, 1, 2], ["tuft", 0.5, 1, 3]],
	"boreal_clearing": [["pebbles", 0.1, 1, 1], ["fern", 0.3, 1, 2], ["mushrooms", 0.1, 1, 1]],
	"boreal_ferns": [["pine", 0.15, 1, 1], ["mossy_rock", 0.15, 1, 1], ["dark_bush", 0.3, 1, 2], ["fern", 0.9, 3, 5], ["mushrooms", 0.25, 1, 2]],
	"hill_scree": [["rock", 0.5, 1, 2], ["brown_rock", 0.2, 1, 1], ["pebbles", 0.6, 1, 3], ["dry_tuft", 0.2, 1, 2]],
	"hill_dry_brush": [["dry_shrub", 0.8, 2, 3], ["thistle", 0.4, 1, 2], ["dry_branch", 0.2, 1, 1], ["dry_tuft", 0.6, 2, 4]],
	"stone_crags": [["spire", 0.5, 1, 2], ["boulder", 0.5, 1, 2], ["rock_pile", 0.3, 1, 1], ["lichen_rock", 0.2, 1, 1]],
	"desert_dunes": [["pebbles", 0.05, 1, 1], ["dune_grass", 0.15, 1, 1]],
	"desert_cacti": [["cactus", 0.8, 2, 3], ["sand_rock", 0.1, 1, 1], ["desert_flower", 0.3, 1, 2], ["dry_tuft", 0.2, 1, 2]],
	"snow_field": [["ice_shards", 0.05, 1, 1], ["snow_tuft", 0.15, 1, 1]],
	"snow_pines": [["snow_pine", 0.9, 2, 4], ["snow_bush", 0.15, 1, 1], ["snow_log", 0.1, 1, 1], ["frozen_branch", 0.15, 1, 1]],
	# A água (sea-life/02): a Comum e as zonas; o lixo só é comum nas zonas Lixo.
	"wshallow": [["sea_rock", 0.03, 1, 1], ["sunken_rock", 0.05, 1, 1], ["algae_patch", 0.07, 1, 1], ["seagrass", 0.12, 1, 2], ["floating_weed", 0.015, 1, 1], ["bottle", 0.004, 1, 1], ["can", 0.004, 1, 1]],
	"wshallow_rocks": [["sea_rock", 0.25, 1, 1], ["sunken_rock", 0.2, 1, 1], ["algae_patch", 0.1, 1, 1], ["seagrass", 0.08, 1, 1]],
	"wshallow_seagrass": [["kelp", 0.06, 1, 1], ["algae_patch", 0.2, 1, 1], ["seagrass", 0.45, 1, 3], ["floating_weed", 0.05, 1, 1]],
	"wshallow_trash": [["tire", 0.06, 1, 1], ["jug", 0.06, 1, 1], ["old_boot", 0.08, 1, 1], ["plastic_bag", 0.15, 1, 1], ["bottle", 0.2, 1, 1], ["can", 0.18, 1, 1], ["seagrass", 0.08, 1, 1]],
	"wdeep": [["sea_stack", 0.01, 1, 1], ["kelp", 0.04, 1, 1], ["sunken_rock", 0.02, 1, 1], ["floating_weed", 0.02, 1, 1], ["bottle", 0.003, 1, 1]],
	"wdeep_rocks": [["sea_stack", 0.18, 1, 1], ["sea_rock", 0.2, 1, 1], ["sunken_rock", 0.12, 1, 1]],
	"wdeep_kelp": [["kelp", 0.4, 1, 2], ["sunken_rock", 0.04, 1, 1], ["floating_weed", 0.1, 1, 1]],
	"wdeep_trash": [["jug", 0.06, 1, 1], ["tire", 0.05, 1, 1], ["old_boot", 0.1, 1, 1], ["plastic_bag", 0.12, 1, 1], ["bottle", 0.2, 1, 1], ["can", 0.15, 1, 1], ["floating_weed", 0.06, 1, 1]],
}
const PLACE_TRIES := 8
static var _warned_zones: Dictionary = {}
## A chance de um hexágono ter um enxame de vagalumes, por bioma (fireflies/01). A revisar.
const SWARM_CHANCE: Dictionary[String, float] = {"temperate": 0.12, "boreal": 0.18}
const SWARM_RADIUS := 6.0
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
	for entry: Array in recipe_of(tile):
		if random.randf() >= (entry[1] as float):
			continue
		for _index: int in random.randi_range(entry[2], entry[3]):
			var decoration := _placed(entry[0], random, decorations)
			if decoration != null:
				decorations.append(decoration)
	return decorations


## A receita da zona, ou a do bioma na Comum e numa zona que o jogo ainda não desenha.
static func recipe_of(tile: HexTile) -> Array:
	if not tile.zone.is_empty():
		if RECIPES.has(tile.zone):
			return RECIPES[tile.zone]
		if not _warned_zones.has(tile.zone):
			_warned_zones[tile.zone] = true
			push_warning("HexDecorations: a zona '%s' não tem receita; usando a do bioma." % tile.zone)
	return RECIPES.get(tile.biome, [])


## O ponto do enxame de vagalumes do hexágono, a partir do centro, ou null. O gerador é
## próprio, para o sorteio das decorações não mudar (fireflies/01).
static func swarm_of(tile: HexTile, map_seed: int) -> Variant:
	var chance: float = SWARM_CHANCE.get(tile.biome, 0.0)
	if chance <= 0.0 or tile.bare:
		return null
	var random := RandomNumberGenerator.new()
	random.seed = hash([map_seed, tile.coord, "fireflies"])
	if random.randf() >= chance:
		return null
	for _index: int in PLACE_TRIES:
		var spot := random_spot(random)
		if is_free_spot(spot, SWARM_RADIUS, []):
			return spot
	return null


static func _placed(kind: String, random: RandomNumberGenerator, decorations: Array[Decoration]) -> Decoration:
	for _index: int in PLACE_TRIES:
		var spot := random_spot(random)
		if _is_free(spot, kind, decorations):
			var decoration := Decoration.new()
			decoration.kind = kind
			decoration.column = random.randi_range(0, VARIANTS - 1)
			decoration.offset = spot
			decoration.flipped = random.randf() < 0.5
			return decoration
	return null


static func _is_free(spot: Vector2i, kind: String, decorations: Array[Decoration]) -> bool:
	var taken: Array = []
	for decoration: Decoration in decorations:
		taken.append([decoration.offset, KIND_RADIUS[decoration.kind]])
	return is_free_spot(spot, KIND_RADIUS[kind], taken)


## Um ponto do hexágono, a partir do centro, que cabe uma coisa de raio `radius`: dentro
## do hexágono, longe do centro e longe de cada `[ponto, raio]` de `taken`
## (vegetation-brush/02 usa a mesma regra para as peças do pincel).
static func is_free_spot(spot: Vector2i, radius: float, taken: Array) -> bool:
	if absf(spot.x) / 2.0 + absf(spot.y) > MAX_EDGE_DISTANCE or Vector2(spot).length() < radius:
		return false
	for entry: Array in taken:
		if Vector2(spot - (entry[0] as Vector2i)).length() < maxf(radius, entry[1] as float):
			return false
	return true


static func random_spot(random: RandomNumberGenerator) -> Vector2i:
	return Vector2i(random.randi_range(-MAX_X, MAX_X), random.randi_range(-MAX_Y, MAX_Y))
