extends Control

const StarterCardScene := preload("res://screens/starter_select/starter_card.tscn")

## Aberta por uma cena (liora-intro/03): sem voltar, e escolher volta ao mapa.
var _story := false

@onready var _cards: HBoxContainer = %Cards
@onready var _confirm_panel: StarterConfirmPanel = %ConfirmPanel


func setup(params: Dictionary) -> void:
	_story = bool(params.get("story", false))


func _ready() -> void:
	for species: CreatureSpecies in GameData.get_starters():
		var card: StarterCard = StarterCardScene.instantiate()
		card.setup(species)
		card.pressed.connect(_confirm_panel.open.bind(species))
		_cards.add_child(card)
	_confirm_panel.choose_pressed.connect(_choose)


func handle_back() -> bool:
	if _confirm_panel.visible:
		_confirm_panel.close()
		return true
	return _story


func _choose(species_id: int) -> void:
	_confirm_panel.set_busy(true)
	var result: Result = await Session.choose_starter(species_id)
	if result.ok:
		if _story:
			Router.back()
		else:
			Home.go()
		return
	_confirm_panel.set_busy(false)
	_confirm_panel.show_error(result.error)
