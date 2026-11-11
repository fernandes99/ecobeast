class_name NextCreaturePanel
extends Control

signal chosen(team_index: int)

const RowScene := preload("res://screens/board_battle/next_creature_row.tscn")

var _can_go_back: bool = false

@onready var _dim: ColorRect = %Dim
@onready var _message: Label = %Message
@onready var _list: VBoxContainer = %NextList
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	hide()
	_dim.color = UiPalette.OVERLAY
	_back_button.pressed.connect(go_back)


func open(team: Array[BattleCreature], names: Array[String], active_index: int = -1, can_go_back: bool = false) -> void:
	for row: Node in _list.get_children():
		_list.remove_child(row)
		row.queue_free()
	for index: int in team.size():
		var row: NextCreatureRow = RowScene.instantiate()
		row.set_creature(team[index], names[index], index == active_index)
		row.pressed.connect(func() -> void: chosen.emit(index))
		_list.add_child(row)
	_can_go_back = can_go_back
	_back_button.visible = can_go_back
	_message.hide()
	show()


func close() -> void:
	hide()


## Depois de um desmaio, não faz nada: o jogador precisa escolher.
func go_back() -> void:
	if _can_go_back:
		close()


func show_error(message: String) -> void:
	_message.text = message
	_message.show()
