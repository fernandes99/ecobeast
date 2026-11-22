class_name ObjectPanel
extends VBoxContainer
## O bloco Peças do editor (map-editor/05, free-props/03, free-objects): a prévia grande
## com as variantes, os tipos de peça por categoria e busca (editor-ui/01) e, com uma
## peça escolhida, a variante, o espelho, o bloqueio, a ação e apagar dela. A barra no mapa (ObjectBar) e as teclas chamam os
## mesmos métodos.

signal edited(step: EditorHistory.Step)
signal selection_changed(index: int)
signal blocks_editing_changed(on: bool)
## "Salvar como do tipo" (free-objects/02): as linhas da peça escolhida viram as do tipo.
signal type_block_save_requested(prop_type_id: int, variant: int, lines: Array[Dictionary])

const PREVIEW_SIZE := Vector2(0.0, 120.0)
const CHIP_SIZE := Vector2(34.0, 30.0)
const GRID_COLUMNS := 4
const TILE_SIZE := Vector2(0.0, 104.0)
const THUMB_SIZE := Vector2(64.0, 60.0)
const MAX_THUMB_SCALE := 4.0
const TILE_FONT_SIZE := 13
const FIRST_CATEGORY := 1
const DIALOGUE_HEIGHT := 110.0
const DIALOGUE_COMMIT_DELAY := 0.5
const NO_RESULTS := "Nenhuma peça com esse nome."
const ACCENTS: Dictionary[String, String] = {"á": "a", "à": "a", "â": "a", "ã": "a", "ä": "a", "é": "e", "ê": "e", "è": "e", "í": "i", "î": "i", "ó": "o", "ô": "o", "õ": "o", "ò": "o", "ú": "u", "û": "u", "ü": "u", "ç": "c"}

var prop_type_id := 0
var variant := 1
var mirrored := false
var selected_prop := -1
var editing_blocks := false
## A linha de bloqueio da peça mexida por último, para Fechar ou Abrir.
var active_line := -1
## A linha nova sendo desenhada a cliques, nas coordenadas do pé, ou vazia.
var drawing := false
var drawing_line: Array[Vector2i] = []

