class_name IslandOverview
extends Node2D
## A visão de cima do editor de ilhas (map-editor/02): a ilha inteira plana, um
## hexágono de cor chapada por hexágono. O `HexMapView` monta só as linhas perto da
## tela, e montar a ilha inteira com ele trava o jogo; aqui cada hexágono é uma
## instância de um `MultiMesh`, desenhado de uma vez. As posições são as do
## `HexMapView` sem a altura, então as duas visões ficam alinhadas.
##
## Pintar só troca a cor da instância, e pôr ou tirar um hexágono usa uma vaga
## livre (map-editor/03): nada é remontado, nem numa ilha de 20.000 hexágonos.

## A cor de cada superfície: a média da própria textura, para a visão de cima
## lembrar o jogo sem cores fixas no código.
static var _surface_colors: Dictionary[String, Color] = {}

var _multimesh := MultiMesh.new()
## A instância de cada hexágono; as `count` primeiras estão em uso.
var _index_of: Dictionary[Vector2i, int] = {}
var _coord_at: Array[Vector2i] = []
var _count := 0


func _init() -> void:
	var corners := HexMapView.HEX_CORNERS
	var points := PackedVector2Array()
	for corner: int in range(1, corners.size() - 1):
		points.append_array(PackedVector2Array([corners[0], corners[corner], corners[corner + 1]]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	var hexagon := ArrayMesh.new()
	hexagon.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_colors = true
	_multimesh.mesh = hexagon
	_multimesh.instance_count = IslandDraft.MAX_TILES
	_multimesh.visible_instance_count = 0


func set_map(map: ExplorationMap) -> void:
	_index_of.clear()
	_coord_at.clear()
	_count = 0
	for tile: HexTile in map.tiles.values():
		_add(tile)
	_multimesh.visible_instance_count = _count
	queue_redraw()


## Os hexágonos mudaram: a cor dos que ficaram, e a vaga dos que entraram ou saíram.
func update_tiles(coords: Array[Vector2i], map: ExplorationMap) -> void:
	for coord: Vector2i in coords:
		var tile := map.tile_at(coord)
		if tile == null:
			_remove(coord)
		elif _index_of.has(coord):
			_multimesh.set_instance_color(_index_of[coord], surface_color(tile))
		else:
			_add(tile)
	_multimesh.visible_instance_count = _count
	queue_redraw()


## A cor de um hexágono na visão de cima: a da textura que ele mostra no jogo.
static func surface_color(tile: HexTile) -> Color:
	var surface := tile.surface()
	if not _surface_colors.has(surface):
		_surface_colors[surface] = _average_color(HexMapView.SURFACE_PATH % surface)
	return _surface_colors[surface]


func _add(tile: HexTile) -> void:
	if _count >= _multimesh.instance_count:
		return
	var index := _count
	_count += 1
	_index_of[tile.coord] = index
	if _coord_at.size() < _count:
		_coord_at.resize(_count)
	_coord_at[index] = tile.coord
	var origin := HexMapView.flat_center(tile.coord) - HexMapView.SURFACE_CENTER
	_multimesh.set_instance_transform_2d(index, Transform2D(0.0, origin))
	_multimesh.set_instance_color(index, surface_color(tile))


## A última instância ocupa a vaga de quem saiu.
func _remove(coord: Vector2i) -> void:
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
	_count = last


static func _average_color(path: String) -> Color:
	var texture: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	var image: Image = texture.get_image() if texture != null else null
	if image == null:
		return UiPalette.TEXT_MUTED
	if image.is_compressed():
		image.decompress()
	# As texturas do terreno são pequenas: a média de todos os pixels sai rápido,
	# uma vez por superfície.
	var sum := Vector3.ZERO
	var count := 0
	for y: int in image.get_height():
		for x: int in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.5:
				sum += Vector3(pixel.r, pixel.g, pixel.b)
				count += 1
	if count == 0:
		return UiPalette.TEXT_MUTED
	sum /= count
	return Color(sum.x, sum.y, sum.z)


func _draw() -> void:
	if _count > 0:
		draw_multimesh(_multimesh, null)
