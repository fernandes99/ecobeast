class_name MapEditor
extends Window
## O editor de ilhas (map-editor/02): uma janela só de desenvolvimento, aberta com
## F2 quando o jogo roda pelo editor do Godot, para criar no PC as ilhas fixas e
## guardá-las no banco pelas rotas de `/v1/editor`. Como o visualizador do F1, é
## uma janela do sistema (`force_native`) por cima do jogo, que usa a sessão de
## quem está logado nele.

const TITLE := "Ecobeast: editor de ilhas"
const WINDOW_SIZE := Vector2i(1600, 900)
const MIN_SIZE := Vector2i(1280, 720)
const FONT_SIZE := 16
const SIDE_WIDTH := 340.0
const NO_SESSION := "Entre no jogo para usar o editor."
const EDITOR_OFF := "O editor está desligado neste servidor. Ponha o seu id em MAP_EDITOR_USER_IDS no .env do servidor."
const UNSAVED_QUESTION := "Salvar as mudanças?"
const DISCARD := &"discard"

## A resposta à pergunta de salvar: "save", "discard" ou "cancel".
signal _unsaved_answered(answer: String)
## A resposta à pergunta de apagar.
signal _delete_answered(confirmed: bool)

var _blocked: VBoxContainer
var _blocked_label: Label
var _editor: VBoxContainer
var _name_edit: LineEdit
var _status_label: Label
var _message_label: Label
var _save_button: Button
var _side: VBoxContainer
var _list: IslandList
var _new_panel: NewIslandPanel
var _canvas: EditorCanvas
var _hover_label: Label
var _unsaved_dialog: ConfirmationDialog
var _confirm_dialog: ConfirmationDialog

var _draft: IslandDraft = null
var _status := ""
var _dirty := false
var _generator_loaded := false
var _busy := false


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
	_build()


func _ready() -> void:
	var screen := DisplayServer.screen_get_usable_rect(get_tree().root.current_screen)
	position = screen.position + Vector2i((Vector2(screen.size - size) / 2.0).round())
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


## Fecha a janela, perguntando antes se há mudanças não salvas.
func close() -> void:
	if await _resolve_unsaved():
		hide()


func _on_visibility_changed() -> void:
	if visible:
		_refresh_list()


# --- Ilhas ---------------------------------------------------------------------

func _refresh_list() -> void:
	if Api.session == null:
		_show_blocked(NO_SESSION)
		return
	var response: ApiResponse = await EditorApi.list_islands()
	if response.code == EditorApi.NOT_FOUND or response.code == EditorApi.FORBIDDEN:
		_show_blocked(EDITOR_OFF)
		return
	if not response.ok:
		_show_blocked(response.error)
		return
	_blocked.visible = false
	_editor.visible = true
	_list.set_islands(DictFields.get_array(response.data, "islands"), _draft.id if _draft != null else 0)
	if not _generator_loaded:
		var params: ApiResponse = await EditorApi.generator_params()
		if params.ok:
			_new_panel.set_generator_params(params.data)
			_generator_loaded = true


func _open_island(id: int) -> void:
	if _draft != null and _draft.id == id:
		return
	if not await _resolve_unsaved():
		_list.select(_draft.id if _draft != null else 0)
		return
	_set_message("Abrindo...")
	var response: ApiResponse = await EditorApi.read_island(id)
	if not response.ok:
		_set_message(response.error, true)
		return
	_set_message("")
	_show_island(IslandDraft.from_dict(response.data), DictFields.get_string(response.data, "status"))


func _show_island(draft: IslandDraft, status: String) -> void:
	_draft = draft
	_status = status
	_name_edit.text = draft.name if draft != null else ""
	_name_edit.editable = draft != null
	_canvas.show_draft(draft)
	_set_dirty(false)
	_update_header()


func _start_new_island() -> void:
	if not await _resolve_unsaved():
		return
	_new_panel.reset()
	_list.visible = false
	_new_panel.visible = true


func _leave_new_island() -> void:
	_new_panel.visible = false
	_list.visible = true
	# Volta para a ilha de antes, ou para o mapa vazio.
	_canvas.show_draft(_draft)


func _on_preview(preview: IslandDraft) -> void:
	_canvas.show_draft(preview)
	_hover_label.text = "%d hexágonos. A ilha só é gravada ao clicar em Criar." % preview.tiles.size()


func _on_create(preview: IslandDraft) -> void:
	_new_panel.begin_create()
	var response: ApiResponse = await EditorApi.create_island(preview.to_dict())
	if not response.ok:
		_new_panel.finish_create(response.error)
		return
	_new_panel.finish_create("")
	preview.id = DictFields.get_int(response.data, "id")
	_new_panel.visible = false
	_list.visible = true
	_show_island(preview, "draft")
	_refresh_list()


func _on_delete(id: int, island_name: String) -> void:
	_confirm_dialog.dialog_text = "Apagar a ilha %s? Não dá para desfazer." % island_name
	_confirm_dialog.popup_centered()
	var confirmed: bool = await _delete_answered
	if not confirmed:
		return
	var response: ApiResponse = await EditorApi.delete_island(id)
	if not response.ok:
		_set_message(response.error, true)
		return
	if _draft != null and _draft.id == id:
		_show_island(null, "")
	_refresh_list()


# --- Salvar --------------------------------------------------------------------

