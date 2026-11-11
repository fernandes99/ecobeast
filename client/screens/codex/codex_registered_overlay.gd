class_name CodexRegisteredOverlay
extends Control

signal closed

const ElementBadgeScene := preload("res://ui/components/element_badge.tscn")

const NUMBER_TEXT := "#%03d %s"
const GLOW_ALPHA := 0.55

@onready var _dim: ColorRect = %Dim
@onready var _glow: TextureRect = %Glow
@onready var _portrait: CreaturePortrait = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _element_row: HBoxContainer = %ElementRow
@onready var _description_label: Label = %DescriptionLabel
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	hide()
	_dim.color = UiPalette.OVERLAY
	_glow.texture = _glow_gradient(UiPalette.ACCENT)
	_continue_button.pressed.connect(close)


func play(species_id: int) -> void:
	var species := GameData.get_species(species_id)
	_portrait.set_species(species_id)
	_name_label.text = NUMBER_TEXT % [species_id, species.name]
	for badge: Node in _element_row.get_children():
		_element_row.remove_child(badge)
		badge.queue_free()
	for element_id: int in species.element_ids:
		var badge: ElementBadge = ElementBadgeScene.instantiate()
		badge.set_element(element_id)
		_element_row.add_child(badge)
	_description_label.text = species.description
	show()
	await closed


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func _glow_gradient(color: Color) -> GradientTexture2D:
	var clear := color
	clear.a = 0.0
	var center := color
	center.a = GLOW_ALPHA
	var gradient := Gradient.new()
	gradient.set_color(0, center)
	gradient.set_color(1, clear)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture
