class_name InteriorEditor
extends VBoxContainer

## O modo Interiores do F2 (interiors/03): a lista das salas, criar, renomear, mudar o
## tamanho, excluir e salvar, e as 8 ferramentas sobre o `InteriorDraft`, com desfazer.

signal islands_requested
signal interiors_changed(rows: Array)

const SAVED_TEXT := "Sala salva."
const NEW_NAME := "Sala nova"
const TOOLS: Array[Dictionary] = [
	{"id": &"floor", "name": "Chão", "icon": "ground", "layer": "floor"},
	{"id": &"floor_detail", "name": "Detalhe do chão", "icon": "path", "layer": "floor_detail"},
	{"id": &"wall", "name": "Parede", "icon": "fence", "layer": "wall"},
	{"id": &"wall_detail", "name": "Detalhe da parede", "icon": "stamp", "layer": "wall_detail"},
	{"id": &"object", "name": "Objeto", "icon": "object", "layer": ""},
	{"id": &"block", "name": "Bloqueio", "icon": "blocks", "layer": ""},
	{"id": &"npc", "name": "NPC", "icon": "npc", "layer": ""},
	{"id": &"door", "name": "Porta", "icon": "flag", "layer": ""},
]
const HINTS: Dictionary[StringName, String] = {
	&"object": "Botão esquerdo: pôr a escolha da paleta, ou escolher e arrastar um objeto. Botão direito ou Delete: apagar. A linha de baixo do objeto vira bloqueio.",
	&"block": "Botão esquerdo: bloquear o quadrado. Botão direito: desbloquear. Vermelho é bloqueio marcado; cinza é sem chão.",
	&"door": "Botão esquerdo: pôr a porta, num quadrado de chão sem bloqueio. O Domador nasce nela e sai por ela.",
}
const TILE_HINT := "Botão esquerdo: pintar a escolha da paleta (arraste para repetir). Botão direito: apagar desta camada."

var _draft: InteriorDraft = null
var _rows: Array = []
var _history := UndoRedo.new()
var _saved_version := 0
var _tool: StringName = &"floor"
var _busy := false
var _stroke_before: Dictionary = {}
var _stroke_start := Vector2i.ZERO
var _stroke_secondary := false
var _selected_object := -1
var _selected_npc := -1
var _drag_offset := Vector2i.ZERO
var _last_id := 0

var _rooms_button: Button
var _rooms_popup: PopupPanel
var _rooms_list: VBoxContainer
var _name_edit: LineEdit
var _width_spin: SpinBox
var _height_spin: SpinBox
var _save_button: Button
var _undo_button: Button
var _redo_button: Button
var _blocks_check: CheckButton
var _message: Label
var _hover_label: Label
var _tool_buttons: Dictionary[StringName, Button] = {}
var _canvas := InteriorCanvas.new()
var _palette := InteriorPalette.new()
var _npc_panel := InteriorNpcPanel.new()
var _hint: Label
var _new_dialog: ConfirmationDialog
var _new_name: LineEdit
var _new_width: SpinBox
var _new_height: SpinBox
var _delete_dialog: ConfirmationDialog


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	_build()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_history.free()


## Lê a lista e abre a última sala aberta, ou a primeira.
func open() -> void:
	_npc_panel.refresh_lists()
	await _load_list()
	if _draft != null:
		return
	var id := _last_id
	if id == 0 and not _rows.is_empty():
		id = int((_rows[0] as Dictionary).get("id", 0))
	if id > 0:
		await _open_room(id)


func is_dirty() -> bool:
	return _draft != null and _history.get_version() != _saved_version


## Pergunta, com mudanças sem salvar, por `ask` (que devolve "save", "discard" ou "cancel").
func resolve_unsaved(ask: Callable) -> bool:
	if not is_dirty():
		return true
	var answer: String = await ask.call()
	if answer == "save":
		return await save()
	if answer == "discard":
		_set_draft(null)
		return true
	return false


