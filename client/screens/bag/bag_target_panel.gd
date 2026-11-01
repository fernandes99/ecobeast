class_name BagTargetPanel
extends Control
## Painel que escolhe em quem usar o item (inventory-shop/03, RF-17). Só exibe e
## repassa o toque: quem chama o Session é a tela.

signal chosen(uid: String)

const RowScene := preload("res://screens/bag/bag_target_row.tscn")
const TITLE_TEXT := "Usar %s em:"

@onready var _dim: ColorRect = %Dim
@onready var _title: Label = %Title
@onready var _list: VBoxContainer = %TargetList
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
	hide()
	_dim.color = UiPalette.OVERLAY
	_cancel_button.pressed.connect(close)


func open(item: Item, party: Array[CreatureInstance]) -> void:
	_title.text = TITLE_TEXT % item.name
	for row: Node in _list.get_children():
		_list.remove_child(row)
		row.queue_free()
	for creature: CreatureInstance in party:
		var row: BagTargetRow = RowScene.instantiate()
		row.set_creature(creature)
		row.pressed.connect(func() -> void: chosen.emit(creature.uid))
		_list.add_child(row)
	set_busy(false)
	show()


func close() -> void:
	hide()


## Enquanto o pedido volta, nada aqui responde ao toque.
func set_busy(busy: bool) -> void:
	_cancel_button.disabled = busy
	for row: BagTargetRow in _list.get_children():
		row.disabled = busy
