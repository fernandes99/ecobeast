class_name MapEditor
extends Window

const TITLE := "Ecobeast: editor de ilhas"
const WINDOW_SIZE := Vector2i(1600, 900)
const MIN_SIZE := Vector2i(1280, 720)
const FONT_SIZE := 16
const SIDE_WIDTH := 430.0
const ISLANDS_SIZE := Vector2i(460, 360)
const ICONS := "res://tools/map_editor/icons/%s.svg"
const ICON_WIDTH := 22
const NAME_WIDTH := 220.0
const SHORTCUTS := "Roda: zoom  ·  Botão do meio ou Espaço: arrastar  ·  Tab: visão de cima  ·  Ctrl+Z / Ctrl+Y: desfazer e refazer"
const NO_SESSION := "Entre no jogo para usar o editor."
const EDITOR_OFF := "O editor está desligado neste servidor. Ponha o seu id em MAP_EDITOR_USER_IDS no .env do servidor."
const UNSAVED_QUESTION := "Salvar as mudanças?"
const DISCARD := &"discard"

signal _unsaved_answered(answer: String)
signal _delete_answered(confirmed: bool)
signal _publish_answered(confirmed: bool)
signal _type_block_answered(confirmed: bool)

var _blocked: VBoxContainer
var _blocked_label: Label
var _editor: VBoxContainer
var _name_edit: LineEdit
var _status_label: Label
var _message_label: Label
var _save_button: Button
var _publish_button: Button
var _islands_button: Button
var _story_button: Button
var _story_line := StoryLineView.new()
var _interior_editor := InteriorEditor.new()
var _interiors_button: Button
var _scene_timeline := SceneTimeline.new()
var _islands_popup: PopupPanel
var _undo_button: Button
var _redo_button: Button
var _layers_button: Button
var _cut_button: Button
var _layers_popup: PopupPanel
var _tools_scroll: ScrollContainer
var _object_bar: ObjectBar
var _areas_check: CheckButton
var _actions_check: CheckButton
var _blocks_check: CheckButton
var _contour_check: CheckButton
var _motion_check: CheckButton
var _low_processor_before := false
var _publish_dialog: ConfirmationDialog
var _type_block_dialog: ConfirmationDialog
var _side: VBoxContainer
var _list: IslandList
var _new_panel: NewIslandPanel
var _tools: EditorTools
var _history: EditorHistory
var _canvas: EditorCanvas
var _hover_label: Label
var _unsaved_dialog: ConfirmationDialog
var _confirm_dialog: ConfirmationDialog

var _draft: IslandDraft = null
var _status := ""
var _home := false
var _home_check: CheckBox
var _dirty := false
var _saved_version := 0
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
	# Os painéis de Ilhas e Camadas abrem dentro da janela, perto do botão.
	gui_embed_subwindows = true
	_build()


func _ready() -> void:
	var screen := DisplayServer.screen_get_usable_rect(get_tree().root.current_screen)
	position = screen.position + Vector2i((Vector2(screen.size - size) / 2.0).round())
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func close() -> void:
	if _interior_editor.visible:
		if await _interior_editor.resolve_unsaved(ask_unsaved):
			hide()
		return
	if await _resolve_unsaved():
		hide()


## Pergunta se salva as mudanças: "save", "discard" ou "cancel".
func ask_unsaved() -> String:
	_unsaved_dialog.popup_centered()
	var answer: String = await _unsaved_answered
	return answer


## O modo Interiores (interiors/03) troca o conteúdo da janela.
func _show_interiors() -> void:
	if not await _resolve_unsaved():
		return
	_editor.visible = false
	_interior_editor.visible = true
	_interior_editor.open()


func _show_islands() -> void:
	if not await _interior_editor.resolve_unsaved(ask_unsaved):
		return
	_interior_editor.visible = false
	_editor.visible = true


func _on_visibility_changed() -> void:
	if visible:
		_low_processor_before = OS.low_processor_usage_mode
		_refresh_list()
		_apply_motion()
	else:
		HexMapView.animated = true
		OS.low_processor_usage_mode = _low_processor_before


## As animações do mapa desligadas (editor-performance/01): o vento, a água e a fumaça
## param, e o Godot só redesenha quando algo muda, até o editor fechar.
func _apply_motion() -> void:
	var on := _motion_check.button_pressed
	HexMapView.animated = on
	OS.low_processor_usage_mode = _low_processor_before or not on


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
	_editor.visible = not _interior_editor.visible
	_load_interior_list()
	_list.set_islands(DictFields.get_array(response.data, "islands"), _draft.id if _draft != null else 0)
	if not _generator_loaded:
		var params: ApiResponse = await EditorApi.generator_params()
		if params.ok:
			_new_panel.set_generator_params(params.data)
			_tools.detail_chance = _new_panel.detail_chance()
			_generator_loaded = true


func _load_interior_list() -> void:
	var response: ApiResponse = await EditorApi.list_interiors()
	if response.ok:
		_tools.object_panel.set_interiors(DictFields.get_array(response.data, "interiors"))


func _open_island(id: int) -> void:
	_islands_popup.hide()
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
	_home = DictFields.get_bool(response.data, "home")
	_update_header()


