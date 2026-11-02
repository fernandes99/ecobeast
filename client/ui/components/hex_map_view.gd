class_name HexMapView
extends Node2D
## O mapa de exploração na tela (wild-battle/04 a 12). Três HexRowView por linha, de
## trás para a frente, com uma malha por textura: quem está na frente cobre quem
## está atrás. O ponto da textura vem da posição no mapa, antes da altura, e não
## do hexágono, então cada bioma é uma superfície contínua. Uma linha só é montada
## quando chega perto da tela, porque criar as malhas do mapa inteiro de uma vez
## trava o jogo (.specs/wild-battle/architecture.md).

## Com estes passos, os hexágonos ficam encostados, sem vão.
const STEP_X := 64
const STEP_Y := 42
const ROW_SHIFT := 32
## Altura de cada nível de HexTile.level(), em pixels da arte: múltiplos de 8.
const LEVEL_HEIGHTS: Array[float] = [0.0, 8.0, 16.0, 24.0, 32.0]
## Quanto a lateral desce além do nível, na borda de baixo do mapa.
const SIDE_HEIGHT := 26.0
## O hexágono mais a lateral.
const TILE_SIZE := Vector2(64.0, 84.0)
## Centro da superfície, a partir do canto do hexágono.
const SURFACE_CENTER := Vector2(32.0, 29.0)
## Os cantos a partir do canto do hexágono, com a ponta para cima.
const HEX_CORNERS: Array[Vector2] = [
	Vector2(32.0, 0.0),
	Vector2(64.0, 16.0),
	Vector2(64.0, 42.0),
	Vector2(32.0, 58.0),
	Vector2(0.0, 42.0),
	Vector2(0.0, 16.0),
]
## As duas bordas de baixo: o vizinho que encosta nela, os cantos e a cor da face.
const LOWER_NEIGHBORS: Array[Vector2i] = [Vector2i(-1, 1), Vector2i(0, 1)]
const LOWER_EDGE_CORNERS: Array[Vector2i] = [Vector2i(4, 3), Vector2i(3, 2)]
const FACE_COLORS: Array[Color] = [Color.WHITE, Color(0.76, 0.76, 0.76)]
## Quantas linhas além da borda da tela já ficam montadas: com a altura e as
## árvores, uma linha aparece bem antes de a posição dela chegar à tela.
const ROW_MARGIN := 3
## Pontos da tela lógica por pixel da arte, antes de arredondar. A revisar.
const ART_SCALE := 2.0
const SURFACE_PATH := "res://assets/terrain/surfaces/%s.png"
## A textura do paredão de cada nível: terra até a colina, rocha na pedra e na
## montanha. A água nunca tem vizinho mais baixo, só a borda do mapa.
const FACE_TEXTURES: Array[String] = ["side", "side", "side", "cliff", "cliff"]
const CONTOUR_TEXTURE := "contour"
const HIGHLIGHT_TEXTURE := "highlight"

var _map: ExplorationMap = null
var _textures: Dictionary[String, Texture2D] = {}
## Os nós das linhas, por número da linha.
var _rows: Dictionary[int, HexRowView] = {}
## As decorações de cada linha, em nós próprios, porque o vento é um material e vale
## para o nó inteiro. As da metade de cima dos hexágonos e as da metade de baixo, com
## o ator entre as duas.
var _back_rows: Dictionary[int, HexRowView] = {}
var _front_rows: Dictionary[int, HexRowView] = {}
## Um só para todas as linhas.
var _wind_material := ShaderMaterial.new()
## Os hexágonos das linhas que ainda não foram montadas.
var _unbuilt_rows: Dictionary[int, Array] = {}
## A linha com o destaque; null até o primeiro set_current.
var _highlighted_row: HexRowView = null
## Os triângulos de um hexágono, a partir do canto dele.
var _hex_triangles := PackedVector2Array()
## Pixels reais por ponto da tela lógica, em cada eixo.
var _window_scale := Vector2.ONE
## Onde caber o mapa inteiro, no modo de depuração; vazia na escala normal.
var _whole_map_area := Rect2()


func _init() -> void:
	_wind_material.shader = load(HexDecorations.WIND_SHADER_PATH) as Shader
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
	for row_number: int in _unbuilt_rows.keys():
		if row_number >= first_row and row_number <= last_row:
			_build_row(_rows[row_number], _back_rows[row_number], _front_rows[row_number], _unbuilt_rows[row_number])
			_unbuilt_rows.erase(row_number)


## Pode ser chamado antes ou depois de o nó entrar na árvore.
func set_map(map: ExplorationMap) -> void:
	_map = map
	for row: HexRowView in _rows.values() + _back_rows.values() + _front_rows.values():
		remove_child(row)
		row.queue_free()
	_rows.clear()
	_back_rows.clear()
	_front_rows.clear()
	_unbuilt_rows.clear()
	_highlighted_row = null
	for tile: HexTile in map.tiles.values():
		if not _unbuilt_rows.has(tile.coord.y):
			_unbuilt_rows[tile.coord.y] = []
		_unbuilt_rows[tile.coord.y].append(tile)
	var row_numbers: Array = _unbuilt_rows.keys()
	row_numbers.sort()
	# Os nós nascem na ordem certa, mesmo que as malhas venham fora de ordem.
	for row_number: int in row_numbers:
		_rows[row_number] = HexRowView.new()
		add_child(_rows[row_number])
		_back_rows[row_number] = _new_decoration_row()
		_front_rows[row_number] = _new_decoration_row()


