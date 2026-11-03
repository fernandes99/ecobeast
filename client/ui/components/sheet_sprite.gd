class_name SheetSprite
extends AnimatedSprite2D
## Um personagem do mapa (wild-battle/10 e 13). Cada folha tem uma linha por direção e
## uma coluna por quadro. Só há linhas olhando para a direita: a esquerda é a mesma
## arte espelhada. A posição do nó é o ponto entre os pés.

const CELL_SIZE := Vector2i(32, 32)
## Da frente para as costas.
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
	var texture: Texture2D = load(path)
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
