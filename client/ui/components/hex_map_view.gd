class_name HexMapView
extends Node2D
## O mapa de exploração na tela (wild-battle/01). Um nó só desenha todos os
## hexágonos em _draw, de cima para baixo, para quem está mais abaixo cobrir a
## lateral de quem está acima. A geometria vem dos sprites
## (.specs/wild-battle/architecture.md).

## Os passos deixam um vão entre os hexágonos, do exemplo do dono. Encostados
## (sem vão) seriam 32, 21 e 16.
const STEP_X := 34
const STEP_Y := 24
const ROW_SHIFT := 17
## Centro da superfície dentro do sprite de 32×48.
const SURFACE_CENTER := Vector2(16.0, 20.0)
## Pontos da tela lógica por pixel da arte, antes de arredondar. A revisar.
const ART_SCALE := 3.0

var _tiles: Array[HexTile] = []
var _textures: Dictionary[String, Texture2D] = {}
## Pixels reais por ponto da tela lógica, em cada eixo.
var _window_scale := Vector2.ONE


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	get_viewport().size_changed.connect(_update_scale)
	_update_scale()


func _draw() -> void:
	for tile: HexTile in _tiles:
		var texture := _texture(tile.sprite_path())
		if texture != null:
			draw_texture(texture, _tile_origin(tile.coord))


## Pode ser chamado antes ou depois de o nó entrar na árvore.
func set_map(map: ExplorationMap) -> void:
	_tiles = map.tiles.values()
	_tiles.sort_custom(_is_drawn_before)
	queue_redraw()


## O centro da superfície de um hexágono, em pixels da arte.
func surface_center(coord: Vector2i) -> Vector2:
	return _tile_origin(coord) + SURFACE_CENTER


## O hexágono que contém um ponto, em pixels da arte. Não confere se ele existe.
func coord_at(point: Vector2) -> Vector2i:
	var relative := point - SURFACE_CENTER
	var r := relative.y / STEP_Y
	var q := (relative.x - ROW_SHIFT * r) / STEP_X
	var s := -q - r
	var rounded_q := roundf(q)
	var rounded_r := roundf(r)
	var rounded_s := roundf(s)
	# As três coordenadas somam 0: a que mais arredondou é recalculada.
	var error_q := absf(rounded_q - q)
	var error_r := absf(rounded_r - r)
	if error_q > error_r and error_q > absf(rounded_s - s):
		rounded_q = -rounded_r - rounded_s
	elif error_r > absf(rounded_s - s):
		rounded_r = -rounded_q - rounded_s
	return Vector2i(roundi(rounded_q), roundi(rounded_r))


## A escala do nó na tela lógica, que dá um número inteiro de pixels reais.
func pixel_scale() -> Vector2:
	return scale


## Arredonda uma posição da tela lógica para um pixel real inteiro.
func snapped_to_pixels(value: Vector2) -> Vector2:
	return (value * _window_scale).round() / _window_scale


## Um eixo de cada vez: a tela lógica tem tamanho inteiro, então a escala da
## janela nunca é exatamente igual nos dois, e a diferença se acumula no mapa.
func _update_scale() -> void:
	_window_scale = Vector2(get_window().size) / get_viewport_rect().size
	var pixels := maxi(1, roundi(_window_scale.y * ART_SCALE))
	scale = Vector2(pixels, pixels) / _window_scale


func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		if ResourceLoader.exists(path):
			_textures[path] = load(path) as Texture2D
		else:
			push_error("HexMapView: falta o sprite '%s'" % path)
			_textures[path] = null
	return _textures[path]


static func _tile_origin(coord: Vector2i) -> Vector2:
	return Vector2(STEP_X * coord.x + ROW_SHIFT * coord.y, STEP_Y * coord.y)


static func _is_drawn_before(a: HexTile, b: HexTile) -> bool:
	return a.coord.y < b.coord.y
