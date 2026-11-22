class_name NpcListRow
extends RefCounted

## Uma linha da lista de NPCs do F2: a figura, o nome, a descrição e os selos de
## quantas vezes ele está no mapa e de quantas missões ele dá (auralis/07).

const HEIGHT := 76.0
const PORTRAIT := Vector2(60, 60)
const PADDING := 6
const PERSON_SCALE := 2.0
const PERSON_FOOT := 58.0
const CHIP_FONT_SIZE := 15
const DESCRIPTION_FONT_SIZE := 16
const DISABLED_ALPHA := 0.45

var npc_id := 0
var button: Button
var name_text := ""
var description := ""
var _placed_chip: Label
var _quests_chip: Label


func _init(id: int, button_group: ButtonGroup) -> void:
	npc_id = id
	var row := GameData.get_npc(id)
	name_text = str(row.get("name", ""))
	description = str(row.get("description", ""))
	button = EditorTools.tool_button("", button_group)
	button.custom_minimum_size.y = HEIGHT

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, PADDING)
	button.add_child(margin)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override(&"separation", 8)
	margin.add_child(line)
	line.add_child(_portrait(id))

	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override(&"separation", 2)
	line.add_child(texts)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override(&"separation", 4)
	texts.add_child(top)
	var title := _label(name_text, UiPalette.TEXT)
	title.theme_type_variation = &"BoldLabel"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	_placed_chip = _chip(UiPalette.BATTLE_LEVEL_PLAYER)
	top.add_child(_placed_chip)
	_quests_chip = _chip(UiPalette.PRIMARY)
	top.add_child(_quests_chip)
	var about := _label(description, UiPalette.TEXT_SECONDARY)
	about.add_theme_font_size_override(&"font_size", DESCRIPTION_FONT_SIZE)
	texts.add_child(about)

	button.disabled = not _has_art(id)
	if button.disabled:
		margin.modulate.a = DISABLED_ALPHA
	set_counts(0, -1)


## Quantas vezes está no mapa e quantas missões dá; -1 é "ainda sem a lista".
func set_counts(placed: int, quests: int) -> void:
	_placed_chip.visible = placed > 0
	_placed_chip.text = "No mapa" if placed == 1 else "No mapa ×%d" % placed
	_quests_chip.visible = quests > 0
	_quests_chip.text = "%d missão" % quests if quests == 1 else "%d missões" % quests
	var lines: Array[String] = [name_text, description]
	if button.disabled:
		lines.append("Sem as folhas assets/creatures/%s/explore/idle.png e walk.png." % NpcSprite.slug_of(npc_id))
	elif placed > 0:
		lines.append("Já está nesta ilha. Clicar escolhe o primeiro dele no mapa.")
	button.tooltip_text = "\n".join(lines)


func matches(query: String) -> bool:
	return query.is_empty() or name_text.findn(query) >= 0 or description.findn(query) >= 0


static func _has_art(id: int) -> bool:
	return TamerAppearance.for_npc(id) != null or NpcSprite.first_frame(NpcSprite.slug_of(id)) != null


## A pessoa é o Domador vestido, parado no primeiro quadro; o Ecobeast, o primeiro
## quadro parado recortado, ampliado em pixels inteiros.
static func _portrait(id: int) -> Control:
	var box := Control.new()
	box.custom_minimum_size = PORTRAIT
	box.clip_contents = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var appearance := TamerAppearance.for_npc(id)
	if appearance != null:
		var look := TamerSprite.new()
		look.set_appearance(appearance)
		look.pause()
		look.scale = Vector2.ONE * PERSON_SCALE
		look.position = Vector2(PORTRAIT.x / 2.0, PERSON_FOOT)
		box.add_child(look)
		return box
	var frame := NpcSprite.first_frame(NpcSprite.slug_of(id))
	if frame == null:
		return box
	var image := frame.get_image()
	var used := image.get_used_rect()
	if used.has_area():
		image = image.get_region(used)
	var zoom := maxi(1, floori(minf(PORTRAIT.x / image.get_width(), PORTRAIT.y / image.get_height())))
	image.resize(image.get_width() * zoom, image.get_height() * zoom, Image.INTERPOLATE_NEAREST)
	var picture := TextureRect.new()
	picture.texture = ImageTexture.create_from_image(image)
	picture.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(picture)
	return box


static func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_color_override(&"font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


static func _chip(background: Color) -> Label:
	var chip := Label.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.add_theme_font_size_override(&"font_size", CHIP_FONT_SIZE)
	chip.add_theme_color_override(&"font_color", UiPalette.TEXT)
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_corner_radius_all(4)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	chip.add_theme_stylebox_override(&"normal", style)
	return chip
