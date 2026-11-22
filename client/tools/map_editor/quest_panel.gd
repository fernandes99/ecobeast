class_name QuestPanel
extends VBoxContainer

## A ferramenta Missões (auralis/07): as missões de cada NPC da ilha, salvas na hora
## pelas rotas do editor, fora do rascunho e do desfazer.

## Os hexágonos marcados no mapa mudaram.
signal changed
signal message(text: String, error: bool)
## A lista de missões da ilha mudou (o painel NPC mostra as de cada um).
signal quests_changed

const SAVE_FIRST_TEXT := "Salve a ilha para criar missões."
const LOADING_TEXT := "Carregando as missões…"
const PICK_TEXT := "Clique nos hexágonos do lugar. Botão direito ou Esc terminam."
const OUTSIDE_TEXT := "Esse hexágono não é da ilha."
const CONFIRM_DELETE_TEXT := "Confirmar: apagar"
const NO_ITEM := 0
const AMOUNT_TYPES: Array[int] = [1, 2, 3, 6, 7, 8, 10]
const SPECIES_TYPES: Array[int] = [7, 8]
const TARGET_TYPES: Array[int] = [5, 9]
const PLACE_TYPE := 4
## "Encontre X item" (auralis/09).
const FIND_ITEM_TYPE := 10
const PERCENT_TYPE := 3
const MINUTES_TYPE := 6
const MAX_AMOUNT := 9999
const MAX_COINS := 1000000
const MAX_ITEM_QUANTITY := 99
const MAX_REQUIRED := 99

var picking := false

var _draft: IslandDraft = null
var _island_id := 0
var _types: Array[Dictionary] = []
var _quests: Array[Dictionary] = []
## A missão aberta no formulário: 0 é a nova, -1 fechado.
var _editing := -1
var _tiles: Array[Vector2i] = []
var _busy := false
var _busy_loading := false

