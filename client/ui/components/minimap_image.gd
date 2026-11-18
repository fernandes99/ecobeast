class_name MinimapImage
extends RefCounted
## A planta do mapa descoberto, vista de cima, que o minimapa e o mapa grande mostram
## (.specs/minimap/architecture.md): um pixel vale ART_PER_PIXEL pixels da arte no chão
## plano, com a cor do bioma, o chão, os caminhos, as pontes e a sombra da costa, e a
## névoa no que não foi descoberto.
##
## A grade se repete: andar 64 px da arte é o hexágono do lado, e 336 px para baixo é
## (-4, 8). Com 16 px por pixel, os pixels de um hexágono são os do molde da linha dele
## (r módulo 8) deslocados, sem perguntar o dono pixel a pixel.

## A revisar.
const ART_PER_PIXEL := 16.0
const GLIMPSE := 0.5
## A caixa do topo plano de um hexágono (HexMapView.HEX_CORNERS).
const HEX_BOX := Vector2(64.0, 58.0)
const OPEN_WATER: Array[String] = ["wshallow", "wdeep"]
const BRIDGE_STEP := 4.0
const PERIOD_ROWS := 8
const PERIOD_PIXELS := Vector2i(4, 21)
const PERIOD_Q := 4
const LOWER_NEIGHBORS: Array[Vector2i] = [Vector2i(-1, 1), Vector2i(0, 1)]

static var _patterns: Array = []

var texture: ImageTexture = null
var image_size := Vector2i.ZERO

var _map: ExplorationMap = null
var _discovery: MapDiscovery = null
var _show_all := false
var _origin := Vector2.ZERO
var _origin_pixel := Vector2i.ZERO
var _image: Image = null
var _tile_colors: Dictionary[Vector2i, Color] = {}
## Os pixels com cor própria: a sombra da costa, os caminhos e as pontes.
var _overrides: Dictionary[int, Color] = {}
## Quanto cada hexágono aparece; os que não estão aqui ficam na névoa.
var _seen: Dictionary[Vector2i, float] = {}


func build(map: ExplorationMap, discovery: MapDiscovery, show_all: bool) -> void:
	_map = map
	_discovery = discovery
	_show_all = show_all
	_measure()
	_tile_colors.clear()
	_overrides.clear()
	for coord: Vector2i in _map.tiles:
		var tile := _map.tiles[coord]
		var color := _ground_color(tile.ground)
		_tile_colors[coord] = color if color.a > 0.0 else MinimapPalette.biome(tile.biome)
	_shade_shore()
	_paint_trails()
	_seen.clear()
	if _show_all:
		for coord: Vector2i in _map.tiles:
			_seen[coord] = 1.0
	else:
		for coord: Vector2i in _discovery.all():
			_update_seen(coord)
			for near: Vector2i in _map.neighbors(coord):
				_update_seen(near)
	_image = Image.create_empty(image_size.x, image_size.y, false, Image.FORMAT_RGB8)
	_image.fill(MinimapPalette.FOG)
	for coord: Vector2i in _seen:
		_paint_tile(coord)
	texture = ImageTexture.create_from_image(_image)


## Repinta os hexágonos recém-descobertos e o anel em volta deles.
func reveal(coords: Array[Vector2i]) -> void:
	if _image == null or coords.is_empty():
		return
	var touched: Dictionary[Vector2i, bool] = {}
	for coord: Vector2i in coords:
		touched[coord] = true
		for near: Vector2i in _map.neighbors(coord):
			touched[near] = true
	var changed := false
	for coord: Vector2i in touched:
		if _update_seen(coord):
			_paint_tile(coord)
			changed = true
	if changed:
		texture.update(_image)


## De um ponto do chão plano para o ponto da imagem, em pixels dela.
func art_to_image(flat: Vector2) -> Vector2:
	return (flat - _origin) / ART_PER_PIXEL


func image_to_art(point: Vector2) -> Vector2:
	return _origin + point * ART_PER_PIXEL


## Uma cópia da imagem de agora (sem janela, a textura não devolve a atualizada).
func snapshot() -> Image:
	return _image.duplicate() as Image


func owner_at(pixel: Vector2i) -> Vector2i:
	var coord := HexMapView.grid_coord(_origin + (Vector2(pixel) + Vector2(0.5, 0.5)) * ART_PER_PIXEL)
	return coord if _map.has(coord) else Vector2i.MAX


func pixels_of(coord: Vector2i) -> Array[Vector2i]:
	var row := posmod(coord.y, PERIOD_ROWS)
	var periods := (coord.y - row) / PERIOD_ROWS
	var shift := Vector2i(PERIOD_PIXELS.x * (coord.x + PERIOD_Q * periods), PERIOD_PIXELS.y * periods) - _origin_pixel
	var out: Array[Vector2i] = []
	for pixel: Vector2i in _pattern(row):
		var at := pixel + shift
		if at.x >= 0 and at.y >= 0 and at.x < image_size.x and at.y < image_size.y:
			out.append(at)
	return out


