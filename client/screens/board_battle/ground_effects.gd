class_name GroundEffects
extends Node2D

## O desenho animado de cada marca no chão, por cima da cor do hexágono (board-battle/23 e 35).

const FLAME_SPOTS: Array[Vector2] = [
	Vector2(-26, 6), Vector2(24, 4), Vector2(-12, 22), Vector2(14, 24),
	Vector2(0, -18), Vector2(-30, -10), Vector2(30, -12),
]
const FLAME_SIZE := 5.5
const SQUASH := 0.6
const FEATHERS := 5
const THORN_SPOTS: Array[Vector2] = [
	Vector2(-28, -6), Vector2(28, -8), Vector2(-4, -22), Vector2(14, -16),
	Vector2(-24, 12), Vector2(24, 14), Vector2(-8, 26), Vector2(10, 28),
]
const BUBBLE_SPOTS: Array[Vector2] = [Vector2(-22, -6), Vector2(20, -12), Vector2(-14, 20), Vector2(18, 18), Vector2(2, -24)]
const CRYSTAL_SPOTS: Array[Vector2] = [Vector2(-26, -4), Vector2(24, -10), Vector2(-12, 22), Vector2(16, 22), Vector2(0, -22), Vector2(32, 8)]
const FLOWER_SPOTS: Array[Vector2] = [Vector2(-26, 0), Vector2(26, -4), Vector2(-12, 24), Vector2(14, 26), Vector2(-6, -20), Vector2(18, -22)]
const SAND_RADIUS := 34.0
const RIPPLES := 3
const RIPPLE_PERIOD := 1.6
const SPARK_PERIOD := 0.8
const SPARK_SECONDS := 0.18

var board: BoardView = null
var kinds: Dictionary[Vector2i, String] = {}:
	set(value):
		kinds = value
		set_process(not kinds.is_empty())
		queue_redraw()

var _time := 0.0


func _ready() -> void:
	set_process(not kinds.is_empty())


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	for cell: Vector2i in kinds:
		var at := board.cell_center(cell)
		var t := _time + _random(cell, 0) * 10.0
		match kinds[cell]:
			"fire":
				_draw_fire(at, t)
			"feathers":
				_draw_feathers(at, t)
			"whirlwind":
				_draw_whirlwind(at, t)
			"thorns":
				_draw_thorns(at, t)
			"electric_tide":
				_draw_electric_tide(cell, at, t)
			"mud":
				_draw_mud(at, t)
			"frost":
				_draw_frost(at, t)
			"toxic_pool":
				_draw_toxic_pool(at, t)
			"quicksand":
				_draw_quicksand(at, t)
			"garden":
				_draw_garden(at, t)
			"puddle":
				_draw_puddle(cell, at, t)


func _draw_fire(at: Vector2, t: float) -> void:
	for index: int in FLAME_SPOTS.size():
		var flicker := 0.75 + 0.25 * sin(t * 9.0 + index * 1.3) + 0.1 * sin(t * 23.0 + index)
		var spot := at + FLAME_SPOTS[index]
		draw_colored_polygon(CreatureAura.flame_points(spot, FLAME_SIZE * flicker), Color(UiPalette.STATUS_COLORS["burn"], 0.9))
		draw_colored_polygon(CreatureAura.flame_points(spot + Vector2(0.0, 1.5), FLAME_SIZE * flicker * 0.5), Color(UiPalette.AURA_FLAME_CORE, 0.9))


func _draw_feathers(at: Vector2, t: float) -> void:
	for index: int in FEATHERS:
		var fall := fposmod(t * 0.3 + index / float(FEATHERS), 1.0)
		var sway := sin(t * 1.6 + index * 2.1)
		var spot := at + Vector2(lerpf(-26.0, 26.0, (index + 0.5) / FEATHERS) + sway * 6.0, lerpf(-30.0, 26.0, fall))
		var alpha := minf(1.0, minf(fall, 1.0 - fall) * 5.0)
		var angle := sway * 0.6 + 0.5
		var along := Vector2.from_angle(angle)
		draw_colored_polygon(_ellipse(spot, Vector2(6.0, 2.4), angle), Color(UiPalette.GROUND_FEATHER, alpha * 0.95))
		draw_line(spot - along * 7.5, spot + along * 5.0, Color(UiPalette.GROUND_FEATHER_SHAFT, alpha), 1.2, true)


