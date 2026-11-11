class_name TerrainSwatch
extends Button

const ART_SCALE := 0.75
const HEX_ART_SIZE := Vector2(64.0, 58.0)
const OUTLINE_WIDTH := 3.0
const MAX_RISE := 20.0
const TOP_MARGIN := 4.0
const LABEL_LINES := 2
const LABEL_SIZE := 13
const LABEL_LINE_HEIGHT := 16.0

var _surface: Texture2D = null
var _face: Texture2D = null
var _rise := 0.0
var _label := ""


func _init() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"focus", &"disabled"]:
		add_theme_stylebox_override(state, empty)
	var hex := HEX_ART_SIZE * ART_SCALE
	custom_minimum_size = Vector2(hex.x + 8.0, TOP_MARGIN + hex.y + MAX_RISE * ART_SCALE + 6.0 + LABEL_LINE_HEIGHT * LABEL_LINES)


func set_terrain(biome: String, label: String, height: int) -> void:
	_surface = _load(HexMapView.SURFACE_PATH % biome)
	_face = _load(HexMapView.SURFACE_PATH % HexMapView.face_texture(biome))
	_rise = minf(HexMapView.LEVEL_HEIGHTS[height] + 4.0, MAX_RISE) if height > 0 else 0.0
	_label = label
	tooltip_text = label
	queue_redraw()


## Sem chão, a amostra mostra o bioma escolhido.
func set_ground(slug: String, label: String, biome: String) -> void:
	set_terrain(biome, label, 1)
	if not slug.is_empty():
		_surface = _load(HexGrounds.TEXTURE_PATH % slug)
		queue_redraw()


func _load(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func _draw() -> void:
	var top_left := Vector2((size.x - HEX_ART_SIZE.x * ART_SCALE) / 2.0, TOP_MARGIN)
	var corners: Array[Vector2] = []
	for corner: Vector2 in HexMapView.HEX_CORNERS:
		corners.append(top_left + corner * ART_SCALE)
	if _rise > 0.0 and _face != null:
		for edge: int in HexMapView.LOWER_EDGE_CORNERS.size():
			var pair := HexMapView.LOWER_EDGE_CORNERS[edge]
			var from_art := HexMapView.HEX_CORNERS[pair.x]
			var to_art := HexMapView.HEX_CORNERS[pair.y]
			var down := Vector2(0.0, _rise)
			var art_quad: Array[Vector2] = [from_art, to_art, to_art + down, from_art + down]
			var quad := PackedVector2Array()
			var uvs := PackedVector2Array()
			for point: Vector2 in art_quad:
				quad.append(top_left + point * ART_SCALE)
				uvs.append(Vector2(point.x / _face.get_width(), (point.y - from_art.y) / _face.get_height()))
			draw_colored_polygon(quad, HexMapView.FACE_COLORS[edge], uvs, _face)
	var hexagon := PackedVector2Array(corners)
	if _surface != null:
		var uvs := PackedVector2Array()
		for corner: Vector2 in HexMapView.HEX_CORNERS:
			uvs.append(corner / Vector2(_surface.get_size()))
		draw_colored_polygon(hexagon, Color.WHITE, uvs, _surface)
	var outline := hexagon.duplicate()
	outline.append(hexagon[0])
	if button_pressed:
		draw_polyline(outline, UiPalette.ACCENT, OUTLINE_WIDTH, true)
	elif is_hovered():
		draw_polyline(outline, UiPalette.TEXT_SECONDARY, 1.5, true)
	var font := get_theme_font(&"font")
	var color := UiPalette.TEXT if button_pressed else UiPalette.TEXT_SECONDARY
	var first_line := size.y - LABEL_LINE_HEIGHT * LABEL_LINES + LABEL_SIZE
	draw_multiline_string(font, Vector2(0.0, first_line), _label, HORIZONTAL_ALIGNMENT_CENTER, size.x, LABEL_SIZE, LABEL_LINES, color)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT or what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()