func _show_island(draft: IslandDraft, status: String) -> void:
	_draft = draft
	_status = status
	_home = false
	_name_edit.text = draft.name if draft != null else ""
	_name_edit.editable = draft != null
	_canvas.selected_action = -1
	_canvas.selected_npc = -1
	_canvas.selected_trail = -1
	_canvas.selected_wall = -1
	_canvas.show_draft(draft)
	_tools.set_draft(draft)
	_history.reset(draft)
	_mark_saved()
	_update_header()


func _start_new_island() -> void:
	if not await _resolve_unsaved():
		return
	_islands_popup.hide()
	_new_panel.reset()
	_set_tools_visible(false)
	_new_panel.visible = true


func _leave_new_island() -> void:
	_new_panel.visible = false
	_set_tools_visible(true)
	_canvas.show_draft(_draft)


func _set_tools_visible(on: bool) -> void:
	_tools_scroll.visible = on
	_tools.tool_column.visible = on


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
	_set_tools_visible(true)
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


func save() -> bool:
	if _draft == null or _busy:
		return false
	_busy = true
	_save_button.disabled = true
	_set_message("Salvando...")
	var clipped := _draft.clip_trails()
	_tools.finish_fence(_draft)
	var clipped_walls := _draft.clip_walls()
	var clipped_bridges := _draft.clip_bridges()
	if clipped_walls > 0:
		_tools.fence_panel.refresh()
		_canvas.selected_wall = _tools.fence_panel.selected
		_canvas.refresh_walls()
	if clipped > 0:
		_tools.path_panel.refresh()
		_canvas.selected_trail = _tools.path_panel.selected
		_canvas.refresh_trails()
	var response: ApiResponse = await EditorApi.save_island(_draft.id, _draft.to_dict())
	_busy = false
	_save_button.disabled = false
	if not response.ok:
		_set_message(response.error, true)
		return false
	var message := "Salvo."
	if clipped > 0:
		message += " %d caminho(s) passavam fora da ilha e foram cortados." % clipped
	if clipped_walls > 0:
		message += " %d parede(s) passavam fora da ilha e foram cortadas." % clipped_walls
	if clipped_bridges > 0:
		message += " %d ponte(s) tinham uma ponta fora da terra e foram apagadas." % clipped_bridges
	var stale := ScenePanel.stale_warnings(_draft)
	if not stale.is_empty():
		message += " " + " ".join(stale)
	_set_message(message, not stale.is_empty())
	_status = DictFields.get_string(response.data, "status")
	_mark_saved()
	_update_header()
	_refresh_list()
	return true


func _resolve_unsaved() -> bool:
	if not _dirty or _draft == null:
		return true
	var answer := await ask_unsaved()
	if answer == "save":
		return await save()
	if answer == "discard":
		_show_island(null, "")
		return true
	return false


func _mark_saved() -> void:
	_saved_version = _history.version()
	_update_dirty()


func _update_dirty() -> void:
	_dirty = _draft != null and _history.version() != _saved_version
	title = TITLE + (" *" if _dirty else "")
	_update_header()


func publish() -> void:
	if _draft == null or _busy:
		return
	if _dirty:
		_set_message("Salve antes de publicar.", true)
		return
	_publish_dialog.dialog_text = "Publicar a ilha %s?\nEla passa a valer para o jogo quando a islands existir." % _draft.name
	_publish_dialog.popup_centered()
	var confirmed: bool = await _publish_answered
	if not confirmed:
		return
	_busy = true
	_update_header()
	_set_message("Publicando...")
	var response: ApiResponse = await EditorApi.publish_island(_draft.id)
	_busy = false
	if not response.ok:
		_set_message(response.error, true)
		_update_header()
		return
	_set_message("Publicada.")
	_status = DictFields.get_string(response.data, "status")
	_update_header()
	_refresh_list()


func _set_home(on: bool) -> void:
	if _draft == null or _busy:
		return
	_busy = true
	_update_header()
	var response: ApiResponse = await EditorApi.set_island_home(_draft.id, on)
	_busy = false
	if response.ok:
		_home = DictFields.get_bool(response.data, "home")
		_set_message("Esta ilha é a casa do jogador." if _home else "Esta ilha deixou de ser a casa do jogador.")
	else:
		_set_message(response.error, true)
	_update_header()


func _on_name_changed(text: String) -> void:
	if _draft == null:
		return
	var before := _draft.name
	_draft.name = text.strip_edges()
	_history.record_rename(before, _draft.name)
	_update_dirty()


func _can_paint() -> bool:
	return _draft != null and not _new_panel.visible


func _on_stroke_started(coord: Vector2i, secondary: bool) -> void:
	if not _can_paint():
		return
	_tools.pointer = _canvas.pointer_flat()
	if _tools.tool == EditorTools.Tool.FENCE:
		_tools.fence_click(_draft, _tools.pointer, secondary)
		_canvas.set_fence_mouse(_tools.pointer)
		return
	if _tools.tool == EditorTools.Tool.BRIDGE:
		_tools.bridge_click(_draft, _tools.pointer, secondary)
		_canvas.set_fence_mouse(_tools.pointer)
		return
	_tools.begin_stroke(_draft, secondary)
	_paint(coord)


