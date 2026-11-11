class_name TurnQueueBar
extends HBoxContainer

const PortraitScene := preload("res://ui/components/creature_portrait.tscn")
const PORTRAIT_SIZE := 48
const CURRENT_SIZE := 64
const BORDER_WIDTH := 3
const CURRENT_BORDER_WIDTH := 5


func set_queue(entries: Array[Dictionary]) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	for index: int in entries.size():
		add_child(_chip(entries[index], index == 0))


func _chip(entry: Dictionary, is_current: bool) -> Control:
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UiPalette.SURFACE
	var is_player := DictFields.get_string(entry, "side") == "player"
	style.border_color = UiPalette.BOARD_PLAYER if is_player else UiPalette.BOARD_ENEMY
	if is_current:
		style.border_color = UiPalette.BOARD_ACTIVE
	style.set_border_width_all(CURRENT_BORDER_WIDTH if is_current else BORDER_WIDTH)
	style.set_corner_radius_all(CURRENT_SIZE)
	chip.add_theme_stylebox_override(&"panel", style)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait: CreaturePortrait = PortraitScene.instantiate()
	portrait.portrait_size = CURRENT_SIZE if is_current else PORTRAIT_SIZE
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(portrait)
	portrait.set_species(DictFields.get_int(entry, "species_id"))
	return chip