## Põe um filho deste nó na profundidade de uma linha: por cima dela e das decorações
## de trás, e por baixo das decorações da frente e das linhas seguintes.
func set_actor_row(actor: Node2D, row: int) -> void:
	var front := _front_rows[row].get_index()
	move_child(actor, front if actor.get_index() > front else front - 1)


## Põe o destaque em um hexágono. Só a linha redesenha: nenhuma malha é remontada.
func set_current(coord: Vector2i) -> void:
	if _highlighted_row != null:
		_highlighted_row.highlight = null
		_highlighted_row.queue_redraw()
	_highlighted_row = _rows[coord.y]
	_highlighted_row.highlight = _texture(SURFACE_PATH % HIGHLIGHT_TEXTURE)
	_highlighted_row.highlight_position = _tile_origin(coord) - _rise(_level_at(coord))
	_highlighted_row.queue_redraw()


## Só para depuração: cabe o mapa inteiro em `area`, da tela lógica. Reduzido
## desse jeito, o mapa precisa de filtro suave, e os pixels deixam de ser inteiros.
func show_whole_map(area: Rect2) -> void:
	_whole_map_area = area
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_update_scale()


## Volta à escala normal; a posição fica por conta de quem chamou.
func show_pixel_art() -> void:
	_whole_map_area = Rect2()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_update_scale()


## O centro da superfície de um hexágono, na altura dele, em pixels da arte.
func surface_center(coord: Vector2i) -> Vector2:
	return _tile_origin(coord) + SURFACE_CENTER - _rise(_level_at(coord))


## O hexágono visível em um ponto, em pixels da arte: a superfície mais alta que
## o contém ou, em um paredão, o dono dele. Não confere se ele existe no mapa.
func coord_at(point: Vector2) -> Vector2i:
	for level: int in range(LEVEL_HEIGHTS.size() - 1, -1, -1):
		var coord := _grid_coord(point + _rise(level))
		if _map != null and _map.has(coord) and _level_at(coord) == level:
			return coord
	return _grid_coord(point)


## A escala do nó na tela lógica, que dá um número inteiro de pixels reais.
func pixel_scale() -> Vector2:
	return scale


## A escala da pixel art, mesmo com o mapa inteiro na tela.
func art_scale() -> Vector2:
	var pixels := maxi(1, roundi(_window_scale.y * ART_SCALE))
	return Vector2(pixels, pixels) / _window_scale


## Arredonda uma posição da tela lógica para um pixel real inteiro.
func snapped_to_pixels(value: Vector2) -> Vector2:
	return (value * _window_scale).round() / _window_scale


## O hexágono da grade que contém um ponto, sem contar a altura. Cada linha é uma
## faixa de STEP_Y: embaixo, a parte reta; em cima, as pontas, que a linha de trás
## divide com ela.
func _grid_coord(point: Vector2) -> Vector2i:
	var r := floori(point.y / STEP_Y)
	var inside_row := point.y - r * STEP_Y
	var x := point.x - ROW_SHIFT * r
	var q := floori(x / STEP_X)
	var inside_cell := x - q * STEP_X
	var slope_height := HEX_CORNERS[1].y
	# A borda de cima desce até o meio da célula e sobe depois dele.
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
	scale = art_scale()


func _fit_whole_map() -> void:
	var bounds := _map_bounds()
	var ratio := _whole_map_area.size / bounds.size
	scale = Vector2.ONE * minf(ratio.x, ratio.y)
	position = _whole_map_area.get_center() - bounds.get_center() * scale


## O retângulo que todos os hexágonos ocupam, em pixels da arte.
func _map_bounds() -> Rect2:
	var bounds := Rect2()
	for tile: HexTile in _map.tiles.values():
		var rise := _rise(tile.level())
		var box := Rect2(_tile_origin(tile.coord) - rise, TILE_SIZE + rise)
		bounds = box if not bounds.has_area() else bounds.merge(box)
	return bounds


func _new_decoration_row() -> HexRowView:
	var row := HexRowView.new()
	row.material = _wind_material
	add_child(row)
	return row


## Numa linha, nada se sobrepõe: cada hexágono fica na sua coluna. Só as decorações
## vêm por cima, e por isso nos nós seguintes.
func _build_row(row: HexRowView, back: HexRowView, front: HexRowView, tiles: Array) -> void:
	var by_face := _grouped(tiles, func(tile: HexTile) -> String: return FACE_TEXTURES[tile.level()])
	for face: String in by_face:
		_add_faces(row, face, by_face[face])
	_add_drips(row, tiles)
	var by_surface := _grouped(tiles, func(tile: HexTile) -> String: return tile.surface())
	for surface: String in by_surface:
		_add_surface(row, surface, by_surface[surface])
	_add_transitions(row, tiles)
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
		points.append_array(Transform2D(0.0, origin - _rise(tile.level())) * _hex_triangles)
	_add_mesh(row, SURFACE_PATH % texture_name, points, ground)