func _paint(coord: Vector2i) -> void:
	if not _can_paint() or _tools.tool == EditorTools.Tool.FENCE:
		return
	_tools.pointer = _canvas.pointer_flat()
	var changed := _tools.paint(_draft, coord)
	if changed.is_empty():
		return
	if _tools.paints_marks():
		_canvas.refresh_marks(changed)
	elif _tools.tool == EditorTools.Tool.OBJECT or _tools.tool == EditorTools.Tool.BLOCKS:
		_canvas.refresh_props_at(changed)
	elif _tools.tool == EditorTools.Tool.VEGETATION:
		_canvas.refresh_props_at(changed)
	elif _tools.tool == EditorTools.Tool.NPC:
		_canvas.refresh_npcs()
	elif _tools.tool == EditorTools.Tool.STAMP:
		if _tools.stamp_panel.mode == StampPanel.Mode.SELECT:
			_canvas.refresh_brush()
			return
		_canvas.update_tiles(changed)
		_canvas.refresh_props()
	elif _tools.tool == EditorTools.Tool.REMOVE:
		_canvas.refresh_props_at(changed)
		_canvas.refresh_npcs()
	elif _tools.tool == EditorTools.Tool.ERASER:
		_canvas.refresh_props_at(changed)
	else:
		_canvas.update_tiles(changed)
	title = TITLE + " *"


## Arrastando a peça solta escolhida (free-props/03) ou desenhando um caminho
## (free-trails/04).
func _on_pointer_dragged(flat: Vector2) -> void:
	if not _can_paint():
		return
	if _tools.tool == EditorTools.Tool.PATH:
		var piece := _tools.extend_path(_draft, flat)
		if piece != null:
			_canvas.refresh_trail_piece(piece)
			title = TITLE + " *"
		return
	if not _tools.is_moving():
		return
	var moved := _tools.drag(_draft, flat)
	if moved.is_empty():
		return
	_canvas.refresh_props_at(moved)
	_place_object_bar()
	title = TITLE + " *"


func _on_tools_edited(step: EditorHistory.Step, merge: bool) -> void:
	_history.record(step, merge)
	_canvas.refresh_marks()
	_canvas.refresh_props()
	_canvas.refresh_trails()
	_canvas.selected_wall = _tools.fence_panel.selected
	_canvas.refresh_walls()
	_canvas.selected_bridge = _tools.bridge_panel.selected
	_canvas.refresh_bridges()
	_canvas.refresh_npcs()
	_update_dirty()
	_place_object_bar()


func _on_area_delete(key: int, area_name: String) -> void:
	_confirm_dialog.dialog_text = "Apagar a área %s? Os hexágonos dela ficam sem área." % area_name
	_confirm_dialog.popup_centered()
	var confirmed: bool = await _delete_answered
	if confirmed:
		_tools.area_panel.delete_area(key)


func _on_brush_changed() -> void:
	_canvas.editing_prop_block = _tools.object_panel.editing_blocks and _tools.object_panel.selected_prop >= 0
	_canvas.all_block_points = _tools.tool == EditorTools.Tool.BLOCKS
	_canvas.refresh_brush()
	_place_object_bar()
	if _canvas.show_zones != (_tools.tool == EditorTools.Tool.ZONE):
		_canvas.show_zones = _tools.tool == EditorTools.Tool.ZONE
	if _tools.tool == EditorTools.Tool.ACTION and not _actions_check.button_pressed:
		_actions_check.button_pressed = true
	elif _tools.tool == EditorTools.Tool.AREA and not _areas_check.button_pressed:
		_areas_check.button_pressed = true
	if (_tools.object_panel.editing_blocks or _tools.tool == EditorTools.Tool.BLOCKS) and not _blocks_check.button_pressed:
		_blocks_check.button_pressed = true


func _on_layers_toggled(_on: bool) -> void:
	_canvas.set_layers(_areas_check.button_pressed, _actions_check.button_pressed)
	_canvas.set_blocks(_blocks_check.button_pressed)


func _on_stroke_ended() -> void:
	if not _can_paint() or _tools.tool == EditorTools.Tool.FENCE:
		return
	_history.record(_tools.end_stroke(_draft))
	if _tools.tool == EditorTools.Tool.PATH:
		_canvas.refresh_trails()
	_update_dirty()


func _on_history_applied(coords: Array[Vector2i]) -> void:
	_canvas.update_tiles(coords)
	_canvas.refresh_marks()
	_canvas.refresh_props()
	_tools.path_panel.refresh()
	_canvas.selected_trail = _tools.path_panel.selected
	_canvas.refresh_trails()
	_tools.fence_panel.refresh()
	_canvas.selected_wall = _tools.fence_panel.selected
	_canvas.refresh_walls()
	_tools.bridge_panel.refresh()
	_canvas.selected_bridge = _tools.bridge_panel.selected
	_canvas.refresh_bridges()
	_canvas.refresh_npcs()
	_tools.refresh_panels()
	if _name_edit.text.strip_edges() != _draft.name:
		_name_edit.text = _draft.name
	_update_dirty()
	_place_object_bar()


func _undo() -> void:
	if _draft != null:
		_history.undo()


func _redo() -> void:
	if _draft != null:
		_history.redo()


