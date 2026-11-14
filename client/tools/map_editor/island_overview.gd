class_name IslandOverview
extends Node2D

static var _surface_colors: Dictionary[String, Color] = {}

var _multimesh := MultiMesh.new()
var _index_of: Dictionary[Vector2i, int] = {}
var _coord_at: Array[Vector2i] = []
var _count := 0
var _trails: Array[MapTrail] = []


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


func set_trails(trails: Array[MapTrail]) -> void:
	_trails = trails.duplicate()
	queue_redraw()


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


static func surface_color(tile: HexTile) -> Color:
	var path := HexMapView.SURFACE_PATH % tile.biome if tile.ground.is_empty() else HexGrounds.TEXTURE_PATH % tile.ground
	if not _surface_colors.has(path):
		_surface_colors[path] = _average_color(path)
	return _surface_colors[path]


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
	for trail: MapTrail in _trails:
		var color := _average_color(HexGrounds.TEXTURE_PATH % trail.ground) if not _surface_colors.has(trail.ground) else _surface_colors[trail.ground]
		_surface_colors[trail.ground] = color
		draw_polyline(HexGrounds.smoothed(trail), color, trail.width)
