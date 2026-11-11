class_name IslandList
extends VBoxContainer

signal open_requested(id: int)
signal new_requested
signal delete_requested(id: int, island_name: String)

const STATUS_NAMES: Dictionary[String, String] = {
	"draft": "Rascunho",
	"published": "Publicada",
	"changed": "Publicada, com mudanças",
}

var _items: ItemList
var _delete_button: Button
var _islands: Array[Dictionary] = []


static func status_name(status: String) -> String:
	return STATUS_NAMES.get(status, status)


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	var title := Label.new()
	title.text = "Ilhas"
	EditorTools.section_title(title)
	add_child(title)

	_items = ItemList.new()
	_items.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_items.item_selected.connect(_on_item_selected)
	add_child(_items)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 8)
	add_child(buttons)
	var new_button := Button.new()
	new_button.text = "Nova ilha"
	new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_button.pressed.connect(new_requested.emit)
	buttons.add_child(new_button)
	_delete_button = Button.new()
	_delete_button.text = "Apagar"
	_delete_button.theme_type_variation = &"DangerButton"
	_delete_button.tooltip_text = "Só uma ilha que nunca foi publicada pode ser apagada."
	_delete_button.pressed.connect(_on_delete_pressed)
	buttons.add_child(_delete_button)
	_update_delete_button()


func set_islands(islands: Array, selected_id: int) -> void:
	_islands.clear()
	_items.clear()
	for island: Variant in islands:
		if not island is Dictionary:
			continue
		_islands.append(island)
		_items.add_item("%s  ·  %s" % [DictFields.get_string(island, "name"), status_name(DictFields.get_string(island, "status"))])
	select(selected_id)


func select(id: int) -> void:
	_items.deselect_all()
	for index: int in _islands.size():
		if DictFields.get_int(_islands[index], "id") == id:
			_items.select(index)
	_update_delete_button()


func _selected() -> Dictionary:
	var picked := _items.get_selected_items()
	return _islands[picked[0]] if not picked.is_empty() else {}


func _on_item_selected(index: int) -> void:
	_update_delete_button()
	open_requested.emit(DictFields.get_int(_islands[index], "id"))


func _on_delete_pressed() -> void:
	var island := _selected()
	if not island.is_empty():
		delete_requested.emit(DictFields.get_int(island, "id"), DictFields.get_string(island, "name"))


func _update_delete_button() -> void:
	var island := _selected()
	_delete_button.disabled = island.is_empty() or DictFields.get_string(island, "status") != "draft"
