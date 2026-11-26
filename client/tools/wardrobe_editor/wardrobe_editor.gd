class_name WardrobeEditor
extends Window
## O editor de roupas (tamer-looks/05), aberto pelo F6 com o jogo rodando pelo editor do
## Godot: edita pixel a pixel as folhas de adulto dos corpos e das peças do Domador e
## grava por cima dos PNGs, pondo o slug no hand_drawn.json, que o make_wardrobe.gd pula.

signal _unsaved_answered(answer: String)

const TITLE := "Ecobeast: editor de roupas"
const WINDOW_SIZE := Vector2i(1280, 720)
const MIN_SIZE := Vector2i(1100, 640)
const GAP := 16
const FONT_SIZE := 15
const SIDE_WIDTH := 250
const PREVIEW_WIDTH := 300
const SWATCH := Vector2(28, 28)
const BODY_FOLDER := "res://assets/tamer/bodies/%s"
const PART_FOLDER := "res://assets/tamer/parts/%s"
const HAND_DRAWN := "res://assets/tamer/hand_drawn.json"
const ADULT_BODIES: Array[String] = ["male", "female"]
const ANIMATIONS: Array[String] = [TamerSprite.IDLE, TamerSprite.RUN]
const ANIMATION_NAMES: Array[String] = ["Parado", "Correndo"]
const SUFFIXES: Array[String] = ["", TamerSprite.BACK_SUFFIX, TamerSprite.SHORT_SUFFIX]
const SUFFIX_NAMES: Array[String] = ["Frente", "Atrás", "Curta"]
const SAVED := "Salvo. Volte à janela do Godot para ele reimportar."
const UNSAVED_QUESTION := "A folha tem mudanças não salvas."
const DISCARD := &"discard"
const ARROWS: Dictionary[Key, Vector2i] = {KEY_LEFT: Vector2i.LEFT, KEY_RIGHT: Vector2i.RIGHT, KEY_UP: Vector2i.UP, KEY_DOWN: Vector2i.DOWN}

var _entries: Array[Dictionary] = []
var _entry := -1
var _animation := 0
var _suffix := 0
var _sheet: WardrobeSheet = null

var _list := ItemList.new()
var _animation_option := OptionButton.new()
var _sheet_option := OptionButton.new()
var _tool_buttons: Array[Button] = []
var _swatches := HFlowContainer.new()
var _current_color := ColorPickerButton.new()
var _undo_button := Button.new()
var _redo_button := Button.new()
var _save_button := Button.new()
var _body_check := CheckBox.new()
var _previous_check := CheckBox.new()
var _canvas := WardrobeCanvas.new()
var _frames := WardrobeFrames.new()
var _preview := WardrobePreview.new()
var _palette_label := Label.new()
var _palette_option := OptionButton.new()
var _skin_option := OptionButton.new()
var _guide_option := OptionButton.new()
var _message := Label.new()
var _view_label := Label.new()
var _unsaved_dialog := ConfirmationDialog.new()


func _init() -> void:
	# O force_native só pode mudar com a janela escondida: quem cria chama show().
	visible = false
	title = TITLE
	size = WINDOW_SIZE
	min_size = MIN_SIZE
	force_native = true
	initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
	close_requested.connect(close)
	window_input.connect(_on_window_input)
	var project_theme := ThemeDB.get_project_theme()
	theme = project_theme.duplicate() if project_theme != null else Theme.new()
	theme.default_font_size = FONT_SIZE
	_compact(theme)
	_build()
	_entries = entries()
	_fill_list()


func _ready() -> void:
	position = _place_beside_game()
	if not _entries.is_empty():
		open_entry(0)


