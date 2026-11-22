class_name GroundItemPanel
extends VBoxContainer

## A ferramenta Itens (auralis/09): o item, a quantidade e as opções do próximo a pôr,
## ou do escolhido no mapa.

signal edited(step: EditorHistory.Step, merge: bool)
signal selection_changed(index: int)

const ICON_PATH := "res://assets/items/%s.png"
const ICON_WIDTH := 32
const MAX_QUANTITY := 99

var item_id := 0
var quantity := 1
var once := true
var hidden_item := false
var selected := -1

var _draft: IslandDraft = null
var _rng := RandomNumberGenerator.new()
var _buttons: Dictionary[int, Button] = {}
var _group := ButtonGroup.new()
var _quantity: SpinBox
var _back: CheckBox
var _hidden: CheckBox
var _selected_box: VBoxContainer
var _selected_label: Label
var _count: Label


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	_count = _hint("")
	add_child(_count)
	_selected_box = VBoxContainer.new()
	_selected_box.add_theme_constant_override(&"separation", 6)
	add_child(_selected_box)
	_selected_label = Label.new()
	_selected_label.theme_type_variation = &"BoldLabel"
	_selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selected_box.add_child(_selected_label)
	var remove := Button.new()
	remove.text = "Tirar item  (Delete)"
	remove.theme_type_variation = &"DangerButton"
	remove.focus_mode = Control.FOCUS_NONE
	remove.pressed.connect(delete_selected)
	_selected_box.add_child(remove)
	_selected_box.add_child(HSeparator.new())

	var quantity_row := HBoxContainer.new()
	add_child(quantity_row)
	var quantity_label := Label.new()
	quantity_label.text = "Quantidade"
	quantity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quantity_row.add_child(quantity_label)
	_quantity = SpinBox.new()
	_quantity.min_value = 1
	_quantity.max_value = MAX_QUANTITY
	_quantity.value = quantity
	_quantity.value_changed.connect(func(value: float) -> void:
		quantity = int(value)
		_change_selected("Quantidade do item", true))
	quantity_row.add_child(_quantity)

	_back = CheckBox.new()
	_back.text = "Volta a cada entrada na ilha"
	_back.tooltip_text = "Desligado, o item é um tesouro: cada jogador pega uma vez só."
	_back.focus_mode = Control.FOCUS_NONE
	_back.toggled.connect(func(on: bool) -> void:
		once = not on
		_change_selected("Item volta", false))
	add_child(_back)
	_hidden = CheckBox.new()
	_hidden.text = "Escondido"
	_hidden.tooltip_text = "No jogo, o brilho fica mais fraco e só aparece a até 2 hexágonos do Domador."
	_hidden.focus_mode = Control.FOCUS_NONE
	_hidden.toggled.connect(func(on: bool) -> void:
		hidden_item = on
		_change_selected("Item escondido", false))
	add_child(_hidden)

	add_child(_hint("Clique num hexágono para pôr o item, ou num item para escolhê-lo. Botão direito tira."))
	for item: Item in GameData.get_items():
		var button := EditorTools.tool_button(item.name, _group)
		var path := ICON_PATH % item.slug
		if ResourceLoader.exists(path):
			button.icon = load(path) as Texture2D
			button.expand_icon = false
			button.add_theme_constant_override(&"icon_max_width", ICON_WIDTH)
			button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.pressed.connect(_pick_item.bind(item.id))
		add_child(button)
		_buttons[item.id] = button
		if item_id == 0:
			item_id = item.id
	refresh()


func set_draft(draft: IslandDraft) -> void:
	_draft = draft
	select(-1)


func select(index: int) -> void:
	if _draft == null or index >= _draft.items.size():
		index = -1
	selected = index
	if index >= 0:
		var item: Dictionary = _draft.items[index]
		item_id = int(item.get("item_id", item_id))
		quantity = int(item.get("quantity", 1))
		once = bool(item.get("once", true))
		hidden_item = bool(item.get("hidden", false))
	refresh()
	selection_changed.emit(selected)


func refresh() -> void:
	if _draft != null and selected >= _draft.items.size():
		selected = -1
	for id: int in _buttons:
		_buttons[id].set_pressed_no_signal(id == item_id)
	_quantity.set_value_no_signal(quantity)
	_back.set_pressed_no_signal(not once)
	_hidden.set_pressed_no_signal(hidden_item)
	var total := _draft.items.size() if _draft != null else 0
	_count.text = "%d ite%s no chão desta ilha." % [total, "m" if total == 1 else "ns"]
	_selected_box.visible = selected >= 0
	if selected >= 0:
		var coord := _draft.item_coord(selected)
		_selected_label.text = "%s  ·  (%d, %d)" % [GameData.get_item(item_id).name, coord.x, coord.y]


## Põe o item da lista no hexágono e o escolhe; o hexágono precisa ser de terra.
func place(coord: Vector2i) -> EditorHistory.Step:
	if _draft == null or item_id <= 0 or not _draft.tiles.has(coord) or _draft.tiles[coord].blocks_walking():
		return null
	var step := _step("Pôr item")
	_draft.items.append({"key": _draft.new_item_key(_rng), "item_id": item_id, "q": coord.x, "r": coord.y, "quantity": quantity, "once": once, "hidden": hidden_item})
	step.items_after = _draft.items.duplicate(true)
	select(_draft.items.size() - 1)
	return step


func remove_at(coord: Vector2i) -> EditorHistory.Step:
	if _draft == null:
		return null
	var index := _draft.item_at(coord)
	if index < 0:
		return null
	var step := _step("Tirar item")
	_draft.items.remove_at(index)
	step.items_after = _draft.items.duplicate(true)
	select(-1)
	return step


func delete_selected() -> void:
	if _draft == null or selected < 0:
		return
	var step := remove_at(_draft.item_coord(selected))
	if step != null:
		edited.emit(step, false)


func _pick_item(id: int) -> void:
	item_id = id
	_change_selected("Trocar item", false)
	refresh()


## As opções valem para o próximo item e, com um escolhido, mudam ele.
func _change_selected(label: String, merge: bool) -> void:
	if _draft == null or selected < 0:
		return
	var item: Dictionary = _draft.items[selected]
	if int(item.get("item_id", 0)) == item_id and int(item.get("quantity", 0)) == quantity and bool(item.get("once", true)) == once and bool(item.get("hidden", false)) == hidden_item:
		return
	var step := _step(label)
	item["item_id"] = item_id
	item["quantity"] = quantity
	item["once"] = once
	item["hidden"] = hidden_item
	step.items_after = _draft.items.duplicate(true)
	refresh()
	edited.emit(step, merge)


func _step(label: String) -> EditorHistory.Step:
	var step := EditorHistory.Step.new()
	step.label = label
	step.items_before = _draft.items.duplicate(true)
	return step


## O ícone do item para o mapa do editor; nulo sem a imagem.
static func icon_of(id: int) -> Texture2D:
	var item := GameData.get_item(id)
	if item == null:
		return null
	var path := ICON_PATH % item.slug
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


static func _hint(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	return label