var _draft: IslandDraft = null
var _prop_types: Array[Dictionary] = []
var _prop_buttons: Dictionary[int, Button] = {}
var _category_buttons: Dictionary[int, Button] = {}
var _category_id := FIRST_CATEGORY
var _search: LineEdit
var _grid: GridContainer
var _no_results: Label
var _preview: TextureRect
var _caption: Label
var _variant_label: Label
var _chips: HFlowContainer
var _chip_group := ButtonGroup.new()
var _mirror_button: Button
var _selected_box: VBoxContainer
var _blocks_button: Button
var _block_box: VBoxContainer
var _block_label: Label
var _close_button: Button
var _type_block_button: Button
var _action_select: OptionButton
var _action_ids: Array[int] = []
var _interior_select: OptionButton
var _interior_ids: Array[int] = []
var _dialogue_box: TextEdit
var _dialogue_timer: Timer
## A troca da fala ainda fora do desfazer, que entra meio segundo depois da última letra.
var _dialogue_step: EditorHistory.Step = null
var _syncing_dialogue := false


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	var frame := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = UiPalette.BACKGROUND_DEEP
	frame_style.set_corner_radius_all(8)
	frame_style.set_content_margin_all(8.0)
	frame.add_theme_stylebox_override(&"panel", frame_style)
	add_child(frame)
	_preview = TextureRect.new()
	_preview.custom_minimum_size = PREVIEW_SIZE
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(_preview)
	_caption = Label.new()
	_caption.theme_type_variation = &"BoldLabel"
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.clip_text = true
	add_child(_caption)

	_variant_label = Label.new()
	_variant_label.theme_type_variation = &"SecondaryLabel"
	add_child(_variant_label)
	_chips = HFlowContainer.new()
	_chips.add_theme_constant_override(&"h_separation", 4)
	_chips.add_theme_constant_override(&"v_separation", 4)
	add_child(_chips)

	_mirror_button = EditorTools.tool_button("Espelhar  (M)", null)
	_mirror_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mirror_button.icon = load(MapEditor.ICONS % "mirror") as Texture2D
	_mirror_button.add_theme_constant_override(&"icon_max_width", MapEditor.ICON_WIDTH)
	_mirror_button.toggled.connect(_on_mirror_toggled)
	add_child(_mirror_button)

	_selected_box = VBoxContainer.new()
	_selected_box.add_theme_constant_override(&"separation", 6)
	add_child(_selected_box)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 6)
	_selected_box.add_child(buttons)
	_blocks_button = EditorTools.tool_button("Editar bloqueio", null)
	_blocks_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_blocks_button.icon = load(MapEditor.ICONS % "lock") as Texture2D
	_blocks_button.add_theme_constant_override(&"icon_max_width", MapEditor.ICON_WIDTH)
	_blocks_button.tooltip_text = "Mostra os pontos das linhas de bloqueio da peça para editar."
	_blocks_button.toggled.connect(_on_blocks_toggled)
	buttons.add_child(_blocks_button)
	var delete := Button.new()
	delete.text = "Apagar"
	delete.icon = load(MapEditor.ICONS % "trash") as Texture2D
	delete.add_theme_constant_override(&"icon_max_width", MapEditor.ICON_WIDTH)
	delete.tooltip_text = "Apagar a peça (Delete)"
	delete.theme_type_variation = &"DangerButton"
	delete.focus_mode = Control.FOCUS_NONE
	delete.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete.pressed.connect(delete_selected)
	buttons.add_child(delete)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override(&"separation", 6)
	_selected_box.add_child(action_row)
	var action_title := Label.new()
	action_title.text = "Ação"
	action_row.add_child(action_title)
	_action_select = OptionButton.new()
	_action_select.focus_mode = Control.FOCUS_NONE
	_action_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_select.tooltip_text = "Acontece quando o Domador toca na peça e encosta no bloqueio dela."
	_action_select.add_item("Nenhuma")
	_action_ids.append(0)
	for row: Dictionary in GameData.get_rows("action_types"):
		_action_select.add_item(str(row.get("name", "")))
		_action_ids.append(int(row.get("id", 0)))
	_action_select.item_selected.connect(_on_action_selected)
	action_row.add_child(_action_select)
	var interior_row := HBoxContainer.new()
	interior_row.add_theme_constant_override(&"separation", 6)
	_selected_box.add_child(interior_row)
	var interior_title := Label.new()
	interior_title.text = "Sala"
	interior_row.add_child(interior_title)
	_interior_select = OptionButton.new()
	_interior_select.focus_mode = Control.FOCUS_NONE
	_interior_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_interior_select.tooltip_text = "Tocar na peça abre esta sala, no lugar da tela da ação (modo Interiores)."
	_interior_select.item_selected.connect(_on_interior_selected)
	interior_row.add_child(_interior_select)
	set_interiors([])
	var dialogue_title := Label.new()
	dialogue_title.text = "Fala (opcional) · cada parágrafo é uma fala"
	dialogue_title.theme_type_variation = &"SecondaryLabel"
	_selected_box.add_child(dialogue_title)
	_dialogue_box = TextEdit.new()
	_dialogue_box.custom_minimum_size.y = DIALOGUE_HEIGHT
	_dialogue_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_dialogue_box.placeholder_text = "Para o norte: a vila.

