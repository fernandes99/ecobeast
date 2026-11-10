class_name BattleItemsPanel
extends Control
## Painel de itens da batalha (inventory-shop/04, RF-14 a RF-17; capture/02):
## primeiro o item e, se houver mais de um Ecobeast, o alvo. A Esfera não pede
## alvo. Só exibe e repassa o toque: quem manda a ação é a tela.

signal chosen(item_id: int, team_index: int)
signal capture_chosen(item_id: int)

const ItemRowScene := preload("res://screens/bag/bag_item_row.tscn")
const TargetRowScene := preload("res://screens/battle/next_creature_row.tscn")

const ITEMS_TITLE := "Usar um item"
const TARGET_TITLE := "Usar %s em:"

var _slots: Array[InventorySlot] = []
var _team: Array[BattleCreature] = []
var _names: Array[String] = []
## Falso contra um Domador NPC: as Esferas não aparecem (npc-tamers/04).
var _allow_capture: bool = true

@onready var _dim: ColorRect = %Dim
@onready var _title: Label = %Title
@onready var _empty_label: Label = %EmptyLabel
@onready var _item_list: VBoxContainer = %ItemList
@onready var _target_list: VBoxContainer = %TargetList
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	hide()
	_dim.color = UiPalette.OVERLAY
	_close_button.pressed.connect(go_back)


## `names`: o nome de exibição de cada criatura de `team`, na mesma ordem.
## `allow_capture`: falso esconde as Esferas.
func open(slots: Array[InventorySlot], team: Array[BattleCreature], names: Array[String], allow_capture: bool = true) -> void:
	_allow_capture = allow_capture
	_slots = slots.duplicate()
	_slots.sort_custom(func(first: InventorySlot, second: InventorySlot) -> bool:
		return GameData.get_item(first.item_id).sort_order < GameData.get_item(second.item_id).sort_order)
	_team = team
	_names = names
	_show_items()
	show()


func close() -> void:
	hide()


## Da escolha do alvo volta aos itens; dos itens, fecha o painel.
func go_back() -> void:
	if _target_list.visible:
		_show_items()
	else:
		close()


func _show_items() -> void:
	_title.text = ITEMS_TITLE
	_target_list.hide()
	_clear(_item_list)
	for slot: InventorySlot in _slots:
		var item := GameData.get_item(slot.item_id)
		if item.can_be_used() or (item.can_capture() and _allow_capture):
			var row: BagItemRow = ItemRowScene.instantiate()
			row.item = item
			row.quantity = slot.quantity
			row.offer_capture = true
			row.use_pressed.connect(_choose_item)
			_item_list.add_child(row)
	_item_list.show()
	_empty_label.visible = _item_list.get_child_count() == 0


func _choose_item(item: Item) -> void:
	if item.can_capture():
		capture_chosen.emit(item.id)
	else:
		_choose_target(item)


func _choose_target(item: Item) -> void:
	if _team.size() == 1:
		chosen.emit(item.id, 0)
		return
	_title.text = TARGET_TITLE % item.name
	_item_list.hide()
	_clear(_target_list)
	for index: int in _team.size():
		var row: NextCreatureRow = TargetRowScene.instantiate()
		row.set_creature(_team[index], _names[index])
		row.pressed.connect(func() -> void: chosen.emit(item.id, index))
		_target_list.add_child(row)
	_target_list.show()


func _clear(list: Control) -> void:
	for child: Node in list.get_children():
		list.remove_child(child)
		child.queue_free()