## A coluna do paredão acompanha a posição no mapa; a linha 0 da textura é a borda
## de cima, em qualquer inclinação.
func _add_faces(row: HexRowView, texture_name: String, tiles: Array) -> void:
	var points := PackedVector2Array()
	var texture_points := PackedVector2Array()
	var colors := PackedColorArray()
	for tile: HexTile in tiles:
		var level := tile.level()
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


## O bioma descendo pelo paredão: segue a inclinação da borda e, como a textura da
## face, a linha 0 da célula fica colada na superfície. Nunca passa do pé do paredão.
func _add_drips(row: HexRowView, tiles: Array) -> void:
	var points := PackedVector2Array()
	var texture_points := PackedVector2Array()
	var colors := PackedColorArray()
	var size := Vector2(HexTransitions.DRIP_CELL_SIZE)
	for tile: HexTile in tiles:
		var level := tile.level()
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


## Uma folha só, então todos os arremates da linha cabem em uma malha.
func _add_transitions(row: HexRowView, tiles: Array) -> void:
	var points := PackedVector2Array()
	var texture_points := PackedVector2Array()
	var size := Vector2(HexTransitions.CELL_SIZE)
	var width := Vector2(size.x, 0.0)
	var down := Vector2(0.0, size.y)
	for tile: HexTile in tiles:
		var origin := _tile_origin(tile.coord) - _rise(tile.level())
		for transition: HexTransitions.Transition in HexTransitions.transitions_of(tile, _map):
			var top_left := origin - _front_lift(tile, transition.neighbor)
			points.append_array(_quad(top_left, top_left + width, down))
			var cell := Vector2(transition.cell) * size
			texture_points.append_array(_quad(cell, cell + width, down))
	_add_mesh(row, HexTransitions.TEXTURE_PATH, points, texture_points)


## Um vizinho da frente mais alto cobre a borda de baixo: a espuma sobe para
## encostar na borda dele.
func _front_lift(tile: HexTile, neighbor: Vector2i) -> Vector2:
	if not LOWER_NEIGHBORS.has(neighbor):
		return Vector2.ZERO
	var lift := _rise(_level_at(tile.coord + neighbor)) - _rise(tile.level())
	return lift if lift.y > 0.0 else Vector2.ZERO


## O jogador fica no centro do hexágono: o que encosta no chão acima dele fica atrás,
## e o resto, na frente.
func _add_decorations(back: HexRowView, front: HexRowView, tiles: Array) -> void:
	var behind: Array[HexDecorations.Decoration] = []
	var ahead: Array[HexDecorations.Decoration] = []
	for tile: HexTile in tiles:
		var center := Vector2i(_tile_origin(tile.coord) + SURFACE_CENTER - _rise(tile.level()))
		for decoration: HexDecorations.Decoration in HexDecorations.decorations_of(tile, _map.map_seed):
			decoration.base = center + decoration.offset
			if decoration.offset.y < 0:
				behind.append(decoration)
			else:
				ahead.append(decoration)
	_add_decoration_mesh(back, behind)
	_add_decoration_mesh(front, ahead)


## Da decoração mais de trás para a mais da frente.
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


## Os quatro valores que o shader do vento lê em cada vértice da planta.
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


## Quanto o paredão desce até o vizinho; na borda do mapa, até a base da lateral.
func _face_height(neighbor: Vector2i, level: int) -> float:
	if not _map.has(neighbor):
		return LEVEL_HEIGHTS[level] + SIDE_HEIGHT
	return LEVEL_HEIGHTS[level] - LEVEL_HEIGHTS[_level_at(neighbor)]


func _add_mesh(row: HexRowView, path: String, points: PackedVector2Array, texture_points: PackedVector2Array, colors := PackedColorArray(), wind := PackedFloat32Array()) -> void:
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
	if not wind.is_empty():
		arrays[Mesh.ARRAY_CUSTOM0] = wind
		flags = Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT
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


## Os dois triângulos de uma faixa, da borda de cima até `down` abaixo dela.
static func _quad(from: Vector2, to: Vector2, down: Vector2) -> PackedVector2Array:
	return PackedVector2Array([from, to, to + down, from, to + down, from + down])


## 0 fora do mapa.
func _level_at(coord: Vector2i) -> int:
	var tile: HexTile = _map.tile_at(coord) if _map != null else null
	return tile.level() if tile != null else 0


static func _rise(level: int) -> Vector2:
	return Vector2(0.0, LEVEL_HEIGHTS[level])


static func _tile_origin(coord: Vector2i) -> Vector2:
	return Vector2(STEP_X * coord.x + ROW_SHIFT * coord.y, STEP_Y * coord.y)
