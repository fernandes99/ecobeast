class_name CreatureAura
extends Node2D

const TINT_WEIGHT := 0.45
const FROZEN_WEIGHT := 0.35
const ZAP_WEIGHT := 0.6
const PULSE_SPEED := 6.0
const SLEEP_SPEED := 0.5
const ZAP_PERIOD := 0.7
const ZAP_SECONDS := 0.2
const TREMBLE := 1.5
const ZAP_SHAKE := 2.0
const MIN_HEIGHT := 24.0
const MIN_HALF_WIDTH := 12.0
const OUTLINE := 1.5
const FLAMES := 6
const BUBBLES := 5
const CRYSTALS := 6
const STARS := 3
const LINKS := 12

var effects: Array[String] = []:
	set(value):
		effects = value
		_apply()

var back := Node2D.new()
var _token: BoardView.Token = null
var _time := 0.0


## O desenho de uma chama ou de uma gota: ponta para cima e fundo redondo.
static func flame_points(at: Vector2, size: float) -> PackedVector2Array:
	var points := PackedVector2Array([at + Vector2(0.0, -size * 2.2)])
	var steps := 8
	for index: int in steps + 1:
		var angle := deg_to_rad(-15.0 + index * 210.0 / steps)
		points.append(at + Vector2.from_angle(angle) * size)
	return points


func attach(token: BoardView.Token) -> void:
	_token = token
	back.draw.connect(_draw_back)
	token.add_child(back)
	token.move_child(back, 0)
	token.add_child(self)
	set_process(false)


func _apply() -> void:
	if _token == null:
		return
	var speed := 1.0
	if effects.has("sleep"):
		speed = SLEEP_SPEED
	if effects.has("freeze"):
		speed = 0.0
	_token.set_speed(speed)
	set_process(not effects.is_empty())
	_update_body()
	queue_redraw()
	back.queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_update_body()
	queue_redraw()
	back.queue_redraw()


func _update_body() -> void:
	var tint := Color.WHITE
	for slug: String in BattleStatuses.ORDER:
		if not effects.has(slug):
			continue
		match slug:
			"burn", "poison":
				tint = Color.WHITE.lerp(_color(slug), TINT_WEIGHT * (0.5 + 0.5 * sin(_time * PULSE_SPEED)))
			"freeze":
				tint = Color.WHITE.lerp(_color(slug), FROZEN_WEIGHT)
			"paralysis":
				if _zapping():
					tint = Color.WHITE.lerp(_color(slug), ZAP_WEIGHT)
		if tint != Color.WHITE:
			break
	_token.sprite.modulate = tint
	var shift := 0.0
	if effects.has("fear"):
		shift += sin(_time * 45.0) * TREMBLE
	if effects.has("paralysis") and _zapping():
		shift += sin(_time * 90.0) * ZAP_SHAKE
	_token.sprite.position = Vector2(shift, 0.0)


func _draw() -> void:
	for slug: String in effects:
		match slug:
			"burn":
				_draw_flames()
			"poison":
				_draw_bubbles()
			"paralysis":
				_draw_sparks()
			"sleep":
				_draw_sleep()
			"freeze":
				_draw_crystals()
			"confusion":
				_draw_stars()
			"fear":
				_draw_sweat()
			"trapped":
				_draw_chain(self, false)
			"protect":
				_draw_bubble()


func _draw_back() -> void:
	if effects.has("trapped"):
		_draw_chain(back, true)


func _draw_flames() -> void:
	for index: int in FLAMES:
		var p := fposmod(_time * 0.9 + index / float(FLAMES), 1.0)
		var side := -1.0 if index % 2 == 0 else 1.0
		var at := Vector2(side * _half_width() * (0.55 + 0.35 * sin(index * 2.4)) + sin(_time * 5.0 + index) * 1.5,
				_feet() - _height() * (0.1 + p * 0.8))
		var color := UiPalette.AURA_FLAME_CORE.lerp(_color("burn"), clampf(p * 2.5, 0.0, 1.0))
		color.a = 1.0 - p * p
		_shape(flame_points(at, lerpf(4.5, 1.5, p)), color)


func _draw_bubbles() -> void:
	var color := _color("poison")
	for index: int in BUBBLES:
		var p := fposmod(_time * 0.6 + index / float(BUBBLES), 1.0)
		var at := Vector2(sin(index * 1.9) * _half_width() * 0.7 + sin(_time * 3.0 + index * 2.0) * 3.0,
				_feet() - _height() * (0.1 + p * 0.9))
		var radius := lerpf(2.5, 5.0, p)
		var alpha := sqrt(1.0 - p)
		draw_circle(at, radius, Color(color.lightened(0.2), 0.75 * alpha))
		draw_arc(at, radius, 0.0, TAU, 12, Color(UiPalette.BACKGROUND_DEEP, 0.8 * alpha), OUTLINE)
		draw_circle(at + Vector2(-radius, -radius) * 0.35, radius * 0.25, Color(UiPalette.AURA_SHINE, alpha))


func _draw_sparks() -> void:
	var color := _color("paralysis")
	for index: int in 3:
		var at := _middle() + Vector2(cos(index * 2.1 + 0.5) * _half_width(), sin(index * 2.1 + 0.5) * _height() * 0.4)
		var twinkle := maxf(0.0, sin(_time * 7.0 + index * 2.0))
		var arm := 5.0 * twinkle
		draw_line(at - Vector2(arm, 0.0), at + Vector2(arm, 0.0), color, 2.0)
		draw_line(at - Vector2(0.0, arm), at + Vector2(0.0, arm), color, 2.0)
	if not _zapping():
		return
	var zap := floori(_time / ZAP_PERIOD)
	for bolt: int in 2:
		var angle := zap * 2.7 + bolt * PI
		var direction := Vector2.from_angle(angle)
		var start := _middle() + direction * Vector2(_half_width(), _height() * 0.4) * 0.6
		var points := PackedVector2Array([start])
		for step: int in 4:
			var side := direction.orthogonal() * (4.0 if step % 2 == 0 else -4.0)
			points.append(start + direction * _height() * 0.09 * (step + 1) + side)
		draw_polyline(points, UiPalette.BACKGROUND_DEEP, 4.5)
		draw_polyline(points, color, 2.5)


