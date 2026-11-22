class_name GroundItemSprite
extends Node2D

## Um item no chão de Explorar (auralis/09): o item não aparece, só um brilho sutil de
## pontinhos piscando no chão; o escondido brilha mais fraco e só de perto, pela tela.

## Cada pontinho: o lugar em pixels da arte, a partir do centro do hexágono, e o atraso
## no ciclo, para não piscarem juntos.
const TWINKLES: Array[Vector3] = [Vector3(-3.0, -2.0, 0.0), Vector3(3.0, -4.0, 0.35), Vector3(1.0, 1.0, 0.7)]
const TWINKLE_SECONDS := 1.8
const TWINKLE_ARM := 1.0
const VISIBLE_ALPHA := 0.75
const HIDDEN_ALPHA := 0.4
## Até quantos hexágonos do Domador o escondido brilha.
const HIDDEN_RADIUS := 2

var item: MapGroundItem
var _time := randf() * TWINKLE_SECONDS


static func make(ground_item: MapGroundItem) -> GroundItemSprite:
	var sprite := GroundItemSprite.new()
	sprite.item = ground_item
	return sprite


func place_on(view: HexMapView) -> void:
	view.add_child(self)
	position = view.surface_center(item.coord).round()
	view.set_actor_depth(self, HexMapView.flat_center(item.coord), item.coord.y)


## O escondido só aparece a até `HIDDEN_RADIUS` hexágonos do Domador.
func show_near(player: Vector2i) -> void:
	if item.hidden:
		visible = ExplorationMap.distance(player, item.coord) <= HIDDEN_RADIUS


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var strength := HIDDEN_ALPHA if item.hidden else VISIBLE_ALPHA
	for twinkle: Vector3 in TWINKLES:
		var phase := fmod(_time / TWINKLE_SECONDS + twinkle.z, 1.0)
		var glow := maxf(0.0, sin(phase * TAU))
		if glow <= 0.1:
			continue
		var at := Vector2(twinkle.x, twinkle.y)
		draw_rect(Rect2(at, Vector2.ONE), Color(UiPalette.TEXT, glow * strength))
		if glow > 0.7:
			var arm := Color(UiPalette.WARNING, (glow - 0.5) * strength)
			draw_rect(Rect2(at - Vector2(TWINKLE_ARM, 0.0), Vector2(TWINKLE_ARM, 1.0)), arm)
			draw_rect(Rect2(at + Vector2(1.0, 0.0), Vector2(TWINKLE_ARM, 1.0)), arm)
			draw_rect(Rect2(at - Vector2(0.0, TWINKLE_ARM), Vector2(1.0, TWINKLE_ARM)), arm)
			draw_rect(Rect2(at + Vector2(0.0, 1.0), Vector2(1.0, TWINKLE_ARM)), arm)
