class_name CreaturePortrait
extends Control
## Retrato de uma espécie (foundation/02, RF-12): o sprite, se existir em
## res://assets/creatures/<slug>/front.png, ou um placeholder desenhado — círculo
## na cor do primeiro Elemento, borda na cor do segundo e a inicial do nome.

const SPRITE_PATH := "res://assets/creatures/%s/front.png"
const BORDER_WIDTH := 6.0
## Tamanho da inicial em relação ao retrato.
const INITIAL_SCALE := 0.45
## Quanto a borda escurece quando a espécie tem um Elemento só.
const SINGLE_ELEMENT_BORDER_DARKEN := 0.25

@export var portrait_size: int = 160

var _species_id: int = -1
var _fill_color := Color.TRANSPARENT
var _border_color := Color.TRANSPARENT

@onready var _sprite: TextureRect = %Sprite
@onready var _initial: Label = %Initial


func _ready() -> void:
	custom_minimum_size = Vector2(portrait_size, portrait_size)
	_initial.add_theme_font_size_override(&"font_size", roundi(portrait_size * INITIAL_SCALE))
	_refresh()


func _draw() -> void:
	if _fill_color.a == 0.0:
		return
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	draw_circle(center, radius, _fill_color, true, -1.0, true)
	draw_circle(center, radius - BORDER_WIDTH / 2.0, _border_color, false, BORDER_WIDTH, true)


## Pode ser chamado antes ou depois de o componente entrar na árvore.
func set_species(species_id: int) -> void:
	_species_id = species_id
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
		else:
			_show_placeholder(species)
	queue_redraw()


func _show_placeholder(species: CreatureSpecies) -> void:
	var first := GameData.get_element(species.element_ids[0])
	_fill_color = first.color
	if species.element_ids.size() > 1:
		_border_color = GameData.get_element(species.element_ids[1]).color
	else:
		_border_color = first.color.darkened(SINGLE_ELEMENT_BORDER_DARKEN)
	_initial.text = species.name.left(1).to_upper()
