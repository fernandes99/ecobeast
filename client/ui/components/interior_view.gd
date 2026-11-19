class_name InteriorView
extends Node2D

## Uma sala na escala 1 da arte (interiors/02), no jogo e no editor. O chão e o detalhe
## do chão ficam embaixo de tudo; a parede, os objetos e os atores se ordenam pelo pé, e
## por isso uma estante alta cobre o Domador atrás dela.

var actors: Node2D
var object_nodes: Array[Sprite2D] = []

var _interior: Interior = null
var _layers: Dictionary[String, TileMapLayer] = {}
var _sorted: Node2D
var _objects: Node2D


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for layer: String in ["floor", "floor_detail"]:
		_layers[layer] = _tile_layer(self, false)
	_sorted = Node2D.new()
	_sorted.y_sort_enabled = true
	add_child(_sorted)
	for layer: String in ["wall", "wall_detail"]:
		_layers[layer] = _tile_layer(_sorted, true)
	_objects = Node2D.new()
	_objects.y_sort_enabled = true
	_sorted.add_child(_objects)
	actors = Node2D.new()
	actors.y_sort_enabled = true
	_sorted.add_child(actors)


func show_interior(interior: Interior) -> void:
	_interior = interior
	for layer: TileMapLayer in _layers.values():
		layer.clear()
	for tile: InteriorTile in interior.tiles:
		_set_tile(tile)
	refresh_objects()


## Redesenha as 4 camadas nesses quadrados, pelo que a sala tem agora.
func refresh_tiles(cells: Array[Vector2i]) -> void:
	if _interior == null:
		return
	var wanted: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in cells:
		wanted[cell] = true
		for layer: TileMapLayer in _layers.values():
			layer.erase_cell(cell)
	for tile: InteriorTile in _interior.tiles:
		if wanted.has(tile.cell):
			_set_tile(tile)


func refresh_objects() -> void:
	for node: Sprite2D in object_nodes:
		node.free()
	object_nodes.clear()
	if _interior == null:
		return
	var feet: Array[int] = []
	for index: int in _interior.objects.size():
		var item := _interior.objects[index]
		var foot := item.foot_y()
		for earlier: int in index:
			if _interior.objects[earlier].rect().intersects(item.rect()):
				foot = maxi(foot, feet[earlier])
		feet.append(foot)
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.texture = InteriorTiles.sheet_texture(item.sheet)
		sprite.region_enabled = true
		sprite.region_rect = Rect2(Vector2(item.atlas * InteriorTiles.CELL), Vector2(item.size * InteriorTiles.CELL))
		sprite.position = Vector2(item.cell.x * InteriorTiles.CELL, foot * InteriorTiles.CELL)
		sprite.offset = Vector2(0.0, (item.cell.y - foot) * InteriorTiles.CELL)
		_objects.add_child(sprite)
		object_nodes.append(sprite)


func _set_tile(tile: InteriorTile) -> void:
	var source := InteriorTiles.source_id(tile.sheet)
	if source < 0 or not InteriorTiles.has_tile(tile.sheet, tile.atlas) or not _layers.has(tile.layer):
		return
	_layers[tile.layer].set_cell(tile.cell, source, tile.atlas)


func _tile_layer(parent: Node, sorted: bool) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = InteriorTiles.tile_set()
	layer.y_sort_enabled = sorted
	parent.add_child(layer)
	return layer
