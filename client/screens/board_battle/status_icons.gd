class_name StatusIcons
extends Node2D

const RADIUS := 11.0
const GAP := 3.0
const OUTLINE := 2.0
const LINE := 2.0

var slugs: Array[String] = []:
	set(value):
		slugs = value
		queue_redraw()


func _draw() -> void:
	var width := slugs.size() * RADIUS * 2.0 + maxf(0, slugs.size() - 1) * GAP
	var x := -width / 2.0 + RADIUS
	for slug: String in slugs:
		_icon(slug, Vector2(x, 0.0))
		x += RADIUS * 2.0 + GAP


func _icon(slug: String, at: Vector2) -> void:
	var dark := UiPalette.BACKGROUND_DEEP
	draw_circle(at, RADIUS + OUTLINE, dark)
	draw_circle(at, RADIUS, UiPalette.STATUS_COLORS.get(slug, UiPalette.WARNING))
	match slug:
		"burn":
			draw_colored_polygon(_moved(_flame(), at), dark)
		"poison":
			draw_circle(at + Vector2(-2.5, 2.5), 3.5, dark)
			draw_circle(at + Vector2(3.5, -1.0), 2.5, dark)
			draw_circle(at + Vector2(-0.5, -4.5), 1.8, dark)
		"paralysis":
			draw_colored_polygon(_moved(PackedVector2Array([
				Vector2(2.0, -8.0), Vector2(-4.5, 1.0), Vector2(-0.5, 1.0),
				Vector2(-2.0, 8.0), Vector2(4.5, -1.5), Vector2(0.5, -1.5),
			]), at), dark)
		"sleep":
			draw_polyline(_moved(PackedVector2Array([
				Vector2(-4.0, -4.5), Vector2(4.0, -4.5), Vector2(-4.0, 4.5), Vector2(4.0, 4.5),
			]), at), dark, LINE + 0.5)
		"freeze":
			for index: int in 3:
				var arm := Vector2.from_angle(PI / 2.0 + index * PI / 3.0) * 7.0
				draw_line(at - arm, at + arm, dark, LINE)
		"confusion":
			draw_polyline(_moved(_spiral(), at), dark, LINE)
		"fear":
			draw_line(at + Vector2(0.0, -7.0), at + Vector2(0.0, 2.0), dark, LINE + 1.0)
			draw_circle(at + Vector2(0.0, 5.5), 1.6, dark)
		"trapped":
			draw_arc(at + Vector2(0.0, -1.5), 3.2, PI, TAU, 10, dark, LINE)
			draw_rect(Rect2(at + Vector2(-5.0, -1.5), Vector2(10.0, 8.0)), dark)
		"dazed":
			for index: int in 3:
				var spot := at + Vector2.from_angle(-PI / 2.0 + index * TAU / 3.0) * 4.5
				draw_colored_polygon(_moved(_sparkle(3.6), spot), dark)
		"soaked":
			draw_colored_polygon(CreatureAura.flame_points(at + Vector2(0.0, 2.5), 6.0), dark)
		"sprouting":
			draw_line(at + Vector2(0.0, 7.0), at + Vector2(0.0, -1.0), dark, LINE)
			draw_colored_polygon(_moved(_leaf(-1.0), at + Vector2(0.0, -1.0)), dark)
			draw_colored_polygon(_moved(_leaf(1.0), at + Vector2(0.0, -1.0)), dark)
		"protect":
			draw_colored_polygon(_moved(PackedVector2Array([
				Vector2(0.0, -7.5), Vector2(6.0, -5.0), Vector2(5.0, 2.0),
				Vector2(0.0, 7.5), Vector2(-5.0, 2.0), Vector2(-6.0, -5.0),
			]), at), dark)


## Uma folha de broto, para um lado (-1) ou para o outro (1), saindo da haste.
static func _leaf(side: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2.ZERO, Vector2(side * 3.0, -4.5), Vector2(side * 7.0, -5.0), Vector2(side * 4.5, -1.0),
	])


func _flame() -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(0.0, -8.0)])
	var steps := 10
	for index: int in steps + 1:
		var angle := deg_to_rad(-25.0 + index * 230.0 / steps)
		points.append(Vector2(0.0, 2.0) + Vector2.from_angle(angle) * 5.0)
	return points


## Uma estrelinha de 4 pontas.
static func _sparkle(size: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for corner: int in 8:
		var radius := size if corner % 2 == 0 else size * 0.35
		points.append(Vector2.from_angle(-PI / 2.0 + corner * PI / 4.0) * radius)
	return points


func _spiral() -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := 28
	for index: int in steps + 1:
		var t := index / float(steps)
		points.append(Vector2.from_angle(t * TAU * 2.0) * (7.0 - t * 6.0))
	return points


func _moved(points: PackedVector2Array, at: Vector2) -> PackedVector2Array:
	var moved := PackedVector2Array()
	for point: Vector2 in points:
		moved.append(point + at)
	return moved
