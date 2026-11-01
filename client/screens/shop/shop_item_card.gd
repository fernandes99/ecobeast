class_name ShopItemCard
extends PanelContainer
## Um item à venda na Loja. Só mostra: quem decide a compra é o servidor.

signal buy_pressed(item_id: int)

const OWNED_TEXT := "Você tem %d"

var item: Item = null

@onready var _icon: ItemIcon = %Icon
@onready var _name_label: Label = %NameLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _price_label: Label = %PriceLabel
@onready var _owned_label: Label = %OwnedLabel
@onready var _buy_button: Button = %BuyButton


func _ready() -> void:
	_buy_button.pressed.connect(func() -> void: buy_pressed.emit(item.id))
	_icon.set_item(item)
	_name_label.text = item.name
	_description_label.text = item.description
	_price_label.text = str(item.price)


func set_state(owned: int, can_buy: bool) -> void:
	_owned_label.text = OWNED_TEXT % owned
	_buy_button.disabled = not can_buy
