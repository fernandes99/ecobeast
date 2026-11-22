class_name PartyBubble
extends TapPanel
## Uma bolinha da equipe na Home do Hub (hub-start/03): o rosto do Ecobeast com o anel de
## HP (creature-faces/02). Quem está na ilha fica maior, crescendo para cima, com uma sombra
## embaixo, e os outros ficam apagados.

const SIZE := 88
const SELECTED_SCALE := 1.15
const DIMMED := Color(0.6, 0.62, 0.7)
const SWITCH_SECONDS := 0.12
const SHADOW_ALPHA := 0.45
const SHADOW_SIZE := Vector2(0.42, 0.1)

var _creature: CreatureInstance = null
var _selected: bool = false
var _face := CreatureFace.new()
var _tween: Tween = null


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	size_flags_horizontal = SIZE_SHRINK_CENTER
	size_flags_vertical = SIZE_SHRINK_CENTER
	add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	_face.face_size = SIZE
	add_child(_face)
	resized.connect(func() -> void: pivot_offset = Vector2(size.x / 2.0, size.y))


func _ready() -> void:
	_refresh()


func set_creature(creature: CreatureInstance) -> void:
	_creature = creature
	if is_node_ready():
		_refresh()


func set_selected(on: bool) -> void:
	_selected = on
	if is_node_ready():
		_show_selection(true)


func _refresh() -> void:
	var empty := _creature == null
	mouse_filter = MOUSE_FILTER_IGNORE if empty else MOUSE_FILTER_PASS
	mouse_default_cursor_shape = CURSOR_ARROW if empty else CURSOR_POINTING_HAND
	_face.set_creature(_creature)
	_show_selection(false)


func _show_selection(animate: bool) -> void:
	var wanted_scale := Vector2.ONE * (SELECTED_SCALE if _selected else 1.0)
	var wanted_tint := Color.WHITE if _selected or _creature == null else DIMMED
	if _tween != null:
		_tween.kill()
	if animate:
		_tween = create_tween().set_parallel()
		_tween.tween_property(self, "scale", wanted_scale, SWITCH_SECONDS)
		_tween.tween_property(_face, "modulate", wanted_tint, SWITCH_SECONDS)
	else:
		scale = wanted_scale
		_face.modulate = wanted_tint
	z_index = 1 if _selected else 0
	queue_redraw()


func _draw() -> void:
	if not _selected:
		return
	var shadow := UiPalette.OVERLAY
	shadow.a = SHADOW_ALPHA
	var center := Vector2(size.x / 2.0, size.y)
	draw_set_transform(center, 0.0, Vector2(1.0, SHADOW_SIZE.y / SHADOW_SIZE.x))
	draw_circle(Vector2.ZERO, size.x * SHADOW_SIZE.x, shadow, true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
