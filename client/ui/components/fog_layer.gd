class_name FogLayer
extends ColorRect
## A névoa por cima do mapa de Explorar (.specs/fog-of-war/02-fog-layer.md): cobre com
## a cor do fundo o que o Domador ainda não descobriu. Fica entre o mapa e a luz da hora.
## O shader lê uma imagem com um pixel por hexágono: quanto ele aparece e a altura.

const SHADER_PATH := "res://ui/components/fog.gdshader"
## O anel em volta do descoberto, que aparece pela metade. A revisar.
const GLIMPSE := 0.5
const GLIMPSE_RADIUS := 1
## Quanto tempo um hexágono leva para aparecer, em segundos. A revisar.
const FADE_TIME := 0.8

var _material := ShaderMaterial.new()
var _map: ExplorationMap = null
var _discovery: MapDiscovery = null
var _image: Image = null
var _texture: ImageTexture = null
var _origin := Vector2i.ZERO
## Os hexágonos que ainda estão aparecendo, com o quanto devem aparecer no fim.
var _fading: Dictionary[Vector2i, float] = {}
var _dirty := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	_material.shader = load(SHADER_PATH) as Shader
	_material.set_shader_parameter(&"fog_top", UiPalette.BACKGROUND)
	_material.set_shader_parameter(&"fog_bottom", UiPalette.BACKGROUND_DEEP)
	material = _material
	visible = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_material.set_shader_parameter(&"rect_size", size)
	_advance_fades(delta / FADE_TIME)
	if _dirty:
		_dirty = false
		_texture.update(_image)


func set_map(map: ExplorationMap, discovery: MapDiscovery) -> void:
	_map = map
	_discovery = discovery
	_fading.clear()
	var low := Vector2i.MAX
	var high := Vector2i.MIN
	for coord: Vector2i in map.tiles:
		low = low.min(coord)
		high = high.max(coord)
	_origin = low
	var data_size := high - low + Vector2i.ONE
	_image = Image.create_empty(data_size.x, data_size.y, false, Image.FORMAT_RG8)
	for tile: HexTile in map.tiles.values():
		_image.set_pixelv(tile.coord - _origin, Color(_wanted(tile.coord), (tile.height + 1) / 255.0, 0.0))
	_texture = ImageTexture.create_from_image(_image)
	_dirty = false
	_material.set_shader_parameter(&"hex_data", _texture)
	_material.set_shader_parameter(&"data_origin", Vector2(_origin))
	_material.set_shader_parameter(&"data_size", Vector2(data_size))
	visible = true


## Os hexágonos recém-descobertos e o anel em volta deles aparecem aos poucos.
func reveal(coords: Array[Vector2i]) -> void:
	if _image == null:
		return
	for coord: Vector2i in coords:
		for near: Vector2i in _around(coord):
			var wanted := _wanted(near)
			if wanted > _value_at(near):
				_fading[near] = wanted


## A posição do ponto (0, 0) da arte, nas coordenadas deste retângulo, e os pixels por
## pixel da arte (como o DayLightLayer).
func set_view(art_origin: Vector2, art_scale: float) -> void:
	_material.set_shader_parameter(&"art_origin", art_origin)
	_material.set_shader_parameter(&"art_scale", maxf(art_scale, 0.0001))


func _advance_fades(step: float) -> void:
	for coord: Vector2i in _fading.keys():
		var target: float = _fading[coord]
		var value := minf(_value_at(coord) + step, target)
		_set_value(coord, value)
		if value >= target:
			_fading.erase(coord)


## 1 no descoberto, GLIMPSE no anel em volta dele e 0 no resto.
func _wanted(coord: Vector2i) -> float:
	if _discovery.is_discovered(coord):
		return 1.0
	for near: Vector2i in _around(coord):
		if _discovery.is_discovered(near):
			return GLIMPSE
	return 0.0


func _around(center: Vector2i) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for dq: int in range(-GLIMPSE_RADIUS, GLIMPSE_RADIUS + 1):
		for dr: int in range(maxi(-GLIMPSE_RADIUS, -dq - GLIMPSE_RADIUS), mini(GLIMPSE_RADIUS, -dq + GLIMPSE_RADIUS) + 1):
			var coord := center + Vector2i(dq, dr)
			if _map.has(coord):
				coords.append(coord)
	return coords


func _value_at(coord: Vector2i) -> float:
	return _image.get_pixelv(coord - _origin).r


func _set_value(coord: Vector2i, value: float) -> void:
	var pixel := _image.get_pixelv(coord - _origin)
	pixel.r = value
	_image.set_pixelv(coord - _origin, pixel)
	_dirty = true
