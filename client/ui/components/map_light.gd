class_name MapLight
extends RefCounted
## Um ponto de luz da noite, em pixels da arte do mapa (.specs/day-night/).

var position := Vector2.ZERO
var radius := 0.0
var color := Color.WHITE
## O hexágono da peça que acende (fog-of-war/02).
var coord := Vector2i.ZERO


static func make(at: Vector2, light_radius: float, light_color: Color) -> MapLight:
	var light := MapLight.new()
	light.position = at
	light.radius = light_radius
	light.color = light_color
	return light
