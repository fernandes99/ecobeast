extends Control

const CellScene := preload("res://screens/codex/codex_cell.tscn")

const LOADING_TEXT := "Carregando..."

var _codex: Codex = null
var _busy: bool = false

@onready var _seen_count: Label = %SeenCount
@onready var _caught_count: Label = %CaughtCount
@onready var _counts: HBoxContainer = %Counts
@onready var _status_box: VBoxContainer = %StatusBox
@onready var _status_label: Label = %StatusLabel
@onready var _retry_button: Button = %RetryButton
@onready var _scroll: ScrollContainer = %Scroll
@onready var _grid: GridContainer = %Grid
@onready var _debug_clear_button: Button = %DebugClearButton
@onready var _back_button: Button = %BackButton
@onready var _detail: CodexDetail = %Detail


func _ready() -> void:
	_back_button.pressed.connect(Router.back)
	_retry_button.pressed.connect(_load)
	_debug_clear_button.visible = OS.is_debug_build()
	_debug_clear_button.pressed.connect(_debug_clear)
	_load()


func handle_back() -> bool:
	if _busy:
		return true
	if _detail.visible:
		_detail.close()
		return true
	return false


func _load() -> void:
	_busy = true
	_show_status(LOADING_TEXT, false)
	var result: Result = await Session.load_codex()
	_busy = false
	if not result.ok:
		_show_status(result.error, true)
		return
	_codex = result.data
	_show_codex()


func _show_status(text: String, can_retry: bool) -> void:
	_status_label.text = text
	_retry_button.visible = can_retry
	_status_box.show()
	_scroll.hide()
	_counts.hide()


func _show_codex() -> void:
	_seen_count.text = str(_codex.seen_count())
	_caught_count.text = str(_codex.caught_count())
	_counts.show()
	for cell: Node in _grid.get_children():
		_grid.remove_child(cell)
		cell.queue_free()
	for species: CreatureSpecies in GameData.get_all_species():
		var cell: CodexCell = CellScene.instantiate()
		cell.species_id = species.id
		cell.status = _codex.status(species.id)
		if cell.status != Codex.Status.UNKNOWN:
			cell.pressed.connect(_open_detail.bind(species.id))
		_grid.add_child(cell)
	_status_box.hide()
	_scroll.show()


func _open_detail(species_id: int) -> void:
	if not _busy:
		_detail.open(species_id, _codex)


func _debug_clear() -> void:
	if _busy:
		return
	_busy = true
	var result: Result = await Session.debug_clear_codex()
	_busy = false
	if not result.ok:
		_show_status(result.error, true)
		return
	_load()
