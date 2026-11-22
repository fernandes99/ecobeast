class_name HubClouds
extends Control
## As nuvens que passam pela Home do Hub (hub-start/05): cada uma anda para a direita na
## sua velocidade e volta pela esquerda ao sair.

const SHEET := preload("res://assets/ui/hub/clouds.png")
const CELL := Vector2(64, 28)
const KINDS := 3
const PIXEL := 3.0

## Quantas nuvens, a faixa de altura delas (da altura desta área) e a faixa de velocidade.
@export var count := 5
@export var top := 0.05
@export var bottom := 0.6
@export var min_speed := 6.0
@export var max_speed := 14.0
@export var cloud_alpha := 1.0

var _clouds: Array[Sprite2D] = []
var _speeds: Array[float] = []


func _ready() -> void:
	clip_contents = true
	mouse_filter = MOUSE_FILTER_IGNORE
	var random := RandomNumberGenerator.new()
	random.seed = hash(name)
	for index: int in count:
		var cloud := Sprite2D.new()
		var region := AtlasTexture.new()
		region.atlas = SHEET
		region.region = Rect2(Vector2(index % KINDS * CELL.x, 0.0), CELL)
		cloud.texture = region
		cloud.centered = false
		cloud.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cloud.scale = Vector2.ONE * PIXEL
		cloud.flip_h = random.randf() < 0.5
		cloud.modulate.a = cloud_alpha
		cloud.set_meta(&"x", random.randf())
		cloud.set_meta(&"y", random.randf_range(top, bottom))
		add_child(cloud)
		_clouds.append(cloud)
		_speeds.append(random.randf_range(min_speed, max_speed))
	resized.connect(_place)
	_place()


func _place() -> void:
	for cloud: Sprite2D in _clouds:
		var width := CELL.x * PIXEL
		cloud.position = Vector2(
			roundf(float(cloud.get_meta(&"x")) * (size.x + width) - width),
			roundf(float(cloud.get_meta(&"y")) * size.y))


func _process(delta: float) -> void:
	var width := CELL.x * PIXEL
	for index: int in _clouds.size():
		var cloud := _clouds[index]
		var x := float(cloud.get_meta(&"x")) + _speeds[index] * delta / (size.x + width)
		if x > 1.0:
			x -= 1.0
		cloud.set_meta(&"x", x)
		cloud.position.x = roundf(x * (size.x + width) - width)
