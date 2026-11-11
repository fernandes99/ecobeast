class_name ItemIcon
extends Control

const SPRITE_PATH := "res://assets/items/%s.png"
const INITIAL_SCALE := 0.45

@export var icon_size: int = 96

var _item: Item = null
var _fill_color := Color.TRANSPARENT

@onready var _sprite: TextureRect = %Sprite
@onready var _initial: Label = %Initial


func _ready() -> void:
	custom_minimum_size = Vector2(icon_size, icon_size)
	_initial.add_theme_font_size_override(&"font_size", roundi(icon_size * INITIAL_SCALE))
	_refresh()


func _draw() -> void:
	if _fill_color.a > 0.0:
		draw_circle(size / 2.0, minf(size.x, size.y) / 2.0, _fill_color, true, -1.0, true)


func set_item(item: Item) -> void:
	_item = item
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	_fill_color = Color.TRANSPARENT
	_sprite.visible = false
	_initial.text = ""
	if _item != null:
		var path := SPRITE_PATH % _item.slug
		if ResourceLoader.exists(path):
			_sprite.texture = load(path) as Texture2D
			_sprite.visible = true
		else:
			_show_placeholder()
	queue_redraw()


func _show_placeholder() -> void:
	var category := GameData.get_row("item_categories", _item.item_category_id)
	_fill_color = UiPalette.ITEM_CATEGORY_COLORS.get(category["slug"], UiPalette.SURFACE_RAISED)
	_initial.text = _item.name.left(1).to_upper()
