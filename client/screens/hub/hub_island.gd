class_name HubIsland
extends Control
## A ilhota da Home do Hub (hub-start/04): um ExplorationMap só do cliente, de enfeite,
## desenhado pelo mesmo HexMapView de Explorar, com o Domador e o Ecobeast em cima.

signal placed

const MAX_ZOOM := 4
## A folga em cima da ilhota, em pixels da arte, para as árvores e os atores.
const TOP_ROOM := 28.0
const MAP_SEED := 4242
const BIOME := "temperate"
const CENTER := Vector2i(0, 0)
## q, r e a altura de cada hexágono.
const TILES: Array[Vector3i] = [
	Vector3i(0, -2, 4),
	Vector3i(0, -1, 3), Vector3i(1, -1, 2),
	Vector3i(-1, 0, 2), Vector3i(0, 0, 2),
	Vector3i(-1, 1, 1), Vector3i(0, 1, 1),
]

var _view := HexMapView.new()
var _map := ExplorationMap.new()


func _ready() -> void:
	clip_contents = true
	mouse_filter = MOUSE_FILTER_IGNORE
	_map.map_seed = MAP_SEED
	for spec: Vector3i in TILES:
		var tile := HexTile.new()
		tile.coord = Vector2i(spec.x, spec.y)
		tile.biome = BIOME
		tile.height = spec.z
		tile.variant = 1
		tile.bare = tile.coord == CENTER
		_map.tiles[tile.coord] = tile
	add_child(_view)
	_view.set_map(_map)
	_view.build_all_rows()
	resized.connect(_place)
	_place.call_deferred()


## Põe um ator no hexágono do meio, `offset_x` pixels da arte para o lado.
func add_actor(actor: Node2D, offset_x: float) -> void:
	actor.scale = Vector2.ONE
	_view.add_child(actor)
	var shift := Vector2(offset_x, 0.0)
	actor.position = _view.surface_center(CENTER) + shift
	_view.set_actor_depth(actor, HexMapView.flat_center(CENTER) + shift, CENTER.y)


## O pé de um ator posto com `offset_x`, em pixels da arte.
func surface_point(offset_x: float) -> Vector2:
	return _view.surface_center(CENTER) + Vector2(offset_x, 0.0)


## Um ponto da arte, no espaço desta ilhota.
func to_local_point(art_point: Vector2) -> Vector2:
	return _view.position + art_point * _view.scale


func pixel_scale() -> float:
	return _view.scale.x


## O maior zoom inteiro em que a ilhota cabe inteira, centrada.
func _place() -> void:
	if size.y <= 0.0:
		return
	var bounds := _view.map_bounds().grow_side(SIDE_TOP, TOP_ROOM)
	for zoom: int in range(MAX_ZOOM, HexMapView.MIN_ZOOM - 1, -1):
		_view.zoom_level = zoom
		if bounds.size.x * _view.scale.x <= size.x and bounds.size.y * _view.scale.y <= size.y:
			break
	_view.position = _view.snapped_to_pixels(size / 2.0 - bounds.get_center() * _view.scale)
	placed.emit()
