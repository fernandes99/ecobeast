class_name Minimap
extends Control
## O minimapa redondo de Explorar (.specs/minimap/01-minimap.md): o pedaço da
## MinimapImage em volta do Domador, recortado pelo furo do anel dourado, com os
## marcadores descobertos e o pino no centro. O toque emite `tapped`.

signal tapped

const MAX_TAP_TRAVEL := 24.0

var _image: MinimapImage = null
var _markers: Array[MapMarker] = []
var _discovery: MapDiscovery = null
var _show_all := false
var _center := Vector2.ZERO
var _press := Vector2.INF
var _clip := Control.new()
var _layer := Control.new()
var _ring := TextureRect.new()


func _init() -> void:
	var scale_ := MinimapArt.ART_SCALE
	custom_minimum_size = Vector2.ONE * MinimapArt.RING_SIZE * scale_
	size = custom_minimum_size
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	var hole := Vector2.ONE * MinimapArt.HOLE_SIZE * scale_
	_clip.position = (custom_minimum_size - hole) / 2.0
	_clip.size = hole
	_clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.draw.connect(func() -> void: _clip.draw_texture_rect(MinimapArt.mask(), Rect2(Vector2.ZERO, hole), false))
	add_child(_clip)
	_layer.size = hole
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.draw.connect(_draw_map)
	_clip.add_child(_layer)
	_ring.texture = MinimapArt.ring()
	_ring.size = custom_minimum_size
	_ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ring.stretch_mode = TextureRect.STRETCH_SCALE
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ring)


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		_layer.queue_redraw()


func set_source(image: MinimapImage, markers: Array[MapMarker], discovery: MapDiscovery) -> void:
	_image = image
	_markers = markers
	_discovery = discovery
	_layer.queue_redraw()


func set_show_all(on: bool) -> void:
	_show_all = on
	_layer.queue_redraw()


## O ponto dos pés do Domador no chão plano.
func set_center(flat: Vector2) -> void:
	_center = flat


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	if mouse.pressed:
		_press = mouse.position
	elif mouse.position.distance_to(_press) <= MAX_TAP_TRAVEL and mouse.position.distance_to(size / 2.0) <= size.x / 2.0:
		_press = Vector2.INF
		tapped.emit()


func _draw_map() -> void:
	var hole := _layer.size
	_layer.draw_rect(Rect2(Vector2.ZERO, hole), MinimapPalette.FOG)
	if _image == null or _image.texture == null:
		return
	var scale_ := float(MinimapArt.ART_SCALE)
	var middle := (hole / 2.0).floor()
	var pixel := _image.art_to_image(_center).floor()
	var offset := (middle - (pixel + Vector2(0.5, 0.5)) * scale_).floor()
	_layer.draw_texture_rect(_image.texture, Rect2(offset, Vector2(_image.image_size) * scale_), false)
	for marker: MapMarker in MapMarker.shown(_markers, _discovery, _show_all):
		draw_icon(_layer, MinimapArt.icon(marker.kind), offset + _image.art_to_image(marker.flat) * scale_, false)
	draw_icon(_layer, MinimapArt.icon(&"pin"), middle, true)


## Desenha um ícone da arte em ART_SCALE, centrado no ponto ou com a ponta de baixo nele.
static func draw_icon(canvas: CanvasItem, icon: Texture2D, at: Vector2, tip: bool) -> void:
	if icon == null:
		return
	var icon_size := icon.get_size() * MinimapArt.ART_SCALE
	var corner := at - Vector2(icon_size.x / 2.0, icon_size.y if tip else icon_size.y / 2.0)
	canvas.draw_texture_rect(icon, Rect2(corner.floor(), icon_size), false)
