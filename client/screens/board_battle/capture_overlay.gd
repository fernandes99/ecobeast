class_name CaptureOverlay
extends Control

const LOADING_TIME := 3.5
const RESULT_TIME := 1.2
const ESCAPE_TIME := 0.25
const ENTERED_SCALE := Vector2(0.08, 0.08)
const LOADING_TEXT := "Entrando na Esfera..."
const SUCCESS_TEXT := "Capturado!"
const FAILURE_TEXT := "Escapou!"

var _home := Vector2.ZERO

@onready var _dim: ColorRect = %Dim
@onready var _ring: CaptureRing = %Ring
@onready var _icon: ItemIcon = %Icon
@onready var _portrait: CreaturePortrait = %Portrait
@onready var _message: Label = %Message


func _ready() -> void:
	hide()
	_dim.color = UiPalette.OVERLAY
	_home = _portrait.position


func play(item: Item, species_id: int, success: bool) -> void:
	_icon.set_item(item)
	_portrait.set_species(species_id)
	_place_at_home()
	_ring.value = 0.0
	_show_message(LOADING_TEXT, UiPalette.TEXT)
	show()

	await _enter_sphere()
	if success:
		_show_message(SUCCESS_TEXT, UiPalette.HP_HIGH)
	else:
		_show_message(FAILURE_TEXT, UiPalette.DANGER)
		await _leave_sphere()
	await get_tree().create_timer(RESULT_TIME - _escape_time(success)).timeout
	hide()


func _place_at_home() -> void:
	_portrait.position = _home
	_portrait.scale = Vector2.ONE
	_portrait.modulate.a = 1.0


func _show_message(text: String, color: Color) -> void:
	_message.text = text
	_message.add_theme_color_override(&"font_color", color)


func _enter_sphere() -> void:
	var target := _icon.position + (_icon.size - _portrait.size) / 2.0
	var tween := create_tween().set_parallel()
	tween.tween_property(_ring, "value", 1.0, LOADING_TIME)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_portrait, "position", target, LOADING_TIME)
	tween.tween_property(_portrait, "scale", ENTERED_SCALE, LOADING_TIME)
	tween.tween_property(_portrait, "modulate:a", 0.0, LOADING_TIME)
	await tween.finished


func _leave_sphere() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(_portrait, "position", _home, ESCAPE_TIME)
	tween.tween_property(_portrait, "scale", Vector2.ONE, ESCAPE_TIME)
	tween.tween_property(_portrait, "modulate:a", 1.0, ESCAPE_TIME)
	await tween.finished


func _escape_time(success: bool) -> float:
	return 0.0 if success else ESCAPE_TIME