func _draw_sleep() -> void:
	for index: int in 3:
		var p := fposmod(_time * 0.45 + index / 3.0, 1.0)
		var at := _head() + Vector2(_half_width() * 0.4 + p * 16.0, -4.0 - p * 26.0)
		var size := lerpf(4.0, 8.0, p)
		var points := PackedVector2Array([
			at + Vector2(-size, -size), at + Vector2(size, -size),
			at + Vector2(-size, size), at + Vector2(size, size),
		])
		var alpha := sin(p * PI)
		draw_polyline(points, Color(UiPalette.BACKGROUND_DEEP, alpha), 4.5)
		draw_polyline(points, Color(_color("sleep").lightened(0.5), alpha), 2.5)


func _draw_crystals() -> void:
	var color := _color("freeze")
	for index: int in CRYSTALS:
		var angle := index * TAU / CRYSTALS + 0.4
		var at := _middle() + Vector2(cos(angle) * _half_width() * 1.05, sin(angle) * _height() * 0.5)
		var twinkle := 0.5 + 0.5 * sin(_time * 3.0 + index * 1.7)
		var size := 3.5 + 2.0 * twinkle
		var diamond := PackedVector2Array([
			at + Vector2(0.0, -size * 1.6), at + Vector2(size, 0.0),
			at + Vector2(0.0, size * 1.6), at + Vector2(-size, 0.0),
		])
		_shape(diamond, Color(color, 0.5 + 0.5 * twinkle))
		draw_circle(at + Vector2(0.0, -size * 0.5), 1.0, Color(UiPalette.AURA_SHINE, twinkle))


func _draw_stars() -> void:
	var center := _head() + Vector2(0.0, -4.0)
	for index: int in STARS:
		var angle := _time * 3.0 + index * TAU / STARS
		var at := center + Vector2(cos(angle) * maxf(_half_width(), 16.0), sin(angle) * 6.0)
		var size := 6.0 + 1.5 * sin(angle)
		var points := PackedVector2Array()
		for corner: int in 10:
			var radius := size if corner % 2 == 0 else size * 0.45
			points.append(at + Vector2.from_angle(-PI / 2.0 + corner * PI / 5.0) * radius)
		_shape(points, UiPalette.AURA_STAR)


func _draw_sweat() -> void:
	for index: int in 2:
		var p := fposmod(_time * 0.8 + index * 0.5, 1.0)
		var side := -1.0 if index == 0 else 1.0
		var at := _head() + Vector2(side * _half_width() * 0.55, _height() * (0.1 + p * 0.25))
		_shape(flame_points(at, 3.0), Color(UiPalette.AURA_SWEAT, 1.0 - p))


func _draw_chain(layer: Node2D, behind: bool) -> void:
	var color := _color("trapped")
	var radius_x := _half_width() * 1.1
	var radius_y := radius_x * 0.35
	for index: int in LINKS:
		var angle := _time * 1.2 + index * TAU / LINKS
		if (sin(angle) < 0.0) != behind:
			continue
		var at := Vector2(cos(angle) * radius_x, _feet() - 4.0 + sin(angle) * radius_y)
		var tone := color.darkened(0.3) if behind else color
		layer.draw_set_transform(at, angle + (PI / 2.0 if index % 2 == 0 else 0.0), Vector2(1.0, 0.55))
		layer.draw_arc(Vector2.ZERO, 4.0, 0.0, TAU, 10, UiPalette.BACKGROUND_DEEP, 3.2)
		layer.draw_arc(Vector2.ZERO, 4.0, 0.0, TAU, 10, tone, 1.8)
	layer.draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_bubble() -> void:
	var color := _color("protect")
	var radius_y := _height() * 0.62
	var radius_x := maxf(_half_width() * 1.3, radius_y * 0.8)
	draw_set_transform(_middle(), 0.0, Vector2(radius_x / radius_y, 1.0))
	draw_circle(Vector2.ZERO, radius_y, Color(color, 0.14 + 0.06 * sin(_time * 2.5)))
	draw_arc(Vector2.ZERO, radius_y, 0.0, TAU, 32, Color(color, 0.75), 2.0)
	var start := _time * 1.5
	draw_arc(Vector2.ZERO, radius_y * 0.82, start, start + 0.9, 12, Color(UiPalette.AURA_SHINE, 0.6), 2.5)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _shape(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, Color(UiPalette.BACKGROUND_DEEP, color.a * 0.7), OUTLINE)


func _zapping() -> bool:
	return fposmod(_time, ZAP_PERIOD) < ZAP_SECONDS


func _color(slug: String) -> Color:
	return UiPalette.STATUS_COLORS.get(slug, UiPalette.WARNING)


func _feet() -> float:
	return BoardView.FEET_Y


func _height() -> float:
	return maxf(_token.height, MIN_HEIGHT)


func _half_width() -> float:
	return maxf(_token.shadow_radius, MIN_HALF_WIDTH)


func _middle() -> Vector2:
	return Vector2(0.0, _feet() - _height() / 2.0)


func _head() -> Vector2:
	return Vector2(0.0, _feet() - _height())
