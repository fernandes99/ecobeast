class_name TamerSprite
extends AnimatedSprite2D
## O Domador no mapa (wild-battle/10). Cada folha tem uma linha por direção e uma
## coluna por quadro. Só há linhas olhando para a direita: a esquerda é a mesma
## arte espelhada. A posição do nó é o ponto entre os pés.

const SHEET_PATH := "res://assets/tamer/%s.png"
const IDLE := "idle"
const RUN := "run"
const CELL_SIZE := Vector2i(32, 32)
## Da frente para as costas.
const SHEET_ROWS := 5
const FRONT_ROW := 0
const LOWER_ROW := 1
const SIDE_ROW := 2
const UPPER_ROW := 3
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

var _row := FRONT_ROW


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = false
	offset = -Vector2(CELL_SIZE.x / 2.0, CELL_SIZE.y)
	sprite_frames = SpriteFrames.new()
	sprite_frames.remove_animation(&"default")
	_add_sheet(IDLE, IDLE_SECONDS)
	_add_sheet(RUN, RUN_SECONDS)
	play_idle()


## Vira para um vizinho do hexágono atual; vale a partir da próxima animação.
func face(neighbor: Vector2i) -> void:
	_row = NEIGHBOR_ROWS[neighbor]
	flip_h = LEFT_NEIGHBORS.has(neighbor)


func play_idle() -> void:
	play(_animation_name(IDLE, _row))


func play_run() -> void:
	play(_animation_name(RUN, _row))


func _add_sheet(sheet: String, cycle_seconds: float) -> void:
	var texture: Texture2D = load(SHEET_PATH % sheet)
	var columns := floori(texture.get_size().x / CELL_SIZE.x)
	for row: int in SHEET_ROWS:
		var animation := _animation_name(sheet, row)
		sprite_frames.add_animation(animation)
		sprite_frames.set_animation_speed(animation, columns / cycle_seconds)
		for column: int in columns:
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(Vector2i(column, row) * CELL_SIZE, CELL_SIZE)
			sprite_frames.add_frame(animation, frame)


func _animation_name(sheet: String, row: int) -> StringName:
	return StringName("%s_%d" % [sheet, row])
