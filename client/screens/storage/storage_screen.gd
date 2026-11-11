extends Control

const CellScene := preload("res://screens/storage/storage_cell.tscn")

const FILTER_HEIGHT := 56.0
const FILTER_FONT_SIZE := 20
const ALL_TEXT := "Todos"
const LOADING_TEXT := "Carregando..."
const EMPTY_TEXT := "Nenhum Ecobeast no Santuário."
const NOT_FOUND_TEXT := "Nenhum Ecobeast encontrado."
const COUNT_ONE_TEXT := "1 Ecobeast"
const COUNT_TEXT := "%d Ecobeasts"
const HIGHEST_TEXT := "Maior nível"
const LOWEST_TEXT := "Menor nível"
const MOVE_TEXT := "Mover para a equipe"
const ENTERED_TEXT := "%s entrou na equipe."

var _filter := StorageFilter.new()
var _filter_buttons: Dictionary[int, Button] = {}
var _selected: CreatureInstance = null
var _is_loaded: bool = false
var _busy: bool = false

@onready var _count_label: Label = %CountLabel
@onready var _search_box: VBoxContainer = %SearchBox
@onready var _search_field: LineEdit = %SearchField
@onready var _filter_row: HBoxContainer = %FilterRow
@onready var _sort_button: Button = %SortButton
@onready var _scroll: ScrollContainer = %Scroll
@onready var _grid: GridContainer = %Grid
@onready var _status_box: VBoxContainer = %StatusBox
@onready var _status_label: Label = %StatusLabel
@onready var _retry_button: Button = %RetryButton
@onready var _message: Label = %Message
@onready var _back_button: Button = %BackButton
@onready var _actions_panel: CreatureActionsPanel = %ActionsPanel
@onready var _swap_panel: TeamSwapPanel = %SwapPanel


func _ready() -> void:
	_back_button.pressed.connect(Router.back)
	_retry_button.pressed.connect(_load)
	_search_field.text_changed.connect(_search)
	_sort_button.pressed.connect(_toggle_order)
	_actions_panel.move_pressed.connect(_move)
	_actions_panel.details_pressed.connect(_open_details)
	_swap_panel.chosen.connect(_swap_with)
	# O apelido muda na tela de detalhes, com esta aberta embaixo.
	Session.player_changed.connect(_show_storage)
	_load()


func handle_back() -> bool:
	if _busy:
		return true
	if _swap_panel.visible:
		_swap_panel.close()
		return true
	if _actions_panel.visible:
		_actions_panel.close()
		return true
	return false


func _load() -> void:
	_is_loaded = false
	_show_status(LOADING_TEXT, false)
	_search_box.hide()
	var result: Result = await Session.load_storage()
	if not result.ok:
		_show_status(result.error, true)
		return
	_is_loaded = true
	_show_storage()


func _show_status(text: String, can_retry: bool) -> void:
	_status_label.text = text
	_retry_button.visible = can_retry
	_status_box.show()
	_scroll.hide()


func _show_storage() -> void:
	if not _is_loaded:
		return
	var storage := Session.storage
	_count_label.text = COUNT_ONE_TEXT if storage.size() == 1 else COUNT_TEXT % storage.size()
	_search_box.visible = not storage.is_empty()
	_show_filters()
	_sort_button.text = HIGHEST_TEXT if _filter.highest_first else LOWEST_TEXT
	_show_grid()


func _show_filters() -> void:
	var present := _present_elements()
	if not present.has(_filter.element_id):
		_filter.element_id = StorageFilter.ALL_ELEMENTS
	for button: Node in _filter_row.get_children():
		_filter_row.remove_child(button)
		button.queue_free()
	_filter_buttons.clear()
	_filter_row.add_child(_make_filter(ALL_TEXT, StorageFilter.ALL_ELEMENTS))
	for element: Element in GameData.get_elements():
		if present.has(element.id):
			_filter_row.add_child(_make_filter(element.name, element.id))
	_paint_filters()


func _present_elements() -> Array[int]:
	var present: Array[int] = [StorageFilter.ALL_ELEMENTS]
	for creature: CreatureInstance in Session.storage:
		present.append_array(GameData.get_species(creature.species_id).element_ids)
	return present


func _make_filter(text: String, element_id: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, FILTER_HEIGHT)
	button.add_theme_font_size_override(&"font_size", FILTER_FONT_SIZE)
	button.pressed.connect(_choose_filter.bind(element_id))
	_filter_buttons[element_id] = button
	return button


func _paint_filters() -> void:
	for element_id: int in _filter_buttons:
		var is_current := element_id == _filter.element_id
		_filter_buttons[element_id].theme_type_variation = &"" if is_current else &"OutlineButton"


func _show_grid() -> void:
	for cell: Node in _grid.get_children():
		_grid.remove_child(cell)
		cell.queue_free()
	var found := _filter.apply(Session.storage)
	for creature: CreatureInstance in found:
		var cell: StorageCell = CellScene.instantiate()
		cell.creature = creature
		cell.pressed.connect(_open_actions.bind(creature))
		_grid.add_child(cell)
	if not found.is_empty():
		_status_box.hide()
		_scroll.show()
	else:
		_show_status(EMPTY_TEXT if Session.storage.is_empty() else NOT_FOUND_TEXT, false)


func _search(text: String) -> void:
	_filter.search = text
	_show_grid()


func _choose_filter(element_id: int) -> void:
	_filter.element_id = element_id
	_paint_filters()
	_show_grid()


func _toggle_order() -> void:
	_filter.highest_first = not _filter.highest_first
	_sort_button.text = HIGHEST_TEXT if _filter.highest_first else LOWEST_TEXT
	_show_grid()


func _open_actions(creature: CreatureInstance) -> void:
	_selected = creature
	_message.hide()
	_actions_panel.open(creature, MOVE_TEXT)


func _open_details() -> void:
	_actions_panel.close()
	Router.push(&"creature_details", {"uid": _selected.uid})


func _selected_name() -> String:
	return _selected.display_name(GameData.get_species(_selected.species_id))


func _move() -> void:
	if Session.player.party.size() >= Player.PARTY_SIZE:
		_actions_panel.close()
		_swap_panel.open(_selected_name(), Session.player.party)
		return
	_busy = true
	_actions_panel.set_busy(true)
	var result: Result = await Session.bring_to_team(_selected.uid)
	_busy = false
	_actions_panel.set_busy(false)
	if result.ok:
		_actions_panel.close()
		_show_entered()
	else:
		_actions_panel.show_error(result.error)


func _swap_with(replace_uid: String) -> void:
	_busy = true
	_swap_panel.set_busy(true)
	var result: Result = await Session.bring_to_team(_selected.uid, replace_uid)
	_busy = false
	_swap_panel.set_busy(false)
	if result.ok:
		_swap_panel.close()
		_show_entered()
	else:
		_swap_panel.show_error(result.error)


func _show_entered() -> void:
	_message.text = ENTERED_TEXT % _selected_name()
	_message.show()
