class_name StageChips
extends Node2D

const FONT := preload("res://ui/theme/fonts/nunito_black.tres")
const FONT_SIZE := 15
const TEXT_OUTLINE := 4
const PER_ROW := 2
const PAD := 5.0
const GAP := 3.0
const HEIGHT := 20.0
const ARROW_WIDTH := 8.0
const ARROW_HEIGHT := 7.0
const ARROW_GAP := 1.5
const MAX_ARROWS := 3
const CORNER := 5
const BORDER := 2

var stages: Dictionary = {}:
	set(value):
		stages = value
		queue_redraw()


func _draw() -> void:
	var chips: Array[Array] = []
	var rows := GameData.get_rows("stats").duplicate()
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["id"]) < int(b["id"]))
	for row: Dictionary in rows:
		var level: int = stages.get(row["slug"], 0)
		if level != 0:
			chips.append([str(row["short_name"]), level])
	var y := 0.0
	for start: int in range(0, chips.size(), PER_ROW):
		var line := chips.slice(start, start + PER_ROW)
		var widths: Array[float] = []
		var total := 0.0
		for chip: Array in line:
			widths.append(_width(chip[0], chip[1]))
			total += widths[-1]
		total += GAP * (line.size() - 1)
		var x := -total / 2.0
		for index: int in line.size():
			_chip(Rect2(x, y, widths[index], HEIGHT), line[index][0], line[index][1])
			x += widths[index] + GAP
		y += HEIGHT + GAP


func _width(text: String, level: int) -> float:
	var width := PAD * 2.0 + FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x + 3.0
	var arrows := mini(absi(level), MAX_ARROWS)
	width += arrows * ARROW_WIDTH + (arrows - 1) * ARROW_GAP
	if absi(level) > MAX_ARROWS:
		width += FONT.get_string_size(str(absi(level)), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x + 2.0
	return width


func _chip(rect: Rect2, text: String, level: int) -> void:
	var color := UiPalette.STAT_UP if level > 0 else UiPalette.STAT_DOWN
	var box := StyleBoxFlat.new()
	box.bg_color = Color(UiPalette.BACKGROUND_DEEP, 0.85)
	box.border_color = color
	box.set_border_width_all(BORDER)
	box.set_corner_radius_all(CORNER)
	box.draw(get_canvas_item(), rect)
	var baseline := rect.position.y + (HEIGHT + FONT.get_ascent(FONT_SIZE) - FONT.get_descent(FONT_SIZE)) / 2.0
	var x := rect.position.x + PAD
	draw_string_outline(FONT, Vector2(x, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT_OUTLINE, UiPalette.BACKGROUND_DEEP)
	draw_string(FONT, Vector2(x, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, UiPalette.TEXT)
	x += FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x + 3.0
	var top := rect.position.y + (HEIGHT - ARROW_HEIGHT) / 2.0
	for _index: int in mini(absi(level), MAX_ARROWS):
		var points: PackedVector2Array
		if level > 0:
			points = [Vector2(x + ARROW_WIDTH / 2.0, top), Vector2(x + ARROW_WIDTH, top + ARROW_HEIGHT), Vector2(x, top + ARROW_HEIGHT)]
		else:
			points = [Vector2(x, top), Vector2(x + ARROW_WIDTH, top), Vector2(x + ARROW_WIDTH / 2.0, top + ARROW_HEIGHT)]
		draw_colored_polygon(points, color)
		x += ARROW_WIDTH + ARROW_GAP
	if absi(level) > MAX_ARROWS:
		draw_string(FONT, Vector2(x + 1.0, baseline), str(absi(level)), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
