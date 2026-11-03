class_name TamerSprite
extends SheetSprite
## O Domador no mapa (wild-battle/10).

const SHEET_PATH := "res://assets/tamer/%s.png"
const IDLE := "idle"
const RUN := "run"
## Um hexágono não tem vizinho bem em cima nem bem embaixo.
const NEIGHBOR_ROWS: Dictionary[Vector2i, int] = {
	Vector2i(1, -1): UPPER_ROW,
	Vector2i(1, 0): SIDE_ROW,
	Vector2i(0, 1): LOWER_ROW,
	Vector2i(-1, 1): LOWER_ROW,
	Vector2i(-1, 0): SIDE_ROW,
	Vector2i(0, -1): UPPER_ROW,
}
const LEFT_NEIGHBORS: Array[Vector2i] = [Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(0, -1)]
## Um ciclo de cada folha, em segundos. A revisar.
const IDLE_SECONDS := 0.8
const RUN_SECONDS := 0.36


func _init() -> void:
	super()
	_add_sheet(IDLE, SHEET_PATH % IDLE, IDLE_SECONDS)
	_add_sheet(RUN, SHEET_PATH % RUN, RUN_SECONDS)
	play_idle()


## Vira para um vizinho do hexágono atual; vale a partir da próxima animação.
func face(neighbor: Vector2i) -> void:
	_row = NEIGHBOR_ROWS[neighbor]
	flip_h = LEFT_NEIGHBORS.has(neighbor)


func play_idle() -> void:
	play_sheet(IDLE)


func play_run() -> void:
	play_sheet(RUN)
