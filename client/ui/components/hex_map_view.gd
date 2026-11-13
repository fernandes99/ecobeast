class_name HexMapView
extends Node2D
## O mapa de exploração na tela (wild-battle/04 a 12). Três HexRowView por linha, de
## trás para a frente, com uma malha por textura: quem está na frente cobre quem
## está atrás. O ponto da textura vem da posição no mapa, antes da altura, e não
## do hexágono, então cada bioma é uma superfície contínua. Uma linha só é montada
## quando chega perto da tela, porque criar as malhas do mapa inteiro de uma vez
## trava o jogo (.specs/wild-battle/architecture.md).

const STEP_X := 64
const STEP_Y := 42
const ROW_SHIFT := 32
## Altura de cada HexTile.height, em pixels da arte: múltiplos de 8.
const LEVEL_HEIGHTS: Array[float] = [0.0, 8.0, 16.0, 24.0, 32.0]
const SIDE_HEIGHT := 26.0
const TILE_SIZE := Vector2(64.0, 84.0)
const SURFACE_CENTER := Vector2(32.0, 29.0)
const HEX_CORNERS: Array[Vector2] = [
	Vector2(32.0, 0.0),
	Vector2(64.0, 16.0),
	Vector2(64.0, 42.0),
	Vector2(32.0, 58.0),
	Vector2(0.0, 42.0),
	Vector2(0.0, 16.0),
]
const LOWER_NEIGHBORS: Array[Vector2i] = [Vector2i(-1, 1), Vector2i(0, 1)]
const LOWER_EDGE_CORNERS: Array[Vector2i] = [Vector2i(4, 3), Vector2i(3, 2)]
const FACE_COLORS: Array[Color] = [Color.WHITE, Color(0.76, 0.76, 0.76)]
## Quantas linhas além da borda da tela já ficam montadas: com a altura e as
## árvores, uma linha aparece bem antes de a posição dela chegar à tela.
const ROW_MARGIN := 3
const ART_SCALE := 2.0
const SURFACE_PATH := "res://assets/terrain/surfaces/%s.png"
const CLIFF_BIOMES: Array[String] = ["stone", "mountain"]
const CONTOUR_TEXTURE := "contour"
const HIGHLIGHT_TEXTURE := "highlight"

var fixed_scale := 0.0:
	set(value):
		fixed_scale = value
		if is_inside_tree():
			_update_scale()
var allows_decoration := Callable()

var chunk_columns := 0

var _map: ExplorationMap = null
var _textures: Dictionary[String, Texture2D] = {}
var _rows: Dictionary[Vector2i, HexRowView] = {}
## As decorações de cada pedaço, em nós próprios, porque o vento é um material e vale
## para o nó inteiro. As da metade de cima dos hexágonos e as da metade de baixo, com
## o ator entre as duas.
var _back_rows: Dictionary[Vector2i, HexRowView] = {}
var _front_rows: Dictionary[Vector2i, HexRowView] = {}
## Os pedaços de cada linha. Na árvore, uma linha tem primeiro o chão de todos os
## pedaços, depois as decorações de trás e por último as da frente: uma árvore que
## passa da borda do hexágono fica por cima do chão do pedaço ao lado.
var _row_chunks: Dictionary[int, Array] = {}
var _wind_material := ShaderMaterial.new()
var _terrain_material := ShaderMaterial.new()
var _unbuilt_rows: Dictionary[Vector2i, Array] = {}
var _highlighted_row: HexRowView = null
var _hex_triangles := PackedVector2Array()
var _window_scale := Vector2.ONE
var _whole_map_area := Rect2()
var _objects: Array[MapObjectSprite] = []


func _init() -> void:
	_wind_material.shader = load(HexDecorations.WIND_SHADER_PATH) as Shader
	_terrain_material.shader = load(HexGrounds.SHADER_PATH) as Shader
	for corner: int in range(1, HEX_CORNERS.size() - 1):
		_hex_triangles.append_array(PackedVector2Array([HEX_CORNERS[0], HEX_CORNERS[corner], HEX_CORNERS[corner + 1]]))


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	get_viewport().size_changed.connect(_update_scale)
	_update_scale()


func _process(_delta: float) -> void:
	if _unbuilt_rows.is_empty():
		return
	var height := get_viewport_rect().size.y
	var first_row := floori(-position.y / scale.y / STEP_Y) - ROW_MARGIN
	var last_row := ceili((height - position.y) / scale.y / STEP_Y) + ROW_MARGIN
	for key: Vector2i in _unbuilt_rows.keys():
		if key.y >= first_row and key.y <= last_row:
			_build_chunk(key)


