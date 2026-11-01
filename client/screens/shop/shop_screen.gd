extends Control
## Loja (inventory-shop/02, TELAS.md #12): uma aba por categoria e um card por
## item. Quem cobra e entrega o item é o servidor; a tela pede e mostra o jogador
## que volta.

const CardScene := preload("res://screens/shop/shop_item_card.tscn")

const TAB_HEIGHT := 64.0
const PURCHASED_MESSAGE := "Item comprado!"

## As categorias com itens, uma por aba.
var _categories: Array[ItemCategory] = []
## Há uma compra no servidor.
var _buying: bool = false

@onready var _coins_label: Label = %CoinsLabel
@onready var _tab_row: HBoxContainer = %TabRow
@onready var _scroll: ScrollContainer = %Scroll
@onready var _item_list: VBoxContainer = %ItemList
@onready var _message: Label = %Message
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(Router.back)
	for category: ItemCategory in GameData.get_item_categories():
		if not _items_of(category).is_empty():
			_tab_row.add_child(_make_tab(category, _categories.size()))
			_categories.append(category)
	if not _categories.is_empty():
		_show_tab(0)


## A resposta do servidor volta para esta tela: ela não fecha antes disso.
func handle_back() -> bool:
	return _buying


func _make_tab(category: ItemCategory, index: int) -> Button:
	var tab := Button.new()
	tab.text = category.name
	tab.custom_minimum_size = Vector2(0.0, TAB_HEIGHT)
	tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.pressed.connect(_show_tab.bind(index))
	return tab


func _items_of(category: ItemCategory) -> Array[Item]:
	var items: Array[Item] = []
	for item: Item in GameData.get_items():
		if item.item_category_id == category.id:
			items.append(item)
	return items


func _show_tab(index: int) -> void:
	if _buying:
		return
	for tab_index: int in _tab_row.get_child_count():
		var tab := _tab_row.get_child(tab_index) as Button
		tab.theme_type_variation = &"" if tab_index == index else &"OutlineButton"
	for card: Node in _item_list.get_children():
		_item_list.remove_child(card)
		card.queue_free()
	for item: Item in _items_of(_categories[index]):
		var card: ShopItemCard = CardScene.instantiate()
		card.item = item
		card.buy_pressed.connect(_buy)
		_item_list.add_child(card)
	_scroll.scroll_vertical = 0
	_message.hide()
	_refresh()


func _buy(item_id: int) -> void:
	_buying = true
	_message.hide()
	_back_button.disabled = true
	_refresh()
	var result: Result = await Session.buy_item(item_id)
	_buying = false
	_back_button.disabled = false
	_refresh()
	if result.ok:
		_show_message(PURCHASED_MESSAGE, &"BoldLabel")
	else:
		_show_message(result.error, &"DangerLabel")


func _refresh() -> void:
	var player := Session.player
	# Sem jogador só se o progresso foi apagado em outro aparelho.
	if player == null:
		return
	_coins_label.text = str(player.coins)
	for card: ShopItemCard in _item_list.get_children():
		card.set_state(player.quantity_of(card.item.id), not _buying and player.coins >= card.item.price)


func _show_message(text: String, variation: StringName) -> void:
	_message.text = text
	_message.theme_type_variation = variation
	_message.show()