## Grava o rascunho inteiro. Devolve se deu certo.
func save() -> bool:
	if _draft == null or _busy:
		return false
	_busy = true
	_save_button.disabled = true
	_set_message("Salvando...")
	var response: ApiResponse = await EditorApi.save_island(_draft.id, _draft.to_dict())
	_busy = false
	_save_button.disabled = false
	if not response.ok:
		_set_message(response.error, true)
		return false
	_set_message("Salvo.")
	_status = DictFields.get_string(response.data, "status")
	_set_dirty(false)
	_update_header()
	_refresh_list()
	return true


## Sem mudanças, segue. Com elas, pergunta: Salvar, Descartar ou Cancelar.
## Devolve se pode seguir.
func _resolve_unsaved() -> bool:
	if not _dirty or _draft == null:
		return true
	_unsaved_dialog.popup_centered()
	var answer: String = await _unsaved_answered
	if answer == "save":
		return await save()
	if answer == "discard":
		_show_island(null, "")
		return true
	return false


func _set_dirty(dirty: bool) -> void:
	_dirty = dirty
	title = TITLE + (" *" if dirty else "")


func _on_name_changed(text: String) -> void:
	if _draft == null:
		return
	_draft.name = text.strip_edges()
	_set_dirty(true)


# --- Tela ----------------------------------------------------------------------

func _update_header() -> void:
	_status_label.text = IslandList.status_name(_status) if _draft != null else "Nenhuma ilha aberta"
	_save_button.disabled = _draft == null


func _set_message(text: String, error: bool = false) -> void:
	_message_label.text = text
	_message_label.add_theme_color_override(&"font_color", UiPalette.DANGER if error else UiPalette.TEXT_SECONDARY)


func _show_blocked(message: String) -> void:
	_editor.visible = false
	_blocked.visible = true
	_blocked_label.text = message


func _on_hovered(coord: Vector2i, tile: HexTile) -> void:
	if tile == null:
		_hover_label.text = ""
		return
	_hover_label.text = "(%d, %d)  ·  %s  ·  %s" % [coord.x, coord.y, _biome_name(tile.biome), _shape_name(tile.shape)]


func _biome_name(slug: String) -> String:
	for row: Dictionary in GameData.get_rows("biomes"):
		if row.get("slug") == slug:
			return str(row.get("name", slug))
	return slug


static func _shape_name(shape: String) -> String:
	return {"flat": "Plano", "hill": "Colina", "mont": "Montanha"}.get(shape, shape)


func _on_window_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_F2:
		set_input_as_handled()
		close()
	elif key.keycode == KEY_S and key.ctrl_pressed:
		set_input_as_handled()
		save()
	elif key.keycode == KEY_TAB and not _typing():
		set_input_as_handled()
		_canvas.toggle_overview()


## Um campo de texto tem o foco: o Tab é dele.
func _typing() -> bool:
	return gui_get_focus_owner() is LineEdit


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
	var stack := Control.new()
	margin.add_child(stack)

	_blocked = VBoxContainer.new()
	_blocked.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blocked.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(_blocked)
	_blocked_label = Label.new()
	_blocked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_blocked_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blocked.add_child(_blocked_label)
	var retry := Button.new()
	retry.text = "Tentar de novo"
	retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry.pressed.connect(_refresh_list)
	_blocked.add_child(retry)

	_editor = VBoxContainer.new()
	_editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_editor.add_theme_constant_override(&"separation", 8)
	_editor.visible = false
	stack.add_child(_editor)

	var header := HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 12)
	_editor.add_child(header)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Nome da ilha"
	_name_edit.max_length = 40
	_name_edit.custom_minimum_size.x = 320.0
	_name_edit.editable = false
	_name_edit.text_changed.connect(_on_name_changed)
	header.add_child(_name_edit)
	_status_label = Label.new()
	_status_label.theme_type_variation = &"SecondaryLabel"
	header.add_child(_status_label)
	_message_label = Label.new()
	_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message_label.clip_text = true
	header.add_child(_message_label)
	_save_button = Button.new()
	_save_button.text = "Salvar (Ctrl+S)"
	_save_button.pressed.connect(save)
	header.add_child(_save_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(&"separation", 10)
	_editor.add_child(body)
	_side = VBoxContainer.new()
	_side.custom_minimum_size.x = SIDE_WIDTH
	body.add_child(_side)
	_list = IslandList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.open_requested.connect(_open_island)
	_list.new_requested.connect(_start_new_island)
	_list.delete_requested.connect(_on_delete)
	_side.add_child(_list)
	_new_panel = NewIslandPanel.new()
	_new_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_new_panel.visible = false
	_new_panel.preview_ready.connect(_on_preview)
	_new_panel.create_requested.connect(_on_create)
	_new_panel.cancelled.connect(_leave_new_island)
	_side.add_child(_new_panel)

	_canvas = EditorCanvas.new()
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.hovered.connect(_on_hovered)
	body.add_child(_canvas)

	_hover_label = Label.new()
	_hover_label.theme_type_variation = &"SecondaryLabel"
	_hover_label.text = "Roda do mouse: zoom. Botão do meio, ou espaço e o botão esquerdo: arrastar. Tab: visão de cima."
	_editor.add_child(_hover_label)

	_unsaved_dialog = ConfirmationDialog.new()
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

	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.title = TITLE
	_confirm_dialog.ok_button_text = "Apagar"
	_confirm_dialog.cancel_button_text = "Cancelar"
	_confirm_dialog.confirmed.connect(func() -> void: _delete_answered.emit(true))
	_confirm_dialog.canceled.connect(func() -> void: _delete_answered.emit(false))
	add_child(_confirm_dialog)
	_update_header()