## Os corpos de adulto e depois as peças, pela ordem do lugar; nunca as folhas da criança.
func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for body: Dictionary in GameData.get_rows("body_types"):
		if TamerSprite.is_child_body(body) or not ADULT_BODIES.has(body["slug"]):
			continue
		result.append({"label": body["name"], "folder": BODY_FOLDER % body["slug"], "kind": "body", "slug": body["slug"], "palette_kind": "skin", "group": "Corpo"})
	var slots := GameData.get_rows("appearance_slots").duplicate()
	slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["layer"] < b["layer"])
	for slot: Dictionary in slots:
		for part: Dictionary in GameData.get_rows("appearance_parts"):
			if part["appearance_slot_id"] != slot["id"]:
				continue
			var kind: Variant = slot["palette_kind"]
			result.append({"label": part["name"], "folder": PART_FOLDER % part["slug"], "kind": "part", "slug": part["slug"], "palette_kind": kind if kind != null else "", "group": slot["name"]})
	return result


func open_entry(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	if not await _resolve_unsaved():
		_select_list_entry(_entry)
		return
	_entry = index
	_select_list_entry(index)
	_fill_sheet_options()
	_fill_palettes()
	_open_sheet()


## Grava a folha aberta e põe o corpo ou a peça no hand_drawn.json.
func save() -> void:
	if _sheet == null or _entry < 0:
		return
	_canvas.commit()
	if _sheet.dirty:
		var error := _sheet.save()
		if error != OK:
			_say("Não foi possível salvar: %s" % error_string(error))
			return
	var entry := _entries[_entry]
	_mark_hand_drawn(entry["kind"], entry["slug"])
	_refresh_buttons()
	_refresh_colors()
	_say(SAVED)


func close() -> void:
	if await _resolve_unsaved():
		hide()
		# Relê do arquivo: o Descartar não pode deixar a edição na tela na volta.
		if _entry >= 0:
			_open_sheet()


# --- montagem ------------------------------------------------------------------

## Os botões do tema são do celular, altos demais para uma ferramenta de 1280×720.
static func _compact(target: Theme) -> void:
	for type: StringName in [&"Button", &"OptionButton", &"CheckBox", &"ColorPickerButton"]:
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus", &"hover_pressed"]:
			if not target.has_stylebox(state, type):
				continue
			var box := target.get_stylebox(state, type).duplicate() as StyleBox
			box.content_margin_top = 4
			box.content_margin_bottom = 4
			box.content_margin_left = 10
			box.content_margin_right = 10
			target.set_stylebox(state, type, box)

func _build() -> void:
	var background := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UiPalette.BACKGROUND
	background.add_theme_stylebox_override(&"panel", style)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	margin.add_child(row)
	row.add_child(_build_side())
	row.add_child(_build_center())
	row.add_child(_build_right())

	_unsaved_dialog.title = TITLE
	_unsaved_dialog.dialog_text = UNSAVED_QUESTION
	_unsaved_dialog.ok_button_text = "Salvar"
	_unsaved_dialog.cancel_button_text = "Cancelar"
	_unsaved_dialog.add_button("Descartar", true, DISCARD)
	_unsaved_dialog.confirmed.connect(func() -> void: _unsaved_answered.emit("save"))
	_unsaved_dialog.canceled.connect(func() -> void: _unsaved_answered.emit("cancel"))
	_unsaved_dialog.custom_action.connect(func(action: StringName) -> void:
		if action == DISCARD:
			_unsaved_dialog.hide()
			_unsaved_answered.emit("discard"))
	add_child(_unsaved_dialog)


func _build_side() -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = SIDE_WIDTH
	column.add_theme_constant_override(&"separation", 8)
	column.add_child(_heading("Peças"))
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.focus_mode = Control.FOCUS_NONE
	_list.item_selected.connect(func(item: int) -> void:
		var index: int = _list.get_item_metadata(item)
		if index != _entry:
			open_entry(index))
	column.add_child(_list)
	column.add_child(_heading("Animação"))
	for index: int in ANIMATION_NAMES.size():
		_animation_option.add_item(ANIMATION_NAMES[index], index)
	_animation_option.focus_mode = Control.FOCUS_NONE
	_animation_option.item_selected.connect(func(item: int) -> void: _change_sheet(item, _suffix))
	column.add_child(_animation_option)
	column.add_child(_heading("Folha"))
	_sheet_option.focus_mode = Control.FOCUS_NONE
	_sheet_option.item_selected.connect(func(item: int) -> void: _change_sheet(_animation, _sheet_option.get_item_id(item)))
	column.add_child(_sheet_option)
	return column


func _build_center() -> Control:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 8)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override(&"separation", 6)
	var group := ButtonGroup.new()
	for tool: Array in [[WardrobeCanvas.PENCIL, "Lápis", "B"], [WardrobeCanvas.ERASER, "Borracha", "E; o botão direito também apaga"], [WardrobeCanvas.PICKER, "Conta-gotas", "I"], [WardrobeCanvas.SELECT, "Seleção", "S; Ctrl+C copia, Ctrl+X recorta, Ctrl+V cola, Ctrl+A seleciona o quadro, Delete apaga, arraste ou use as setas para mover e Enter ou Esc para assentar"]]:
		var button := Button.new()
		button.text = tool[1]
		button.tooltip_text = tool[2]
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_choose_tool.bind(tool[0]))
		bar.add_child(button)
		_tool_buttons.append(button)
	_tool_buttons[0].button_pressed = true
	bar.add_child(_spacer())
	for action: Array in [[_undo_button, "Desfazer", _undo], [_redo_button, "Refazer", _redo], [_save_button, "Salvar", save]]:
		var button: Button = action[0]
		button.text = action[1]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(action[2])
		bar.add_child(button)
	column.add_child(bar)

	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.picked.connect(_on_picked)
	_canvas.view_changed.connect(_refresh_view_label)
	column.add_child(_canvas)
	_frames.cell_chosen.connect(_choose_cell)
	column.add_child(_frames)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override(&"separation", 8)
	_message.theme_type_variation = &"SecondaryLabel"
	_message.text = " "
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message.clip_text = true
	footer.add_child(_message)
	_view_label.theme_type_variation = &"SecondaryLabel"
	_view_label.tooltip_text = "Roda do mouse: zoom. Ctrl+roda ou [ e ]: tamanho do pincel. Botão do meio: arrastar a vista."
	_view_label.mouse_filter = Control.MOUSE_FILTER_PASS
	footer.add_child(_view_label)
	var fit := Button.new()
	fit.text = "Ajustar"
	fit.tooltip_text = "0: volta ao zoom que cabe"
	fit.focus_mode = Control.FOCUS_NONE
	fit.pressed.connect(_canvas.fit_view)
	footer.add_child(fit)
	column.add_child(footer)
	return column


