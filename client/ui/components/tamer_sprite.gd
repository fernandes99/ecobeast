class_name TamerSprite
extends WanderingSprite
## Um Domador no mapa (wild-battle/10): o do jogador, que anda de hexágono em
## hexágono pela tela de exploração, e os Domadores NPC (npc-tamers/04), que passeiam
## dentro do próprio hexágono depois do `wander_in`. Os dois usam as folhas do template.

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

## As animações, montadas uma vez: o jogador e os Domadores NPC perto dele usam as
## mesmas folhas.
static var _frames: SpriteFrames = null


func _init() -> void:
	super()
	if _frames == null:
		_add_sheet(IDLE, SHEET_PATH % IDLE, IDLE_SECONDS)
		_add_sheet(RUN, SHEET_PATH % RUN, RUN_SECONDS)
		_frames = sprite_frames
	sprite_frames = _frames
	play_idle()


## Vira para um vizinho do hexágono atual; vale a partir da próxima animação.
func face(neighbor: Vector2i) -> void:
	_row = NEIGHBOR_ROWS[neighbor]
	flip_h = LEFT_NEIGHBORS.has(neighbor)


func play_idle() -> void:
	play_sheet(IDLE)


func play_run() -> void:
	play_sheet(RUN)


func _play_still() -> void:
	play_idle()


func _play_moving() -> void:
	play_run()
