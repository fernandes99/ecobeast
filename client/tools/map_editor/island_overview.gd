class_name IslandOverview
extends Node2D
## A visão de cima do editor de ilhas (map-editor/02): a ilha inteira plana, um
## hexágono de cor chapada por hexágono, numa malha só. O `HexMapView` monta só as
## linhas perto da tela, e montar a ilha inteira com ele trava o jogo; esta malha
## desenha 20.000 hexágonos de uma vez. As posições são as do `HexMapView` sem a
## altura, então as duas visões ficam alinhadas.

## A cor de cada superfície: a média da própria textura, para a visão de cima
## lembrar o jogo sem cores fixas no código.
static var _surface_colors: Dictionary[String, Color] = {}

var _mesh: ArrayMesh = null
var _hex_triangles := PackedVector2Array()


func _init() -> void:
	var corners := HexMapView.HEX_CORNERS
	for corner: int in range(1, corners.size() - 1):
		_hex_triangles.append_array(PackedVector2Array([corners[0], corners[corner], corners[corner + 1]]))


func set_map(map: ExplorationMap) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for tile: HexTile in map.tiles.values():
		var origin := HexMapView.flat_center(tile.coord) - HexMapView.SURFACE_CENTER
		points.append_array(Transform2D(0.0, origin) * _hex_triangles)
		var color := surface_color(tile)
		for _vertex: int in _hex_triangles.size():
			colors.append(color)
	_mesh = null
	if not points.is_empty():
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = points
		arrays[Mesh.ARRAY_COLOR] = colors
		_mesh = ArrayMesh.new()
		_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	queue_redraw()


## A cor de um hexágono na visão de cima: a da textura que ele mostra no jogo.
static func surface_color(tile: HexTile) -> Color:
	var surface := tile.surface()
	if not _surface_colors.has(surface):
		_surface_colors[surface] = _average_color(HexMapView.SURFACE_PATH % surface)
	return _surface_colors[surface]


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
	if _mesh != null:
		draw_mesh(_mesh, null)
