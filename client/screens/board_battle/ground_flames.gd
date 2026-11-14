class_name GroundFlames
extends Node2D

const SPOTS: Array[Vector2] = [
	Vector2(-26, 6), Vector2(24, 4), Vector2(-12, 22), Vector2(14, 24),
	Vector2(0, -18), Vector2(-30, -10), Vector2(30, -12),
]
const SIZE := 5.5

var board: BoardView = null
var kinds: Dictionary[Vector2i, String] = {}:
	set(value):
		kinds = value
		set_process(_has_flames())
		queue_redraw()

var _time := 0.0


func _ready() -> void:
	set_process(_has_flames())


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	for cell: Vector2i in kinds:
		if kinds[cell] != "fire":
			continue
		var center := board.cell_center(cell)
		for index: int in SPOTS.size():
			var flicker := 0.75 + 0.25 * sin(_time * 9.0 + index * 1.3) + 0.1 * sin(_time * 23.0 + index)
			var at := center + SPOTS[index]
			_flame(CreatureAura.flame_points(at, SIZE * flicker), UiPalette.STATUS_COLORS["burn"])
			_flame(CreatureAura.flame_points(at + Vector2(0.0, 1.5), SIZE * flicker * 0.5), UiPalette.AURA_FLAME_CORE)


func _flame(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, Color(color, 0.9))


func _has_flames() -> bool:
	return kinds.values().has("fire")