func _update_header() -> void:
	_status_label.text = IslandList.status_name(_status) if _draft != null else "Nenhuma ilha aberta"
	_tools.scene_panel.set_published(_draft != null and (_status == "published" or _status == "changed"))
	_save_button.disabled = _draft == null or _busy
	_publish_button.disabled = _draft == null or _busy or _dirty or _status == "published"
	_publish_button.tooltip_text = "Salve antes de publicar." if _dirty else "Confere a ilha e a deixa pronta para o jogo."
	var published := _draft != null and _draft.id > 0 and (_status == "published" or _status == "changed")
	_home_check.set_pressed_no_signal(_home)
	_tools.scene_panel.home = _home
	_home_check.disabled = not published or _busy
	_home_check.tooltip_text = "O jogo abre nesta ilha. Só uma ilha é a casa." if published else "Publique a ilha primeiro."
	_undo_button.disabled = _draft == null or not _history.can_undo()
	_redo_button.disabled = _draft == null or not _history.can_redo()


func _set_message(text: String, error: bool = false) -> void:
	_message_label.text = text
	_message_label.add_theme_color_override(&"font_color", UiPalette.DANGER if error else UiPalette.TEXT_SECONDARY)


func _show_blocked(message: String) -> void:
	_editor.visible = false
	_blocked.visible = true
	_blocked_label.text = message


func _on_hovered(coord: Vector2i, tile: HexTile) -> void:
	if tile == null:
		_hover_label.text = SHORTCUTS
		return
	var text := "(%d, %d)  ·  %s  ·  Altura %d" % [coord.x, coord.y, _biome_name(tile.biome), tile.height]
	if not tile.ground.is_empty():
		text += "  ·  %s" % _ground_name(tile.ground)
	_hover_label.text = text


func _ground_name(slug: String) -> String:
	for row: Dictionary in GameData.get_rows("ground_types"):
		if row.get("slug") == slug:
			return str(row.get("name", slug))
	return slug


func _biome_name(slug: String) -> String:
	for row: Dictionary in GameData.get_rows("biomes"):
		if row.get("slug") == slug:
			return str(row.get("name", slug))
	return slug


func _on_window_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_F2:
		set_input_as_handled()
		close()
	elif _interior_editor.visible:
		if _interior_editor.handle_input(key):
			set_input_as_handled()
	elif key.keycode == KEY_S and key.ctrl_pressed:
		set_input_as_handled()
		save()
	elif _typing():
		# O campo de texto tem o seu próprio Tab, Ctrl+Z e números.
		return
	elif key.keycode == KEY_TAB:
		set_input_as_handled()
		_canvas.toggle_overview()
	elif key.keycode == KEY_H and not key.ctrl_pressed:
		set_input_as_handled()
		toggle_height_cut()
	elif key.ctrl_pressed and (key.keycode == KEY_Y or (key.keycode == KEY_Z and key.shift_pressed)):
		set_input_as_handled()
		_redo()
	elif key.ctrl_pressed and key.keycode == KEY_Z:
		set_input_as_handled()
		_undo()
	elif _tool_key(key):
		set_input_as_handled()
	elif key.keycode >= KEY_1 and key.keycode < KEY_1 + EditorTools.GROUPS.size() and not key.ctrl_pressed:
		set_input_as_handled()
		_tools.press_group_key(key.keycode - KEY_1)
	elif key.keycode == KEY_BRACKETLEFT:
		set_input_as_handled()
		_tools.set_radius(_tools.radius - 1)
	elif key.keycode == KEY_BRACKETRIGHT:
		set_input_as_handled()
		_tools.set_radius(_tools.radius + 1)


## Enter termina a cerca em desenho; Esc desiste dela ou solta a escolhida; Delete apaga.
func _fence_key(key: InputEventKey) -> bool:
	var handled := false
	if key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
		handled = _tools.drawing_fence()
		_tools.finish_fence(_draft)
	elif key.keycode == KEY_ESCAPE:
		handled = _tools.drawing_fence() or _tools.fence_panel.selected >= 0
		if _tools.drawing_fence():
			_tools.cancel_fence()
		else:
			_tools.fence_panel.select(-1)
	elif key.keycode == KEY_DELETE or key.keycode == KEY_BACKSPACE:
		handled = _tools.fence_panel.selected >= 0
		_tools.fence_panel.delete_selected()
	if handled:
		_canvas.refresh_brush()
	return handled


## Esc desiste da ponte em desenho ou solta a escolhida; Delete apaga a escolhida.
func _bridge_key(key: InputEventKey) -> bool:
	var handled := false
	if key.keycode == KEY_ESCAPE:
		handled = _tools.drawing_bridge() or _tools.bridge_panel.selected >= 0
		if _tools.drawing_bridge():
			_tools.cancel_bridge()
		else:
			_tools.bridge_panel.select(-1)
	elif key.keycode == KEY_DELETE or key.keycode == KEY_BACKSPACE:
		handled = _tools.bridge_panel.selected >= 0
		_tools.bridge_panel.delete_selected()
	if handled:
		_canvas.refresh_brush()
	return handled


