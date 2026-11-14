class_name GroundMask
extends Node
## O chão de uma ilha numa imagem do chão plano, em páginas, com o id do tipo no canal
## vermelho (.specs/free-trails/architecture.md). Cada página é um SubViewport que
## desenha as trilhas e os pisos por hexágono e os traços; a textura dele é lida pelo
## shader do chão. Só existem as páginas com chão.

const PAGE_SIZE := 2048.0
const TEXEL := 2.0
const MARGIN := 32
const TEXELS := int(PAGE_SIZE / TEXEL) + MARGIN * 2
const TRAIL_WIDTH := 22.0

var _map: ExplorationMap = null
var _pages: Dictionary[Vector2i, SubViewport] = {}
var _ground_tiles: Dictionary[Vector2i, bool] = {}
var _trails: Array[MapTrail] = []
var _trail_tiles: Dictionary[Vector2i, bool] = {}
var _ids: Dictionary[String, int] = {}


func set_map(map: ExplorationMap) -> void:
	_map = map
	_ids.clear()
	for row: Dictionary in GameData.get_rows("ground_types"):
		_ids[str(row.get("slug", ""))] = int(row.get("id", 0))
	_ground_tiles.clear()
	for tile: HexTile in map.tiles.values():
		if not tile.ground.is_empty():
			_ground_tiles[tile.coord] = true
	_trails = map.trails.duplicate()
	_mark_trail_tiles()
	for page: SubViewport in _pages.values():
		remove_child(page)
		page.queue_free()
	_pages.clear()
	_refresh_pages(_all_page_keys())


func set_trails(trails: Array[MapTrail], changed: Array[MapTrail]) -> void:
	_trails = trails.duplicate()
	_mark_trail_tiles()
	var keys: Dictionary[Vector2i, bool] = {}
	for trail: MapTrail in changed:
		for key: Vector2i in _pages_of_rect(trail_bounds(trail)):
			keys[key] = true
	_refresh_pages(keys.keys())


## Os hexágonos mudaram: refaz o chão deles e redesenha as páginas em volta.
func update_tiles(coords: Array[Vector2i]) -> void:
	var keys: Dictionary[Vector2i, bool] = {}
	for coord: Vector2i in coords:
		var tile := _map.tile_at(coord)
		if tile != null and not tile.ground.is_empty():
			_ground_tiles[coord] = true
		else:
			_ground_tiles.erase(coord)
		for key: Vector2i in _pages_of_rect(_hex_bounds(coord).grow(HexMapView.STEP_X)):
			keys[key] = true
	_refresh_pages(keys.keys())


func page_keys() -> Array[Vector2i]:
	return _pages.keys()


static func page_of(flat: Vector2) -> Vector2i:
	return Vector2i(floori(flat.x / PAGE_SIZE), floori(flat.y / PAGE_SIZE))


static func page_origin(key: Vector2i) -> Vector2:
	return Vector2(key) * PAGE_SIZE


func texture_of(key: Vector2i) -> Texture2D:
	var page: SubViewport = _pages.get(key)
	return page.get_texture() if page != null else null


## Se um hexágono precisa da malha de chão: tem chão, um vizinho com chão ou um traço
## passando nele.
func covers(coord: Vector2i) -> bool:
	if _ground_tiles.has(coord):
		return true
	for offset: Vector2i in HexGrounds.EDGE_NEIGHBORS:
		if _ground_tiles.has(coord + offset):
			return true
	return _trail_tiles.has(coord)


func has_trail(coord: Vector2i) -> bool:
	return _trail_tiles.has(coord)


## O id do chão num ponto do chão plano, lido da página já desenhada (para testes).
func id_at(flat: Vector2) -> int:
	var page: SubViewport = _pages.get(page_of(flat))
	if page == null:
		return 0
	var image := page.get_texture().get_image()
	var texel := Vector2i(((flat - page_origin(page_of(flat))) / TEXEL).floor()) + Vector2i(MARGIN, MARGIN)
	return roundi(image.get_pixel(texel.x, texel.y).r8) if image != null else -1


static func trail_bounds(trail: MapTrail) -> Rect2:
	var bounds := Rect2(trail.points[0], Vector2.ZERO)
	for point: Vector2 in trail.points:
		bounds = bounds.expand(point)
	return bounds.grow(trail.width / 2.0 + HexMapView.STEP_X)