## Os pixels absolutos (contados do ponto 0 da arte) do hexágono (0, row).
static func _pattern(row: int) -> Array[Vector2i]:
	if _patterns.is_empty():
		for index: int in PERIOD_ROWS:
			var pixels: Array[Vector2i] = []
			var coord := Vector2i(0, index)
			var corner := HexMapView.flat_center(coord) - HexMapView.SURFACE_CENTER
			var low := Vector2i((corner / ART_PER_PIXEL).floor()) - Vector2i.ONE
			var high := Vector2i(((corner + HEX_BOX) / ART_PER_PIXEL).ceil()) + Vector2i.ONE
			for y: int in range(low.y, high.y + 1):
				for x: int in range(low.x, high.x + 1):
					if HexMapView.grid_coord((Vector2(x, y) + Vector2(0.5, 0.5)) * ART_PER_PIXEL) == coord:
						pixels.append(Vector2i(x, y))
			_patterns.append(pixels)
	return _patterns[row]


func _measure() -> void:
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for coord: Vector2i in _map.tiles:
		var corner := HexMapView.flat_center(coord) - HexMapView.SURFACE_CENTER
		low = low.min(corner)
		high = high.max(corner)
	if _map.tiles.is_empty():
		low = Vector2.ZERO
		high = Vector2.ZERO
	_origin_pixel = Vector2i((low / ART_PER_PIXEL).floor())
	_origin = Vector2(_origin_pixel) * ART_PER_PIXEL
	image_size = Vector2i(((high + HEX_BOX - _origin) / ART_PER_PIXEL).ceil()).max(Vector2i.ONE)


## A terra com água aberta logo abaixo fica mais escura: a beira da ilha.
func _shade_shore() -> void:
	for coord: Vector2i in _map.tiles:
		var tile := _map.tiles[coord]
		if HexTile.WATER_BIOMES.has(tile.biome) or not _has_water_below(coord):
			continue
		var color := _tile_colors[coord]
		var shaded := Color(color.r * MinimapPalette.SHORE_SHADE, color.g * MinimapPalette.SHORE_SHADE, color.b * MinimapPalette.SHORE_SHADE)
		for pixel: Vector2i in pixels_of(coord):
			var below := owner_at(pixel + Vector2i.DOWN)
			if below != Vector2i.MAX and OPEN_WATER.has(_map.tiles[below].biome):
				_overrides[_pixel_index(pixel)] = shaded


func _has_water_below(coord: Vector2i) -> bool:
	for step: Vector2i in LOWER_NEIGHBORS:
		var near := _map.tile_at(coord + step)
		if near != null and OPEN_WATER.has(near.biome):
			return true
	return false


func _paint_trails() -> void:
	for trail: MapTrail in _map.trails:
		var color := _ground_color(trail.ground)
		if color.a == 0.0:
			continue
		for point: Vector2 in HexGrounds.smoothed(trail):
			_stamp(point, trail.width / 2.0, color)
	for bridge: MapBridge in _map.bridges:
		var steps := maxi(1, ceili(bridge.from.distance_to(bridge.to) / BRIDGE_STEP))
		for step: int in steps + 1:
			_stamp(bridge.from.lerp(bridge.to, float(step) / steps), bridge.width / 2.0, MinimapPalette.BRIDGE)


## Pinta os pixels a até `art_radius` do ponto, e pelo menos o pixel dele.
func _stamp(flat: Vector2, art_radius: float, color: Color) -> void:
	var center := art_to_image(flat)
	var radius := maxf(art_radius / ART_PER_PIXEL, 0.5)
	for y: int in range(floori(center.y - radius), ceili(center.y + radius) + 1):
		for x: int in range(floori(center.x - radius), ceili(center.x + radius) + 1):
			if x < 0 or y < 0 or x >= image_size.x or y >= image_size.y:
				continue
			var inside := Vector2(x + 0.5, y + 0.5).distance_to(center) <= radius
			if (inside or Vector2i(x, y) == Vector2i(center.floor())) and owner_at(Vector2i(x, y)) != Vector2i.MAX:
				_overrides[y * image_size.x + x] = color


static func _ground_color(ground: String) -> Color:
	match HexGrounds.kind_of(ground):
		HexGrounds.TRAIL:
			return MinimapPalette.TRAIL
		HexGrounds.FLOOR:
			return MinimapPalette.FLOOR
	return Color.TRANSPARENT


## Recalcula quanto o hexágono aparece e diz se mudou.
func _update_seen(coord: Vector2i) -> bool:
	if not _map.has(coord):
		return false
	var value := _value_of(coord)
	if value == _seen.get(coord, 0.0):
		return false
	if value > 0.0:
		_seen[coord] = value
	else:
		_seen.erase(coord)
	return true


func _value_of(coord: Vector2i) -> float:
	if _show_all or _discovery.is_discovered(coord):
		return 1.0
	for near: Vector2i in _map.neighbors(coord):
		if _discovery.is_discovered(near):
			return GLIMPSE
	return 0.0


func _paint_tile(coord: Vector2i) -> void:
	var seen: float = _seen.get(coord, 0.0)
	var color: Color = _tile_colors[coord]
	for pixel: Vector2i in pixels_of(coord):
		var base: Color = _overrides.get(_pixel_index(pixel), color)
		_image.set_pixelv(pixel, base if seen >= 1.0 else base.lerp(MinimapPalette.FOG, 1.0 - seen))


func _pixel_index(pixel: Vector2i) -> int:
	return pixel.y * image_size.x + pixel.x
