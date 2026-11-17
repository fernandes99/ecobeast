class_name IslandMapPanel
extends Control
## O mapa grande da ilha (.specs/minimap/02-island-map.md), aberto pelo minimapa: a
## mesma MinimapImage na moldura dourada, com zoom em degraus inteiros, arrasto, os
## marcadores descobertos, a legenda e o Fechar. Só mostra; não anda o Domador.

signal closed

const SafeAreaScene := preload("res://ui/components/safe_area.tscn")
const ZONE_TITLE := "Mapa da zona"
const CLOSE_TEXT := "Fechar"
## Até quantas vezes a escala inicial o zoom vai. A revisar.
const MAX_ZOOM_TIMES := 3
const BACKDROP_ALPHA := 0.92
## A borda da moldura, em pixels da arte (frame.png).
const FRAME_BORDER := 5
const ZOOM_BUTTON_SIZE := 56.0
const ZOOM_BUTTON_MARGIN := 12.0
const LEGEND_KINDS: Array[StringName] = [&"pin", &"refuge", &"shop", &"npc"]
const LEGEND_NAMES: Dictionary[StringName, String] = {
	&"pin": "Você",
	&"refuge": "Refúgio",
	&"shop": "Loja",
	&"npc": "NPC",
}

var _image: MinimapImage = null
var _markers: Array[MapMarker] = []
var _discovery: MapDiscovery = null
var _show_all := false
var _player := Vector2.ZERO
var _fit := 1
var _scale := 1
var _offset := Vector2.ZERO
var _pinch := PinchZoom.new()
var _pinch_start_scale := 1
var _dragging := false

var _title := Label.new()
var _frame := Control.new()
var _nine := NinePatchRect.new()
var _area := Control.new()
var _zoom_in := Button.new()
var _zoom_out := Button.new()
var _legend := HBoxContainer.new()


func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color(UiPalette.BACKGROUND, BACKDROP_ALPHA)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var safe: Control = SafeAreaScene.instantiate()
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(safe)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(column)
	var plate := PanelContainer.new()
	plate.theme_type_variation = &"NamePlatePanel"
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.theme_type_variation = &"TitleLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(_title)
	column.add_child(plate)
	_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.resized.connect(_layout_frame)
	column.add_child(_frame)
	_area.clip_contents = true
	_area.mouse_filter = Control.MOUSE_FILTER_STOP
	_area.draw.connect(_draw_map)
	_area.gui_input.connect(_on_area_input)
	_frame.add_child(_area)
	_nine.texture = MinimapArt.frame()
	_nine.draw_center = false
	for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_nine.set_patch_margin(side, MinimapArt.FRAME_MARGIN)
	_nine.scale = Vector2.ONE * MinimapArt.ART_SCALE
	_nine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_nine)
	for button: Button in [_zoom_in, _zoom_out]:
		button.theme_type_variation = &"OutlineButton"
		button.custom_minimum_size = Vector2.ONE * ZOOM_BUTTON_SIZE
		button.size = button.custom_minimum_size
		button.focus_mode = Control.FOCUS_NONE
		_frame.add_child(button)
	_zoom_in.text = "+"
	_zoom_out.text = "−"
	_zoom_in.pressed.connect(func() -> void: _zoom(1, _area.size / 2.0))
	_zoom_out.pressed.connect(func() -> void: _zoom(-1, _area.size / 2.0))
	_legend.alignment = BoxContainer.ALIGNMENT_CENTER
	_legend.add_theme_constant_override(&"separation", 20)
	_legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_legend)
	_pinch.pinch_started.connect(func(_center: Vector2) -> void: _pinch_start_scale = _scale)
	_pinch.pinched.connect(func(ratio: float, center: Vector2) -> void: _zoom_to(roundi(_pinch_start_scale * ratio), center - _area.get_global_rect().position))
	var close := Button.new()
	close.text = CLOSE_TEXT
	close.theme_type_variation = &"OutlineButton"
	close.custom_minimum_size = Vector2(240.0, 64.0)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(close_panel)
	column.add_child(close)


func _process(_delta: float) -> void:
	if visible:
		_area.queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var area := _area.get_global_rect()
	if _pinch.feed(event, area):
		_dragging = false
		get_viewport().set_input_as_handled()
		return
	var step := _pinch.wheel(event, area)
	if step != 0:
		get_viewport().set_input_as_handled()
		_zoom(step, (event as InputEventMouseButton).position - area.position)


func open(image: MinimapImage, markers: Array[MapMarker], discovery: MapDiscovery, show_all: bool, player: Vector2, title: String) -> void:
	_image = image
	_markers = markers
	_discovery = discovery
	_show_all = show_all
	_player = player
	_title.text = title if not title.is_empty() else ZONE_TITLE
	_fill_legend()
	_pinch.cancel()
	_dragging = false
	show()
	_reset_view.call_deferred()