func save() -> bool:
	if _draft == null or _busy:
		return false
	var error := _draft.save_error()
	if not error.is_empty():
		_set_message(error, true)
		return false
	_busy = true
	var response: ApiResponse = await EditorApi.save_interior(_draft.interior.id, _draft.interior.to_dict())
	_busy = false
	if not response.ok:
		_set_message(response.error, true)
		return false
	var saved := Interior.from_dict(response.data)
	if saved != null:
		_draft.restore(saved.to_dict())
	_saved_version = _history.get_version()
	_canvas.refresh_all()
	_refresh_header()
	_set_message(SAVED_TEXT)
	await _load_list()
	return true


func handle_input(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return false
	if key.keycode == KEY_S and key.ctrl_pressed:
		save()
		return true
	if _typing():
		return false
	if key.ctrl_pressed and (key.keycode == KEY_Y or (key.keycode == KEY_Z and key.shift_pressed)):
		_redo()
		return true
	if key.ctrl_pressed and key.keycode == KEY_Z:
		_undo()
		return true
	if key.keycode == KEY_DELETE or key.keycode == KEY_BACKSPACE:
		_delete_selected()
		return true
	if not key.ctrl_pressed and key.keycode >= KEY_1 and key.keycode < KEY_1 + TOOLS.size():
		_set_tool(TOOLS[key.keycode - KEY_1]["id"])
		return true
	return false


func _typing() -> bool:
	var focus := get_viewport().gui_get_focus_owner()
	return focus is LineEdit or focus is TextEdit


func _load_list() -> void:
	var response: ApiResponse = await EditorApi.list_interiors()
	if not response.ok:
		_set_message(response.error, true)
		return
	_rows = DictFields.get_array(response.data, "interiors")
	_fill_rooms()
	interiors_changed.emit(_rows)


func _open_room(id: int) -> void:
	var response: ApiResponse = await EditorApi.read_interior(id)
	if not response.ok:
		_set_message(response.error, true)
		return
	var room := Interior.from_dict(response.data)
	if room != null:
		_set_draft(room)


func _set_draft(room: Interior) -> void:
	_draft = InteriorDraft.new(room) if room != null else null
	_last_id = room.id if room != null else _last_id
	_history.clear_history(false)
	_saved_version = _history.get_version()
	_selected_object = -1
	_selected_npc = -1
	if _draft != null:
		_canvas.set_draft(_draft)
	_canvas.visible = _draft != null
	_refresh_header()
	_refresh_selection()


func _refresh_header() -> void:
	var has_room := _draft != null
	_name_edit.editable = has_room
	_width_spin.editable = has_room
	_height_spin.editable = has_room
	_save_button.disabled = not has_room
	if has_room:
		if _name_edit.text != _draft.interior.name:
			_name_edit.text = _draft.interior.name
		_width_spin.set_value_no_signal(_draft.interior.width)
		_height_spin.set_value_no_signal(_draft.interior.height)
	_rooms_button.text = ("Salas: %s%s" % [_draft.interior.name, " *" if is_dirty() else ""]) if has_room else "Salas"
	_undo_button.disabled = not _history.has_undo()
	_redo_button.disabled = not _history.has_redo()


# O desfazer: um passo por pincelada ou por mudança no painel, no nome ou no tamanho.

func _commit(before: Dictionary, label: String, merge := false) -> void:
	var after := _draft.snapshot()
	if after == before:
		return
	_history.create_action(label, UndoRedo.MERGE_ENDS if merge else UndoRedo.MERGE_DISABLE)
	_history.add_do_method(_apply.bind(after))
	_history.add_undo_method(_apply.bind(before))
	_history.commit_action(false)
	_refresh_header()


func _apply(data: Dictionary) -> void:
	_draft.restore(data)
	_selected_object = -1
	_selected_npc = -1
	_canvas.refresh_all()
	_refresh_header()
	_refresh_selection()


func _undo() -> void:
	if _history.has_undo():
		_history.undo()
		_refresh_header()


func _redo() -> void:
	if _history.has_redo():
		_history.redo()
		_refresh_header()


# As ferramentas.

func _set_tool(id: StringName) -> void:
	_tool = id
	for tool_id: StringName in _tool_buttons:
		_tool_buttons[tool_id].set_pressed_no_signal(tool_id == id)
	var layer := _layer_of(id)
	_palette.visible = not layer.is_empty() or id == &"object"
	_npc_panel.visible = id == &"npc"
	_hint.text = TILE_HINT if not layer.is_empty() else HINTS.get(id, "")
	_hint.visible = not _hint.text.is_empty()
	_canvas.show_blocks = id == &"block" or _blocks_check.button_pressed
	_selected_object = -1
	_selected_npc = -1
	_refresh_selection()
	_refresh_preview()


func _layer_of(id: StringName) -> String:
	for tool: Dictionary in TOOLS:
		if tool["id"] == id:
			return str(tool["layer"])
	return ""


func _refresh_preview() -> void:
	if _palette.visible:
		_canvas.set_preview(_palette.sheet, _palette.atlas, _palette.size_cells)
	else:
		_canvas.set_preview("", Vector2i.ZERO, Vector2i.ZERO)


func _refresh_selection() -> void:
	var rect := Rect2i()
	if _draft != null and _selected_object >= 0 and _selected_object < _draft.interior.objects.size():
		rect = _draft.interior.objects[_selected_object].rect()
	elif _draft != null and _selected_npc >= 0 and _selected_npc < _draft.interior.npcs.size():
		rect = Rect2i(_draft.interior.npcs[_selected_npc].cell, Vector2i.ONE)
	_canvas.selected_rect = rect
	_npc_panel.show_npc(_draft.interior.npcs[_selected_npc] if _draft != null and _selected_npc >= 0 and _selected_npc < _draft.interior.npcs.size() else null)
	_canvas.refresh_marks()


func _on_stroke_started(cell: Vector2i, secondary: bool) -> void:
	if _draft == null:
		return
	_stroke_before = _draft.snapshot()
	_stroke_start = cell
	_stroke_secondary = secondary
	_set_message("")
	var layer := _layer_of(_tool)
	if not layer.is_empty():
		_paint_at(layer, cell)
	elif _tool == &"object":
		_start_object(cell)
	elif _tool == &"block":
		if _draft.set_block(cell, not secondary):
			_canvas.refresh_marks()
	elif _tool == &"npc":
		_start_npc(cell)
	elif _tool == &"door" and not secondary:
		var error := _draft.set_door(cell)
		if not error.is_empty():
			_set_message(error, true)
		_canvas.refresh_marks()


func _on_stroke_moved(cell: Vector2i) -> void:
	if _draft == null:
		return
	var layer := _layer_of(_tool)
	if not layer.is_empty():
		_paint_at(layer, cell)
	elif _tool == &"object" and not _stroke_secondary and _selected_object >= 0:
		if _draft.move_object(_selected_object, cell - _drag_offset):
			_canvas.refresh_objects()
			_refresh_selection()
	elif _tool == &"block":
		if _draft.set_block(cell, not _stroke_secondary):
			_canvas.refresh_marks()
	elif _tool == &"npc" and not _stroke_secondary and _selected_npc >= 0:
		if _draft.move_npc(_selected_npc, cell).is_empty():
			_refresh_selection()


func _on_stroke_ended() -> void:
	if _draft == null:
		return
	_commit(_stroke_before, "Editar a sala")


func _paint_at(layer: String, cell: Vector2i) -> void:
	if _stroke_secondary:
		if _draft.erase(layer, cell):
			_canvas.refresh_cells([cell])
		return
	var origin := InteriorDraft.stamp_origin(_stroke_start, cell, _palette.size_cells)
	var changed := _draft.paint(layer, origin, _palette.sheet, _palette.atlas, _palette.size_cells)
	if not changed.is_empty():
		_canvas.refresh_cells(changed)


func _start_object(cell: Vector2i) -> void:
	var index := _draft.object_at(cell)
	if _stroke_secondary:
		if index >= 0:
			_draft.remove_object(index)
			_selected_object = -1
			_canvas.refresh_objects()
			_refresh_selection()
		return
	if index < 0:
		index = _draft.place_object(cell, _palette.sheet, _palette.atlas, _palette.size_cells)
		if index < 0:
			_set_message("O objeto passa da borda da sala.", true)
			return
		_canvas.refresh_objects()
	_selected_object = index
	_drag_offset = cell - _draft.interior.objects[index].cell
	_refresh_selection()


func _start_npc(cell: Vector2i) -> void:
	var index := _draft.npc_at(cell)
	if _stroke_secondary:
		if index >= 0:
			_draft.remove_npc(index)
			_selected_npc = -1
			_refresh_selection()
		return
	if index < 0:
		var values := _npc_panel.values()
		var dialogue := str(values["dialogue"])
		if dialogue.is_empty():
			dialogue = str(GameData.get_npc(int(values["npc_id"])).get("default_dialogue", ""))
		var error := _draft.place_npc(cell, int(values["npc_id"]), dialogue, int(values["action_type_id"]))
		if not error.is_empty():
			_set_message(error, true)
			return
		index = _draft.interior.npcs.size() - 1
	_selected_npc = index
	_refresh_selection()


func _on_npc_changed(npc_id: int, dialogue: String, action_type_id: int) -> void:
	if _draft == null or _selected_npc < 0 or _selected_npc >= _draft.interior.npcs.size():
		return
	var before := _draft.snapshot()
	_draft.update_npc(_selected_npc, npc_id, dialogue, action_type_id)
	var keep := _selected_npc
	_commit(before, "Editar o NPC")
	_selected_npc = keep
	_canvas.refresh_marks()


func _delete_selected() -> void:
	if _draft == null:
		return
	var before := _draft.snapshot()
	if _tool == &"object" and _selected_object >= 0:
		_draft.remove_object(_selected_object)
		_selected_object = -1
		_canvas.refresh_objects()
	elif _tool == &"npc" and _selected_npc >= 0:
		_draft.remove_npc(_selected_npc)
		_selected_npc = -1
	else:
		return
	_commit(before, "Apagar")
	_refresh_selection()


func _on_hovered(cell: Vector2i) -> void:
	if _draft == null or not _draft.interior.has_cell(cell):
		_hover_label.text = ""
		return
	_hover_label.text = "Quadrado (%d, %d)" % [cell.x, cell.y]


# O nome, o tamanho e as salas.

func _on_name_changed(text: String) -> void:
	if _draft == null or text.is_empty() or text == _draft.interior.name:
		return
	var before := _draft.snapshot()
	_draft.interior.name = text
	_commit(before, "Renomear", true)


func _on_size_changed(_value: float) -> void:
	if _draft == null:
		return
	var before := _draft.snapshot()
	_draft.resize(int(_width_spin.value), int(_height_spin.value))
	_commit(before, "Mudar o tamanho")
	_canvas.refresh_all()


func _fill_rooms() -> void:
	for child: Node in _rooms_list.get_children():
		child.queue_free()
	for row: Variant in _rows:
		var room := row as Dictionary
		var button := Button.new()
		button.text = "%d. %s" % [int(room.get("id", 0)), str(room.get("name", ""))]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_choose_room.bind(int(room.get("id", 0))))
		_rooms_list.add_child(button)


