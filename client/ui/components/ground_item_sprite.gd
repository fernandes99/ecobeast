class_name GroundItemSprite
extends Node2D

## Um item no chão de Explorar (auralis/09): o item não aparece, só um brilho de
## pontinhos piscando sobre uma luz dourada que pulsa no chão, somada à cor dele; o
## escondido brilha mais fraco e só de perto, pela tela.

## Cada pontinho: o lugar em pixels da arte, a partir do centro do hexágono, e o atraso
## no ciclo, para não piscarem juntos.
const TWINKLES: Array[Vector3] = [Vector3(-4.0, -3.0, 0.0), Vector3(3.0, -6.0, 0.25), Vector3(1.0, 1.0, 0.5), Vector3(-1.0, -9.0, 0.75)]
const TWINKLE_SECONDS := 1.6
const TWINKLE_ARM := 2
## A luz no chão: uma elipse, em pixels da arte, que some para a borda.
const HALO_RADIUS := Vector2(7.0, 4.0)
const HALO_SECONDS := 2.4
const HALO_MIN := 0.25
const HALO_MAX := 0.55
const VISIBLE_ALPHA := 1.0
const HIDDEN_ALPHA := 0.55
## Até quantos hexágonos do Domador o escondido brilha.
const HIDDEN_RADIUS := 2

var item: MapGroundItem
var _time := randf() * TWINKLE_SECONDS


static func make(ground_item: MapGroundItem) -> GroundItemSprite:
	var sprite := GroundItemSprite.new()
	sprite.item = ground_item
	var light := CanvasItemMaterial.new()
	light.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = light
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
	var pulse := (sin(_time * TAU / HALO_SECONDS) + 1.0) / 2.0
	var halo := lerpf(HALO_MIN, HALO_MAX, pulse) * strength
	for y: int in range(-int(HALO_RADIUS.y), int(HALO_RADIUS.y) + 1):
		for x: int in range(-int(HALO_RADIUS.x), int(HALO_RADIUS.x) + 1):
			var reach := Vector2(x / HALO_RADIUS.x, y / HALO_RADIUS.y).length()
			if reach < 1.0:
				draw_rect(Rect2(x, y, 1, 1), Color(UiPalette.WARNING, halo * pow(1.0 - reach, 2.0)))
	for twinkle: Vector3 in TWINKLES:
		var phase := fmod(_time / TWINKLE_SECONDS + twinkle.z, 1.0)
		var glow := maxf(0.0, sin(phase * TAU))
		if glow <= 0.1:
			continue
		var at := Vector2(twinkle.x, twinkle.y)
		draw_rect(Rect2(at, Vector2.ONE), Color(UiPalette.TEXT, glow * strength))
		if glow < 0.5:
			continue
		var arm := 1 if glow < 0.85 else TWINKLE_ARM
		for step: int in range(1, arm + 1):
			var color := Color(UiPalette.WARNING, glow * strength * (1.0 if step == 1 else 0.6))
			for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				draw_rect(Rect2(at + direction * step, Vector2.ONE), color)