## Os hexágonos que um traço pode pintar: o de cada ponto suavizado e os vizinhos
## (mais uma volta para os traços largos).
static func trail_coords(trail: MapTrail) -> Array[Vector2i]:
	var marked: Dictionary[Vector2i, bool] = {}
	var rings := 2 if trail.width > 40 else 1
	for point: Vector2 in HexGrounds.smoothed(trail):
		var center := HexMapView.grid_coord(point)
		if marked.has(center):
			continue
		marked[center] = true
		var ring: Array[Vector2i] = [center]
		for _ring: int in rings:
			var next: Array[Vector2i] = []
			for coord: Vector2i in ring:
				for offset: Vector2i in HexGrounds.EDGE_NEIGHBORS:
					next.append(coord + offset)
			for coord: Vector2i in next:
				marked[coord] = true
			ring = next
	return marked.keys()


func _mark_trail_tiles() -> void:
	_trail_tiles.clear()
	for trail: MapTrail in _trails:
		for coord: Vector2i in trail_coords(trail):
			_trail_tiles[coord] = true


func _all_page_keys() -> Array[Vector2i]:
	var keys: Dictionary[Vector2i, bool] = {}
	for coord: Vector2i in _ground_tiles:
		for key: Vector2i in _pages_of_rect(_hex_bounds(coord).grow(HexMapView.STEP_X)):
			keys[key] = true
	for trail: MapTrail in _trails:
		for key: Vector2i in _pages_of_rect(trail_bounds(trail)):
			keys[key] = true
	return keys.keys()


## Cria, redesenha ou apaga as páginas: uma página fica enquanto algum hexágono da
## malha de chão tem o centro nela.
func _refresh_pages(keys: Array[Vector2i]) -> void:
	for key: Vector2i in keys:
		if _page_needed(key):
			if not _pages.has(key):
				_pages[key] = _new_page(key)
			var page := _pages[key]
			(page.get_child(0) as CanvasItem).queue_redraw()
			page.render_target_update_mode = SubViewport.UPDATE_ONCE
		elif _pages.has(key):
			var page := _pages[key]
			_pages.erase(key)
			remove_child(page)
			page.queue_free()


func _page_needed(key: Vector2i) -> bool:
	var area := Rect2(page_origin(key), Vector2.ONE * PAGE_SIZE)
	for coord: Vector2i in _ground_tiles:
		if area.has_point(HexMapView.flat_center(coord)):
			return true
		for offset: Vector2i in HexGrounds.EDGE_NEIGHBORS:
			if area.has_point(HexMapView.flat_center(coord + offset)):
				return true
	for trail: MapTrail in _trails:
		if trail_bounds(trail).intersects(area):
			return true
	return false


func _pages_of_rect(rect: Rect2) -> Array[Vector2i]:
	var keys: Array[Vector2i] = []
	var first := page_of(rect.position - Vector2.ONE * MARGIN * TEXEL)
	var last := page_of(rect.end + Vector2.ONE * MARGIN * TEXEL)
	for y: int in range(first.y, last.y + 1):
		for x: int in range(first.x, last.x + 1):
			keys.append(Vector2i(x, y))
	return keys


static func _hex_bounds(coord: Vector2i) -> Rect2:
	return Rect2(HexMapView.flat_center(coord) - HexMapView.SURFACE_CENTER, Vector2(HexMapView.STEP_X, HexMapView.HEX_CORNERS[3].y))


func _new_page(key: Vector2i) -> SubViewport:
	var page := SubViewport.new()
	page.size = Vector2i(TEXELS, TEXELS)
	page.transparent_bg = true
	page.disable_3d = true
	page.render_target_update_mode = SubViewport.UPDATE_ONCE
	var canvas := Node2D.new()
	canvas.draw.connect(_draw_page.bind(canvas, key))
	page.add_child(canvas)
	add_child(page)
	page.canvas_transform = Transform2D(0.0, Vector2.ONE / TEXEL, 0.0, Vector2(MARGIN, MARGIN) - page_origin(key) / TEXEL)
	return page


func _draw_page(canvas: Node2D, key: Vector2i) -> void:
	var area := Rect2(page_origin(key), Vector2.ONE * PAGE_SIZE).grow(MARGIN * TEXEL + HexMapView.STEP_X)
	var floors: Array[HexTile] = []
	for coord: Vector2i in _ground_tiles:
		if not area.has_point(HexMapView.flat_center(coord)):
			continue
		var tile := _map.tile_at(coord)
		if HexGrounds.kind_of(tile.ground) == HexGrounds.FLOOR:
			floors.append(tile)
		else:
			HexGrounds.draw_trail_tile(canvas, tile, _map, _color(tile.ground))
	for tile: HexTile in floors:
		HexGrounds.draw_floor_tile(canvas, tile, _color(tile.ground))
	for trail: MapTrail in _trails:
		if trail_bounds(trail).intersects(area):
			HexGrounds.draw_trail(canvas, trail, _color(trail.ground))


func _color(slug: String) -> Color:
	return Color8(_ids.get(slug, 0), 0, 0, 255)