var _notice: Label
var _body: VBoxContainer
var _required: EditorNumberField
var _list: VBoxContainer
var _form: VBoxContainer
var _form_title: Label
var _giver: OptionButton
var _type: OptionButton
var _amount_row: HBoxContainer
var _amount_label: Label
var _amount: EditorNumberField
var _species_row: HBoxContainer
var _species: OptionButton
var _target_row: HBoxContainer
var _target: OptionButton
var _target_item_row: HBoxContainer
var _target_item: OptionButton
var _place_box: VBoxContainer
var _place_name: LineEdit
var _pick_button: Button
var _tiles_label: Label
var _title: LineEdit
var _coins: EditorNumberField
var _item: OptionButton
var _item_quantity: EditorNumberField
var _item_quantity_row: HBoxContainer
var _counts: CheckBox
var _delete: Button


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	_notice = _hint(SAVE_FIRST_TEXT)
	add_child(_notice)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override(&"separation", 8)
	add_child(_body)

	_body.add_child(_hint("Missões que abrem a próxima ilha (0 = todas as que contam)"))
	var required_row := HBoxContainer.new()
	required_row.add_theme_constant_override(&"separation", 6)
	_body.add_child(required_row)
	_required = EditorNumberField.new(0, MAX_REQUIRED, true, false)
	_required.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	required_row.add_child(_required)
	required_row.add_child(_button("Salvar", _save_required))

	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", 4)
	_body.add_child(_list)
	_body.add_child(_button("Nova missão", _open.bind(0)))

	_form = VBoxContainer.new()
	_form.add_theme_constant_override(&"separation", 6)
	_body.add_child(_form)
	_form.add_child(HSeparator.new())
	_form_title = Label.new()
	_form_title.theme_type_variation = &"BoldLabel"
	_form.add_child(_form_title)
	_giver = OptionButton.new()
	_form.add_child(_row("Quem dá", _giver))
	_type = OptionButton.new()
	_type.item_selected.connect(func(_index: int) -> void: _refresh_fields())
	_form.add_child(_row("Tipo", _type))

	_amount = EditorNumberField.new(1, MAX_AMOUNT, true, false)
	_amount_row = _row("Quantidade", _amount)
	_amount_label = _amount_row.get_child(0) as Label
	_form.add_child(_amount_row)
	_species = OptionButton.new()
	for row: Dictionary in GameData.get_rows("species"):
		_species.add_item("%d · %s" % [int(row.get("id", 0)), row.get("name", "")], int(row.get("id", 0)))
	_species_row = _row("Espécie", _species)
	_form.add_child(_species_row)
	_target = OptionButton.new()
	for row: Dictionary in GameData.get_rows("npcs"):
		_target.add_item(str(row.get("name", "")), int(row.get("id", 0)))
	_target_row = _row("NPC alvo", _target)
	_form.add_child(_target_row)
	_target_item = OptionButton.new()
	for row: Dictionary in GameData.get_rows("items"):
		_target_item.add_item(str(row.get("name", "")), int(row.get("id", 0)))
	_target_item_row = _row("Item a encontrar", _target_item)
	_form.add_child(_target_item_row)

	_place_box = VBoxContainer.new()
	_place_box.add_theme_constant_override(&"separation", 6)
	_form.add_child(_place_box)
	_place_name = LineEdit.new()
	_place_name.placeholder_text = "o Farol"
	_place_name.max_length = 40
	_place_box.add_child(_row("Nome do lugar", _place_name))
	var pick_row := HBoxContainer.new()
	pick_row.add_theme_constant_override(&"separation", 6)
	_place_box.add_child(pick_row)
	_pick_button = _button("Escolher no mapa", toggle_pick)
	pick_row.add_child(_pick_button)
	_tiles_label = _hint("")
	pick_row.add_child(_tiles_label)

	_title = LineEdit.new()
	_title.max_length = 60
	_title.placeholder_text = "Automático"
	_form.add_child(_row("Título", _title))
	_coins = EditorNumberField.new(0, MAX_COINS, true, false)
	_form.add_child(_row("Moedas", _coins))
	_item = OptionButton.new()
	_item.add_item("Nenhum", NO_ITEM)
	for row: Dictionary in GameData.get_rows("items"):
		_item.add_item(str(row.get("name", "")), int(row.get("id", 0)))
	_item.item_selected.connect(func(_index: int) -> void: _refresh_fields())
	_form.add_child(_row("Item de recompensa", _item))
	_item_quantity = EditorNumberField.new(1, MAX_ITEM_QUANTITY, true, false)
	_item_quantity_row = _row("Quantidade do item", _item_quantity)
	_form.add_child(_item_quantity_row)
	_counts = CheckBox.new()
	_counts.text = "Conta para abrir a próxima ilha"
	_counts.focus_mode = Control.FOCUS_NONE
	_form.add_child(_counts)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override(&"separation", 6)
	_form.add_child(actions)
	actions.add_child(_button("Salvar", _save))
	_delete = _button("Apagar", _remove)
	_delete.theme_type_variation = &"DangerButton"
	actions.add_child(_delete)
	actions.add_child(_button("Cancelar", _close))
	visibility_changed.connect(_load_if_needed)
	_render()


func set_draft(draft: IslandDraft) -> void:
	_draft = draft
	_island_id = 0
	_quests = []
	_close()
	_load_if_needed()
	quests_changed.emit()


## Os hexágonos do lugar no formulário, para o mapa marcar.
func map_marks() -> Dictionary:
	var area: Array[Vector2i] = []
	if _editing >= 0 and _type.get_selected_id() == PLACE_TYPE:
		area.assign(_tiles)
	return {"area": area}


## Um clique no mapa com o "Escolher no mapa" ligado: põe ou tira o hexágono.
func pick(coord: Vector2i) -> void:
	if not picking:
		return
	if _draft == null or not _draft.tiles.has(coord):
		message.emit(OUTSIDE_TEXT, true)
		return
	if _tiles.has(coord):
		_tiles.erase(coord)
	else:
		_tiles.append(coord)
	_refresh_fields()
	changed.emit()


func toggle_pick() -> void:
	picking = not picking
	message.emit(PICK_TEXT if picking else "", false)
	_refresh_fields()


