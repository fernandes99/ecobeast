extends Control

const RowScene := preload("res://screens/bag/bag_item_row.tscn")

const USED_MESSAGE := "%s usado em %s."

var _using: bool = false
var _selected_item: Item = null

@onready var _scroll: ScrollContainer = %Scroll
@onready var _item_list: VBoxContainer = %ItemList
@onready var _empty_label: Label = %EmptyLabel
@onready var _message: Label = %Message
@onready var _back_button: Button = %BackButton
@onready var _target_panel: BagTargetPanel = %TargetPanel


func _ready() -> void:
	_back_button.pressed.connect(Router.back)
	_target_panel.chosen.connect(_use)
	_refresh()


func handle_back() -> bool:
	if _using:
		return true
	if _target_panel.visible:
		_target_panel.close()
		return true
	return false


func _refresh() -> void:
	var player := Session.player
	# Sem jogador só se o progresso foi apagado em outro aparelho.
	if player == null:
		return
	var scroll_position := _scroll.scroll_vertical
	for child: Node in _item_list.get_children():
		_item_list.remove_child(child)
		child.queue_free()
	for category: ItemCategory in GameData.get_item_categories():
		_add_category(category, player)
	_empty_label.visible = player.inventory.is_empty()
	_scroll.set_deferred(&"scroll_vertical", scroll_position)


func _add_category(category: ItemCategory, player: Player) -> void:
	var has_title := false
	for item: Item in GameData.get_items():
		var quantity := player.quantity_of(item.id)
		if item.item_category_id != category.id or quantity == 0:
			continue
		if not has_title:
			_item_list.add_child(_make_title(category))
			has_title = true
		var row: BagItemRow = RowScene.instantiate()
		row.item = item
		row.quantity = quantity
		row.use_pressed.connect(_choose_target)
		_item_list.add_child(row)


func _make_title(category: ItemCategory) -> Label:
	var title := Label.new()
	title.text = category.name
	title.theme_type_variation = &"BoldLabel"
	return title


func _choose_target(item: Item) -> void:
	if _using:
		return
	_selected_item = item
	_message.hide()
	_target_panel.open(item, Session.player.party)


func _use(uid: String) -> void:
	if _using:
		return
	var item := _selected_item
	var target_name := _creature_name(uid)
	_using = true
	_back_button.disabled = true
	_target_panel.set_busy(true)
	var result: Result = await Session.use_item(item.id, uid)
	_using = false
	_back_button.disabled = false
	_target_panel.close()
	_refresh()
	if result.ok:
		_show_message(USED_MESSAGE % [item.name, target_name], &"BoldLabel")
	else:
		_show_message(result.error, &"DangerLabel")


func _creature_name(uid: String) -> String:
	for creature: CreatureInstance in Session.player.party:
		if creature.uid == uid:
			return creature.display_name(GameData.get_species(creature.species_id))
	return ""


func _show_message(text: String, variation: StringName) -> void:
	_message.text = text
	_message.theme_type_variation = variation
	_message.show()
