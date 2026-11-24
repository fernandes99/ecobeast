class_name QuestListPanel
extends Control

## A lista inteira das missões aceitas (explore-hud/03), aberta pelo quadro por cima de
## Explorar: agrupadas por ilha, a aberta primeiro, cada uma com o título, quem entrega,
## a barra e o progresso, numa lista que rola, e o Fechar.

signal closed

const SafeAreaScene := preload("res://ui/components/safe_area.tscn")
const TITLE := "Missões"
const FROM_TEXT := "de %s"
const CLOSE_TEXT := "Fechar"
const BACKDROP_ALPHA := 0.92
const ROW_FONT := 22
const SMALL_FONT := 17
const ISLAND_FONT := 20
const CARD_RADIUS := 14

var _list := VBoxContainer.new()
var _scroll := ScrollContainer.new()


func _init() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color(UiPalette.BACKGROUND, BACKDROP_ALPHA)
	backdrop.mouse_filter = MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(backdrop)
	var safe: Control = SafeAreaScene.instantiate()
	safe.mouse_filter = MOUSE_FILTER_IGNORE
	safe.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(safe)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 16)
	column.mouse_filter = MOUSE_FILTER_IGNORE
	safe.add_child(column)
	var plate := PanelContainer.new()
	plate.theme_type_variation = &"NamePlatePanel"
	plate.size_flags_horizontal = SIZE_SHRINK_CENTER
	plate.mouse_filter = MOUSE_FILTER_IGNORE
	var title := Label.new()
	title.text = TITLE
	title.theme_type_variation = &"TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(title)
	column.add_child(plate)
	_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)
	_list.size_flags_horizontal = SIZE_EXPAND_FILL
	_list.add_theme_constant_override(&"separation", 12)
	_scroll.add_child(_list)
	var close := Button.new()
	close.text = CLOSE_TEXT
	close.theme_type_variation = &"OutlineButton"
	close.custom_minimum_size = Vector2(240.0, 64.0)
	close.size_flags_horizontal = SIZE_SHRINK_CENTER
	close.pressed.connect(close_panel)
	column.add_child(close)


func open(quests: Array[ActiveQuest], island_id: int) -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var island := -2
	for quest in QuestTracker.ordered(quests, island_id):
		if quest.island_id != island:
			island = quest.island_id
			var header := Label.new()
			header.text = quest.island_name
			header.theme_type_variation = &"BoldLabel"
			header.add_theme_font_size_override(&"font_size", ISLAND_FONT)
			_list.add_child(header)
		_list.add_child(_card(quest))
	_scroll.scroll_vertical = 0
	show()


func close_panel() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func _card(quest: ActiveQuest) -> Control:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UiPalette.SURFACE
	style.border_color = UiPalette.BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(CARD_RADIUS)
	style.set_content_margin_all(14)
	card.add_theme_stylebox_override(&"panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 4)
	card.add_child(box)
	box.add_child(QuestTracker.row(quest, false, ROW_FONT, SMALL_FONT))
	var giver := Label.new()
	giver.text = FROM_TEXT % quest.npc_name
	giver.theme_type_variation = &"SecondaryLabel"
	giver.add_theme_font_size_override(&"font_size", SMALL_FONT)
	box.add_child(giver)
	return card