func cancel_pick() -> void:
	if picking:
		toggle_pick()


## Carrega as missões da ilha salva mesmo com a ferramenta escondida (o painel NPC as mostra).
func ensure_loaded() -> void:
	_load_if_needed(true)


func is_loaded() -> bool:
	return _draft != null and _draft.id > 0 and _draft.id == _island_id and not _busy_loading


func quests_of(npc_id: int) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for quest: Dictionary in _quests:
		if int(quest.get("npc_id", 0)) == npc_id:
			found.append(quest)
	return found


## Abre a missão (0 é a nova, já com o NPC que dá) vinda do painel NPC.
func open_for(npc_id: int, quest_id: int) -> void:
	if quest_id > 0:
		_open(quest_id)
	else:
		_open(0, npc_id)


func _load_if_needed(force := false) -> void:
	if (not force and not is_visible_in_tree()) or _draft == null or _draft.id <= 0 or _draft.id == _island_id or _busy:
		_render()
		return
	_island_id = _draft.id
	_notice.text = LOADING_TEXT
	_body.visible = false
	_notice.visible = true
	var island_id := _island_id
	_busy_loading = true
	var response := await _send(func() -> ApiResponse: return await EditorApi.list_quests(island_id))
	_busy_loading = false
	if island_id != _island_id:
		return
	if response != null:
		_apply(response.data)
	elif _draft != null:
		_island_id = 0
	_render()
	quests_changed.emit()


func _apply(data: Variant) -> void:
	if not data is Dictionary:
		return
	_types.clear()
	for row: Variant in DictFields.get_array(data, "types"):
		if row is Dictionary:
			_types.append(row)
	_quests.clear()
	for row: Variant in DictFields.get_array(data, "quests"):
		if row is Dictionary:
			_quests.append(row)
	var required: Variant = data.get("required_quests")
	_required.set_value(int(required) if required != null else 0)
	if _type.item_count != _types.size():
		_type.clear()
		for row: Dictionary in _types:
			_type.add_item(str(row.get("name", "")), int(row.get("id", 0)))
	quests_changed.emit()


func _render() -> void:
	var saved := _draft != null and _draft.id > 0 and _draft.id == _island_id
	_notice.visible = not saved
	if not saved:
		_notice.text = SAVE_FIRST_TEXT if _draft == null or _draft.id <= 0 else LOADING_TEXT
	_body.visible = saved
	for child: Node in _list.get_children():
		child.queue_free()
	var last_npc := -1
	for quest: Dictionary in _quests:
		var npc_id := int(quest.get("npc_id", 0))
		if npc_id != last_npc:
			last_npc = npc_id
			var header := Label.new()
			header.theme_type_variation = &"BoldLabel"
			header.text = _npc_name(npc_id) + ("" if _placed(npc_id) else "  ·  fora do mapa")
			_list.add_child(header)
		_list.add_child(_quest_row(quest))
	if _quests.is_empty():
		_list.add_child(_hint("Nenhuma missão nesta ilha."))
	_form.visible = _editing >= 0
	_refresh_fields()


