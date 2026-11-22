extends Control

## O Arquipélago Auralis (auralis/03): as ilhas em ordem, entrando nas abertas.
## O estado de cada uma vem pronto do servidor.

const LOADING_TEXT := "Carregando ilhas..."
const EMPTY_TEXT := "Nenhuma ilha no Arquipélago ainda."
const OPEN_TEXT := "Toque para explorar."
const NEXT_TEXT := "Complete a ilha anterior para abrir."
const HIDDEN_TITLE := "???"
const HIDDEN_TEXT := "Ilha desconhecida."
const DEBUG_UNLOCK_TEXT := "Abrir (depuração)"
const LOCK_ICON := preload("res://ui/icons/lock.svg")
const CARD_HEIGHT := 88.0
const LOCK_SIZE := 32.0
const ROW_SEPARATION := 16

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
	_loading = true
	_back_button.disabled = true
	for child: Node in _list.get_children():
		child.queue_free()
	_show_message(LOADING_TEXT, &"SecondaryLabel")
	var result: Result = await Session.load_archipelago()
	_loading = false
	_back_button.disabled = false
	if not result.ok:
		_show_message(result.error, &"DangerLabel")
		return
	var islands: Array[ArchipelagoIsland] = result.data
	if islands.is_empty():
		_show_message(EMPTY_TEXT, &"SecondaryLabel")
		return
	_message.hide()
	for island: ArchipelagoIsland in islands:
		_list.add_child(_card(island))


func _card(island: ArchipelagoIsland) -> TapPanel:
	var card := TapPanel.new()
	card.theme_type_variation = &"SectionPanel"
	card.custom_minimum_size.y = CARD_HEIGHT
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", ROW_SEPARATION)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var open := island.state == ArchipelagoIsland.OPEN
	if not open:
		row.add_child(_lock())
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)
	match island.state:
		ArchipelagoIsland.OPEN:
			column.add_child(_label(island.name, &"BoldLabel"))
			column.add_child(_label(OPEN_TEXT, &"SecondaryLabel"))
			card.pressed.connect(_enter.bind(island.id))
		ArchipelagoIsland.NEXT:
			column.add_child(_label(island.name, &"BoldLabel"))
			column.add_child(_label(NEXT_TEXT, &"SecondaryLabel"))
			if OS.is_debug_build():
				column.add_child(_debug_unlock(island.id))
		_:
			column.add_child(_label(HIDDEN_TITLE, &"BoldLabel"))
			column.add_child(_label(HIDDEN_TEXT, &"SecondaryLabel"))
	if not open:
		card.modulate = UiPalette.TEXT_SECONDARY
	return card


func _lock() -> TextureRect:
	var lock := TextureRect.new()
	lock.texture = LOCK_ICON
	lock.custom_minimum_size = Vector2.ONE * LOCK_SIZE
	lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lock


func _debug_unlock(island_id: int) -> Button:
	var button := Button.new()
	button.text = DEBUG_UNLOCK_TEXT
	button.theme_type_variation = &"OutlineButton"
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.pressed.connect(_unlock.bind(island_id))
	return button


func _label(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _enter(island_id: int) -> void:
	Router.go_to(&"exploration", {"island_id": island_id})


func _unlock(island_id: int) -> void:
	if _loading:
		return
	var result: Result = await Session.unlock_island(island_id)
	if not result.ok:
		_show_message(result.error, &"DangerLabel")
		return
	_load()


func _show_message(text: String, variation: StringName) -> void:
	_message.text = text
	_message.theme_type_variation = variation
	_message.show()
