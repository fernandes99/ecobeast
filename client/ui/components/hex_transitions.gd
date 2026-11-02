class_name HexTransitions
extends RefCounted
## Os arremates nas divisas entre biomas (wild-battle/09). São só enfeite, como as
## decorações: saem do mapa e da seed, sem passar pelo servidor. A folha tem uma
## coluna por borda do hexágono e, para cada material, uma linha por variante. O
## escorrido é parecido: o bioma descendo pelo paredão, em uma folha só dele.

const TEXTURE_PATH := "res://assets/terrain/transitions/transitions.png"
const CELL_SIZE := Vector2i(64, 58)
const VARIANTS := 3
## Os vizinhos em sentido horário, a partir do de cima à direita: o índice é a
## coluna da folha.
const NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1),
]
## De quem recebe para quem avança: a divisa tem arremate de um lado só. A água
## não está na lista: ela recebe da terra, e não há arremate entre rasa e funda.
const SURFACE_ORDER: Array[String] = ["temperate", "boreal", "hill", "stone", "mont"]
const FOAM := "foam"
const MATERIAL_ROWS: Dictionary[String, int] = {
	"foam": 0,
	"temperate": 1,
	"boreal": 2,
	"hill": 3,
	"stone": 4,
	"mont": 5,
}
const DRIP_TEXTURE_PATH := "res://assets/terrain/transitions/drips.png"
const DRIP_CELL_SIZE := Vector2i(32, 16)
const DRIP_VARIANTS := 4
## Cada material tem duas linhas: a curta e, daqui para cima, a comprida.
const DRIP_LONG_FROM := 16.0
## Só o que é solto ou cresce escorre: rocha não.
const DRIP_ROWS: Dictionary[String, int] = {
	"temperate": 0,
	"boreal": 1,
	"hill": 2,
}
const NO_DRIP := Vector2i(-1, -1)


class Transition:
	extends RefCounted
	## A célula da folha: coluna e linha.
	var cell: Vector2i
	## O vizinho que avança, a partir do hexágono.
	var neighbor: Vector2i


static func transitions_of(tile: HexTile, map: ExplorationMap) -> Array[Transition]:
	var transitions: Array[Transition] = []
	var rank := SURFACE_ORDER.find(tile.surface())
	for edge: int in NEIGHBORS.size():
		var neighbor := map.tile_at(tile.coord + NEIGHBORS[edge])
		if neighbor == null or SURFACE_ORDER.find(neighbor.surface()) <= rank:
			continue
		# A borda de cima de um vizinho mais alto já fecha a divisa; só a água recebe aí.
		var behind_higher := HexMapView.LOWER_NEIGHBORS.has(NEIGHBORS[edge]) and neighbor.level() > tile.level()
		if behind_higher and tile.level() > 0:
			continue
		var material := FOAM if tile.level() == 0 else neighbor.surface()
		var variant := hash([map.map_seed, tile.coord, edge]) % VARIANTS
		var transition := Transition.new()
		transition.cell = Vector2i(edge, MATERIAL_ROWS[material] * VARIANTS + variant)
		transition.neighbor = NEIGHBORS[edge]
		transitions.append(transition)
	return transitions


## A célula do escorrido em um paredão desta altura, ou NO_DRIP.
static func drip_cell(tile: HexTile, edge: int, height: float, map_seed: int) -> Vector2i:
	if not DRIP_ROWS.has(tile.surface()):
		return NO_DRIP
	var row: int = DRIP_ROWS[tile.surface()] * 2 + (1 if height >= DRIP_LONG_FROM else 0)
	return Vector2i(hash([map_seed, tile.coord, edge]) % DRIP_VARIANTS, row)
