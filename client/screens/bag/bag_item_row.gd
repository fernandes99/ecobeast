class_name BagItemRow
extends PanelContainer
## Um item da Mochila (inventory-shop/03, RF-14 e RF-16). Só mostra e repassa o
## toque: quem decide o uso é o servidor.

signal use_pressed(item: Item)

const QUANTITY_TEXT := "x%d"

var item: Item = null
var quantity: int = 0

@onready var _icon: ItemIcon = %Icon
@onready var _name_label: Label = %NameLabel
@onready var _quantity_label: Label = %QuantityLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _use_button: Button = %UseButton


func _ready() -> void:
	_use_button.pressed.connect(func() -> void: use_pressed.emit(item))
	_icon.set_item(item)
	_name_label.text = item.name
	_quantity_label.text = QUANTITY_TEXT % quantity
	_description_label.text = item.description
	_use_button.visible = item.can_be_used()