func _quest_row(quest: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	var id := int(quest.get("id", 0))
	var open := EditorTools.tool_button("%d. %s" % [int(quest.get("position", 0)), quest.get("display_title", "")], null)
	open.toggle_mode = false
	open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open.clip_text = true
	open.tooltip_text = summary(quest)
	open.pressed.connect(_open.bind(id))
	if id == _editing:
		open.theme_type_variation = &"OutlineButton"
	row.add_child(open)
	row.add_child(_button("↑", _move.bind(id, true)))
	row.add_child(_button("↓", _move.bind(id, false)))
	return row


static func summary(quest: Dictionary) -> String:
	var parts: Array[String] = []
	var coins := int(quest.get("coins", 0))
	if coins > 0:
		parts.append("%d moedas" % coins)
	var item: Variant = quest.get("item_id")
	if item != null:
		parts.append("%d× %s" % [int(quest.get("item_quantity", 1)), GameData.get_item(int(item)).name])
	if not bool(quest.get("counts_for_unlock", true)):
		parts.append("não conta para abrir a próxima ilha")
	return "Recompensa: só o XP" if parts.is_empty() else ", ".join(parts)


## Abre o formulário: 0 é a missão nova, para o `giver` ou o primeiro NPC posto na ilha.
func _open(id: int, giver := 0) -> void:
	var quest := _find(id)
	_editing = id if not quest.is_empty() else 0
	_delete.text = "Apagar"
	_delete.visible = _editing > 0
	_form_title.text = "Nova missão" if _editing == 0 else "Missão %d" % _editing
	_fill_givers(int(quest.get("npc_id", giver if giver > 0 else _first_placed())))
	_type.select(maxi(0, _type.get_item_index(int(quest.get("quest_type_id", 1)))))
	var amount: Variant = quest.get("amount")
	_amount.set_value(int(amount) if amount != null else 1)
	_select(_species, quest.get("species_id"))
	_select(_target, quest.get("target_npc_id"))
	_select(_target_item, quest.get("target_item_id"))
	_place_name.text = str(quest.get("place_name", "")) if quest.get("place_name") != null else ""
	_tiles.clear()
	for tile: Variant in DictFields.get_array(quest, "tiles"):
		if tile is Dictionary:
			_tiles.append(Vector2i(DictFields.get_int(tile, "q"), DictFields.get_int(tile, "r")))
	_title.text = str(quest.get("title", "")) if quest.get("title") != null else ""
	_title.placeholder_text = "Automático: %s" % quest.get("display_title", "") if _editing > 0 and quest.get("title") == null else "Automático"
	_coins.set_value(int(quest.get("coins", 0)))
	_select(_item, quest.get("item_id"))
	var quantity: Variant = quest.get("item_quantity")
	_item_quantity.set_value(int(quantity) if quantity != null else 1)
	_counts.button_pressed = bool(quest.get("counts_for_unlock", true))
	cancel_pick()
	_render()
	changed.emit()


func _close() -> void:
	_editing = -1
	_tiles.clear()
	cancel_pick()
	if _form != null:
		_render()
	changed.emit()


func _refresh_fields() -> void:
	if _form == null:
		return
	var type_id := _type.get_selected_id()
	_amount_row.visible = AMOUNT_TYPES.has(type_id)
	_amount_label.text = "Porcentagem (%)" if type_id == PERCENT_TYPE else ("Minutos" if type_id == MINUTES_TYPE else "Quantidade")
	_species_row.visible = SPECIES_TYPES.has(type_id)
	_target_row.visible = TARGET_TYPES.has(type_id)
	_target_item_row.visible = type_id == FIND_ITEM_TYPE
	_place_box.visible = type_id == PLACE_TYPE
	_pick_button.text = "Pronto" if picking else "Escolher no mapa"
	_tiles_label.text = "%d hexágono%s" % [_tiles.size(), "" if _tiles.size() == 1 else "s"]
	_item_quantity_row.visible = _item.get_selected_id() != NO_ITEM
	if type_id != PLACE_TYPE and picking:
		picking = false
		message.emit("", false)


func _body_of_form() -> Dictionary:
	var type_id := _type.get_selected_id()
	var amount := _amount.value()
	var coins := _coins.value()
	var quantity := _item_quantity.value()
	var item_id := _item.get_selected_id()
	var tiles: Array[Dictionary] = []
	for coord: Vector2i in _tiles:
		tiles.append({"q": coord.x, "r": coord.y})
	return {
		"npc_id": _giver.get_selected_id(),
		"quest_type_id": type_id,
		"amount": _id_or_null(not is_nan(amount), 0 if is_nan(amount) else int(amount)),
		"species_id": _id_or_null(SPECIES_TYPES.has(type_id), _species.get_selected_id()),
		"target_npc_id": _id_or_null(TARGET_TYPES.has(type_id), _target.get_selected_id()),
		"target_item_id": _id_or_null(type_id == FIND_ITEM_TYPE, _target_item.get_selected_id()),
		"place_name": _place_name.text,
		"title": _title.text,
		"coins": -1 if is_nan(coins) else int(coins),
		"item_id": _id_or_null(item_id != NO_ITEM, item_id),
		"item_quantity": 0 if is_nan(quantity) else int(quantity),
		"counts_for_unlock": _counts.button_pressed,
		"tiles": tiles,
	}


func _save() -> void:
	if _editing < 0:
		return
	var body := _body_of_form()
	var island_id := _island_id
	var id := _editing
	var response := await _send(func() -> ApiResponse:
		if id == 0:
			return await EditorApi.create_quest(island_id, body)
		return await EditorApi.save_quest(id, body))
	if response == null:
		return
	_apply(response.data)
	message.emit("Missão salva.", false)
	_close()


func _remove() -> void:
	if _editing <= 0:
		return
	if _delete.text != CONFIRM_DELETE_TEXT:
		_delete.text = CONFIRM_DELETE_TEXT
		return
	var id := _editing
	var response := await _send(func() -> ApiResponse: return await EditorApi.delete_quest(id))
	if response == null:
		return
	_apply(response.data)
	message.emit("Missão apagada.", false)
	_close()


func _move(id: int, up: bool) -> void:
	var response := await _send(func() -> ApiResponse: return await EditorApi.move_quest(id, up))
	if response != null:
		_apply(response.data)
		_render()


func _save_required() -> void:
	var value := _required.value()
	if is_nan(value):
		message.emit("Use um número de 0 a %d." % MAX_REQUIRED, true)
		return
	var island_id := _island_id
	var required: Variant = _id_or_null(int(value) != 0, int(value))
	var response := await _send(func() -> ApiResponse: return await EditorApi.set_required_quests(island_id, required))
	if response != null:
		_apply(response.data)
		message.emit("Missões para abrir a próxima ilha: %s." % ("todas" if int(value) == 0 else str(int(value))), false)
		_render()


## Espera a chamada; com erro, mostra a mensagem do servidor e devolve nulo.
func _send(request: Callable) -> ApiResponse:
	if _busy:
		return null
	_busy = true
	var response: ApiResponse = await request.call()
	_busy = false
	if not is_inside_tree():
		return null
	if not response.ok:
		message.emit(response.error, true)
		return null
	return response


func _fill_givers(chosen: int) -> void:
	_giver.clear()
	var placed: Array[int] = []
	if _draft != null:
		for npc: Dictionary in _draft.npcs:
			var id := int(npc.get("npc_id", 0))
			if not placed.has(id):
				placed.append(id)
	for id: int in placed:
		_giver.add_item(_npc_name(id), id)
	if not placed.is_empty():
		_giver.add_separator("Fora do mapa (numa sala)")
	for row: Dictionary in GameData.get_rows("npcs"):
		var id := int(row.get("id", 0))
		if not placed.has(id):
			_giver.add_item(str(row.get("name", "")), id)
	_select(_giver, chosen)


func _first_placed() -> int:
	if _draft != null and not _draft.npcs.is_empty():
		return int(_draft.npcs[0].get("npc_id", 0))
	return 0


func _placed(npc_id: int) -> bool:
	if _draft == null:
		return false
	return _draft.npcs.any(func(npc: Dictionary) -> bool: return int(npc.get("npc_id", 0)) == npc_id)


func _find(id: int) -> Dictionary:
	for quest: Dictionary in _quests:
		if int(quest.get("id", 0)) == id:
			return quest
	return {}


## O JSON pede nulo no campo que o tipo não usa.
static func _id_or_null(present: bool, value: int) -> Variant:
	if present:
		return value
	return null


static func _npc_name(id: int) -> String:
	return str(GameData.get_npc(id).get("name", "NPC %d" % id))


static func _select(option: OptionButton, id: Variant) -> void:
	var index := option.get_item_index(int(id)) if id != null else -1
	option.select(index if index >= 0 else 0)


static func _row(text: String, field: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = 120.0
	row.add_child(label)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if field is OptionButton:
		(field as OptionButton).focus_mode = Control.FOCUS_NONE
		(field as OptionButton).fit_to_longest_item = false
	row.add_child(field)
	return row


static func _hint(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	return label


static func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button