func _build_right() -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = PREVIEW_WIDTH
	column.add_theme_constant_override(&"separation", 8)
	column.add_child(_heading("Prévia"))
	column.add_child(_preview)
	column.add_child(_palette_label)
	_palette_label.text = "Cor"
	for option: OptionButton in [_palette_option, _skin_option, _guide_option]:
		option.focus_mode = Control.FOCUS_NONE
		option.item_selected.connect(func(_item: int) -> void: _refresh_guide())
	column.add_child(_palette_option)
	column.add_child(_heading("Pele"))
	for palette: Dictionary in _palettes_of("skin"):
		_skin_option.add_item(palette["name"], palette["id"])
	column.add_child(_skin_option)
	column.add_child(_heading("Corpo guia"))
	for body: Dictionary in GameData.get_rows("body_types"):
		if ADULT_BODIES.has(body["slug"]):
			_guide_option.add_item(body["name"])
			_guide_option.set_item_metadata(_guide_option.item_count - 1, body["slug"])
	column.add_child(_guide_option)
	var guides := HBoxContainer.new()
	for check: Array in [[_body_check, "Corpo"], [_previous_check, "Quadro anterior"]]:
		var box: CheckBox = check[0]
		box.text = check[1]
		box.button_pressed = true
		box.focus_mode = Control.FOCUS_NONE
		guides.add_child(box)
	_body_check.toggled.connect(func(on: bool) -> void: _canvas.show_body = on)
	_previous_check.toggled.connect(func(on: bool) -> void: _canvas.show_previous = on)
	column.add_child(guides)
	column.add_child(_heading("Cores da folha"))
	_swatches.add_theme_constant_override(&"h_separation", 4)
	_swatches.add_theme_constant_override(&"v_separation", 4)
	column.add_child(_swatches)
	column.add_child(_heading("Cor do lápis"))
	_current_color.custom_minimum_size = Vector2(SWATCH.x * 3, SWATCH.y)
	_current_color.focus_mode = Control.FOCUS_NONE
	_current_color.edit_alpha = false
	_current_color.color = _canvas.color
	_current_color.color_changed.connect(_set_color)
	column.add_child(_current_color)
	return column