## As teclas que dependem da ferramenta: alturas, a peça escolhida e o foco da área.
func _tool_key(key: InputEventKey) -> bool:
	if _draft == null or key.ctrl_pressed:
		return false
	if key.shift_pressed and key.keycode >= KEY_0 and key.keycode <= mini(KEY_9, KEY_0 + HexTile.MAX_HEIGHT):
		return _tools.pick_height_key(key.keycode - KEY_0)
	if _tools.tool == EditorTools.Tool.AREA and key.keycode == KEY_F:
		_tools.area_panel.toggle_focus()
		return true
	if _tools.tool == EditorTools.Tool.STAMP and key.keycode == KEY_M:
		_tools.stamp_panel.toggle_mirror()
		return true
	if _tools.tool == EditorTools.Tool.SCENES and key.keycode == KEY_ESCAPE and _tools.scene_panel.is_picking():
		_tools.scene_panel.cancel_pick()
		return true
	if _tools.tool == EditorTools.Tool.QUESTS and key.keycode == KEY_ESCAPE and _tools.quest_panel.picking:
		_tools.quest_panel.cancel_pick()
		return true
	if _tools.tool == EditorTools.Tool.NPC and _tools.npc_panel.selected >= 0:
		if key.keycode == KEY_DELETE or key.keycode == KEY_BACKSPACE:
			_tools.npc_panel.delete_selected()
			return true
		if key.keycode == KEY_ESCAPE:
			_tools.npc_panel.select(-1)
			return true
	if _tools.tool == EditorTools.Tool.FENCE and _fence_key(key):
		return true
	if _tools.tool == EditorTools.Tool.BRIDGE and _bridge_key(key):
		return true
	if _tools.tool == EditorTools.Tool.PATH and _tools.path_panel.selected >= 0:
		if key.keycode == KEY_DELETE or key.keycode == KEY_BACKSPACE:
			_tools.path_panel.delete_selected()
			return true
		if key.keycode == KEY_ESCAPE:
			_tools.path_panel.select(-1)
			return true
	var objects := _tools.object_panel
	if _tools.tool != EditorTools.Tool.OBJECT and _tools.tool != EditorTools.Tool.BLOCKS:
		return false
	if objects.drawing and (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER or key.keycode == KEY_ESCAPE):
		if key.keycode == KEY_ESCAPE:
			objects.cancel_line()
		else:
			objects.finish_line()
		_canvas.refresh_brush()
		return true
	if _tools.tool == EditorTools.Tool.BLOCKS:
		if key.keycode == KEY_ESCAPE and objects.selected_prop >= 0:
			objects.edit_blocks_of(-1)
			return true
		return false
	if objects.editing_blocks and key.keycode == KEY_ESCAPE:
		objects.toggle_blocks()
		return true
	match key.keycode:
		KEY_LEFT:
			objects.change_variant(-1)
		KEY_RIGHT:
			objects.change_variant(1)
		KEY_M:
			objects.toggle_mirror()
		KEY_DELETE, KEY_BACKSPACE:
			if objects.selected_prop < 0:
				return false
			objects.delete_selected()
		KEY_ESCAPE:
			if objects.selected_prop < 0:
				return false
			objects.select_prop(-1)
		_:
			return false
	return true


