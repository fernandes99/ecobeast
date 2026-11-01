class_name CreatureActionsPanel
extends Control
## As ações de um Ecobeast, por cima da tela (team-and-storage/02, RF-12). Só
## exibe e repassa o toque: quem chama o Session é a tela.

signal move_pressed
signal details_pressed

## O movimento está liberado; o `set_busy` não pode liberar o que `open` travou.
var _can_move: bool = true

@onready var _dim: ColorRect = %Dim
@onready var _portrait: CreaturePortrait = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _move_button: Button = %MoveButton
@onready var _note: Label = %Note
@onready var _details_button: Button = %DetailsButton
@onready var _close_button: Button = %CloseButton
@onready var _message: Label = %Message


func _ready() -> void:
	hide()
	_dim.color = UiPalette.OVERLAY
	_move_button.pressed.connect(func() -> void: move_pressed.emit())
	_details_button.pressed.connect(func() -> void: details_pressed.emit())
	_close_button.pressed.connect(close)


## `note`: o motivo, quando `can_move` é falso.
func open(creature: CreatureInstance, move_text: String, can_move: bool = true, note: String = "") -> void:
	var species := GameData.get_species(creature.species_id)
	_portrait.set_species(species.id)
	_name_label.text = creature.display_name(species)
	_level_label.text = "Nv. %d" % creature.level
	_move_button.text = move_text
	_can_move = can_move
	_note.text = note
	_note.visible = not note.is_empty()
	_message.hide()
	set_busy(false)
	show()


func close() -> void:
	hide()


## Enquanto o pedido volta, nada aqui responde ao toque.
func set_busy(busy: bool) -> void:
	_move_button.disabled = busy or not _can_move
	_details_button.disabled = busy
	_close_button.disabled = busy


func show_error(message: String) -> void:
	_message.text = message
	_message.show()
