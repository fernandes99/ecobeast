extends Control
## Escolha do Ecobeast inicial (onboarding/02, TELAS.md #2). Sem botão de
## voltar: o Domador já foi criado.

const StarterCardScene := preload("res://screens/starter_select/starter_card.tscn")

@onready var _subtitle: Label = %Subtitle
@onready var _cards: VBoxContainer = %Cards
@onready var _confirm_panel: StarterConfirmPanel = %ConfirmPanel


func _ready() -> void:
	if Session.player != null:
		_subtitle.text = "Ele vai te acompanhar desde o começo, %s." % Session.player.name
	for species: CreatureSpecies in GameData.get_starters():
		var card: StarterCard = StarterCardScene.instantiate()
		card.setup(species)
		card.pressed.connect(_confirm_panel.open.bind(species))
		_cards.add_child(card)
	_confirm_panel.choose_pressed.connect(_choose)


## Chamado pelo Router no voltar do Android ou Esc: fecha o painel, se aberto.
func handle_back() -> bool:
	if _confirm_panel.visible:
		_confirm_panel.close()
		return true
	return false


func _choose(species_id: int) -> void:
	_confirm_panel.set_busy(true)
	var result: Result = await Session.choose_starter(species_id)
	if result.ok:
		Router.go_to(&"placeholder", {"title": "Hub"})
		return
	_confirm_panel.set_busy(false)
	_confirm_panel.show_error(result.error)
