class_name HexTransitions
extends RefCounted

const TEXTURE_PATH := "res://assets/terrain/transitions/transitions.png"
const CELL_SIZE := Vector2i(64, 58)
const VARIANTS := 3
const NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1),
]
## De quem recebe para quem avança: a divisa tem arremate de um lado só. A água e a
## lava não estão na lista: elas recebem da terra (a espuma e a crosta), e só a lava
## rasa avança sobre a funda (volcano/01).
const SURFACE_ORDER: Array[String] = ["beach", "desert", "temperate", "boreal", "hill", "glacier", "snow", "stone", "mountain", "volcano"]
const LAVA_CRUST := "lava_crust"
const FOAM := "foam"
const MATERIAL_ROWS: Dictionary[String, int] = {
	"foam": 0,
	"temperate": 1,
	"boreal": 2,
	"hill": 3,
	"stone": 4,
	"mountain": 5,
	"desert": 6,
	"snow": 7,
	"beach": 8,
	"glacier": 9,
	"volcano": 10,
	"lava_crust": 11,
	"lshallow": 12,
}
const DRIP_TEXTURE_PATH := "res://assets/terrain/transitions/drips.png"
const DRIP_CELL_SIZE := Vector2i(32, 16)
const DRIP_VARIANTS := 4
const DRIP_LONG_FROM := 16.0
const DRIP_ROWS: Dictionary[String, int] = {
	"temperate": 0,
	"boreal": 1,
	"hill": 2,
	"desert": 3,
	"snow": 4,
	"beach": 5,
	"glacier": 6,
	"volcano": 7,
}
const NO_DRIP := Vector2i(-1, -1)


class Transition:
	extends RefCounted
	var cell: Vector2i
	var neighbor: Vector2i


static func transitions_of(tile: HexTile, map: ExplorationMap) -> Array[Transition]:
	var transitions: Array[Transition] = []
	var rank := SURFACE_ORDER.find(tile.biome)
	for edge: int in NEIGHBORS.size():
		var neighbor := map.tile_at(tile.coord + NEIGHBORS[edge])
		if neighbor == null:
			continue
		var lava_rim := tile.biome == "ldeep" and neighbor.biome == "lshallow"
		if not lava_rim and SURFACE_ORDER.find(neighbor.biome) <= rank:
			continue
		# A borda de cima de um vizinho mais alto já fecha a divisa, também na água (water-motion/03).
		var behind_higher := HexMapView.LOWER_NEIGHBORS.has(NEIGHBORS[edge]) and neighbor.height > tile.height
		if behind_higher:
			continue
		var material := FOAM if tile.is_water() else (LAVA_CRUST if tile.is_lava() and not lava_rim else neighbor.biome)
		var variant := hash([map.map_seed, tile.coord, edge]) % VARIANTS
		var transition := Transition.new()
		transition.cell = Vector2i(edge, MATERIAL_ROWS[material] * VARIANTS + variant)
		transition.neighbor = NEIGHBORS[edge]
		transitions.append(transition)
	return transitions


static func is_foam(transition: Transition) -> bool:
	return transition.cell.y < (MATERIAL_ROWS[FOAM] + 1) * VARIANTS


static func drip_cell(tile: HexTile, edge: int, height: float, map_seed: int) -> Vector2i:
	if not DRIP_ROWS.has(tile.biome):
		return NO_DRIP
	var row: int = DRIP_ROWS[tile.biome] * 2 + (1 if height >= DRIP_LONG_FROM else 0)
	return Vector2i(hash([map_seed, tile.coord, edge]) % DRIP_VARIANTS, row)