func set_map(map: ExplorationMap) -> void:
	_map = map
	_clear_objects()
	for row: HexRowView in _rows.values() + _back_rows.values() + _front_rows.values():
		remove_child(row)
		row.queue_free()
	_rows.clear()
	_back_rows.clear()
	_front_rows.clear()
	_row_chunks.clear()
	_unbuilt_rows.clear()
	_highlighted_row = null
	for tile: HexTile in map.tiles.values():
		var key := _chunk_of(tile.coord)
		if not _unbuilt_rows.has(key):
			_unbuilt_rows[key] = []
		_unbuilt_rows[key].append(tile)
	for key: Vector2i in _unbuilt_rows:
		if not _row_chunks.has(key.y):
			_row_chunks[key.y] = []
		_row_chunks[key.y].append(key.x)
	var row_numbers: Array = _row_chunks.keys()
	row_numbers.sort()
	# Os nós nascem na ordem certa, mesmo que as malhas venham fora de ordem.
	for row_number: int in row_numbers:
		var chunks: Array = _row_chunks[row_number]
		chunks.sort()
		for chunk: int in chunks:
			_rows[Vector2i(chunk, row_number)] = _new_terrain_row()
		for chunk: int in chunks:
			_back_rows[Vector2i(chunk, row_number)] = _new_decoration_row()
		for chunk: int in chunks:
			_front_rows[Vector2i(chunk, row_number)] = _new_decoration_row()


## Os hexágonos mudaram no mapa (o editor de ilhas pinta, põe e tira, map-editor/03):
## refaz os pedaços deles e os vizinhos, porque os paredões, os arremates e os
## escorridos de um hexágono dependem dos seis vizinhos. Um pedaço que ainda não foi
## montado só troca a lista; ele é montado ao chegar perto da tela.
func update_tiles(coords: Array[Vector2i]) -> void:
	if _map == null or coords.is_empty():
		return
	# Com pedaços, o vizinho de uma ponta pode estar no pedaço ao lado.
	var spread: Array[int] = [0]
	if chunk_columns > 0:
		spread = [-1, 0, 1]
	var by_chunk: Dictionary[Vector2i, Array] = {}
	for coord: Vector2i in coords:
		for dr: int in [-1, 0, 1]:
			for dq: int in spread:
				by_chunk[_chunk_of(coord + Vector2i(dq, dr))] = []
	if chunk_columns > 0:
		for key: Vector2i in by_chunk:
			for q: int in range(key.x * chunk_columns, (key.x + 1) * chunk_columns):
				var tile := _map.tile_at(Vector2i(q, key.y))
				if tile != null:
					by_chunk[key].append(tile)
	else:
		for tile: HexTile in _map.tiles.values():
			var key := _chunk_of(tile.coord)
			if by_chunk.has(key):
				by_chunk[key].append(tile)
	for key: Vector2i in by_chunk:
		var tiles: Array = by_chunk[key]
		if not _rows.has(key):
			if tiles.is_empty():
				continue
			_add_chunk_nodes(key)
			_unbuilt_rows[key] = tiles
			continue
		if _unbuilt_rows.has(key):
			_unbuilt_rows[key] = tiles
			continue
		var row := _rows[key]
		var back := _back_rows[key]
		var front := _front_rows[key]
		for view: HexRowView in [row, back, front]:
			view.meshes.clear()
			view.textures.clear()
			view.queue_redraw()
		if not tiles.is_empty():
			_build_row(row, back, front, tiles)
	for sprite: MapObjectSprite in _objects:
		sprite.place(_rise(_level_at(sprite.object.coord)))
		if sprite.fence:
			var art := _fence_art(sprite.object)
			if art != null:
				sprite.set_fence_texture(art)


