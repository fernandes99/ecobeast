class_name StarterCard
extends TapPanel
## Cartão de uma espécie na escolha do inicial (onboarding/02, RF-05):
## retrato, nome, Elemento e descrição. O cartão inteiro é tocável (TapPanel),
## e a borda fica na cor do Elemento.

const BORDER_WIDTH := 3

var _species: CreatureSpecies

@onready var _portrait: CreaturePortrait = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _badge: ElementBadge = %Badge
@onready var _description: Label = %Description


func setup(species: CreatureSpecies) -> void:
	_species = species


func _ready() -> void:
	var element := GameData.get_element(_species.element_ids[0])
	_portrait.set_species(_species.id)
	_name_label.text = _species.name
	_badge.set_element(element.id)
	_description.text = _species.description
	var style := (get_theme_stylebox(&"panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	style.border_color = element.color
	style.set_border_width_all(BORDER_WIDTH)
	add_theme_stylebox_override(&"panel", style)
