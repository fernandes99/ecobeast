extends Control

## A escolha do Explorar da Home (auralis/03): o mapa aleatório ou o Arquipélago Auralis.

const CARD_HEIGHT := 104.0
const OPTIONS: Array[Dictionary] = [
	{"id": &"random", "title": "Explorar randomicamente", "subtitle": "Um mapa novo a cada vez."},
	{"id": &"archipelago", "title": "Arquipélago Auralis", "subtitle": "Abra as ilhas uma a uma."},
]

@onready var _list: VBoxContainer = %DestinationList
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(Router.back)
	for option: Dictionary in OPTIONS:
		_list.add_child(_card(option["title"], option["subtitle"], _go.bind(option["id"])))


func _card(title: String, subtitle: String, action: Callable) -> TapPanel:
	var card := TapPanel.new()
	card.theme_type_variation = &"SectionPanel"
	card.custom_minimum_size.y = CARD_HEIGHT
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	column.add_child(_label(title, &"BoldLabel"))
	column.add_child(_label(subtitle, &"SecondaryLabel"))
	card.pressed.connect(action)
	return card


func _label(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _go(id: StringName) -> void:
	match id:
		&"random":
			Router.go_to(&"exploration")
		&"archipelago":
			Router.push(&"archipelago")
