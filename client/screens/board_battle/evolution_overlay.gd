class_name EvolutionOverlay
extends Control

const STEP_TIME := 0.25
const STEPS := 6
const FLASH := Color(4.0, 4.0, 4.0)
const NO_CHOICE_TEXT := "Essa escolha não está mais disponível."

var _cancelled := false
var _animating := false

@onready var _dim: ColorRect = %Dim
@onready var _portrait: CreaturePortrait = %Portrait
@onready var _message: Label = %Message
@onready var _error: Label = %Error
@onready var _cancel_button: Button = %CancelButton
@onready var _retry_button: Button = %RetryButton
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	hide()
	_dim.color = UiPalette.OVERLAY
	_error.add_theme_color_override(&"font_color", UiPalette.DANGER)
	_cancel_button.pressed.connect(_cancel)


func play(uid: String, species_id: int, evolved_species_id: int, display_name: String) -> ProgressChoice:
	_cancelled = false
	_portrait.set_species(species_id)
	_portrait.modulate = Color.WHITE
	_message.text = "%s está evoluindo!" % display_name
	_show_buttons(_cancel_button)
	_error.hide()
	show()

	await _animate(species_id, evolved_species_id)
	var accept := not _cancelled
	_show_buttons(null)
	var choice := await _send(uid, accept)
	if choice == null:
		_message.text = NO_CHOICE_TEXT
		_portrait.set_species(species_id)
	elif accept:
		_portrait.set_species(evolved_species_id)
		_message.text = "%s evoluiu para %s!" % [display_name, GameData.get_species(evolved_species_id).name]
	else:
		_portrait.set_species(species_id)
		_message.text = "%s não evoluiu." % display_name
	_show_buttons(_continue_button)
	await _continue_button.pressed
	hide()
	return choice


func go_back() -> void:
	if _animating:
		_cancel()
	elif _continue_button.visible:
		_continue_button.pressed.emit()


func _cancel() -> void:
	_cancelled = true


func _animate(species_id: int, evolved_species_id: int) -> void:
	_animating = true
	for step: int in STEPS:
		if _cancelled:
			break
		var tween := create_tween()
		tween.tween_property(_portrait, "modulate", FLASH, STEP_TIME)
		await tween.finished
		_portrait.set_species(evolved_species_id if step % 2 == 0 else species_id)
		if step == STEPS - 1 and not _cancelled:
			_portrait.set_species(evolved_species_id)
		tween = create_tween()
		tween.tween_property(_portrait, "modulate", Color.WHITE, STEP_TIME)
		await tween.finished
	_portrait.modulate = Color.WHITE
	_animating = false


func _send(uid: String, accept: bool) -> ProgressChoice:
	var result: Result = await Session.evolve(uid, accept)
	while not result.ok:
		_error.text = result.error
		_error.show()
		_show_buttons(_retry_button)
		await _retry_button.pressed
		_show_buttons(null)
		result = await Session.evolve(uid, accept)
	_error.hide()
	return result.data


func _show_buttons(button: Button) -> void:
	for option: Button in [_cancel_button, _retry_button, _continue_button]:
		option.visible = option == button
