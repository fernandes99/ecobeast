class_name SheetSprite
extends AnimatedSprite2D

const CELL_SIZE := Vector2i(32, 32)
const SHEET_ROWS := 5
const FRONT_ROW := 0
const LOWER_ROW := 1
const SIDE_ROW := 2
const UPPER_ROW := 3
const BACK_ROW := 4

var _row := FRONT_ROW


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = false
	offset = -Vector2(CELL_SIZE.x / 2.0, CELL_SIZE.y)
	sprite_frames = SpriteFrames.new()
	sprite_frames.remove_animation(&"default")


func play_sheet(sheet: String) -> void:
	play(_animation_name(sheet, _row))


func _add_sheet(sheet: String, path: String, cycle_seconds: float) -> void:
	add_sheet_to(sprite_frames, sheet, load(path), cycle_seconds)


static func add_sheet_to(frames: SpriteFrames, sheet: String, texture: Texture2D, cycle_seconds: float) -> void:
	var columns := floori(texture.get_size().x / CELL_SIZE.x)
	for row: int in SHEET_ROWS:
		var clip := _animation_name(sheet, row)
		frames.add_animation(clip)
		frames.set_animation_speed(clip, columns / cycle_seconds)
		for column: int in columns:
			var cell := AtlasTexture.new()
			cell.atlas = texture
			cell.region = Rect2(Vector2i(column, row) * CELL_SIZE, CELL_SIZE)
			frames.add_frame(clip, cell)


static func _animation_name(sheet: String, row: int) -> StringName:
	return StringName("%s_%d" % [sheet, row])
