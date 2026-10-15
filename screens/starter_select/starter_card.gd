class_name StarterCard
extends PanelContainer
## Cartão de uma espécie na escolha do inicial (onboarding/02, RF-05):
## retrato, nome, Elemento e descrição. O cartão inteiro é tocável, e a borda
## fica na cor do Elemento.

signal pressed

const BORDER_WIDTH := 3
## Quanto o dedo pode andar entre tocar e soltar para ainda contar como toque
## (mais que isso é o jogador rolando a tela).
const TAP_SLOP := 24.0
const PRESSED_TINT := Color(0.94, 0.94, 0.94)

var _species: CreatureSpecies
var _press_position := Vector2.ZERO
var _is_pressing: bool = false

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


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if button.pressed:
		_is_pressing = true
		_press_position = button.position
		self_modulate = PRESSED_TINT
	elif _is_pressing:
		_is_pressing = false
		self_modulate = Color.WHITE
		var is_tap := button.position.distance_to(_press_position) <= TAP_SLOP
		if is_tap and Rect2(Vector2.ZERO, size).has_point(button.position):
			pressed.emit()
	accept_event()


func _notification(what: int) -> void:
	# Se o toque for cancelado (o dedo saiu ou a tela rolou), desfaz o destaque.
	if what == NOTIFICATION_MOUSE_EXIT and _is_pressing:
		_is_pressing = false
		self_modulate = Color.WHITE
