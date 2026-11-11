extends Control

const LOADING_TEXT := "Carregando ilhas..."
const EMPTY_TEXT := "Nenhuma ilha publicada ainda."
const CARD_HEIGHT := 88.0

var _loading: bool = true

@onready var _list: VBoxContainer = %IslandList
@onready var _message: Label = %Message
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(Router.back)
	_load()


func handle_back() -> bool:
	return _loading


func _load() -> void:
	_back_button.disabled = true
	_show_message(LOADING_TEXT, &"SecondaryLabel")
	var result: Result = await Session.list_islands()
	_loading = false
	_back_button.disabled = false
	if not result.ok:
		_show_message(result.error, &"DangerLabel")
		return
	var islands: Array[IslandSummary] = result.data
	if islands.is_empty():
		_show_message(EMPTY_TEXT, &"SecondaryLabel")
		return
	_message.hide()
	for island: IslandSummary in islands:
		_list.add_child(_card(island))


func _card(island: IslandSummary) -> TapPanel:
	var card := TapPanel.new()
	card.theme_type_variation = &"SectionPanel"
	card.custom_minimum_size.y = CARD_HEIGHT
	var label := Label.new()
	label.text = island.name
	label.theme_type_variation = &"BoldLabel"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(label)
	card.pressed.connect(Router.push.bind(&"exploration", {"island_id": island.id}))
	return card


func _show_message(text: String, variation: StringName) -> void:
	_message.text = text
	_message.theme_type_variation = variation
	_message.show()
