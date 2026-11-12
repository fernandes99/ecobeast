class_name MapObjectSprite
extends Sprite2D
## A arte de um objeto da ilha (.specs/island-villages/architecture.md): o pé da
## imagem fica no canto de baixo da linha da frente do objeto, centrado na média dos
## centros dos hexágonos dele, e sobe a altura do hexágono de apoio. Um objeto animado
## (island-villages/04) tem os quadros lado a lado, cada um com a largura da célula.

const ART_PATH := "res://assets/map_objects/%s/%d.png"
const CENTER_TO_BOTTOM := 29.0
const HIT_ALPHA := 0.5
const HEX_HALF_WIDTH := 32.0
## Quadros por segundo dos objetos animados, os do pacote de arte.
const FRAME_RATES: Dictionary[String, float] = {"windmill": 10.0, "tree": 4.0, "rune_shrine": 8.0}
const DEFAULT_FRAME_RATE := 6.0

var object: MapObject
var front_row := 0
var fence := false

var _image: Image = null
var _frames := 1
var _frame_rate := DEFAULT_FRAME_RATE
var _phase := 0.0


## A arte da variante, ou da última que existe, se o painel diminuiu as variantes.
static func art_path(slug: String, variant: int) -> String:
	for candidate: int in range(variant, 0, -1):
		var path := ART_PATH % [slug, candidate]
		if ResourceLoader.exists(path):
			return path
	return ""


## A largura da célula de um quadro, a mesma do make_objects: simétrica em volta do
## ponto de apoio, cobrindo os hexágonos.
static func cell_width(tiles: Array[Vector2i]) -> int:
	var pivot := 0.0
	var left := INF
	var right := -INF
	for coord: Vector2i in tiles:
		var x := HexMapView.flat_center(coord).x
		pivot += x
		left = minf(left, x - HEX_HALF_WIDTH)
		right = maxf(right, x + HEX_HALF_WIDTH)
	pivot /= tiles.size()
	return ceili(maxf(pivot - left, right - pivot) * 2.0)


static func frame_count(art: Texture2D, tiles: Array[Vector2i]) -> int:
	if art == null or tiles.is_empty():
		return 1
	return maxi(1, roundi(art.get_width() / float(cell_width(tiles))))


## O primeiro quadro, para mostrar parado (a prévia do editor).
static func first_frame(art: Texture2D, tiles: Array[Vector2i]) -> Texture2D:
	var frames := frame_count(art, tiles)
	if frames <= 1:
		return art
	var atlas := AtlasTexture.new()
	atlas.atlas = art
	atlas.region = Rect2(0.0, 0.0, art.get_width() / float(frames), art.get_height())
	return atlas


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
	_frames = frame_count(texture, map_object.tiles)
	hframes = _frames
	_frame_rate = FRAME_RATES.get(slug, DEFAULT_FRAME_RATE)
	# Cada objeto começa num ponto do ciclo, para os vizinhos não andarem juntos.
	_phase = float(absi(hash(map_object.coord)) % 1000) / 1000.0 * _frames
	set_process(_frames > 1)
	centered = false
	offset = Vector2(-_frame_width() / 2.0, -texture.get_height())
	flip_h = map_object.mirrored
	front_row = map_object.tiles[0].y
	for coord: Vector2i in map_object.tiles:
		front_row = maxi(front_row, coord.y)
	return true


## A Cerca (island-villages/05): uma célula montada pelos lados ligados, sem quadros.
func setup_fence(map_object: MapObject, art: Texture2D) -> void:
	object = map_object
	fence = true
	centered = false
	front_row = map_object.coord.y
	set_process(false)
	set_fence_texture(art)


func set_fence_texture(art: Texture2D) -> void:
	if art == texture:
		return
	texture = art
	_image = null
	offset = Vector2(-art.get_width() / 2.0, -art.get_height())


func _process(_delta: float) -> void:
	frame = int(Time.get_ticks_msec() / 1000.0 * _frame_rate + _phase) % _frames


func _frame_width() -> float:
	return texture.get_width() / float(_frames)


func place(rise: Vector2) -> void:
	position = foot_of(object.tiles) - rise


## Se um ponto, em pixels da arte do mapa, cai num pixel desenhado da arte.
func hits(point: Vector2) -> bool:
	var local := point - position - offset
	var size := Vector2(_frame_width(), texture.get_height())
	if local.x < 0.0 or local.y < 0.0 or local.x >= size.x or local.y >= size.y:
		return false
	if flip_h:
		local.x = size.x - 1.0 - local.x
	if _image == null:
		_image = texture.get_image()
	return _image.get_pixelv(Vector2i(local) + Vector2i(roundi(size.x) * frame, 0)).a >= HIT_ALPHA
