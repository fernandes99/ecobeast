class_name NextCreaturePanel
extends Control
## Painel do próximo Ecobeast, depois de um desmaio (battle-screen/03, RF-22 a
## RF-24). Só exibe e repassa o toque: quem chama o Session é a tela. Não se
## fecha sem uma escolha.

signal chosen(team_index: int)

const RowScene := preload("res://screens/battle/next_creature_row.tscn")

@onready var _dim: ColorRect = %Dim
@onready var _message: Label = %Message
@onready var _list: VBoxContainer = %NextList


func _ready() -> void:
	hide()
	_dim.color = UiPalette.OVERLAY


## `names`: o nome de exibição de cada criatura de `team`, na mesma ordem.
func open(team: Array[BattleCreature], names: Array[String]) -> void:
	for row: Node in _list.get_children():
		_list.remove_child(row)
		row.queue_free()
	for index: int in team.size():
		var row: NextCreatureRow = RowScene.instantiate()
		row.set_creature(team[index], names[index])
		row.pressed.connect(func() -> void: chosen.emit(index))
		_list.add_child(row)
	_message.hide()
	show()


func close() -> void:
	hide()


func show_error(message: String) -> void:
	_message.text = message
	_message.show()