func close_panel() -> void:
	if not visible:
		return
	hide()
	_pinch.cancel()
	closed.emit()


## A maior escala inteira em que a imagem cabe na área, no mínimo 1.
static func fit_scale(image_size: Vector2i, area: Vector2) -> int:
	if image_size.x <= 0 or image_size.y <= 0:
		return 1
	return maxi(1, floori(minf(area.x / image_size.x, area.y / image_size.y)))


static func next_scale(current: int, step: int, fit: int) -> int:
	return clampi(current + step, fit, fit * MAX_ZOOM_TIMES)


## A imagem não sai da área: maior que ela, a borda não passa da borda; menor, centrada.
static func clamped_offset(offset: Vector2, image_points: Vector2, area: Vector2) -> Vector2:
	var out := offset
	for axis: int in 2:
		if image_points[axis] >= area[axis]:
			out[axis] = clampf(offset[axis], area[axis] - image_points[axis], 0.0)
		else:
			out[axis] = (area[axis] - image_points[axis]) / 2.0
	return out.round()


## A posição nova para o ponto `anchor` da área continuar sobre o mesmo ponto da imagem.
static func zoomed_offset(offset: Vector2, old_scale: int, new_scale: int, anchor: Vector2) -> Vector2:
	return anchor - (anchor - offset) * float(new_scale) / float(old_scale)


func _reset_view() -> void:
	if _image == null:
		return
	_fit = fit_scale(_image.image_size, _area.size)
	_scale = _fit
	var image_points := _image_points()
	var centered := (_area.size - image_points) / 2.0
	if image_points.x > _area.size.x or image_points.y > _area.size.y:
		centered = _area.size / 2.0 - _image.art_to_image(_player) * _scale
	_offset = clamped_offset(centered, image_points, _area.size)
	_refresh_buttons()


func _zoom(step: int, anchor: Vector2) -> void:
	_zoom_to(next_scale(_scale, step, _fit), anchor)


func _zoom_to(target: int, anchor: Vector2) -> void:
	target = next_scale(target, 0, _fit)
	if _image == null or target == _scale:
		return
	_offset = clamped_offset(zoomed_offset(_offset, _scale, target, anchor), Vector2(_image.image_size) * target, _area.size)
	_scale = target
	_refresh_buttons()


func _on_area_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		_dragging = button.pressed and not _pinch.blocks_tap()
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _dragging and not _pinch.blocks_tap() and _image != null:
		_offset = clamped_offset(_offset + motion.relative, _image_points(), _area.size)


func _image_points() -> Vector2:
	return Vector2(_image.image_size) * _scale if _image != null else Vector2.ZERO


func _refresh_buttons() -> void:
	_zoom_in.disabled = _scale >= _fit * MAX_ZOOM_TIMES
	_zoom_out.disabled = _scale <= _fit


func _layout_frame() -> void:
	var border := FRAME_BORDER * MinimapArt.ART_SCALE
	_nine.size = _frame.size / MinimapArt.ART_SCALE
	_area.position = Vector2.ONE * border
	_area.size = _frame.size - Vector2.ONE * border * 2.0
	var corner := _frame.size - Vector2.ONE * (border + ZOOM_BUTTON_MARGIN)
	_zoom_out.position = corner - _zoom_out.size
	_zoom_in.position = _zoom_out.position - Vector2(0.0, ZOOM_BUTTON_SIZE + 8.0)
	if visible and _image != null:
		_offset = clamped_offset(_offset, _image_points(), _area.size)


func _fill_legend() -> void:
	for child: Node in _legend.get_children():
		child.queue_free()
	var present: Dictionary[StringName, bool] = {&"pin": true}
	for marker: MapMarker in _markers:
		present[marker.kind] = true
	for kind: StringName in LEGEND_KINDS:
		if not present.has(kind):
			continue
		var item := HBoxContainer.new()
		item.add_theme_constant_override(&"separation", 6)
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.texture = MinimapArt.icon(kind)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = icon.texture.get_size() * MinimapArt.ART_SCALE if icon.texture != null else Vector2.ZERO
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(icon)
		var label := Label.new()
		label.text = LEGEND_NAMES[kind]
		item.add_child(label)
		_legend.add_child(item)


func _draw_map() -> void:
	_area.draw_rect(Rect2(Vector2.ZERO, _area.size), MinimapPalette.FOG)
	if _image == null or _image.texture == null:
		return
	_area.draw_texture_rect(_image.texture, Rect2(_offset, _image_points()), false)
	var view := Rect2(Vector2.ZERO, _area.size)
	for marker: MapMarker in MapMarker.shown(_markers, _discovery, _show_all):
		var at := _offset + _image.art_to_image(marker.flat) * _scale
		if view.has_point(at):
			Minimap.draw_icon(_area, MinimapArt.icon(marker.kind), at, false)
	Minimap.draw_icon(_area, MinimapArt.icon(&"pin"), _offset + _image.art_to_image(_player) * _scale, true)