## Os objetos da ilha (island-villages/03): cada um entra logo depois do chão da linha
## seguinte à da frente dele, por baixo das decorações e dos atores dela (ou, com um
## hexágono da frente mais alto, antes das decorações da frente da própria linha).
## Chame depois do `set_map`.
func set_objects(objects: Array[MapObject]) -> void:
	_clear_objects()
	for object: MapObject in objects:
		var row := GameData.get_row("map_object_types", object.object_type_id)
		# A Vegetação não tem arte própria: as plantas dela saem das decorações.
		if str(row.get("slug", "")) == HexDecorations.PLANTS_SLUG:
			continue
		var sprite := MapObjectSprite.new()
		var slug := str(row.get("slug", ""))
		var fence_art := _fence_art(object) if HexFences.is_fence(slug) else null
		if fence_art != null:
			sprite.setup_fence(object, fence_art)
		elif not sprite.setup(object, slug):
			sprite.free()
			continue
		add_child(sprite)
		_objects.append(sprite)
		_place_object(sprite)


## O objeto cuja arte está desenhada num ponto, em pixels da arte, da frente para
## trás; ou `null`.
func object_hit(point: Vector2) -> MapObject:
	var best: MapObjectSprite = null
	for sprite: MapObjectSprite in _objects:
		if sprite.hits(point) and (best == null or sprite.get_index() > best.get_index()):
			best = sprite
	return best.object if best != null else null


func _fence_art(object: MapObject) -> Texture2D:
	var slug := str(GameData.get_row("map_object_types", object.object_type_id).get("slug", ""))
	return HexFences.texture(slug, object.variant, HexFences.links(_map, object.coord, object.object_type_id))


func _clear_objects() -> void:
	for sprite: MapObjectSprite in _objects:
		remove_child(sprite)
		sprite.queue_free()
	_objects.clear()


## A arte que desce da borda de baixo do objeto (a pá do moinho) passa por cima do
## chão da linha da frente, a não ser que um hexágono da frente encostado nele seja
## mais alto: aí o chão dele cobre, como um degrau.
func _place_object(sprite: MapObjectSprite) -> void:
	sprite.place(_rise(_level_at(sprite.object.coord)))
	var row := sprite.front_row
	if not _row_chunks.has(row):
		return
	var at := _last_index(_back_rows, row) + 1
	if _row_chunks.has(row + 1) and not _front_is_higher(sprite.object, row):
		at = _first_index(_back_rows, row + 1)
	move_child(sprite, at if sprite.get_index() > at else at - 1)


func _front_is_higher(object: MapObject, row: int) -> bool:
	var level := _level_at(object.coord)
	for coord: Vector2i in object.tiles:
		if coord.y != row:
			continue
		for below: Vector2i in [coord + Vector2i(-1, 1), coord + Vector2i(0, 1)]:
			if _map.has(below) and _level_at(below) > level:
				return true
	return false


func build_all_rows() -> void:
	for key: Vector2i in _unbuilt_rows.keys():
		_build_chunk(key)


func set_actor_row(actor: Node2D, row: int) -> void:
	var front := _first_index(_front_rows, row)
	move_child(actor, front if actor.get_index() > front else front - 1)


## Põe um filho deste nó logo por cima do terreno de uma linha: por baixo das
## decorações dela, dos atores e das linhas seguintes (islands/03). Chame depois do
## `set_map`, que monta as linhas.
func set_ground_overlay(overlay: Node2D, row: int) -> void:
	if overlay.get_parent() != self:
		add_child(overlay)
	var back := _first_index(_back_rows, row)
	move_child(overlay, back if overlay.get_index() > back else back - 1)


func set_current(coord: Vector2i) -> void:
	if _highlighted_row != null:
		_highlighted_row.highlight = null
		_highlighted_row.queue_redraw()
	_highlighted_row = _rows[_chunk_of(coord)]
	_highlighted_row.highlight = _texture(SURFACE_PATH % HIGHLIGHT_TEXTURE)
	_highlighted_row.highlight_position = _tile_origin(coord) - _rise(_level_at(coord))
	_highlighted_row.queue_redraw()


func _chunk_of(coord: Vector2i) -> Vector2i:
	if chunk_columns <= 0:
		return Vector2i(0, coord.y)
	return Vector2i(floori(float(coord.x) / chunk_columns), coord.y)


func _build_chunk(key: Vector2i) -> void:
	_build_row(_rows[key], _back_rows[key], _front_rows[key], _unbuilt_rows[key])
	_unbuilt_rows.erase(key)


func _first_index(views: Dictionary[Vector2i, HexRowView], row: int) -> int:
	var first := get_child_count()
	for chunk: int in _row_chunks[row]:
		first = mini(first, views[Vector2i(chunk, row)].get_index())
	return first


