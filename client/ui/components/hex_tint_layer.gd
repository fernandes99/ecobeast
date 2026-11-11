class_name HexTintLayer
extends Node2D
## Uma camada de cor por cima do mapa: no editor de ilhas (map-editor/04), as áreas
## de Ecobeasts e as construções; no jogo, as construções da ilha (islands/03). Cada hexágono pintado é uma instância de um
## `MultiMesh`, então trocar a cor de um ou de mil não remonta nada. Com
## `striped`, a cor vem em listras: a área ainda sem espécies.
##
## De perto, o hexágono sobe na altura do terreno, como no `HexMapView`; na visão
## de cima, fica plano.

const STRIPE_SIZE := 12
const STRIPE_WIDTH := 4

var _multimesh := MultiMesh.new()
var _texture: Texture2D = null
var _index_of: Dictionary[Vector2i, int] = {}
var _coord_at: Array[Vector2i] = []
var _levels: Dictionary[Vector2i, int] = {}
var _count := 0
var _raised := false


## `capacity` é quantos hexágonos a camada aguenta pintar.
func _init(striped: bool = false, capacity: int = 0) -> void:
	var corners := HexMapView.HEX_CORNERS
	var points := PackedVector2Array()
	for corner: int in range(1, corners.size() - 1):
		points.append_array(PackedVector2Array([corners[0], corners[corner], corners[corner + 1]]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	if striped:
		var uvs := PackedVector2Array()
		for point: Vector2 in points:
			uvs.append(point / STRIPE_SIZE)
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		_texture = _stripes()
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var hexagon := ArrayMesh.new()
	hexagon.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_colors = true
	_multimesh.mesh = hexagon
	_multimesh.instance_count = capacity
	_multimesh.visible_instance_count = 0


## Pinta um hexágono, na altura `level` do terreno (`HexTile.level()`).
func set_hex(coord: Vector2i, color: Color, level: int) -> void:
	if not _index_of.has(coord):
		if _count >= _multimesh.instance_count:
			return
		_index_of[coord] = _count
		if _coord_at.size() <= _count:
			_coord_at.resize(_count + 1)
		_coord_at[_count] = coord
		_count += 1
		_multimesh.visible_instance_count = _count
	var index: int = _index_of[coord]
	_levels[coord] = level
	_multimesh.set_instance_transform_2d(index, _transform(coord, level))
	_multimesh.set_instance_color(index, color)
	queue_redraw()


## Tira a cor de um hexágono; a última instância ocupa a vaga.
func clear_hex(coord: Vector2i) -> void:
	if not _index_of.has(coord):
		return
	var index: int = _index_of[coord]
	var last := _count - 1
	if index != last:
		var moved := _coord_at[last]
		_multimesh.set_instance_transform_2d(index, _multimesh.get_instance_transform_2d(last))
		_multimesh.set_instance_color(index, _multimesh.get_instance_color(last))
		_coord_at[index] = moved
		_index_of[moved] = index
	_index_of.erase(coord)
	_levels.erase(coord)
	_count = last
	_multimesh.visible_instance_count = _count
	queue_redraw()


func clear_all() -> void:
	_index_of.clear()
	_levels.clear()
	_count = 0
	_multimesh.visible_instance_count = 0
	queue_redraw()


func has_hex(coord: Vector2i) -> bool:
	return _index_of.has(coord)


## De perto, os hexágonos sobem com o terreno; na visão de cima, ficam planos.
func set_raised(raised: bool) -> void:
	if raised == _raised:
		return
	_raised = raised
	for coord: Vector2i in _index_of:
		_multimesh.set_instance_transform_2d(_index_of[coord], _transform(coord, _levels[coord]))
	queue_redraw()


func _transform(coord: Vector2i, level: int) -> Transform2D:
	var origin := HexMapView.flat_center(coord) - HexMapView.SURFACE_CENTER
	if _raised:
		origin.y -= HexMapView.LEVEL_HEIGHTS[level]
	return Transform2D(0.0, origin)


## Listras diagonais brancas, tingidas pela cor de cada instância.
static func _stripes() -> Texture2D:
	var image := Image.create(STRIPE_SIZE, STRIPE_SIZE, false, Image.FORMAT_RGBA8)
	for y: int in STRIPE_SIZE:
		for x: int in STRIPE_SIZE:
			var on := (x + y) % STRIPE_SIZE < STRIPE_WIDTH
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, 1.0 if on else 0.15))
	return ImageTexture.create_from_image(image)


func _draw() -> void:
	if _count > 0:
		draw_multimesh(_multimesh, _texture)