func _choose_room(id: int) -> void:
	_rooms_popup.hide()
	if _draft != null and _draft.interior.id == id:
		return
	var map_editor := _map_editor()
	if map_editor != null and not await resolve_unsaved(map_editor.ask_unsaved):
		return
	await _open_room(id)


func _ask_new_room() -> void:
	_rooms_popup.hide()
	_new_name.text = NEW_NAME
	_new_dialog.popup_centered()


func _create_room() -> void:
	var map_editor := _map_editor()
	if map_editor != null and not await resolve_unsaved(map_editor.ask_unsaved):
		return
	var response: ApiResponse = await EditorApi.create_interior(_new_name.text.strip_edges(), int(_new_width.value), int(_new_height.value))
	if not response.ok:
		_set_message(response.error, true)
		return
	var room := Interior.from_dict(response.data)
	_set_draft(room)
	await _load_list()


func _ask_delete() -> void:
	_rooms_popup.hide()
	if _draft == null:
		return
	_delete_dialog.dialog_text = "Excluir a sala %s? Não dá para desfazer." % _draft.interior.name
	_delete_dialog.popup_centered()


func _delete_room() -> void:
	var response: ApiResponse = await EditorApi.delete_interior(_draft.interior.id)
	if not response.ok:
		_set_message(response.error, true)
		return
	_last_id = 0
	_set_draft(null)
	_set_message("Sala excluída.")
	await _load_list()