Para o sul: a praia."
	_dialogue_box.tooltip_text = "Tocar na peça mostra as falas; depois, abre a sala ou roda a ação, se tiver."
	_dialogue_box.text_changed.connect(_on_dialogue_changed)
	_dialogue_box.focus_exited.connect(_commit_dialogue)
	_selected_box.add_child(_dialogue_box)
	_dialogue_timer = Timer.new()
	_dialogue_timer.one_shot = true
	_dialogue_timer.wait_time = DIALOGUE_COMMIT_DELAY
	_dialogue_timer.timeout.connect(_commit_dialogue)
	add_child(_dialogue_timer)
	_block_box = VBoxContainer.new()
	_block_box.add_theme_constant_override(&"separation", 6)
	_selected_box.add_child(_block_box)
	_block_label = Label.new()
	_block_label.theme_type_variation = &"SecondaryLabel"
	_block_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_block_box.add_child(_block_label)
	var line_row := HBoxContainer.new()
	line_row.add_theme_constant_override(&"separation", 6)
	_block_box.add_child(line_row)
	line_row.add_child(_text_button("Nova linha", "Desenha uma linha a cliques: Enter ou o botão direito termina, e clicar no primeiro ponto fecha.", start_line))
	_close_button = _text_button("Fechar linha", "Liga o último ponto ao primeiro da linha mexida por último, ou desfaz isso.", toggle_closed)
	line_row.add_child(_close_button)
	var type_row := HBoxContainer.new()
	type_row.add_theme_constant_override(&"separation", 6)
	_block_box.add_child(type_row)
	_type_block_button = _text_button("Usar o padrão", "Volta a peça para as linhas padrão da variante dela.", use_type_block)
	type_row.add_child(_type_block_button)
	var save_row := HBoxContainer.new()
	save_row.add_theme_constant_override(&"separation", 6)
	_block_box.add_child(save_row)
	save_row.add_child(_text_button("Salvar para esta variante", "As linhas desta peça viram o padrão desta variante do tipo, em todas as ilhas. Não se desfaz.", request_type_save.bind(false)))
	save_row.add_child(_text_button("Salvar para todas", "As linhas desta peça viram o padrão das variantes do tipo sem padrão próprio, em todas as ilhas. Não se desfaz.", request_type_save.bind(true)))
	var release := Button.new()
	release.text = "Voltar à peça nova  (Esc)"
	release.focus_mode = Control.FOCUS_NONE
	release.pressed.connect(select_prop.bind(-1))
	_selected_box.add_child(release)

	var types_title := Label.new()
	types_title.text = "Peças"
	EditorTools.section_title(types_title)
	add_child(types_title)
	_search = LineEdit.new()
	_search.placeholder_text = "Buscar peça"
	_search.clear_button_enabled = true
	_search.text_changed.connect(search)
	add_child(_search)
	var categories := HFlowContainer.new()
	categories.add_theme_constant_override(&"h_separation", 4)
	categories.add_theme_constant_override(&"v_separation", 4)
	add_child(categories)
	var category_group := ButtonGroup.new()
	category_group.allow_unpress = true
	for row: Dictionary in GameData.get_rows("prop_categories"):
		var category := int(row.get("id", 0))
		var chip := EditorTools.tool_button(str(row.get("name", "")), category_group)
		chip.alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.size_flags_horizontal = Control.SIZE_FILL
		chip.pressed.connect(open_category.bind(category))
		categories.add_child(chip)
		_category_buttons[category] = chip
	_grid = GridContainer.new()
	_grid.columns = GRID_COLUMNS
	_grid.add_theme_constant_override(&"h_separation", 4)
	_grid.add_theme_constant_override(&"v_separation", 4)
	add_child(_grid)
	_no_results = Label.new()
	_no_results.text = NO_RESULTS
	_no_results.theme_type_variation = &"SecondaryLabel"
	_no_results.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_no_results)
	var group := ButtonGroup.new()
	for row: Dictionary in GameData.get_rows("prop_types"):
		_prop_types.append(row)
		var id := int(row.get("id", 0))
		var tile := _tile(str(row.get("name", "")), PropArt.thumbnail(str(row.get("slug", "")), 1), group)
		tile.pressed.connect(pick_prop_type.bind(id))
		_grid.add_child(tile)
		_prop_buttons[id] = tile
	if not _prop_types.is_empty():
		prop_type_id = int(_prop_types[0].get("id", 0))
	open_category(FIRST_CATEGORY)
	refresh()


## Mostra as peças de uma categoria e apaga a busca.
func open_category(id: int) -> void:
	_category_id = id
	_search.text = ""
	_filter()


