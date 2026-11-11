class_name CodexCell
extends TapPanel

const NUMBER_TEXT := "#%03d"
const UNKNOWN_TEXT := "???"
const CAUGHT_MARK_PATH := "res://assets/items/bond_sphere.png"

var species_id: int = 0
var status: Codex.Status = Codex.Status.UNKNOWN

@onready var _number_label: Label = %NumberLabel
@onready var _caught_mark: TextureRect = %CaughtMark
@onready var _portrait: CreaturePortrait = %Portrait
@onready var _unknown_label: Label = %UnknownLabel
@onready var _name_label: Label = %NameLabel


func _ready() -> void:
	_number_label.text = NUMBER_TEXT % species_id
	var known := status != Codex.Status.UNKNOWN
	_portrait.visible = known
	_unknown_label.visible = not known
	_unknown_label.text = UNKNOWN_TEXT
	_unknown_label.add_theme_color_override(&"font_color", UiPalette.TEXT_MUTED)
	_name_label.text = GameData.get_species(species_id).name if known else ""
	_portrait.set_silhouette(status == Codex.Status.SEEN)
	_portrait.set_species(species_id)
	var caught := status == Codex.Status.CAUGHT
	_caught_mark.visible = caught and ResourceLoader.exists(CAUGHT_MARK_PATH)
	if _caught_mark.visible:
		_caught_mark.texture = load(CAUGHT_MARK_PATH) as Texture2D
	mouse_default_cursor_shape = CURSOR_POINTING_HAND if known else CURSOR_ARROW
