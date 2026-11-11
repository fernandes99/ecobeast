class_name MapObjectSprite
extends Sprite2D
## A arte de um objeto da ilha (.specs/island-villages/architecture.md): o pé da
## imagem fica no canto de baixo da linha da frente do objeto, centrado na média dos
## centros dos hexágonos dele, e sobe a altura do hexágono de apoio.

const ART_PATH := "res://assets/map_objects/%s/%d.png"
const CENTER_TO_BOTTOM := 29.0
const HIT_ALPHA := 0.5

var object: MapObject
var front_row := 0

var _image: Image = null


## A arte da variante, ou da última que existe, se o painel diminuiu as variantes.
static func art_path(slug: String, variant: int) -> String:
	for candidate: int in range(variant, 0, -1):
		var path := ART_PATH % [slug, candidate]
		if ResourceLoader.exists(path):
			return path
	return ""


static func foot_of(tiles: Array[Vector2i]) -> Vector2:
	var x := 0.0
	var bottom := -INF
	for coord: Vector2i in tiles:
		var center := HexMapView.flat_center(coord)
		x += center.x
		bottom = maxf(bottom, center.y + CENTER_TO_BOTTOM)
	return Vector2(x / tiles.size(), bottom)


func setup(map_object: MapObject, slug: String) -> bool:
	object = map_object
	var path := art_path(slug, map_object.variant)
	if path.is_empty() or map_object.tiles.is_empty():
		return false
	texture = load(path) as Texture2D
	centered = false
	offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
	flip_h = map_object.mirrored
	front_row = map_object.tiles[0].y
	for coord: Vector2i in map_object.tiles:
		front_row = maxi(front_row, coord.y)
	return true


func place(rise: Vector2) -> void:
	position = foot_of(object.tiles) - rise


## Se um ponto, em pixels da arte do mapa, cai num pixel desenhado da arte.
func hits(point: Vector2) -> bool:
	var local := point - position - offset
	var size := texture.get_size()
	if local.x < 0.0 or local.y < 0.0 or local.x >= size.x or local.y >= size.y:
		return false
	if flip_h:
		local.x = size.x - 1.0 - local.x
	if _image == null:
		_image = texture.get_image()
	return _image.get_pixelv(Vector2i(local)).a >= HIT_ALPHA
