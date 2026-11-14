class_name RouteMark
extends Node2D

## Um pixel da arte, em unidades do mapa.
const PIXEL := HexMapView.ART_SCALE
const RING_RADIUS := Vector2(7.0, 4.5)
const PULSE_SECONDS := 0.8
const PULSE_LOW := 0.45
const OUTLINE_SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const DOT_PIXELS: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]

## O número do ponto na rota, a partir de 1 (wild-battle/15).
var order: int = 0
var _ring: bool = false
var _pixels: Array[Vector2i] = []


func _init(at_order: int, ring: bool) -> void:
	order = at_order
	_ring = ring
	_pixels = _ring_pixels() if ring else DOT_PIXELS


func _ready() -> void:
	if _ring:
		var pulse := create_tween().set_loops()
		pulse.tween_property(self, "modulate:a", PULSE_LOW, PULSE_SECONDS).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(self, "modulate:a", 1.0, PULSE_SECONDS).set_trans(Tween.TRANS_SINE)


## Num canto de pixel da arte, para os pontos não borrarem.
func place(center: Vector2) -> void:
	position = (center / PIXEL).floor() * PIXEL


## Contorno escuro de 1 pixel em volta, para o ponto aparecer na pedra clara e na grama.
func _draw() -> void:
	var shadow: Dictionary[Vector2i, bool] = {}
	for pixel: Vector2i in _pixels:
		for side: Vector2i in OUTLINE_SIDES:
			if not _pixels.has(pixel + side):
				shadow[pixel + side] = true
	for pixel: Vector2i in shadow:
		_draw_pixel(pixel, UiPalette.MAP_ROUTE_SHADOW)
	for pixel: Vector2i in _pixels:
		_draw_pixel(pixel, UiPalette.MAP_ROUTE)


func _draw_pixel(pixel: Vector2i, color: Color) -> void:
	draw_rect(Rect2(Vector2(pixel) * PIXEL, Vector2.ONE * PIXEL), color)


## O contorno de 1 pixel de uma elipse achatada, como o chão visto de cima.
static func _ring_pixels() -> Array[Vector2i]:
	var pixels: Array[Vector2i] = []
	var reach := Vector2i(ceili(RING_RADIUS.x) + 1, ceili(RING_RADIUS.y) + 1)
	for y: int in range(-reach.y, reach.y):
		for x: int in range(-reach.x, reach.x):
			if _inside(x, y) and not (_inside(x - 1, y) and _inside(x + 1, y) and _inside(x, y - 1) and _inside(x, y + 1)):
				pixels.append(Vector2i(x, y))
	return pixels


static func _inside(x: int, y: int) -> bool:
	var point := (Vector2(x, y) + Vector2(0.5, 0.5)) / RING_RADIUS
	return point.length_squared() <= 1.0