func _draw_whirlwind(at: Vector2, t: float) -> void:
	var steps := 12
	for arm: int in 3:
		var points := PackedVector2Array()
		var colors := PackedColorArray()
		for step: int in steps:
			var radius := 4.0 + step * 2.6
			var angle := t * 3.0 + arm * TAU / 3.0 + step * 0.32
			points.append(at + Vector2(cos(angle) * radius, sin(angle) * radius * SQUASH))
			colors.append(Color(UiPalette.GROUND_WHIRL, 0.9 * (1.0 - step / float(steps))))
		draw_polyline_colors(points, colors, 2.0, true)
	for index: int in 6:
		var radius := 12.0 + 3.5 * index
		var angle := t * 2.2 + index * 1.9
		draw_circle(at + Vector2(cos(angle) * radius, sin(angle) * radius * SQUASH - 4.0), 1.7, Color(UiPalette.GROUND_WHIRL_DUST, 0.9))


func _draw_thorns(at: Vector2, t: float) -> void:
	for index: int in THORN_SPOTS.size():
		var base := at + THORN_SPOTS[index]
		var side := 1.0 if index % 2 == 0 else -1.0
		var height := 11.0 + 4.0 * (index % 3)
		var tip := base + Vector2(side * 2.0 + sin(t * 1.4 + index * 1.7) * 1.5, -height)
		var mid := base.lerp(tip, 0.5)
		draw_colored_polygon(PackedVector2Array([base + Vector2(-4.0, 0.0), tip, base + Vector2(4.0, 0.0)]), UiPalette.GROUND_THORN)
		draw_colored_polygon(PackedVector2Array([mid + Vector2(0.0, -1.5), mid + Vector2(side * 6.0, -4.0), mid + Vector2(0.0, 1.5)]), UiPalette.GROUND_THORN)
		draw_line(base + Vector2(-1.0, 0.0), tip, UiPalette.GROUND_THORN_LIGHT, 1.2, true)


func _draw_electric_tide(cell: Vector2i, at: Vector2, t: float) -> void:
	for row: int in 3:
		var points := PackedVector2Array()
		for step: int in 11:
			var x := -30.0 + step * 6.0
			points.append(at + Vector2(x, -14.0 + row * 14.0 + sin(x * 0.22 + t * 3.0 + row) * 2.0))
		draw_polyline(points, Color(UiPalette.GROUND_TIDE_WAVE, 0.75), 1.5, true)
	var flash := floori(t / SPARK_PERIOD)
	if t - flash * SPARK_PERIOD > SPARK_SECONDS:
		return
	var spot := at + Vector2(_random(cell, flash * 7 + 1) * 40.0 - 20.0, _random(cell, flash * 7 + 2) * 32.0 - 16.0)
	var spark := PackedVector2Array([spot])
	for step: int in 4:
		spot += Vector2(4.0 + _random(cell, flash * 7 + 3 + step) * 3.0, 5.0 if step % 2 == 0 else -5.0)
		spark.append(spot)
	draw_polyline(spark, Color(UiPalette.GROUND_TIDE_SPARK, 0.35), 5.0, true)
	draw_polyline(spark, UiPalette.GROUND_TIDE_SPARK, 2.0, true)


