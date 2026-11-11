class_name CaptureRing
extends Control

const WIDTH := 14.0
const POINTS := 96
const START_ANGLE := -PI / 2.0

var value: float = 0.0:
	set(new_value):
		value = clampf(new_value, 0.0, 1.0)
		queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var radius := (minf(size.x, size.y) - WIDTH) / 2.0
	draw_arc(center, radius, 0.0, TAU, POINTS, UiPalette.TRACK, WIDTH, true)
	if value > 0.0:
		var end_angle := START_ANGLE + TAU * value
		draw_arc(center, radius, START_ANGLE, end_angle, POINTS, UiPalette.ACCENT, WIDTH, true)
