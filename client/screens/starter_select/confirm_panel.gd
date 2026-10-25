class_name StarterConfirmPanel
extends Control
## Painel de confirmação da escolha do inicial (onboarding/02, RF-06 e RF-07).
## Só exibe e repassa toques: quem chama o Session é a tela.

## O jogador tocou em "Escolher".
signal choose_pressed(species_id: int)

var _species_id: int = -1
var _busy: bool = false

@onready var _dim: ColorRect = %Dim
@onready var _portrait: CreaturePortrait = %Portrait
@onready var _question: Label = %Question
@onready var _badge: ElementBadge = %Badge
@onready var _message: Label = %Message
@onready var _choose_button: Button = %ChooseButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	hide()
	_dim.color = UiPalette.OVERLAY
	_dim.gui_input.connect(_on_dim_input)
	_choose_button.pressed.connect(func() -> void: choose_pressed.emit(_species_id))
	_back_button.pressed.connect(close)


func open(species: CreatureSpecies) -> void:
	_species_id = species.id
	_portrait.set_species(species.id)
	_question.text = "Escolher %s?" % species.name
	_badge.set_element(species.element_ids[0])
	_message.hide()
	set_busy(false)
	show()


## Fecha sem escolher. Enquanto a escolha está em andamento, não fecha.
func close() -> void:
	if not _busy:
		hide()


func set_busy(busy: bool) -> void:
	_busy = busy
	_choose_button.disabled = busy
	_back_button.disabled = busy
	_choose_button.text = "Escolhendo…" if busy else "Escolher"


func show_error(message: String) -> void:
	_message.text = message
	_message.show()


func _on_dim_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
		close()