func _typing() -> bool:
	return gui_get_focus_owner() is LineEdit or gui_get_focus_owner() is TextEdit


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
	stack.add_child(_story_line)
	_interior_editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_interior_editor.visible = false
	_interior_editor.islands_requested.connect(_show_islands)
	_interior_editor.interiors_changed.connect(func(rows: Array) -> void: _tools.object_panel.set_interiors(rows))
	stack.add_child(_interior_editor)
	_story_line.scene_requested.connect(_open_from_story_line)

	var header := HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 8)
	_editor.add_child(header)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Nome da ilha"
	_name_edit.max_length = 40
	_name_edit.custom_minimum_size.x = NAME_WIDTH
	_name_edit.editable = false
	_name_edit.text_changed.connect(_on_name_changed)
	header.add_child(_name_edit)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_islands_button = header_button("Ilhas", "islands", "As ilhas: abrir, criar e apagar.")
	_islands_button.pressed.connect(_open_islands)
	header.add_child(_islands_button)
	_story_button = header_button("", "scene", "Linha da história: todas as cenas, ligadas pelos Marcos, com os avisos.")
	_story_button.pressed.connect(func() -> void: _story_line.open(_list.island_names()))
	header.add_child(_story_button)
	_interiors_button = header_button("", "object", "Interiores: as salas dos prédios, o lado de dentro do Refúgio e das casas.")
	_interiors_button.pressed.connect(_show_interiors)
	header.add_child(_interiors_button)
	_undo_button = header_button("", "undo", "Desfazer (Ctrl+Z)")
	_undo_button.pressed.connect(_undo)
	header.add_child(_undo_button)
	_redo_button = header_button("", "redo", "Refazer (Ctrl+Y)")
	_redo_button.pressed.connect(_redo)
	header.add_child(_redo_button)
	_cut_button = header_button("", "height", "")
	_cut_button.toggle_mode = true
	_cut_button.pressed.connect(toggle_height_cut)
	header.add_child(_cut_button)
	_refresh_cut_button.call_deferred()
	_layers_button = header_button("", "eye", "Camadas: mostrar ou esconder áreas, ações, bloqueio, contorno e animações.")
	_layers_button.pressed.connect(_open_layers)
	header.add_child(_layers_button)
	_save_button = Button.new()
	_save_button.text = "Salvar"
	_save_button.tooltip_text = "Ctrl+S"
	_save_button.focus_mode = Control.FOCUS_NONE
	_save_button.pressed.connect(save)
	header.add_child(_save_button)
	_publish_button = Button.new()
	_publish_button.text = "Publicar"
	_publish_button.theme_type_variation = &"OutlineButton"
	_publish_button.focus_mode = Control.FOCUS_NONE
	_publish_button.pressed.connect(publish)
	header.add_child(_publish_button)
	_home_check = CheckBox.new()
	_home_check.text = "Casa do jogador"
	_home_check.focus_mode = Control.FOCUS_NONE
	_home_check.toggled.connect(_set_home)
	header.add_child(_home_check)

	_layers_popup = _popup_panel()
	var layers := VBoxContainer.new()
	layers.add_theme_constant_override(&"separation", 4)
	_layers_popup.add_child(layers)
	_areas_check = _layer_check("Áreas", true)
	layers.add_child(_areas_check)
	_actions_check = _layer_check("Ações", true)
	layers.add_child(_actions_check)
	_blocks_check = _layer_check("Bloqueios", true)
	layers.add_child(_blocks_check)
	_contour_check = CheckButton.new()
	_contour_check.text = "Contorno"
	_contour_check.button_pressed = HexMapView.contour_visible
	_contour_check.focus_mode = Control.FOCUS_NONE
	_contour_check.toggled.connect(func(on: bool) -> void: _canvas.set_contour(on))
	layers.add_child(_contour_check)
	_motion_check = CheckButton.new()
	_motion_check.text = "Animações"
	_motion_check.tooltip_text = "O vento, a água e a fumaça do mapa. Desligadas, o editor só redesenha quando algo muda."
	_motion_check.button_pressed = ViewSettings.editor_motion()
	_motion_check.focus_mode = Control.FOCUS_NONE
	_motion_check.toggled.connect(_on_motion_toggled)
	layers.add_child(_motion_check)

	_islands_popup = _popup_panel()
	_list = IslandList.new()
	_list.custom_minimum_size = ISLANDS_SIZE
	_list.open_requested.connect(_open_island)
	_list.new_requested.connect(_start_new_island)
	_list.delete_requested.connect(_on_delete)
	_islands_popup.add_child(_list)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(&"separation", 10)
	_editor.add_child(body)
	_tools = EditorTools.new()
	_tools.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tools.message.connect(func(text: String) -> void: _set_message(text, true))
	_tools.npcs_redrawn.connect(func() -> void:
		_canvas.refresh_npcs()
		_set_message("Aparência do NPC salva."))
	_tools.edited.connect(_on_tools_edited)
	_tools.area_panel.delete_requested.connect(_on_area_delete)
	_tools.area_panel.focus_changed.connect(_on_area_focus)
	_tools.action_panel.selection_changed.connect(func(index: int) -> void:
		_canvas.selected_action = index
		_canvas.refresh_brush())
	_tools.object_panel.selection_changed.connect(_on_object_selected)
	_tools.object_panel.type_block_save_requested.connect(_on_type_block_save)
	_tools.npc_panel.selection_changed.connect(func(index: int) -> void:
		_canvas.selected_npc = index
		_canvas.refresh_brush())
	_tools.scene_panel.changed.connect(func() -> void: _canvas.refresh_brush())
	_tools.scene_panel.message.connect(func(text: String, error: bool) -> void: _set_message(text, error))
	_tools.npc_panel.message.connect(func(text: String, error: bool) -> void: _set_message(text, error))
	_tools.quest_panel.changed.connect(func() -> void: _canvas.refresh_brush())
	_tools.quest_panel.message.connect(func(text: String, error: bool) -> void: _set_message(text, error))
	_tools.scene_panel.test_requested.connect(_test_scene)
	_tools.path_panel.changed.connect(func() -> void:
		_canvas.selected_trail = _tools.path_panel.selected
		_canvas.refresh_brush())
	_tools.fence_panel.changed.connect(func() -> void:
		_canvas.selected_wall = _tools.fence_panel.selected
		_canvas.refresh_brush())
	_tools.bridge_panel.changed.connect(func() -> void:
		_canvas.selected_bridge = _tools.bridge_panel.selected
		_canvas.refresh_brush())
	body.add_child(_tools.tool_column)
	_side = VBoxContainer.new()
	_side.custom_minimum_size.x = SIDE_WIDTH
	body.add_child(_side)
	_tools_scroll = ScrollContainer.new()
	_tools_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tools_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side.add_child(_tools_scroll)
	_tools_scroll.add_child(_tools)
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
	_canvas.brush = _tools.brush_coords
	_canvas.marked = _tools.marked_coords
	_canvas.scene_marks = func() -> Dictionary:
		if _tools.tool == EditorTools.Tool.SCENES:
			return _tools.scene_panel.map_marks()
		if _tools.tool == EditorTools.Tool.QUESTS:
			return _tools.quest_panel.map_marks()
		return {}
	_canvas.fence_preview = _tools.fence_points
	_canvas.bridge_preview = _tools.bridge_points
	_canvas.brush_color = func(coord: Vector2i) -> Color: return _tools.brush_color(_draft, coord)
	_canvas.block_preview = func() -> PackedVector2Array:
		var panel := _tools.object_panel
		var points := PackedVector2Array()
		if _draft == null or not panel.drawing or panel.selected_prop < 0:
			return points
		for local: Vector2i in panel.drawing_line:
			points.append(_draft.prop_flat(panel.selected_prop, local))
		return points
	for row: Dictionary in GameData.get_rows("action_types"):
		var type_id := int(row.get("id", 0))
		_canvas.action_colors[type_id] = Color.from_string(str(row.get("color_hex", "")), UiPalette.TEXT)
		_canvas.action_names[type_id] = str(row.get("name", ""))
	_canvas.stroke_started.connect(_on_stroke_started)
	_canvas.stroke_moved.connect(_paint)
	_canvas.stroke_ended.connect(_on_stroke_ended)
	_canvas.pointer_dragged.connect(_on_pointer_dragged)
	_tools.brush_changed.connect(_on_brush_changed)
	_canvas.view_changed.connect(_place_object_bar)
	var map_column := VBoxContainer.new()
	map_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_column.add_theme_constant_override(&"separation", 0)
	body.add_child(map_column)
	map_column.add_child(_canvas)
	_scene_timeline.set_steps(_tools.scene_panel.steps())
	map_column.add_child(_scene_timeline)
	_tools.scene_panel.scene_opened.connect(func() -> void:
		_scene_timeline.reset()
		_refresh_timeline())
	_tools.scene_panel.changed.connect(_refresh_timeline)
	_tools.brush_changed.connect(_refresh_timeline)
	_object_bar = ObjectBar.new(_tools.object_panel)
	_object_bar.visible = false
	_canvas.add_child(_object_bar)

	_history = EditorHistory.new()
	_history.applied.connect(_on_history_applied)
	add_child(_history)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override(&"separation", 16)
	_editor.add_child(footer)
	_hover_label = Label.new()
	_hover_label.theme_type_variation = &"SecondaryLabel"
	_hover_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hover_label.size_flags_stretch_ratio = 3.0
	_hover_label.clip_text = true
	_hover_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_hover_label.text = SHORTCUTS
	footer.add_child(_hover_label)
	_message_label = Label.new()
	_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message_label.size_flags_stretch_ratio = 2.0
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_message_label.clip_text = true
	_message_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	footer.add_child(_message_label)
	_status_label = Label.new()
	_status_label.theme_type_variation = &"BoldLabel"
	footer.add_child(_status_label)

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

	_type_block_dialog = ConfirmationDialog.new()
	_type_block_dialog.title = TITLE
	_type_block_dialog.ok_button_text = "Salvar no tipo"
	_type_block_dialog.cancel_button_text = "Cancelar"
	_type_block_dialog.confirmed.connect(func() -> void: _type_block_answered.emit(true))
	_type_block_dialog.canceled.connect(func() -> void: _type_block_answered.emit(false))
	add_child(_type_block_dialog)

	_publish_dialog = ConfirmationDialog.new()
	_publish_dialog.title = TITLE
	_publish_dialog.ok_button_text = "Publicar"
	_publish_dialog.cancel_button_text = "Cancelar"
	_publish_dialog.confirmed.connect(func() -> void: _publish_answered.emit(true))
	_publish_dialog.canceled.connect(func() -> void: _publish_answered.emit(false))
	add_child(_publish_dialog)
	_update_header()


