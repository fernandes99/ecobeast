class_name PathPanel
extends VBoxContainer
## O bloco da ferramenta Caminho (free-trails/04): o tipo e a largura do próximo
## traço e, com um traço escolhido, os dele.

signal edited(step: EditorHistory.Step)
signal changed

const WIDTHS: Array[int] = [14, 22, 34]
const WIDTH_NAMES: Array[String] = ["Estreita", "Normal", "Larga"]
const SWATCH_BIOME := "temperate"

var ground := ""
var width := 22
## O traço escolhido no rascunho, ou -1.
var selected := -1

var _draft: IslandDraft = null
var _ground_buttons: Dictionary[String, TerrainSwatch] = {}
var _width_buttons: Dictionary[int, Button] = {}
var _info: Label


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	var grid := GridContainer.new()
	grid.columns = EditorTools.SWATCH_COLUMNS
	grid.add_theme_constant_override(&"h_separation", 4)
	grid.add_theme_constant_override(&"v_separation", 4)
	add_child(grid)
	var ground_group := ButtonGroup.new()
	for row: Dictionary in GameData.get_rows("ground_types"):
		var slug := str(row.get("slug", ""))
		var swatch := TerrainSwatch.new()
		swatch.button_group = ground_group
		swatch.custom_minimum_size.x = EditorTools.SWATCH_WIDTH
		swatch.set_ground(slug, str(row.get("name", slug)), SWATCH_BIOME)
		swatch.pressed.connect(pick_ground.bind(slug))
		grid.add_child(swatch)
		_ground_buttons[slug] = swatch
		if ground.is_empty():
			ground = slug
	var widths := HBoxContainer.new()
	widths.add_theme_constant_override(&"separation", 4)
	add_child(widths)
	var width_group := ButtonGroup.new()
	for index: int in WIDTHS.size():
		var button := EditorTools.tool_button(WIDTH_NAMES[index], width_group)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(pick_width.bind(WIDTHS[index]))
		widths.add_child(button)
		_width_buttons[WIDTHS[index]] = button
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	_info.add_theme_font_size_override(&"font_size", 14)
	add_child(_info)
	refresh()


func set_draft(draft: IslandDraft) -> void:
	_draft = draft
	selected = -1
	refresh()


func select(index: int) -> void:
	selected = index if _draft != null and index >= 0 and index < _draft.trails.size() else -1
	if selected >= 0:
		ground = _draft.trails[selected].ground
		width = _draft.trails[selected].width
	refresh()
	changed.emit()


func pick_ground(slug: String) -> void:
	ground = slug
	if selected >= 0 and _draft.trails[selected].ground != slug:
		_edit(func(trail: MapTrail) -> void: trail.ground = slug)
	refresh()


func pick_width(value: int) -> void:
	width = value
	if selected >= 0 and _draft.trails[selected].width != value:
		_edit(func(trail: MapTrail) -> void: trail.width = value)
	refresh()


func delete_selected() -> void:
	if selected < 0:
		return
	var step := _new_step()
	_draft.trails.remove_at(selected)
	step.trails_after = IslandDraft.copy_trails(_draft.trails)
	selected = -1
	refresh()
	edited.emit(step)
	changed.emit()


## Depois do desfazer: a escolha some se o traço não existe mais.
func refresh() -> void:
	if _draft == null or selected >= _draft.trails.size():
		selected = -1
	for slug: String in _ground_buttons:
		_ground_buttons[slug].set_pressed_no_signal(slug == ground)
	for value: int in _width_buttons:
		_width_buttons[value].set_pressed_no_signal(value == width)
	if selected >= 0:
		_info.text = "Caminho escolhido. As amostras trocam o tipo e a largura dele; Delete apaga, Esc solta."
	else:
		_info.text = "Nenhum caminho escolhido. A escolha vale para o próximo."


func _edit(change: Callable) -> void:
	var step := _new_step()
	change.call(_draft.trails[selected])
	step.trails_after = IslandDraft.copy_trails(_draft.trails)
	edited.emit(step)


func _new_step() -> EditorHistory.Step:
	var step := EditorHistory.Step.new()
	step.label = "Caminho"
	step.trails_before = IslandDraft.copy_trails(_draft.trails)
	return step
