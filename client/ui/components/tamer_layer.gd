class_name TamerLayer
extends AnimatedSprite2D
## Uma peça vestida do Domador (tamer-appearance), filha do `TamerSprite`: copia do
## corpo a animação, o quadro e o espelho, e não anda sozinha.


func _init(frames: SpriteFrames, behind: bool) -> void:
	sprite_frames = frames
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = false
	show_behind_parent = behind


## O pai processa antes do filho: o quadro copiado aqui é o do mesmo frame.
func _process(_delta: float) -> void:
	sync()


func sync() -> void:
	var body := get_parent() as AnimatedSprite2D
	if body == null:
		return
	offset = body.offset
	flip_h = body.flip_h
	if animation != body.animation and sprite_frames.has_animation(body.animation):
		animation = body.animation
	frame = body.frame
