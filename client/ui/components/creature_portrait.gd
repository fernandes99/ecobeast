class_name CreaturePortrait
extends Control

const SPRITE_PATH := "res://assets/creatures/%s/front.png"
const SilhouetteShader := preload("res://ui/components/silhouette.gdshader")
const BORDER_WIDTH := 6.0
const INITIAL_SCALE := 0.45
const SINGLE_ELEMENT_BORDER_DARKEN := 0.25

@export var portrait_size: int = 160
## Espelha o sprite. As artes olham para a direita; o placeholder não muda.
@export var flipped: bool = false:
	set(value):
		flipped = value
		if is_node_ready():
			_sprite.flip_h = value

var _species_id: int = -1
var _silhouette: bool = false
var _fill_color := Color.TRANSPARENT
var _border_color := Color.TRANSPARENT

@onready var _sprite: TextureRect = %Sprite
@onready var _initial: Label = %Initial


func _ready() -> void:
	custom_minimum_size = Vector2(portrait_size, portrait_size)
	_sprite.flip_h = flipped
	_initial.add_theme_font_size_override(&"font_size", roundi(portrait_size * INITIAL_SCALE))
	_refresh()


func _draw() -> void:
	if _fill_color.a == 0.0:
		return
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	draw_circle(center, radius, _fill_color, true, -1.0, true)
	draw_circle(center, radius - BORDER_WIDTH / 2.0, _border_color, false, BORDER_WIDTH, true)


func set_species(species_id: int) -> void:
	_species_id = species_id
	if is_node_ready():
		_refresh()


func set_silhouette(on: bool) -> void:
	_silhouette = on
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	_fill_color = Color.TRANSPARENT
	_sprite.visible = false
	_initial.text = ""
	var species: CreatureSpecies = null
	if _species_id > 0:
		species = GameData.get_species(_species_id)
	if species != null:
		var path := SPRITE_PATH % species.slug
		if ResourceLoader.exists(path):
			_sprite.texture = load(path) as Texture2D
			_sprite.visible = true
			_paint_silhouette()
		else:
			_show_placeholder(species)
	queue_redraw()


func _paint_silhouette() -> void:
	if not _silhouette:
		_sprite.material = null
		return
	var shadow := ShaderMaterial.new()
	shadow.shader = SilhouetteShader
	shadow.set_shader_parameter(&"color", UiPalette.SILHOUETTE)
	_sprite.material = shadow


func _show_placeholder(species: CreatureSpecies) -> void:
	if _silhouette:
		_fill_color = UiPalette.SILHOUETTE
		_border_color = UiPalette.SILHOUETTE
		return
	var first := GameData.get_element(species.element_ids[0])
	_fill_color = first.color
	if species.element_ids.size() > 1:
		_border_color = GameData.get_element(species.element_ids[1]).color
	else:
		_border_color = first.color.darkened(SINGLE_ELEMENT_BORDER_DARKEN)
	_initial.text = species.name.left(1).to_upper()
