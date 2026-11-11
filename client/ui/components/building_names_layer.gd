class_name BuildingNamesLayer
extends Control

const NAME_SIZE := 30
const OUTLINE_SIZE := 8

## Cada nome: o texto e o ponto dele, em pixels da arte do mapa.
var _names: Array[Dictionary] = []
var _map_position := Vector2.ZERO
var _map_scale := Vector2.ONE


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


static func middle_of(tiles: Array[Vector2i]) -> Vector2i:
	var center := Vector2.ZERO
	for coord: Vector2i in tiles:
		center += HexMapView.flat_center(coord)
	center /= tiles.size()
	var middle := tiles[0]
	for coord: Vector2i in tiles:
		if HexMapView.flat_center(coord).distance_to(center) < HexMapView.flat_center(middle).distance_to(center):
			middle = coord
	return middle


func clear() -> void:
	_names.clear()
	queue_redraw()


func add_name(text: String, art_point: Vector2) -> void:
	_names.append({"text": text, "point": art_point})
	queue_redraw()


func set_view(map_position: Vector2, map_scale: Vector2) -> void:
	_map_position = map_position
	_map_scale = map_scale
	queue_redraw()


func _draw() -> void:
	var font := get_theme_font(&"font", &"BoldLabel")
	var font_size := NAME_SIZE
	for entry: Dictionary in _names:
		var text: String = entry["text"]
		var point: Vector2 = entry["point"]
		var at := _map_position + point * _map_scale
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var baseline := (at + Vector2(-width / 2.0, font_size / 3.0)).round()
		draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, OUTLINE_SIZE, UiPalette.BACKGROUND_DEEP)
		draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiPalette.TEXT)
