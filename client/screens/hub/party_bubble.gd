class_name PartyBubble
extends TapPanel
## Uma bolinha da equipe na Home do Hub (hub-start/03): o retrato recortado no círculo,
## o anel na cor do Elemento e o anel claro em quem está no palco.

const CreaturePortraitScene := preload("res://ui/components/creature_portrait.tscn")

const SIZE := 88
const RING := 3
const SELECTED_RING := 5
const INNER_GAP := 3
const FILL_DARKEN := 0.55
const EMPTY_ALPHA := 0.45
const FAINTED_TINT := Color(0.45, 0.45, 0.45)

var _creature: CreatureInstance = null
var _selected: bool = false
var _inner := Panel.new()
var _portrait: CreaturePortrait = null


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	size_flags_horizontal = SIZE_SHRINK_CENTER
	size_flags_vertical = SIZE_SHRINK_CENTER
	_inner.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_inner.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_inner)
	_portrait = CreaturePortraitScene.instantiate()
	_portrait.portrait_size = SIZE - 2 * (SELECTED_RING + INNER_GAP)
	_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	_inner.add_child(_portrait)


func _ready() -> void:
	_refresh()


func set_creature(creature: CreatureInstance) -> void:
	_creature = creature
	if is_node_ready():
		_refresh()


func set_selected(on: bool) -> void:
	_selected = on
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	var empty := _creature == null
	mouse_filter = MOUSE_FILTER_IGNORE if empty else MOUSE_FILTER_PASS
	mouse_default_cursor_shape = CURSOR_ARROW if empty else CURSOR_POINTING_HAND
	_portrait.visible = not empty
	var element_color := UiPalette.BORDER
	if not empty:
		var species := GameData.get_species(_creature.species_id)
		element_color = GameData.get_element(species.element_ids[0]).color
		_portrait.set_species(species.id)
		_portrait.modulate = FAINTED_TINT if _creature.current_hp <= 0 else Color.WHITE
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.set_corner_radius_all(SIZE)
	var width := SELECTED_RING if _selected else RING
	ring.set_border_width_all(width)
	ring.border_color = UiPalette.TEXT if _selected else element_color
	ring.set_content_margin_all(SELECTED_RING + INNER_GAP)
	add_theme_stylebox_override(&"panel", ring)
	var fill := StyleBoxFlat.new()
	fill.set_corner_radius_all(SIZE)
	fill.bg_color = element_color.darkened(FILL_DARKEN)
	if empty:
		fill.bg_color = UiPalette.SURFACE_RAISED
		fill.bg_color.a = EMPTY_ALPHA
	_inner.add_theme_stylebox_override(&"panel", fill)
