class_name TeamSwapPanel
extends Control

signal chosen(uid: String)

const RowScene := preload("res://screens/bag/bag_target_row.tscn")
const NOTE_TEXT := "%s entra na vaga do escolhido."

@onready var _dim: ColorRect = %Dim
@onready var _note: Label = %Note
@onready var _list: VBoxContainer = %TargetList
@onready var _message: Label = %Message
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
	hide()
	_dim.color = UiPalette.OVERLAY
	_cancel_button.pressed.connect(close)


func open(entering_name: String, party: Array[CreatureInstance]) -> void:
	_note.text = NOTE_TEXT % entering_name
	for row: Node in _list.get_children():
		_list.remove_child(row)
		row.queue_free()
	for creature: CreatureInstance in party:
		var row: BagTargetRow = RowScene.instantiate()
		row.set_creature(creature)
		row.pressed.connect(func() -> void: chosen.emit(creature.uid))
		_list.add_child(row)
	_message.hide()
	set_busy(false)
	show()


func close() -> void:
	hide()


func set_busy(busy: bool) -> void:
	_cancel_button.disabled = busy
	for row: BagTargetRow in _list.get_children():
		row.disabled = busy


func show_error(message: String) -> void:
	_message.text = message
	_message.show()
