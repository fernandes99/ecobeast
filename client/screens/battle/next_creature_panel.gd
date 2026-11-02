class_name NextCreaturePanel
extends Control
## Painel de quem entra em campo (battle-screen/03, RF-22 a RF-24, e
## team-and-storage/04): pelo botão Equipe ou depois de um desmaio. Só exibe e
## repassa o toque: quem chama o Session é a tela. Depois de um desmaio, não se
## fecha sem uma escolha.

signal chosen(team_index: int)

const RowScene := preload("res://screens/battle/next_creature_row.tscn")

var _can_go_back: bool = false

@onready var _dim: ColorRect = %Dim
@onready var _message: Label = %Message
@onready var _list: VBoxContainer = %NextList
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	hide()
	_dim.color = UiPalette.OVERLAY
	_back_button.pressed.connect(go_back)


## `names`: o nome de exibição de cada criatura de `team`, na mesma ordem.
## `active_index`: quem está em campo, que não pode ser escolhido; -1 sem ninguém.
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
