class_name PartyBubble
extends TapPanel
## Uma bolinha da equipe na Home do Hub (hub-start/03): o rosto do Ecobeast com o anel de
## HP e, em quem está na ilha, o anel de selecionado (creature-faces/02).

const SIZE := 88

var _creature: CreatureInstance = null
var _selected: bool = false
var _face := CreatureFace.new()


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	size_flags_horizontal = SIZE_SHRINK_CENTER
	size_flags_vertical = SIZE_SHRINK_CENTER
	add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	_face.face_size = SIZE
	add_child(_face)


func _ready() -> void:
	_refresh()


func set_creature(creature: CreatureInstance) -> void:
	_creature = creature
	if is_node_ready():
		_refresh()


func set_selected(on: bool) -> void:
	_selected = on
	_face.set_selected(on)


func _refresh() -> void:
	var empty := _creature == null
	mouse_filter = MOUSE_FILTER_IGNORE if empty else MOUSE_FILTER_PASS
	mouse_default_cursor_shape = CURSOR_ARROW if empty else CURSOR_POINTING_HAND
	_face.set_creature(_creature)
	_face.set_selected(_selected)