static func header_button(text: String, icon_name: String, tip: String) -> Button:
	var button := Button.new()
	button.text = text
	button.icon = load(ICONS % icon_name) as Texture2D
	button.add_theme_constant_override(&"icon_max_width", ICON_WIDTH)
	button.tooltip_text = tip
	button.focus_mode = Control.FOCUS_NONE
	return button


func _popup_panel() -> PopupPanel:
	var panel := PopupPanel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UiPalette.SURFACE
	style.border_color = UiPalette.BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10.0)
	panel.add_theme_stylebox_override(&"panel", style)
	add_child(panel)
	return panel


func _on_motion_toggled(on: bool) -> void:
	ViewSettings.set_editor_motion(on)
	if visible:
		_apply_motion()


func _layer_check(text: String, on: bool) -> CheckButton:
	var check := CheckButton.new()
	check.text = text
	check.button_pressed = on
	check.focus_mode = Control.FOCUS_NONE
	check.toggled.connect(_on_layers_toggled)
	return check


func _open_islands() -> void:
	_popup_below(_islands_popup, _islands_button)


## O corte de altura (terrain-height/03): só visual, sem passo de desfazer.
func toggle_height_cut() -> void:
	var cut := -1 if _tools.height_cut >= 0 else HexMapView.CUT_HEIGHT
	_tools.height_cut = cut
	_canvas.set_height_cut(cut)
	_tools.object_panel.select_prop(-1)
	_refresh_cut_button()


func _refresh_cut_button() -> void:
	var cut := _tools.height_cut >= 0
	_cut_button.set_pressed_no_signal(cut)
	_cut_button.tooltip_text = ("Altura: mostrando até a %d. Clique para ver tudo (H)." if cut else "Altura: mostrando tudo. Clique para ver e editar só até a altura %d (H).") % HexMapView.CUT_HEIGHT