func _draw_mud(at: Vector2, t: float) -> void:
	draw_colored_polygon(_ellipse(at + Vector2(-14.0, 4.0), Vector2(12.0, 6.0)), Color(UiPalette.GROUND_MUD_BLOT, 0.45))
	draw_colored_polygon(_ellipse(at + Vector2(16.0, -6.0), Vector2(10.0, 5.0)), Color(UiPalette.GROUND_MUD_BLOT, 0.45))
	draw_colored_polygon(_ellipse(at + Vector2(4.0, 20.0), Vector2(11.0, 5.0)), Color(UiPalette.GROUND_MUD_BLOT, 0.45))
	for index: int in BUBBLE_SPOTS.size():
		var spot := at + BUBBLE_SPOTS[index]
		var cycle := fposmod(t * 0.45 + index * 0.27, 1.0)
		if cycle < 0.8:
			var radius := lerpf(1.5, 6.0, cycle / 0.8)
			draw_circle(spot, radius, UiPalette.GROUND_MUD)
			draw_circle(spot + Vector2(-radius, -radius) * 0.35, radius * 0.3, UiPalette.GROUND_MUD_SHINE)
		else:
			var pop := (cycle - 0.8) / 0.2
			_ring(spot, Vector2(5.0, 3.0) * (1.0 + pop), Color(UiPalette.GROUND_MUD_SHINE, 1.0 - pop), 1.2)


func _draw_frost(at: Vector2, t: float) -> void:
	for index: int in CRYSTAL_SPOTS.size():
		var spot := at + CRYSTAL_SPOTS[index]
		var size := 5.0 + (index % 3)
		for arm: int in 3:
			var along := Vector2.from_angle(arm * PI / 3.0 + index * 0.4) * size
			draw_line(spot - along, spot + along, UiPalette.GROUND_FROST, 2.0, true)
			draw_line(spot - along, spot + along, UiPalette.GROUND_FROST_CORE, 0.8, true)
		var glint := pow(maxf(0.0, sin(t * 1.8 + index * 2.3)), 6.0)
		if glint > 0.05:
			var shine := Color(UiPalette.AURA_SHINE, glint)
			draw_line(spot + Vector2(-5.0, 0.0) * glint, spot + Vector2(5.0, 0.0) * glint, shine, 1.5, true)
			draw_line(spot + Vector2(0.0, -6.0) * glint, spot + Vector2(0.0, 6.0) * glint, shine, 1.5, true)


func _draw_toxic_pool(at: Vector2, t: float) -> void:
	for index: int in 3:
		var rise := fposmod(t * 0.25 + index / 3.0, 1.0)
		var spot := at + Vector2(-14.0 + index * 14.0 + sin(t + index) * 3.0, lerpf(-8.0, -36.0, rise))
		draw_circle(spot, lerpf(3.0, 7.0, rise), Color(UiPalette.GROUND_TOXIC_VAPOR, 0.3 * sin(rise * PI)))
	for index: int in BUBBLE_SPOTS.size():
		var base := at + BUBBLE_SPOTS[index]
		var cycle := fposmod(t * 0.55 + index * 0.31, 1.0)
		if cycle < 0.8:
			var grow := cycle / 0.8
			var spot := base + Vector2(0.0, -grow * 8.0)
			var radius := lerpf(1.5, 4.0, grow)
			draw_circle(spot, radius, Color(UiPalette.GROUND_TOXIC, 0.95))
			draw_circle(spot + Vector2(-radius, -radius) * 0.35, radius * 0.3, UiPalette.GROUND_TOXIC_SHINE)
		else:
			var pop := (cycle - 0.8) / 0.2
			_ring(base + Vector2(0.0, -8.0), Vector2(4.0, 4.0) * (1.0 + pop), Color(UiPalette.GROUND_TOXIC_SHINE, 1.0 - pop), 1.2)


