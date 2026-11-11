class_name TamerSprite
extends WanderingSprite

const SHEET_PATH := "res://assets/tamer/%s.png"
const IDLE := "idle"
const RUN := "run"
const NEIGHBOR_ROWS: Dictionary[Vector2i, int] = {
	Vector2i(1, -1): UPPER_ROW,
	Vector2i(1, 0): SIDE_ROW,
	Vector2i(0, 1): LOWER_ROW,
	Vector2i(-1, 1): LOWER_ROW,
	Vector2i(-1, 0): SIDE_ROW,
	Vector2i(0, -1): UPPER_ROW,
}
const LEFT_NEIGHBORS: Array[Vector2i] = [Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(0, -1)]
const IDLE_SECONDS := 0.8
const RUN_SECONDS := 0.36

static var _frames: SpriteFrames = null


func _init() -> void:
	super()
	if _frames == null:
		_add_sheet(IDLE, SHEET_PATH % IDLE, IDLE_SECONDS)
		_add_sheet(RUN, SHEET_PATH % RUN, RUN_SECONDS)
		_frames = sprite_frames
	sprite_frames = _frames
	play_idle()


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
