class_name QuestTracker
extends TapPanel

## O quadro de missões de Explorar (explore-hud/03): "Missões (N)", a seta que recolhe e,
## aberto, até 3 missões, as da ilha aberta primeiro, com o título, a barra e o progresso.
## Tocar fora da seta pede a lista inteira (`pressed`).

const TITLE := "Missões (%d)"
const READY_TEXT := "Fale com %s"
const MAX_ROWS := 3
const MAX_WIDTH_RATIO := 0.55
const TITLE_FONT := 20
const ROW_FONT := 18
const SMALL_FONT := 15
const OUTLINE := 6
const ARROW_SIZE := 36
const BAR_HEIGHT := 6
const OPEN_ARROW := "▾"
const CLOSED_ARROW := "▸"

var _title := Label.new()
var _arrow := Button.new()
var _rows := VBoxContainer.new()
var _quests: Array[ActiveQuest] = []
var _island_id := -1
var _collapsed := false


func _init() -> void:
	visible = false
	size_flags_horizontal = SIZE_SHRINK_BEGIN
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	var style := ExplorePlates.panel_style(16)
	style.content_margin_left = 14
	style.content_margin_right = 8
	style.content_margin_bottom = 10
	add_theme_stylebox_override(&"panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	column.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(column)
	var header := HBoxContainer.new()
	header.mouse_filter = MOUSE_FILTER_IGNORE
	column.add_child(header)
	_title.size_flags_horizontal = SIZE_EXPAND_FILL
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.theme_type_variation = &"BoldLabel"
	_title.add_theme_font_size_override(&"font_size", TITLE_FONT)
	_outline(_title)
	header.add_child(_title)
	_arrow.flat = true
	_arrow.focus_mode = FOCUS_NONE
	_arrow.custom_minimum_size = Vector2(ARROW_SIZE, ARROW_SIZE)
	_arrow.add_theme_font_size_override(&"font_size", TITLE_FONT)
	_arrow.pressed.connect(_toggle)
	header.add_child(_arrow)
	_rows.add_theme_constant_override(&"separation", 10)
	_rows.mouse_filter = MOUSE_FILTER_IGNORE
	column.add_child(_rows)
	_collapsed = ViewSettings.quests_collapsed()


## A largura: no máximo 55% da tela, sem passar por baixo do minimapa.
func set_room(width: float) -> void:
	custom_minimum_size.x = width
	size.x = width


static func width_for(screen_width: float, minimap_room: float) -> float:
	return maxf(0.0, minf(screen_width * MAX_WIDTH_RATIO, screen_width - minimap_room))


func set_quests(quests: Array[ActiveQuest], island_id: int) -> void:
	_quests = ordered(quests, island_id)
	_island_id = island_id
	_refresh()


## As da ilha aberta primeiro, cada grupo na ordem da lista.
static func ordered(quests: Array[ActiveQuest], island_id: int) -> Array[ActiveQuest]:
	var here: Array[ActiveQuest] = []
	var others: Array[ActiveQuest] = []
	for quest in quests:
		if quest.island_id == island_id:
			here.append(quest)
		else:
			others.append(quest)
	here.append_array(others)
	return here


func has_quests() -> bool:
	return not _quests.is_empty()


func _toggle() -> void:
	_collapsed = not _collapsed
	ViewSettings.set_quests_collapsed(_collapsed)
	_refresh()


func _refresh() -> void:
	_title.text = TITLE % _quests.size()
	_arrow.text = CLOSED_ARROW if _collapsed else OPEN_ARROW
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_rows.visible = not _collapsed
	if not _collapsed:
		for index in mini(MAX_ROWS, _quests.size()):
			_rows.add_child(row(_quests[index], _quests[index].island_id != _island_id, ROW_FONT, SMALL_FONT))


## Uma linha: o título (e a ilha, se é de outra), a barra e o progresso, ou "Fale com".
static func row(quest: ActiveQuest, other_island: bool, font: int, small: int) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 4)
	box.mouse_filter = MOUSE_FILTER_IGNORE
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 6)
	top.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(top)
	var title := Label.new()
	title.text = quest.title
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.clip_text = true
	title.add_theme_font_size_override(&"font_size", font)
	_outline(title)
	top.add_child(title)
	if other_island and not quest.island_name.is_empty():
		var island := Label.new()
		island.text = quest.island_name
		island.theme_type_variation = &"SecondaryLabel"
		island.add_theme_font_size_override(&"font_size", small)
		top.add_child(island)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override(&"separation", 8)
	bottom.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(bottom)
	var bar := Control.new()
	bar.custom_minimum_size.y = BAR_HEIGHT
	bar.size_flags_horizontal = SIZE_EXPAND_FILL
	bar.size_flags_vertical = SIZE_SHRINK_CENTER
	bar.mouse_filter = MOUSE_FILTER_IGNORE
	var ratio := 1.0 if quest.done else quest.ratio()
	var fill := UiPalette.HP_HIGH if quest.done else UiPalette.ACCENT
	bar.draw.connect(func() -> void:
		var radius := bar.size.y / 2.0
		_draw_pill(bar, Rect2(Vector2.ZERO, bar.size), UiPalette.TRACK, radius)
		if ratio > 0.0:
			_draw_pill(bar, Rect2(Vector2.ZERO, Vector2(maxf(bar.size.y, bar.size.x * ratio), bar.size.y)), fill, radius))
	bottom.add_child(bar)
	var progress := Label.new()
	progress.text = READY_TEXT % quest.npc_name if quest.done else quest.progress_text
	progress.add_theme_font_size_override(&"font_size", small)
	if quest.done:
		progress.add_theme_color_override(&"font_color", UiPalette.HP_HIGH)
	_outline(progress)
	bottom.add_child(progress)
	return box


static func _draw_pill(canvas: Control, rect: Rect2, color: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(ceili(radius))
	canvas.draw_style_box(style, rect)


static func _outline(label: Label) -> void:
	label.add_theme_constant_override(&"outline_size", OUTLINE)
	label.add_theme_color_override(&"font_outline_color", UiPalette.TEXT_OUTLINE)