func _draw_quicksand(at: Vector2, t: float) -> void:
	for index: int in 3:
		var shrink := fposmod(t * 0.3 + index / 3.0, 1.0)
		var radius := SAND_RADIUS * (1.0 - shrink)
		_ring(at, Vector2(radius, radius * SQUASH), Color(UiPalette.GROUND_SAND_RING, 0.3 + 0.7 * shrink), 2.0)
	draw_colored_polygon(_ellipse(at, Vector2(6.0, 6.0 * SQUASH)), Color(UiPalette.GROUND_SAND_GRAIN, 0.6))
	for index: int in 8:
		var pull := fposmod(t * 0.25 + index / 8.0, 1.0)
		var radius := (SAND_RADIUS - 4.0) * (1.0 - pull)
		var angle := index * TAU / 8.0 + pull * 4.0
		draw_circle(at + Vector2(cos(angle) * radius, sin(angle) * radius * SQUASH), 1.4, Color(UiPalette.GROUND_SAND_GRAIN, sin(pull * PI)))


func _draw_garden(at: Vector2, t: float) -> void:
	for index: int in FLOWER_SPOTS.size():
		var base := at + FLOWER_SPOTS[index]
		var head := base + Vector2(sin(t * 1.5 + index * 1.3) * 1.5, -7.0)
		draw_line(base, head, UiPalette.GROUND_STEM, 1.5, true)
		var petal := UiPalette.GROUND_PETALS[index % UiPalette.GROUND_PETALS.size()]
		for leaf: int in 5:
			draw_circle(head + Vector2.from_angle(leaf * TAU / 5.0 + index) * 2.5, 2.0, petal)
		draw_circle(head, 1.5, UiPalette.GROUND_FLOWER_CORE)
	for index: int in 4:
		var rise := fposmod(t * 0.4 + index / 4.0, 1.0)
		var spot := at + Vector2(-18.0 + index * 12.0 + sin(t * 2.0 + index) * 3.0, lerpf(20.0, -10.0, rise))
		var sparkle := Color(UiPalette.GROUND_GARDEN_SPARKLE, sin(rise * PI))
		draw_line(spot + Vector2(-2.5, 0.0), spot + Vector2(2.5, 0.0), sparkle, 1.2, true)
		draw_line(spot + Vector2(0.0, -2.5), spot + Vector2(0.0, 2.5), sparkle, 1.2, true)


func _draw_puddle(cell: Vector2i, at: Vector2, t: float) -> void:
	for index: int in RIPPLES:
		var shifted := t + index * RIPPLE_PERIOD / RIPPLES
		var drop := floori(shifted / RIPPLE_PERIOD)
		var grow := shifted / RIPPLE_PERIOD - drop
		var salt := drop * RIPPLES + index
		var spot := at + Vector2(_random(cell, salt * 2 + 1) * 44.0 - 22.0, _random(cell, salt * 2 + 2) * 32.0 - 16.0)
		var radius := 2.0 + grow * 16.0
		_ring(spot, Vector2(radius, radius * 0.55), Color(UiPalette.GROUND_RIPPLE, minf(1.0, (1.0 - grow) * 1.3)), 2.0)
		if grow > 0.15:
			_ring(spot, Vector2(radius, radius * 0.55) * 0.55, Color(UiPalette.GROUND_RIPPLE, (1.0 - grow) * 0.6), 1.0)
		if grow < 0.1:
			draw_circle(spot + Vector2(0.0, -3.0), 1.5, Color(UiPalette.GROUND_RIPPLE, 0.9))


func _ring(at: Vector2, radius: Vector2, color: Color, width: float) -> void:
	var points := _ellipse(at, radius)
	points.append(points[0])
	draw_polyline(points, color, width, true)


static func _ellipse(at: Vector2, radius: Vector2, angle: float = 0.0, steps: int = 16) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in steps:
		var turn := index * TAU / steps
		points.append(at + Vector2(cos(turn) * radius.x, sin(turn) * radius.y).rotated(angle))
	return points


## Um número de 0 a 1 que só depende do hexágono e de `salt`.
static func _random(cell: Vector2i, salt: int) -> float:
	return posmod(hash([cell.x, cell.y, salt]), 10000) / 10000.0