func _heading(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.theme_type_variation = &"BoldLabel"
	return label


func _spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer


func _fill_list() -> void:
	_list.clear()
	var group := ""
	for index: int in _entries.size():
		var entry := _entries[index]
		if entry["group"] != group:
			group = entry["group"]
			var header := _list.add_item(group, null, false)
			_list.set_item_disabled(header, true)
			_list.set_item_metadata(header, -1)
		var item := _list.add_item("   " + entry["label"])
		_list.set_item_metadata(item, index)


func _select_list_entry(index: int) -> void:
	for item: int in _list.item_count:
		if _list.get_item_metadata(item) == index:
			_list.select(item)
			_list.ensure_current_is_visible()
			return
	_list.deselect_all()


func _fill_sheet_options() -> void:
	_sheet_option.clear()
	var folder: String = _entries[_entry]["folder"]
	for index: int in SUFFIXES.size():
		if _exists(folder, ANIMATIONS[_animation], SUFFIXES[index]):
			_sheet_option.add_item(SUFFIX_NAMES[index], index)
	if _sheet_option.get_item_index(_suffix) < 0:
		_suffix = _sheet_option.get_item_id(0) if _sheet_option.item_count > 0 else 0
	_sheet_option.select(maxi(_sheet_option.get_item_index(_suffix), 0))
	_animation_option.select(_animation)


func _fill_palettes() -> void:
	var kind: String = _entries[_entry]["palette_kind"]
	var is_part: bool = _entries[_entry]["kind"] == "part"
	var keep := _palette_option.get_selected_id()
	_palette_option.clear()
	if is_part and not kind.is_empty():
		for palette: Dictionary in _palettes_of(kind):
			_palette_option.add_item(palette["name"], palette["id"])
	if _palette_option.get_item_index(keep) >= 0:
		_palette_option.select(_palette_option.get_item_index(keep))
	_palette_label.visible = _palette_option.item_count > 0
	_palette_option.visible = _palette_option.item_count > 0


func _palettes_of(kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for palette: Dictionary in GameData.get_rows("palettes"):
		if palette["kind"] == kind:
			result.append(palette)
	return result


# --- folhas --------------------------------------------------------------------

func _change_sheet(animation: int, suffix: int) -> void:
	if animation == _animation and suffix == _suffix:
		return
	if not await _resolve_unsaved():
		_animation_option.select(_animation)
		_sheet_option.select(maxi(_sheet_option.get_item_index(_suffix), 0))
		return
	_animation = animation
	_suffix = suffix
	_fill_sheet_options()
	_open_sheet()


func _open_sheet() -> void:
	var folder: String = _entries[_entry]["folder"]
	if not _exists(folder, ANIMATIONS[_animation], SUFFIXES[_suffix]):
		_sheet = null
		_say("Esta peça não tem a folha %s." % ANIMATION_NAMES[_animation])
		return
	if _sheet != null and _sheet.changed.is_connected(_refresh_buttons):
		_sheet.changed.disconnect(_refresh_buttons)
	_sheet = WardrobeSheet.open(_sheet_path(folder, ANIMATIONS[_animation], SUFFIXES[_suffix]))
	_sheet.changed.connect(_refresh_buttons)
	var cell := _canvas.cell
	cell.x = mini(cell.x, _sheet.columns() - 1)
	_canvas.sheet = _sheet
	_frames.sheet = _sheet
	_choose_cell(cell)
	_refresh_guide()
	_refresh_colors()
	_refresh_buttons()
	_refresh_view_label()
	_say(" ")


func _refresh_guide() -> void:
	if _sheet == null:
		return
	var entry := _entries[_entry]
	var seconds := TamerSprite.IDLE_SECONDS if _animation == 0 else TamerSprite.RUN_SECONDS
	var skin := _skin_option.get_selected_id()
	if entry["kind"] == "body":
		_canvas.guide = null
		_preview.show_sheets(_sheet, null, _canvas.cell.y, seconds, -1, skin)
		return
	var guide_slug: String = _guide_option.get_item_metadata(maxi(_guide_option.selected, 0))
	var body := WardrobeSheet.open(_sheet_path(BODY_FOLDER % guide_slug, ANIMATIONS[_animation], ""))
	_canvas.guide = body
	_preview.show_sheets(body, _sheet, _canvas.cell.y, seconds, _palette_option.get_selected_id(), skin)


func _refresh_colors() -> void:
	for child: Node in _swatches.get_children():
		child.queue_free()
	if _sheet == null:
		return
	for color: Color in _sheet.colors():
		var swatch := Button.new()
		swatch.custom_minimum_size = SWATCH
		swatch.focus_mode = Control.FOCUS_NONE
		swatch.tooltip_text = "#" + color.to_html(false)
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.set_border_width_all(2)
		style.border_color = UiPalette.BORDER
		var hover := style.duplicate() as StyleBoxFlat
		hover.border_color = UiPalette.ACCENT
		swatch.add_theme_stylebox_override(&"normal", style)
		swatch.add_theme_stylebox_override(&"pressed", hover)
		swatch.add_theme_stylebox_override(&"hover", hover)
		swatch.pressed.connect(_on_picked.bind(color))
		_swatches.add_child(swatch)


func _refresh_buttons() -> void:
	var dirty := _sheet != null and _sheet.dirty
	_save_button.disabled = _sheet == null
	_save_button.text = "Salvar*" if dirty else "Salvar"


func _choose_cell(cell: Vector2i) -> void:
	if _sheet == null:
		return
	cell = Vector2i(posmod(cell.x, _sheet.columns()), clampi(cell.y, 0, WardrobeSheet.ROWS - 1))
	var row_changed := cell.y != _canvas.cell.y
	_canvas.cell = cell
	_frames.cell = cell
	if row_changed:
		_refresh_guide()


func _choose_tool(tool: int) -> void:
	_canvas.tool = tool
	_tool_buttons[tool].button_pressed = true


func _on_picked(color: Color) -> void:
	_set_color(color)
	_current_color.color = color
	_choose_tool(WardrobeCanvas.PENCIL)


func _set_color(color: Color) -> void:
	_canvas.color = Color(color, 1.0) if color.a > 0.0 else Color.TRANSPARENT


func _undo() -> void:
	_canvas.commit()
	if _sheet != null and not _sheet.undo():
		_say("Nada para desfazer.")


func _redo() -> void:
	_canvas.commit()
	if _sheet != null and not _sheet.redo():
		_say("Nada para refazer.")


## true quando pode seguir: sem mudança, salvo ou descartado; false no Cancelar.
func _resolve_unsaved() -> bool:
	_canvas.commit()
	if _sheet == null or not _sheet.dirty:
		return true
	_unsaved_dialog.popup_centered()
	var answer: String = await _unsaved_answered
	if answer == "save":
		save()
		return not _sheet.dirty
	if answer == "discard":
		_sheet.dirty = false
		return true
	return false


func _mark_hand_drawn(kind: String, slug: String) -> void:
	var data := {"bodies": [], "parts": []}
	var file := FileAccess.open(HAND_DRAWN, FileAccess.READ)
	if file != null:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if parsed is Dictionary:
			for key: String in data:
				if (parsed as Dictionary).get(key) is Array:
					data[key] = parsed[key]
	var list: Array = data["bodies" if kind == "body" else "parts"]
	if list.has(slug):
		return
	list.append(slug)
	var out := FileAccess.open(HAND_DRAWN, FileAccess.WRITE)
	if out == null:
		_say("Não foi possível gravar o %s." % HAND_DRAWN)
		return
	out.store_string(JSON.stringify(data, "\t", false) + "\n")


func _exists(folder: String, animation: String, suffix: String) -> bool:
	return FileAccess.file_exists(ProjectSettings.globalize_path(_sheet_path(folder, animation, suffix)))


func _sheet_path(folder: String, animation: String, suffix: String) -> String:
	return "%s/%s%s.png" % [folder, animation, suffix]


func _refresh_view_label() -> void:
	_view_label.text = "Zoom %d×   Pincel %d px" % [_canvas.pixel_scale(), _canvas.brush]


func _copy(cut: bool) -> void:
	var done := _canvas.cut() if cut else _canvas.copy()
	if not done:
		_say("Nada selecionado: use a Seleção (S) ou Ctrl+A.")
		return
	var area := _canvas.selection.size
	_say("%s: %d×%d px. Ctrl+V cola em qualquer quadro ou peça." % ["Recortado" if cut else "Copiado", area.x, area.y])


func _paste() -> void:
	if not _canvas.has_clipboard():
		_say("Nada para colar: copie uma seleção antes.")
		return
	_choose_tool(WardrobeCanvas.SELECT)
	_canvas.paste()
	_say("Colado: arraste ou use as setas, e Enter assenta.")


func _say(value: String) -> void:
	_message.text = value


# --- atalhos -------------------------------------------------------------------

func _on_window_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or _unsaved_dialog.visible:
		return
	var ctrl := key.ctrl_pressed or key.meta_pressed
	var handled := true
	if key.keycode == KEY_F6 and not key.echo:
		close()
	elif ctrl and key.keycode == KEY_Z:
		_undo()
	elif ctrl and key.keycode == KEY_Y:
		_redo()
	elif ctrl and key.keycode == KEY_S and not key.echo:
		save()
	elif ctrl and key.keycode == KEY_C and not key.echo:
		_copy(false)
	elif ctrl and key.keycode == KEY_X and not key.echo:
		_copy(true)
	elif ctrl and key.keycode == KEY_V and not key.echo:
		_paste()
	elif ctrl and key.keycode == KEY_A and not key.echo:
		_choose_tool(WardrobeCanvas.SELECT)
		_canvas.select_all()
	elif ctrl:
		handled = false
	elif ARROWS.has(key.keycode):
		if _canvas.tool == WardrobeCanvas.SELECT and _canvas.has_selection():
			_canvas.nudge(ARROWS[key.keycode])
		else:
			_choose_cell(_canvas.cell + ARROWS[key.keycode])
	elif key.keycode == KEY_DELETE or key.keycode == KEY_BACKSPACE:
		_canvas.delete_selection()
	elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER or key.keycode == KEY_ESCAPE:
		_canvas.deselect()
	elif key.keycode == KEY_BRACKETLEFT:
		_canvas.brush -= 1
	elif key.keycode == KEY_BRACKETRIGHT:
		_canvas.brush += 1
	elif key.keycode == KEY_0 or key.keycode == KEY_KP_0:
		_canvas.fit_view()
	elif key.keycode == KEY_S and not key.echo:
		_choose_tool(WardrobeCanvas.SELECT)
	elif key.keycode == KEY_B:
		_choose_tool(WardrobeCanvas.PENCIL)
	elif key.keycode == KEY_E:
		_choose_tool(WardrobeCanvas.ERASER)
	elif key.keycode == KEY_I:
		_choose_tool(WardrobeCanvas.PICKER)
	else:
		handled = false
	if handled:
		set_input_as_handled()


func _place_beside_game() -> Vector2i:
	var game := get_tree().root
	var screen := DisplayServer.screen_get_usable_rect(game.current_screen)
	var top := clampi(game.position.y, screen.position.y, maxi(screen.position.y, screen.end.y - size.y))
	var right := game.position.x + game.size.x + GAP
	if right + size.x <= screen.end.x:
		return Vector2i(right, top)
	var left := game.position.x - GAP - size.x
	if left >= screen.position.x:
		return Vector2i(left, top)
	return screen.position + Vector2i((Vector2(screen.size - size) / 2.0).floor())
