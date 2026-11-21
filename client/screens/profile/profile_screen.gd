extends Control
## O Perfil (hub-start/02): o Domador, os números dele e o caminho para a Aparência.

const PREVIEW_SCALE := 8.0
const PREVIEW_FOOT_GAP := 24.0
const STAT_FONT := 24
const LOADING_TEXT := "…"

var _codex_values: Array[Label] = []
var _level_value := Label.new()
var _coins_value := Label.new()

@onready var _preview_area: Control = %PreviewArea
@onready var _preview: TamerSprite = %Preview
@onready var _name_label: Label = %NameLabel
@onready var _stats: GridContainer = %Stats
@onready var _message: Label = %Message
@onready var _appearance_button: Button = %AppearanceButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_preview.scale = Vector2.ONE * PREVIEW_SCALE
	_preview_area.resized.connect(_place_preview)
	_add_stat("Nível", _level_value)
	_add_stat("Moedas", _coins_value)
	for title: String in ["Espécies vistas", "Espécies capturadas"]:
		var value := Label.new()
		value.text = LOADING_TEXT
		_codex_values.append(value)
		_add_stat(title, value)
	_appearance_button.pressed.connect(Router.push.bind(&"appearance"))
	_back_button.pressed.connect(Router.back)
	Session.player_changed.connect(_refresh)
	_refresh()
	_place_preview()
	_load_codex()


func _add_stat(title: String, value: Label) -> void:
	var label := Label.new()
	label.text = title
	label.theme_type_variation = &"SecondaryLabel"
	label.add_theme_font_size_override(&"font_size", STAT_FONT)
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	_stats.add_child(label)
	value.theme_type_variation = &"BoldLabel"
	value.add_theme_font_size_override(&"font_size", STAT_FONT)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stats.add_child(value)


func _place_preview() -> void:
	_preview.position = Vector2(_preview_area.size.x / 2.0, _preview_area.size.y - PREVIEW_FOOT_GAP).round()


func _refresh() -> void:
	var player := Session.player
	if player == null:
		return
	_preview.set_appearance(player.appearance)
	_name_label.text = player.name
	_level_value.text = str(player.level)
	_coins_value.text = NumberFormat.thousands(player.coins)


func _load_codex() -> void:
	var result: Result = await Session.load_codex()
	if not is_inside_tree():
		return
	if not result.ok:
		_message.text = result.error
		_message.show()
		return
	var codex := result.data as Codex
	_codex_values[0].text = str(codex.seen_count())
	_codex_values[1].text = str(codex.caught_count())
