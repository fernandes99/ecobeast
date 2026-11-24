class_name PartyStrip
extends HBoxContainer

## A equipe no canto de baixo de Explorar (explore-hud/02): o rosto de cada Ecobeast com o
## anel de HP, na ordem da equipe, todos do mesmo tamanho. Tocar em qualquer um avisa a tela.

signal tapped

const FACE := 60
const GAP := 6


func _init() -> void:
	add_theme_constant_override(&"separation", GAP)
	alignment = ALIGNMENT_BEGIN
	size_flags_vertical = SIZE_SHRINK_END
	mouse_filter = MOUSE_FILTER_IGNORE


func set_team(team: Array[CreatureInstance]) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for creature in team:
		var holder := TapPanel.new()
		holder.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
		holder.custom_minimum_size = Vector2(FACE, FACE)
		holder.size_flags_vertical = SIZE_SHRINK_END
		holder.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		holder.pressed.connect(tapped.emit)
		var face := CreatureFace.new()
		face.face_size = FACE
		face.set_creature(creature)
		holder.add_child(face)
		add_child(holder)