func _open_layers() -> void:
	_contour_check.set_pressed_no_signal(HexMapView.contour_visible)
	_popup_below(_layers_popup, _layers_button)


## Abre o painel logo abaixo do botão, alinhado pela direita, sem passar da janela.
func _popup_below(panel: PopupPanel, button: Control) -> void:
	var rect := button.get_global_rect()
	var popup_size := Vector2(panel.get_contents_minimum_size())
	var x := clampf(rect.end.x - popup_size.x, 0.0, float(size.x) - popup_size.x)
	panel.popup(Rect2i(Vector2i(Vector2(x, rect.end.y + 4.0).round()), Vector2i(popup_size.ceil())))


func _on_object_selected(_index: int) -> void:
	_canvas.selected_prop = _tools.object_panel.selected_prop
	_canvas.editing_prop_block = _tools.object_panel.editing_blocks and _tools.object_panel.selected_prop >= 0
	_canvas.refresh_brush()
	_place_object_bar()


## Salvar o padrão (free-objects/02, prop-depth-blocks/02): confirma, grava no servidor,
## troca as linhas da variante no catálogo local e avisa as ilhas com a chegada bloqueada.
func _on_type_block_save(prop_type_id: int, variant: int, lines: Array[Dictionary]) -> void:
	var type_name := str(GameData.get_row("prop_types", prop_type_id).get("name", "?"))
	if variant == GameData.ALL_VARIANTS:
		_type_block_dialog.dialog_text = "As linhas desta peça viram o bloqueio de todo %s sem ajuste, nas variantes sem padrão próprio, em todas as ilhas, também nas publicadas. Não dá para desfazer." % type_name
	else:
		_type_block_dialog.dialog_text = "As linhas desta peça viram o bloqueio de todo %s na variante %d sem ajuste, em todas as ilhas, também nas publicadas. Não dá para desfazer." % [type_name, variant]
	_type_block_dialog.popup_centered()
	if not await _type_block_answered:
		return
	_set_message("Salvando o bloqueio do tipo...")
	var body: Array = []
	for line: Dictionary in lines:
		body.append({"closed": line["closed"], "points": Array(line["points"])})
	var response := await EditorApi.save_prop_type_blocks(prop_type_id, variant, body)
	if not response.ok:
		_set_message(response.error, true)
		return
	GameData.set_prop_blocks(prop_type_id, variant, MapProp.lines_from(DictFields.get_array(response.data, "blocks")))
	_tools.object_panel.type_block_saved()
	_canvas.refresh_props()
	var blocked: Array[String] = []
	for entry: Variant in DictFields.get_array(response.data, "blocked_starts"):
		if entry is Dictionary:
			blocked.append("%s (%s)" % [DictFields.get_string(entry, "name"), "publicada" if DictFields.get_string(entry, "kind") == "published" else "rascunho"])
	if blocked.is_empty():
		_set_message("Bloqueio do tipo %s salvo." % type_name)
	else:
		_set_message("Bloqueio do tipo %s salvo. A chegada ficou bloqueada em: %s. Mova a chegada antes de salvar essas ilhas." % [type_name, ", ".join(blocked)], true)


func _place_object_bar() -> void:
	var panel := _tools.object_panel
	var rect := Rect2()
	if _draft != null and panel.selected_prop >= 0:
		rect = _canvas.prop_rect(panel.selected_prop)
	if not rect.has_area() or _tools.tool != EditorTools.Tool.OBJECT or _canvas.is_overview():
		_object_bar.visible = false
		return
	_object_bar.refresh()
	var bar_size := _object_bar.get_combined_minimum_size()
	var at := (Vector2(rect.get_center().x - bar_size.x / 2.0, rect.end.y + 6.0)).round()
	_object_bar.position = at
	_object_bar.size = bar_size
	_object_bar.visible = Rect2(Vector2.ZERO, _canvas.size).intersects(Rect2(at, bar_size))


func _on_area_focus(key: int) -> void:
	_canvas.set_area_focus(key)
	if key > 0 and not _areas_check.button_pressed:
		_areas_check.button_pressed = true


## Testar daqui (story/04): fecha o editor e toca a cena na ilha publicada, com os
## Marcos de teste, sem gravar nada.
func _test_scene(scene: StoryScene, marks: Array[String]) -> void:
	if _draft == null or Session.player == null:
		_set_message(ScenePanel.NO_PLAYER_TEXT, true)
		return
	Story.begin_test(scene, marks)
	hide()
	Router.push(&"exploration", {"island_id": _draft.id, "story_test": true})


## Uma caixa da Linha da história: abre a ilha da cena e a escolhe na ferramenta Cenas.
func _open_from_story_line(slug: String) -> void:
	var scene := Story.library.find(slug)
	if scene == null:
		return
	await _open_island(scene.island_id)
	if _draft == null or _draft.id != scene.island_id:
		return
	_tools.set_tool(EditorTools.Tool.SCENES)
	_tools.scene_panel.select_scene(slug)


## A faixa de passos aparece com a ferramenta Cenas e uma cena aberta (story/06).
func _refresh_timeline() -> void:
	var open := _tools.tool == EditorTools.Tool.SCENES and _tools.scene_panel.has_scene()
	if open != _scene_timeline.visible:
		_scene_timeline.show_scene(open)