func _last_index(views: Dictionary[Vector2i, HexRowView], row: int) -> int:
	var last := -1
	for chunk: int in _row_chunks[row]:
		last = maxi(last, views[Vector2i(chunk, row)].get_index())
	return last


func _add_chunk_nodes(key: Vector2i) -> void:
	var row := key.y
	var terrain := _new_terrain_row()
	var back := _new_decoration_row()
	var front := _new_decoration_row()
	if _row_chunks.has(row):
		move_child(terrain, _first_index(_back_rows, row))
		move_child(back, _first_index(_front_rows, row))
		move_child(front, _last_index(_front_rows, row) + 1)
		_row_chunks[row].append(key.x)
	else:
		var next_row := 2147483647
		for existing: int in _row_chunks:
			if existing > row and existing < next_row:
				next_row = existing
		if _row_chunks.has(next_row):
			var at := _first_index(_rows, next_row)
			move_child(terrain, at)
			move_child(back, at + 1)
			move_child(front, at + 2)
		_row_chunks[row] = [key.x]
	_rows[key] = terrain
	_back_rows[key] = back
	_front_rows[key] = front
	for sprite: MapObjectSprite in _objects:
		if sprite.front_row == row or sprite.front_row == row - 1:
			_place_object(sprite)


## Só para depuração: cabe o mapa inteiro em `area`, da tela lógica. Reduzido
## desse jeito, o mapa precisa de filtro suave, e os pixels deixam de ser inteiros.
func show_whole_map(area: Rect2) -> void:
	_whole_map_area = area
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_update_scale()


func show_pixel_art() -> void:
	_whole_map_area = Rect2()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_update_scale()


func surface_center(coord: Vector2i) -> Vector2:
	return _tile_origin(coord) + SURFACE_CENTER - _rise(_level_at(coord))


## O hexágono visível em um ponto, em pixels da arte: a superfície mais alta que
## o contém ou, em um paredão, o dono dele. Não confere se ele existe no mapa.
func coord_at(point: Vector2) -> Vector2i:
	for level: int in range(LEVEL_HEIGHTS.size() - 1, -1, -1):
		var coord := grid_coord(point + _rise(level))
		if _map != null and _map.has(coord) and _level_at(coord) == level:
			return coord
	return grid_coord(point)


func pixel_scale() -> Vector2:
	return scale


func art_scale() -> Vector2:
	var pixels := maxi(1, roundi(_window_scale.y * ART_SCALE))
	return Vector2(pixels, pixels) / _window_scale


func snapped_to_pixels(value: Vector2) -> Vector2:
	return (value * _window_scale).round() / _window_scale


static func face_texture(biome: String) -> String:
	return "cliff" if CLIFF_BIOMES.has(biome) else "side"


static func flat_center(coord: Vector2i) -> Vector2:
	return _tile_origin(coord) + SURFACE_CENTER


static func grid_coord(point: Vector2) -> Vector2i:
	var r := floori(point.y / STEP_Y)
	var inside_row := point.y - r * STEP_Y
	var x := point.x - ROW_SHIFT * r
	var q := floori(x / STEP_X)
	var inside_cell := x - q * STEP_X
	var slope_height := HEX_CORNERS[1].y
	if inside_cell < ROW_SHIFT:
		if inside_row < slope_height - inside_cell / 2.0:
			return Vector2i(q, r - 1)
	elif inside_row < (inside_cell - ROW_SHIFT) / 2.0:
		return Vector2i(q + 1, r - 1)
	return Vector2i(q, r)


## Um eixo de cada vez: a tela lógica tem tamanho inteiro, então a escala da
## janela nunca é exatamente igual nos dois, e a diferença se acumula no mapa.
func _update_scale() -> void:
	_window_scale = Vector2(get_window().size) / get_viewport_rect().size
	if _whole_map_area.has_area():
		_fit_whole_map()
		return
	scale = Vector2.ONE * fixed_scale if fixed_scale > 0.0 else art_scale()


func _fit_whole_map() -> void:
	var bounds := _map_bounds()
	var ratio := _whole_map_area.size / bounds.size
	scale = Vector2.ONE * minf(ratio.x, ratio.y)
	position = _whole_map_area.get_center() - bounds.get_center() * scale


func _map_bounds() -> Rect2:
	var bounds := Rect2()
	for tile: HexTile in _map.tiles.values():
		var rise := _rise(tile.height)
		var box := Rect2(_tile_origin(tile.coord) - rise, TILE_SIZE + rise)
		bounds = box if not bounds.has_area() else bounds.merge(box)
	return bounds


