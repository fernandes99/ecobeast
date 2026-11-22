class_name DayLightLayer
extends ColorRect
## O filtro da hora por cima do mapa e do tabuleiro: a cor do céu e as luzes da noite
## (.specs/day-night/architecture.md#o-filtro-da-luz). Fica depois do mapa e antes da UI.

const SHADER_PATH := "res://ui/components/day_light.gdshader"
const MAX_LIGHTS := 32
## Os enxames de vagalumes por vez, fora do limite das luzes (fireflies/01).
const MAX_SWARMS := 32
## Até onde vão os pontinhos e a luz de um enxame, em pixels da arte (o SWARM_RADIUS do shader).
const SWARM_REACH := 16.0
## As bordas de lava acesas por vez, fora do limite das luzes (volcano/01), e o alcance da luz
## delas (o LAVA_RADIUS do shader).
const MAX_LAVA_GLOWS := 48
const LAVA_REACH := 40.0

## [hora, ambiente, saturação], em ordem de hora; depois das 24h volta ao primeiro. A revisar.
const KEYFRAMES: Array[Array] = [
	[0.0, Color(0.42, 0.48, 0.72), 0.65],
	[5.0, Color(0.42, 0.48, 0.72), 0.65],
	[6.5, Color(0.95, 0.84, 0.82), 0.95],
	[8.0, Color(1.0, 1.0, 1.0), 1.0],
	[16.0, Color(1.0, 1.0, 1.0), 1.0],
	[17.5, Color(1.0, 0.84, 0.64), 1.05],
	[19.0, Color(0.72, 0.56, 0.70), 0.85],
	[20.0, Color(0.42, 0.48, 0.72), 0.65],
]

## [hora, força das luzes].
const LIGHT_KEYFRAMES: Array[Array] = [
	[5.0, 1.0],
	[7.0, 0.0],
	[17.0, 0.0],
	[19.0, 1.0],
]

## Quanto o filtro passa de cada borda do pai: o chão do tabuleiro vai além do `Board`.
var margin := 0.0

var _material := ShaderMaterial.new()
var _lights: Array[MapLight] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	_material.shader = load(SHADER_PATH) as Shader
	material = _material
	visible = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = -margin
	offset_top = -margin
	offset_right = margin
	offset_bottom = margin


func _process(_delta: float) -> void:
	if not WorldClock.is_synced():
		visible = false
		return
	var hour := WorldClock.hour()
	var sky := sky_at(hour)
	var ambient: Color = sky[0]
	var saturation: float = sky[1]
	var strength := light_strength_at(hour)
	visible = not (ambient.is_equal_approx(Color.WHITE) and is_equal_approx(saturation, 1.0) and is_zero_approx(strength))
	if not visible:
		return
	_material.set_shader_parameter(&"ambient", Vector3(ambient.r, ambient.g, ambient.b))
	_material.set_shader_parameter(&"saturation", saturation)
	_material.set_shader_parameter(&"light_strength", strength)
	_material.set_shader_parameter(&"rect_size", size)


## A posição do ponto (0, 0) da arte, nas coordenadas deste retângulo, e os pixels por
## pixel da arte.
func set_view(art_origin: Vector2, art_scale: float) -> void:
	_material.set_shader_parameter(&"art_origin", art_origin)
	_material.set_shader_parameter(&"art_scale", maxf(art_scale, 0.0001))


## Até MAX_LIGHTS; as que passam ficam de fora.
func set_lights(lights: Array[MapLight]) -> void:
	_lights = lights.slice(0, MAX_LIGHTS)
	var points := PackedVector4Array()
	var colors := PackedColorArray()
	points.resize(MAX_LIGHTS)
	colors.resize(MAX_LIGHTS)
	for index: int in _lights.size():
		var light := _lights[index]
		points[index] = Vector4(light.position.x, light.position.y, light.radius, 0.0)
		colors[index] = light.color
	_material.set_shader_parameter(&"lights", points)
	_material.set_shader_parameter(&"light_colors", colors)
	_material.set_shader_parameter(&"light_count", _lights.size())


## Os centros dos enxames de vagalumes, em pixels da arte; os que passam ficam de fora.
func set_swarms(points: PackedVector2Array) -> void:
	var count := mini(points.size(), MAX_SWARMS)
	var padded := points.slice(0, count)
	padded.resize(MAX_SWARMS)
	_material.set_shader_parameter(&"swarms", padded)
	_material.set_shader_parameter(&"swarm_count", count)


## Onde está a lava do mapa, um pixel por hexágono (R: lava; G: altura + 1), para o
## shader não escurecer a lava. Sem lava, o shader nem procura.
func set_lava_map(map: ExplorationMap) -> void:
	var low := Vector2i.MAX
	var high := Vector2i.MIN
	var has_lava := false
	for tile: HexTile in map.tiles.values():
		low = low.min(tile.coord)
		high = high.max(tile.coord)
		has_lava = has_lava or tile.is_lava()
	_material.set_shader_parameter(&"lava_on", has_lava)
	if not has_lava:
		return
	var data_size := high - low + Vector2i.ONE
	var image := Image.create_empty(data_size.x, data_size.y, false, Image.FORMAT_RG8)
	for tile: HexTile in map.tiles.values():
		image.set_pixelv(tile.coord - low, Color(1.0 if tile.is_lava() else 0.0, (tile.height + 1) / 255.0, 0.0))
	_material.set_shader_parameter(&"lava_data", ImageTexture.create_from_image(image))
	_material.set_shader_parameter(&"data_origin", Vector2(low))
	_material.set_shader_parameter(&"data_size", Vector2(data_size))


## As bordas de lava acesas, em pixels da arte; as que passam ficam de fora.
func set_lava_glows(points: PackedVector2Array) -> void:
	var count := mini(points.size(), MAX_LAVA_GLOWS)
	var padded := points.slice(0, count)
	padded.resize(MAX_LAVA_GLOWS)
	_material.set_shader_parameter(&"lava_glows", padded)
	_material.set_shader_parameter(&"lava_glow_count", count)


## [ambiente, saturação] na hora, misturando em linha reta os dois pontos em volta.
static func sky_at(hour: float) -> Array:
	var pair := _around(KEYFRAMES, hour)
	var before: Array = pair[0]
	var after: Array = pair[1]
	var weight: float = pair[2]
	return [(before[1] as Color).lerp(after[1], weight), lerpf(before[2], after[2], weight)]


static func light_strength_at(hour: float) -> float:
	var pair := _around(LIGHT_KEYFRAMES, hour)
	return lerpf(pair[0][1], pair[1][1], pair[2])


## [ponto antes, ponto depois, peso de 0 a 1], dando a volta nas 24h.
static func _around(frames: Array[Array], hour: float) -> Array:
	var count := frames.size()
	for index: int in count:
		var after: Array = frames[index]
		if hour < after[0]:
			var before: Array = frames[(index - 1 + count) % count]
			var start: float = before[0] if index > 0 else before[0] - 24.0
			return [before, after, inverse_lerp(start, after[0], hour)]
	var last: Array = frames[count - 1]
	var first: Array = frames[0]
	return [last, first, inverse_lerp(last[0], first[0] + 24.0, hour)]