## Mostra as peças de todas as categorias com o texto no nome; vazio volta à categoria.
func search(text: String) -> void:
	if _search.text != text:
		_search.text = text
	_filter()


## O texto em minúsculas e sem acento, para a busca.
static func fold(text: String) -> String:
	var folded := text.strip_edges().to_lower()
	for accent: String in ACCENTS:
		folded = folded.replace(accent, ACCENTS[accent])
	return folded


func _filter() -> void:
	var query := fold(_search.text)
	var shown := 0
	for row: Dictionary in _prop_types:
		var id := int(row.get("id", 0))
		var shows := int(row.get("prop_category_id", 0)) == _category_id
		if not query.is_empty():
			shows = fold(str(row.get("name", ""))).contains(query)
		_prop_buttons[id].visible = shows
		if shows:
			shown += 1
	for category: int in _category_buttons:
		_category_buttons[category].set_pressed_no_signal(query.is_empty() and category == _category_id)
	_no_results.visible = shown == 0


func _tile(text: String, texture: Texture2D, group: ButtonGroup) -> Button:
	var tile := EditorTools.tool_button("", group)
	tile.custom_minimum_size = TILE_SIZE
	tile.tooltip_text = text
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 4.0
	box.offset_right = -4.0
	box.offset_top = 4.0
	box.offset_bottom = -4.0
	box.add_theme_constant_override(&"separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(box)
	var frame := CenterContainer.new()
	frame.custom_minimum_size = THUMB_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(frame)
	var thumb := TextureRect.new()
	thumb.texture = texture
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if texture != null:
		var art := Vector2(texture.get_width(), texture.get_height())
		var zoom := minf(minf(THUMB_SIZE.x / art.x, THUMB_SIZE.y / art.y), MAX_THUMB_SCALE)
		thumb.custom_minimum_size = (art * zoom).floor()
	frame.add_child(thumb)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = 2
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override(&"font_size", TILE_FONT_SIZE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	return tile


func set_draft(draft: IslandDraft) -> void:
	if _draft != null:
		_commit_dialogue()
	_dialogue_step = null
	_draft = draft
	select_prop(-1)


func current_draft() -> IslandDraft:
	return _draft


## Escolhe a peça e liga a edição do bloqueio dela, ou solta com -1 (a ferramenta
## Bloqueios, prop-depth-blocks/03).
func edit_blocks_of(index: int) -> void:
	select_prop(index)
	_set_editing_blocks(selected_prop >= 0)
	refresh()


## Se a linha mexida por último está fechada.
func active_line_closed() -> bool:
	if _draft == null or selected_prop < 0:
		return false
	var lines := _draft.prop_lines(selected_prop)
	return active_line >= 0 and active_line < lines.size() and bool(lines[active_line]["closed"])


func select_prop(index: int) -> void:
	_commit_dialogue()
	if _draft == null or index >= _draft.props.size():
		index = -1
	var same := index >= 0 and index == selected_prop
	selected_prop = index
	if not same:
		active_line = -1
		cancel_line()
		if index >= 0:
			_reveal_type(int(_draft.props[index].get("prop_type_id", 0)))
	_set_editing_blocks(editing_blocks and same)
	refresh()
	selection_changed.emit(selected_prop)


func refresh() -> void:
	if _draft == null or selected_prop >= _draft.props.size():
		selected_prop = -1
	var shown_type := prop_type_id
	var shown_variant := variant
	var shown_mirror := mirrored
	if selected_prop >= 0:
		var piece: Dictionary = _draft.props[selected_prop]
		shown_type = int(piece.get("prop_type_id", 0))
		shown_variant = int(piece.get("variant", 1))
		shown_mirror = bool(piece.get("mirrored", false))
	for id: int in _prop_buttons:
		_prop_buttons[id].set_pressed_no_signal(id == shown_type)
	var count := _variants(shown_type)
	_preview.texture = PropArt.icon(_slug(shown_type), shown_variant)
	_preview.flip_h = shown_mirror
	var chosen := selected_prop >= 0
	_caption.text = ("Escolhida: %s" if chosen else "Nova: %s") % _type_name(shown_type)
	_variant_label.text = "Variante %d de %d  ·  teclas ← →" % [shown_variant, count]
	_rebuild_chips(count, shown_variant)
	_mirror_button.set_pressed_no_signal(shown_mirror)
	_selected_box.visible = chosen
	_blocks_button.visible = chosen
	if chosen:
		_action_select.select(maxi(0, _action_ids.find(int(_draft.props[selected_prop].get("action_type_id", 0)))))
		_interior_select.select(maxi(0, _interior_ids.find(int(_draft.props[selected_prop].get("interior_id", 0)))))
		var text := str(_draft.props[selected_prop].get("dialogue", ""))
		if _dialogue_box.text != text:
			_syncing_dialogue = true
			_dialogue_box.text = text
			_syncing_dialogue = false
	_blocks_button.set_pressed_no_signal(editing_blocks)
	_block_box.visible = editing_blocks and chosen
	if _block_box.visible:
		var custom := _draft.prop_is_custom(selected_prop)
		var line_count := _draft.prop_lines(selected_prop).size()
		_block_label.text = "%s: %d %s. Arraste um ponto; clique numa linha para pôr um ponto; o botão direito apaga o ponto." % [
			"Bloqueio ajustado" if custom else "Bloqueio do tipo", line_count, "linha" if line_count == 1 else "linhas"]
		if drawing:
			_block_label.text = "Desenhando: %d %s. Enter ou o botão direito termina; clicar no primeiro ponto fecha; Esc desiste." % [
				drawing_line.size(), "ponto" if drawing_line.size() == 1 else "pontos"]
		_type_block_button.disabled = not custom
		var lines := _draft.prop_lines(selected_prop)
		_close_button.disabled = active_line < 0 or active_line >= lines.size() or (lines[active_line]["points"] as Array).size() < 6
		_close_button.text = "Abrir linha" if not _close_button.disabled and bool(lines[active_line]["closed"]) else "Fechar linha"


## A peça solta nova, com o pé `offset` pixels da arte a partir do centro de `coord`.
func new_prop(coord: Vector2i, offset: Vector2i) -> Dictionary:
	return {
		"prop_type_id": prop_type_id,
		"q": coord.x,
		"r": coord.y,
		"dx": offset.x,
		"dy": offset.y,
		"variant": variant,
		"mirrored": mirrored,
	}


func change_variant(delta: int) -> void:
	var piece := _selected_piece()
	if piece.is_empty():
		set_variant(wrapi(variant - 1 + delta, 0, _variants(prop_type_id)) + 1)
		return
	var count := _variants(int(piece.get("prop_type_id", 0)))
	set_variant(wrapi(int(piece.get("variant", 1)) - 1 + delta, 0, count) + 1)


func set_variant(value: int) -> void:
	var piece := _selected_piece()
	if piece.is_empty():
		variant = value
		refresh()
		return
	if int(piece.get("variant", 1)) == value:
		return
	var step := _step("Trocar a variante")
	piece["variant"] = value
	_finish(step)


func toggle_mirror() -> void:
	_on_mirror_toggled(not _mirror_button.button_pressed)


func toggle_blocks() -> void:
	_on_blocks_toggled(not editing_blocks)


## Liga e desliga a fumaça da chaminé da peça escolhida (chimney-smoke/01).
func toggle_smoke() -> void:
	if not has_smoke():
		return
	var piece := _selected_piece()
	var step := _step("Fumaça da peça")
	if bool(piece.get("no_smoke", false)):
		piece.erase("no_smoke")
	else:
		piece["no_smoke"] = true
	_finish(step)


## Se a peça escolhida é de um tipo com fumaça na chaminé.
func has_smoke() -> bool:
	var piece := _selected_piece()
	return not piece.is_empty() and HexMapView.PROP_SMOKE.has(_slug(int(piece.get("prop_type_id", 0))))


func is_smoke_on() -> bool:
	return not bool(_selected_piece().get("no_smoke", false))


func delete_selected() -> void:
	if _draft == null or selected_prop < 0:
		return
	var step := _step("Apagar peça")
	_draft.props.remove_at(selected_prop)
	select_prop(-1)
	_finish(step)


func variant_text() -> String:
	var piece := _selected_piece()
	if piece.is_empty():
		return ""
	return "%d / %d" % [int(piece.get("variant", 1)), _variants(int(piece.get("prop_type_id", 0)))]


func is_mirrored() -> bool:
	return _mirror_button.button_pressed


func pick_prop_type(id: int) -> void:
	prop_type_id = id
	variant = 1
	select_prop(-1)


func _reveal_type(id: int) -> void:
	var category := int(_row(id).get("prop_category_id", 0))
	if _category_buttons.has(category):
		open_category(category)


func _selected_piece() -> Dictionary:
	if _draft == null or selected_prop < 0:
		return {}
	return _draft.props[selected_prop]


func _on_mirror_toggled(on: bool) -> void:
	if selected_prop >= 0:
		var prop_step := _step("Espelhar peça")
		_draft.props[selected_prop]["mirrored"] = on
		_finish(prop_step)
		return
	mirrored = on
	refresh()


func _on_blocks_toggled(on: bool) -> void:
	_set_editing_blocks(on and selected_prop >= 0)
	if not editing_blocks:
		cancel_line()
	refresh()


## As linhas da peça escolhida passam a ser dela: na primeira mudança, uma cópia das
## do tipo.
func ensure_custom_block() -> Array:
	var piece: Dictionary = _draft.props[selected_prop]
	if not piece.has("block"):
		var copies: Array = []
		for line: Dictionary in GameData.get_prop_blocks(int(piece.get("prop_type_id", 0)), int(piece.get("variant", 1))):
			copies.append({"closed": line["closed"], "points": Array(line["points"])})
		piece["block"] = copies
	return piece["block"]


func start_line() -> void:
	if selected_prop < 0:
		return
	drawing = true
	drawing_line.clear()
	refresh()


func cancel_line() -> void:
	drawing = false
	drawing_line.clear()
	if _block_box != null and _draft != null:
		refresh()


## Termina a linha em desenho: com 2 pontos ou mais, ela entra na peça.
func finish_line(closed: bool = false) -> void:
	if not drawing:
		return
	var points := drawing_line.duplicate()
	cancel_line()
	if points.size() < (3 if closed else 2) or selected_prop < 0:
		return
	var lines := _draft.prop_lines(selected_prop)
	if lines.size() >= MapProp.MAX_LINES:
		return
	var step := _step("Nova linha de bloqueio")
	var values: Array = []
	for point: Vector2i in points:
		values.append(point.x)
		values.append(point.y)
	var block := ensure_custom_block()
	block.append({"closed": closed, "points": values})
	active_line = block.size() - 1
	_finish(step)


func toggle_closed() -> void:
	if selected_prop < 0:
		return
	var lines := _draft.prop_lines(selected_prop)
	if active_line < 0 or active_line >= lines.size() or (lines[active_line]["points"] as Array).size() < 6:
		return
	var step := _step("Fechar ou abrir a linha")
	var line: Dictionary = ensure_custom_block()[active_line]
	line["closed"] = not bool(line["closed"])
	_finish(step)


func use_type_block() -> void:
	if selected_prop < 0 or not _draft.prop_is_custom(selected_prop):
		return
	var step := _step("Usar o bloqueio padrão")
	_draft.props[selected_prop].erase("block")
	active_line = -1
	_finish(step)


## Salvar o padrão: da variante da peça escolhida, ou de todas (a variante 0).
func request_type_save(all_variants: bool) -> void:
	if selected_prop < 0:
		return
	var piece: Dictionary = _draft.props[selected_prop]
	var saved_variant := GameData.ALL_VARIANTS if all_variants else int(piece.get("variant", 1))
	type_block_save_requested.emit(int(piece.get("prop_type_id", 0)), saved_variant, _draft.prop_lines(selected_prop))


## Depois de salvar no tipo: a peça escolhida volta a usar as linhas dele.
func type_block_saved() -> void:
	if selected_prop >= 0 and _draft.prop_is_custom(selected_prop):
		use_type_block()
	else:
		refresh()


func _set_editing_blocks(on: bool) -> void:
	if editing_blocks == on:
		return
	editing_blocks = on
	blocks_editing_changed.emit(on)


func _rebuild_chips(count: int, current: int) -> void:
	if _chips.get_child_count() != count:
		for chip: Node in _chips.get_children():
			chip.queue_free()
			_chips.remove_child(chip)
		for value: int in range(1, count + 1):
			var chip := EditorTools.tool_button(str(value), _chip_group)
			chip.alignment = HORIZONTAL_ALIGNMENT_CENTER
			chip.custom_minimum_size = CHIP_SIZE
			chip.size_flags_horizontal = Control.SIZE_FILL
			chip.pressed.connect(set_variant.bind(value))
			_chips.add_child(chip)
	for index: int in _chips.get_child_count():
		(_chips.get_child(index) as Button).set_pressed_no_signal(index + 1 == current)


func _step(label: String) -> EditorHistory.Step:
	var step := EditorHistory.Step.new()
	step.label = label
	step.props_before = _draft.props.duplicate(true)
	return step


func _finish(step: EditorHistory.Step) -> void:
	step.props_after = _draft.props.duplicate(true)
	refresh()
	edited.emit(step)


func _row(id: int) -> Dictionary:
	for row: Dictionary in _prop_types:
		if int(row.get("id", 0)) == id:
			return row
	return {}


func _variants(id: int) -> int:
	return maxi(1, int(_row(id).get("variants", 1)))


func _type_name(id: int) -> String:
	return str(_row(id).get("name", "?"))


func _slug(id: int) -> String:
	return str(_row(id).get("slug", ""))


func _on_action_selected(item: int) -> void:
	if selected_prop < 0:
		return
	var piece: Dictionary = _draft.props[selected_prop]
	var chosen := _action_ids[item]
	if int(piece.get("action_type_id", 0)) == chosen:
		return
	var step := _step("Trocar a ação da peça")
	if chosen > 0:
		piece["action_type_id"] = chosen
	else:
		piece.erase("action_type_id")
	_finish(step)


## As salas da lista Sala (interiors/03): `[{id, name}]`, pela rota do editor.
func set_interiors(rows: Array) -> void:
	_interior_select.clear()
	_interior_ids.clear()
	_interior_select.add_item("Nenhuma")
	_interior_ids.append(0)
	for row: Variant in rows:
		if row is Dictionary:
			_interior_select.add_item(str((row as Dictionary).get("name", "")))
			_interior_ids.append(int((row as Dictionary).get("id", 0)))
	if _draft != null:
		refresh()


func _on_interior_selected(item: int) -> void:
	if selected_prop < 0:
		return
	var piece: Dictionary = _draft.props[selected_prop]
	var chosen := _interior_ids[item]
	if int(piece.get("interior_id", 0)) == chosen:
		return
	var step := _step("Trocar a sala da peça")
	if chosen > 0:
		piece["interior_id"] = chosen
	else:
		piece.erase("interior_id")
	_finish(step)


func _on_dialogue_changed() -> void:
	if _syncing_dialogue or _draft == null or selected_prop < 0:
		return
	var piece: Dictionary = _draft.props[selected_prop]
	if str(piece.get("dialogue", "")) == _dialogue_box.text:
		return
	if _dialogue_step == null:
		_dialogue_step = _step("Trocar a fala da peça")
	if _dialogue_box.text.strip_edges().is_empty():
		piece.erase("dialogue")
	else:
		piece["dialogue"] = _dialogue_box.text
	_dialogue_timer.start()


## Copiar as peças a cada letra travaria o editor numa ilha cheia (editor-performance).
func _commit_dialogue() -> void:
	_dialogue_timer.stop()
	if _dialogue_step == null:
		return
	var step := _dialogue_step
	_dialogue_step = null
	step.props_after = _draft.props.duplicate(true)
	edited.emit(step)


func _text_button(text: String, tip: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tip
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	return button