func _new_terrain_row() -> HexRowView:
	var row := HexRowView.new()
	row.material = _terrain_material
	add_child(row)
	return row


func _new_decoration_row() -> HexRowView:
	var row := HexRowView.new()
	row.material = _wind_material
	add_child(row)
	return row


## Numa linha, nada se sobrepõe: cada hexágono fica na sua coluna. Só as decorações
## vêm por cima, e por isso nos nós seguintes.
func _build_row(row: HexRowView, back: HexRowView, front: HexRowView, tiles: Array) -> void:
	var by_face := _grouped(tiles, func(tile: HexTile) -> String: return face_texture(tile.biome))
	for face: String in by_face:
		_add_faces(row, face, by_face[face])
	_add_drips(row, tiles)
	var by_surface := _grouped(tiles, func(tile: HexTile) -> String: return tile.biome)
	for surface: String in by_surface:
		_add_surface(row, surface, by_surface[surface])
	_add_transitions(row, tiles)
	_add_grounds(row, tiles)
	_add_surface(row, CONTOUR_TEXTURE, tiles)
	_add_decorations(back, front, tiles)
	row.queue_redraw()
	back.queue_redraw()
	front.queue_redraw()


func _grouped(tiles: Array, key: Callable) -> Dictionary[String, Array]:
	var groups: Dictionary[String, Array] = {}
	for tile: HexTile in tiles:
		var name_of_group: String = key.call(tile)
		if not groups.has(name_of_group):
			groups[name_of_group] = []
		groups[name_of_group].append(tile)
	return groups


## O ponto da textura é a posição antes da altura, para os vizinhos do mesmo nível
## continuarem a mesma textura. Mover uma lista inteira por um Transform2D é uma
## conta só do Godot: bem mais rápido que um laço por vértice, em um mapa grande.
func _add_surface(row: HexRowView, texture_name: String, tiles: Array) -> void:
	var points := PackedVector2Array()
	var ground := PackedVector2Array()
	for tile: HexTile in tiles:
		var origin := _tile_origin(tile.coord)
		ground.append_array(Transform2D(0.0, origin) * _hex_triangles)
		points.append_array(Transform2D(0.0, origin - _rise(tile.height)) * _hex_triangles)
	_add_mesh(row, SURFACE_PATH % texture_name, points, ground)


func _add_faces(row: HexRowView, texture_name: String, tiles: Array) -> void:
	var points := PackedVector2Array()
	var texture_points := PackedVector2Array()
	var colors := PackedColorArray()
	for tile: HexTile in tiles:
		var level := tile.height
		var origin := _tile_origin(tile.coord) - _rise(level)
		for edge: int in LOWER_NEIGHBORS.size():
			var height := _face_height(tile.coord + LOWER_NEIGHBORS[edge], level)
			if height <= 0.0:
				continue
			var from := origin + HEX_CORNERS[LOWER_EDGE_CORNERS[edge].x]
			var to := origin + HEX_CORNERS[LOWER_EDGE_CORNERS[edge].y]
			var down := Vector2(0.0, height)
			points.append_array(_quad(from, to, down))
			texture_points.append_array(_quad(Vector2(from.x, 0.0), Vector2(to.x, 0.0), down))
			for _vertex: int in 6:
				colors.append(FACE_COLORS[edge])
	_add_mesh(row, SURFACE_PATH % texture_name, points, texture_points, colors)


func _add_drips(row: HexRowView, tiles: Array) -> void:
	var points := PackedVector2Array()
	var texture_points := PackedVector2Array()
	var colors := PackedColorArray()
	var size := Vector2(HexTransitions.DRIP_CELL_SIZE)
	for tile: HexTile in tiles:
		var level := tile.height
		var origin := _tile_origin(tile.coord) - _rise(level)
		for edge: int in LOWER_NEIGHBORS.size():
			var height := _face_height(tile.coord + LOWER_NEIGHBORS[edge], level)
			var cell := HexTransitions.drip_cell(tile, edge, height, _map.map_seed)
			if height <= 0.0 or cell == HexTransitions.NO_DRIP:
				continue
			var down := Vector2(0.0, minf(height, size.y))
			var from := origin + HEX_CORNERS[LOWER_EDGE_CORNERS[edge].x]
			var to := origin + HEX_CORNERS[LOWER_EDGE_CORNERS[edge].y]
			var top_left := Vector2(cell) * size
			points.append_array(_quad(from, to, down))
			texture_points.append_array(_quad(top_left, top_left + Vector2(size.x, 0.0), down))
			for _vertex: int in 6:
				colors.append(FACE_COLORS[edge])
	_add_mesh(row, HexTransitions.DRIP_TEXTURE_PATH, points, texture_points, colors)


