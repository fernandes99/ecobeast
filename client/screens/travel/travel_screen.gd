extends Control

## A tela Viagem (home-island/03): as ilhas fora da casa, a zona sorteada, o Desafiar e
## as Arenas. Sair daqui usa o `go_to`, e a volta é sempre o `Home.go()`.

const LOADING_TEXT := "Carregando ilhas..."
const CARD_HEIGHT := 88.0
## Os destinos fixos, depois das ilhas; os subtítulos são os do Hub de antes.
const DESTINATIONS: Array[Dictionary] = [
	{"id": &"zone", "title": "Explorar zona", "subtitle": "Conheça novas áreas e capture criaturas."},
	{"id": &"challenge", "title": "Desafiar", "subtitle": "Enfrente outros Domadores."},
	{"id": &"arenas", "title": "Arenas", "subtitle": "Derrote os 8 Mestres e conquiste a Liga."},
]

var _loading: bool = true

@onready var _list: VBoxContainer = %DestinationList
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
	else:
		_message.hide()
		var islands: Array[IslandSummary] = result.data
		for island: IslandSummary in islands:
			if not island.home:
				_list.add_child(_card(island.name, "", _go_island.bind(island.id)))
	for destination: Dictionary in DESTINATIONS:
		_list.add_child(_card(destination["title"], destination["subtitle"], _go.bind(destination["id"])))


func _card(title: String, subtitle: String, action: Callable) -> TapPanel:
	var card := TapPanel.new()
	card.theme_type_variation = &"SectionPanel"
	card.custom_minimum_size.y = CARD_HEIGHT
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	column.add_child(_label(title, &"BoldLabel"))
	if not subtitle.is_empty():
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


func _go_island(island_id: int) -> void:
	Router.go_to(&"exploration", {"island_id": island_id})


func _go(id: StringName) -> void:
	match id:
		&"zone":
			Router.go_to(&"exploration")
		&"challenge":
			var center := get_viewport().get_visible_rect().size / 2.0
			if await BattleIntro.cover(center, &"tamer"):
				Router.go_to(&"board_battle", {"challenge": true})
		&"arenas":
			Router.push(&"placeholder", {"title": "Arenas"})


func _show_message(text: String, variation: StringName) -> void:
	_message.text = text
	_message.theme_type_variation = variation
	_message.show()