func _map_editor() -> MapEditor:
	var window := get_window()
	return window as MapEditor


func _set_message(text: String, error := false) -> void:
	_message.text = text
	_message.theme_type_variation = &"DangerLabel" if error else &"SecondaryLabel"


# A montagem.

func _build() -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 8)
	add_child(header)
	_rooms_button = MapEditor.header_button("Salas", "islands", "As salas: abrir, criar e excluir.")
	_rooms_button.pressed.connect(func() -> void: _popup_below(_rooms_popup, _rooms_button))
	header.add_child(_rooms_button)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Nome da sala"
	_name_edit.max_length = 40
	_name_edit.custom_minimum_size.x = 240.0
	_name_edit.text_changed.connect(_on_name_changed)
	header.add_child(_name_edit)
	header.add_child(_label("Largura"))
	_width_spin = _size_spin()
	_width_spin.value_changed.connect(_on_size_changed)
	header.add_child(_width_spin)
	header.add_child(_label("Altura"))
	_height_spin = _size_spin()
	_height_spin.value_changed.connect(_on_size_changed)
	header.add_child(_height_spin)
	_message = Label.new()
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message.clip_text = true
	header.add_child(_message)
	_blocks_check = CheckButton.new()
	_blocks_check.text = "Bloqueios"
	_blocks_check.focus_mode = Control.FOCUS_NONE
	_blocks_check.toggled.connect(func(_on: bool) -> void:
		_canvas.show_blocks = _tool == &"block" or _blocks_check.button_pressed
		_canvas.refresh_marks())
	header.add_child(_blocks_check)
	_undo_button = MapEditor.header_button("", "undo", "Desfazer (Ctrl+Z)")
	_undo_button.pressed.connect(_undo)
	header.add_child(_undo_button)
	_redo_button = MapEditor.header_button("", "redo", "Refazer (Ctrl+Y)")
	_redo_button.pressed.connect(_redo)
	header.add_child(_redo_button)
	_save_button = Button.new()
	_save_button.text = "Salvar (Ctrl+S)"
	_save_button.focus_mode = Control.FOCUS_NONE
	_save_button.pressed.connect(save)
	header.add_child(_save_button)
	var islands := MapEditor.header_button("Ilhas", "islands", "Voltar para o editor de ilhas.")
	islands.theme_type_variation = &"OutlineButton"
	islands.pressed.connect(func() -> void: islands_requested.emit())
	header.add_child(islands)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(&"separation", 8)
	add_child(body)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 4)
	body.add_child(column)
	for index: int in TOOLS.size():
		var tool: Dictionary = TOOLS[index]
		var button := MapEditor.header_button("", str(tool["icon"]), "%s (%d)" % [tool["name"], index + 1])
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(44, 44)
		button.pressed.connect(_set_tool.bind(tool["id"]))
		column.add_child(button)
		_tool_buttons[tool["id"]] = button
	body.add_child(_canvas)
	_canvas.stroke_started.connect(_on_stroke_started)
	_canvas.stroke_moved.connect(_on_stroke_moved)
	_canvas.stroke_ended.connect(_on_stroke_ended)
	_canvas.hovered.connect(_on_hovered)
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = MapEditor.SIDE_WIDTH
	side.add_theme_constant_override(&"separation", 8)
	body.add_child(side)
	_hint = Label.new()
	_hint.theme_type_variation = &"SecondaryLabel"
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_hint)
	_palette.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_palette.picked.connect(func(_sheet: String, _atlas: Vector2i, _size: Vector2i) -> void: _refresh_preview())
	side.add_child(_palette)
	_npc_panel.changed.connect(_on_npc_changed)
	side.add_child(_npc_panel)
	_hover_label = Label.new()
	_hover_label.theme_type_variation = &"SecondaryLabel"
	_hover_label.text = "Roda: zoom. Botão do meio, ou espaço e o botão esquerdo: arrastar. Teclas 1 a 8: ferramentas. Ctrl+Z e Ctrl+Y: desfazer e refazer."
	add_child(_hover_label)

	_rooms_popup = PopupPanel.new()
	add_child(_rooms_popup)
	var rooms := VBoxContainer.new()
	rooms.custom_minimum_size = Vector2(320, 0)
	rooms.add_theme_constant_override(&"separation", 6)
	_rooms_popup.add_child(rooms)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	rooms.add_child(scroll)
	_rooms_list = VBoxContainer.new()
	_rooms_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rooms_list)
	var new_button := Button.new()
	new_button.text = "Nova sala"
	new_button.focus_mode = Control.FOCUS_NONE
	new_button.pressed.connect(_ask_new_room)
	rooms.add_child(new_button)
	var delete_button := Button.new()
	delete_button.text = "Excluir a sala aberta"
	delete_button.theme_type_variation = &"DangerButton"
	delete_button.focus_mode = Control.FOCUS_NONE
	delete_button.pressed.connect(_ask_delete)
	rooms.add_child(delete_button)

	_new_dialog = ConfirmationDialog.new()
	_new_dialog.title = "Nova sala"
	_new_dialog.ok_button_text = "Criar"
	_new_dialog.cancel_button_text = "Cancelar"
	var form := VBoxContainer.new()
	_new_dialog.add_child(form)
	_new_name = LineEdit.new()
	_new_name.max_length = 40
	form.add_child(_new_name)
	var sizes := HBoxContainer.new()
	form.add_child(sizes)
	sizes.add_child(_label("Largura"))
	_new_width = _size_spin()
	_new_width.value = 16
	sizes.add_child(_new_width)
	sizes.add_child(_label("Altura"))
	_new_height = _size_spin()
	_new_height.value = 12
	sizes.add_child(_new_height)
	_new_dialog.confirmed.connect(_create_room)
	add_child(_new_dialog)
	_delete_dialog = ConfirmationDialog.new()
	_delete_dialog.title = "Excluir sala"
	_delete_dialog.ok_button_text = "Excluir"
	_delete_dialog.cancel_button_text = "Cancelar"
	_delete_dialog.confirmed.connect(_delete_room)
	add_child(_delete_dialog)
	_set_tool(&"floor")
	_refresh_header()


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


func _size_spin() -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = InteriorDraft.MIN_SIZE
	spin.max_value = InteriorDraft.MAX_SIZE
	spin.step = 1.0
	spin.custom_minimum_size.x = 90.0
	return spin


func _popup_below(panel: PopupPanel, button: Control) -> void:
	var rect := button.get_global_rect()
	var popup_size := Vector2(panel.get_contents_minimum_size())
	panel.popup(Rect2i(Vector2i(Vector2(rect.position.x, rect.end.y + 4.0).round()), Vector2i(popup_size.ceil())))