func _add_transitions(row: HexRowView, tiles: Array) -> void:
	var points := PackedVector2Array()
	var texture_points := PackedVector2Array()
	var size := Vector2(HexTransitions.CELL_SIZE)
	var width := Vector2(size.x, 0.0)
	var down := Vector2(0.0, size.y)
	for tile: HexTile in tiles:
		var origin := _tile_origin(tile.coord) - _rise(tile.height)
		for transition: HexTransitions.Transition in HexTransitions.transitions_of(tile, _map):
			var top_left := origin - _front_lift(tile, transition.neighbor)
			points.append_array(_quad(top_left, top_left + width, down))
			var cell := Vector2(transition.cell) * size
			texture_points.append_array(_quad(cell, cell + width, down))
	_add_mesh(row, HexTransitions.TEXTURE_PATH, points, texture_points)


func _add_grounds(row: HexRowView, tiles: Array) -> void:
	var batches: Dictionary[String, HexGrounds.Batch] = {}
	for tile: HexTile in tiles:
		if tile.ground.is_empty():
			continue
		if not batches.has(tile.ground):
			batches[tile.ground] = HexGrounds.Batch.new()
		var flat := _tile_origin(tile.coord)
		var faces: Dictionary[int, float] = {}
		for neighbor: Vector2i in LOWER_NEIGHBORS:
			faces[HexGrounds.EDGE_NEIGHBORS.find(neighbor)] = _face_height(tile.coord + neighbor, tile.height)
		HexGrounds.add_tile(batches[tile.ground], tile, _map, flat - _rise(tile.height), flat, faces)
	for slug: String in batches:
		var batch := batches[slug]
		_add_mesh(row, HexGrounds.TEXTURE_PATH % slug, batch.points, batch.texture_points, batch.colors, batch.custom, batch.shifts)


func _front_lift(tile: HexTile, neighbor: Vector2i) -> Vector2:
	if not LOWER_NEIGHBORS.has(neighbor):
		return Vector2.ZERO
	var lift := _rise(_level_at(tile.coord + neighbor)) - _rise(tile.height)
	return lift if lift.y > 0.0 else Vector2.ZERO


func _add_decorations(back: HexRowView, front: HexRowView, tiles: Array) -> void:
	var behind: Array[HexDecorations.Decoration] = []
	var ahead: Array[HexDecorations.Decoration] = []
	for tile: HexTile in tiles:
		var plants := _plants_at(tile.coord)
		if plants == null and _map.object_at(tile.coord) >= 0:
			continue
		var center := Vector2i(_tile_origin(tile.coord) + SURFACE_CENTER - _rise(tile.height))
		var decorations := HexDecorations.decorations_of(tile, _map.map_seed)
		if plants != null:
			decorations = HexDecorations.decorations_of_object(tile.coord, plants.variant, plants.mirrored)
		for decoration: HexDecorations.Decoration in decorations:
			if plants == null and allows_decoration.is_valid() and not allows_decoration.call(tile.coord, decoration.kind):
				continue
			if plants == null and not HexGrounds.allows_decoration(tile, decoration.kind):
				continue
			decoration.base = center + decoration.offset
			if decoration.offset.y < 0:
				behind.append(decoration)
			else:
				ahead.append(decoration)
	_add_decoration_mesh(back, behind)
	_add_decoration_mesh(front, ahead)


## A Vegetação apoiada neste hexágono, ou `null`.
func _plants_at(coord: Vector2i) -> MapObject:
	var index := _map.object_at(coord)
	if index < 0:
		return null
	var object := _map.objects[index]
	if object.coord != coord:
		return null
	var row := GameData.get_row("map_object_types", object.object_type_id)
	return object if str(row.get("slug", "")) == HexDecorations.PLANTS_SLUG else null


func _add_decoration_mesh(row: HexRowView, decorations: Array[HexDecorations.Decoration]) -> void:
	decorations.sort_custom(func(a: HexDecorations.Decoration, b: HexDecorations.Decoration) -> bool: return a.base.y < b.base.y)
	var points := PackedVector2Array()
	var texture_points := PackedVector2Array()
	var wind := PackedFloat32Array()
	points.resize(decorations.size() * 6)
	texture_points.resize(decorations.size() * 6)
	wind.resize(decorations.size() * 6 * 4)
	for index: int in decorations.size():
		_write_decoration(points, texture_points, index * 6, decorations[index])
		_write_wind(wind, index * 6 * 4, decorations[index])
	_add_mesh(row, HexDecorations.TEXTURE_PATH, points, texture_points, PackedColorArray(), wind)


func _write_wind(wind: PackedFloat32Array, first: int, decoration: HexDecorations.Decoration) -> void:
	var sway: Vector2 = HexDecorations.KIND_SWAY.get(decoration.kind, HexDecorations.NO_SWAY)
	var values := PackedFloat32Array([decoration.base.x, decoration.base.y, -sway.x if decoration.flipped else sway.x, sway.y])
	for vertex: int in 6:
		for value: int in values.size():
			wind[first + vertex * values.size() + value] = values[value]


func _write_decoration(points: PackedVector2Array, texture_points: PackedVector2Array, first: int, decoration: HexDecorations.Decoration) -> void:
	var size := HexDecorations.CELL_SIZE
	var top_left := Vector2(decoration.base - HexDecorations.CELL_BASE)
	var right_bottom := top_left + Vector2(size)
	var cell := Vector2i(decoration.column, HexDecorations.KIND_ROWS[decoration.kind]) * size
	var left := float(cell.x + size.x if decoration.flipped else cell.x)
	var right := float(cell.x if decoration.flipped else cell.x + size.x)
	var top := float(cell.y)
	var bottom := float(cell.y + size.y)
	points[first] = top_left
	points[first + 1] = Vector2(right_bottom.x, top_left.y)
	points[first + 2] = right_bottom
	points[first + 3] = top_left
	points[first + 4] = right_bottom
	points[first + 5] = Vector2(top_left.x, right_bottom.y)
	texture_points[first] = Vector2(left, top)
	texture_points[first + 1] = Vector2(right, top)
	texture_points[first + 2] = Vector2(right, bottom)
	texture_points[first + 3] = Vector2(left, top)
	texture_points[first + 4] = Vector2(right, bottom)
	texture_points[first + 5] = Vector2(left, bottom)


func _face_height(neighbor: Vector2i, level: int) -> float:
	if not _map.has(neighbor):
		return LEVEL_HEIGHTS[level] + SIDE_HEIGHT
	return LEVEL_HEIGHTS[level] - LEVEL_HEIGHTS[_level_at(neighbor)]


func _add_mesh(row: HexRowView, path: String, points: PackedVector2Array, texture_points: PackedVector2Array, colors := PackedColorArray(), custom := PackedFloat32Array(), custom1 := PackedFloat32Array()) -> void:
	var texture := _texture(path)
	if texture == null or points.is_empty():
		return
	var to_uv := Transform2D(Vector2(1.0 / texture.get_width(), 0.0), Vector2(0.0, 1.0 / texture.get_height()), Vector2.ZERO)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_TEX_UV] = to_uv * texture_points
	if not colors.is_empty():
		arrays[Mesh.ARRAY_COLOR] = colors
	var flags := 0
	if not custom.is_empty():
		arrays[Mesh.ARRAY_CUSTOM0] = custom
		flags = Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT
	if not custom1.is_empty():
		arrays[Mesh.ARRAY_CUSTOM1] = custom1
		flags |= Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
	row.meshes.append(mesh)
	row.textures.append(texture)


func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		if ResourceLoader.exists(path):
			_textures[path] = load(path) as Texture2D
		else:
			push_error("HexMapView: falta a textura '%s'" % path)
			_textures[path] = null
	return _textures[path]


static func _quad(from: Vector2, to: Vector2, down: Vector2) -> PackedVector2Array:
	return PackedVector2Array([from, to, to + down, from, to + down, from + down])


func _level_at(coord: Vector2i) -> int:
	var tile: HexTile = _map.tile_at(coord) if _map != null else null
	return tile.height if tile != null else 0


static func _rise(level: int) -> Vector2:
	return Vector2(0.0, LEVEL_HEIGHTS[level])


static func _tile_origin(coord: Vector2i) -> Vector2:
	return Vector2(STEP_X * coord.x + ROW_SHIFT * coord.y, STEP_Y * coord.y)
