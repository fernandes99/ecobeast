class_name HexBridges
extends RefCounted
## As fatias de uma ponte (bridges/05 a 07), já na altura do piso, que entram na ordem de
## desenho pelo pé, cada uma na linha do mapa onde está: assim o chão das linhas da
## frente nunca a cobre.
## - Até 75° da horizontal da tela (`STANDING_ANGLE`), a ponte tem o piso da vista de
##   cima girado, com as pranchas atravessando a ponte, cortado em fatias de 1 px de
##   altura; e os dois corrimãos em pé nas bordas, como a cerca: colunas de 1 px do meio
##   do corrimão da vista de lado assentadas sobre a borda, e o poste da cabeceira
##   inteiro e em pé nas pontas e a cada `POST_GAP`.
## - Mais em pé que isso, a ponte é a vista de cima, linha a linha, com o miolo do piso
##   repetido pela largura.

const ART_PATH := "res://assets/bridges/%s/%s_%s.png"
const PARTS: Array[String] = ["start", "middle", "end"]
const MIN_WIDTH := 16
const MAX_WIDTH := 64
## Por estilo, na vista de cima: a largura da arte e quantas colunas de cada lado são o
## corrimão.
const TOP: Dictionary[String, Vector2i] = {"wood_bridge": Vector2i(29, 6), "rope_bridge": Vector2i(26, 5)}
## Por estilo, na vista de lado: quantas linhas de cima são o corrimão de trás.
const BACK_RAIL: Dictionary[String, int] = {"wood_bridge": 12, "rope_bridge": 14}
## Por estilo: a cada quantos pixels vai um poste do corrimão, além das duas pontas
## (0: só nas pontas).
const POST_GAP: Dictionary[String, float] = {"wood_bridge": 20.0, "rope_bridge": 0.0}
## As colunas do piso junto do corrimão têm a sombra dele: não se repetem.
const DECK_EDGE := 3
## O corrimão da frente entra na ordem um pouco abaixo da borda, na frente de quem anda
## no piso.
const FRONT_LEAD := 6.0
const STANDING_ANGLE := 75.0
const CACHE_LIMIT := 128

static var _sources: Dictionary[String, Image] = {}
static var _textures: Dictionary[String, Texture2D] = {}
## As linhas que o corrimão da frente ocupa na vista de lado, por estilo.
static var _front_rows: Dictionary[String, Vector2i] = {}
## Por "estilo:back" e "estilo:front": o meio do corrimão (as fatias) e o poste.
static var _rail_textures: Dictionary[String, Texture2D] = {}
static var _post_textures: Dictionary[String, Texture2D] = {}
static var _cache: Dictionary[String, Array] = {}


class Piece:
	extends RefCounted
	var texture: Texture2D
	## A fatia na textura e onde o canto de cima dela fica, já na altura do piso.
	var source := Rect2i()
	var top_left := Vector2.ZERO
	## O ponto do chão plano que decide a linha e a faixa da fatia.
	var key := Vector2.ZERO
	var lift := 0.0


static func is_known(slug: String) -> bool:
	return TOP.has(slug)


static func is_standing(bridge: MapBridge) -> bool:
	var delta := bridge.to - bridge.from
	return rad_to_deg(atan2(absf(delta.y), absf(delta.x))) > STANDING_ANGLE


## Até onde o pé anda do eixo da ponte sem subir no corrimão.
static func deck_reach(bridge: MapBridge) -> float:
	if not is_known(bridge.type):
		return 2.0
	var half := clampi(bridge.width, MIN_WIDTH, MAX_WIDTH) / 2.0
	if is_standing(bridge):
		return maxf(2.0, half - TOP[bridge.type].y - 1.0)
	return maxf(2.0, half - 3.0)


## As fatias da ponte. `lifts` é quanto o piso sobe em cada ponta, na ordem de `from` e `to`.
static func pieces(bridge: MapBridge, lifts: Vector2) -> Array[Piece]:
	var result: Array[Piece] = []
	if not is_known(bridge.type) or bridge.from.distance_to(bridge.to) < 1.0 or not _load(bridge.type):
		return result
	var key := "%s|%d|%s|%s|%s" % [bridge.type, bridge.width, bridge.from, bridge.to, lifts]
	if _cache.has(key):
		result.assign(_cache[key])
		return result
	var from := bridge.from
	var to := bridge.to
	var lift_from := lifts.x
	var lift_to := lifts.y
	var standing := is_standing(bridge)
	# O começo da arte fica na ponta de cima (em pé) ou na da esquerda.
	if (standing and from.y > to.y) or (not standing and from.x > to.x):
		var swap := from
		from = to
		to = swap
		lift_from = lifts.y
		lift_to = lifts.x
	if standing:
		result = _standing(bridge, from, to, lift_from, lift_to)
	else:
		result = _fenced(bridge, from, to, lift_from, lift_to)
	if _cache.size() >= CACHE_LIMIT:
		_cache.clear()
	_cache[key] = result
	return result


## O piso girado e os dois corrimãos em pé.
static func _fenced(bridge: MapBridge, from: Vector2, to: Vector2, lift_from: float, lift_to: float) -> Array[Piece]:
	var slug := bridge.type
	var width := clampi(bridge.width, MIN_WIDTH, MAX_WIDTH)
	var half := width / 2.0
	var length := from.distance_to(to)
	var along := (to - from) / length
	# O lado de trás é o de cima da tela.
	var across := Vector2(-along.y, along.x)
	if across.y < 0.0:
		across = -across
	var result := _deck(slug, from, to, along, across, width, lift_from, lift_to)
	var length_steps := maxi(1, roundi(maxf(absf((to - from).x), absf((to - from).y))))
	for side: String in ["back", "front"]:
		var sign := -1.0 if side == "back" else 1.0
		var lead := 0.0 if side == "back" else FRONT_LEAD
		var rail := _rail_textures["%s:%s" % [slug, side]]
		var rail_size := Vector2i(rail.get_width(), rail.get_height())
		for step: int in length_steps + 1:
			var part := float(step) / length_steps
			var lift := roundf(lerpf(lift_from, lift_to, part))
			var foot := (from.lerp(to, part) + across * half * sign).round()
			var column := floori(part * length) % rail_size.x
			result.append(_piece(rail, Rect2i(column, 0, 1, rail_size.y), foot - Vector2(0.0, rail_size.y + lift), foot + Vector2(0.0, lead)))
		var post := _post_textures["%s:%s" % [slug, side]]
		var post_size := Vector2(post.get_width(), post.get_height())
		var gap: float = POST_GAP[slug]
		var posts := maxi(1, roundi(length / gap)) if gap > 0.0 else 1
		for index: int in posts + 1:
			var part := float(index) / posts
			var lift := roundf(lerpf(lift_from, lift_to, part))
			var foot := (from.lerp(to, part) + across * half * sign).round()
			var corner := foot - Vector2(floorf(post_size.x / 2.0), post_size.y + lift)
			result.append(_piece(post, Rect2i(Vector2i.ZERO, Vector2i(post_size)), corner, foot + Vector2(0.0, lead + 0.5)))
	return result


## O piso da vista de cima girado no ângulo da ponte, sem os corrimãos: cada pixel acha a
## linha da arte pela posição ao longo da ponte e a coluna pela distância até o eixo.
static func _deck(slug: String, from: Vector2, to: Vector2, along: Vector2, across: Vector2, width: int, lift_from: float, lift_to: float) -> Array[Piece]:
	var art: Vector2i = TOP[slug]
	var half := width / 2.0
	var length := from.distance_to(to)
	var corners: Array[Vector2] = [from - across * half, from + across * half, to - across * half, to + across * half]
	var box := Rect2(corners[0], Vector2.ZERO)
	for corner: Vector2 in corners:
		box = box.expand(corner)
	var high_lift := maxf(lift_from, lift_to)
	var origin := Vector2i(floori(box.position.x), floori(box.position.y - high_lift))
	var size := Vector2i(ceili(box.end.x) - origin.x + 1, ceili(box.end.y) - origin.y + 1)
	var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var lengths := _lengths(slug, "top", false)
	var steps := maxi(1, floori(length))
	var inner := art.x - art.y * 2
	for y: int in range(floori(box.position.y), ceili(box.end.y) + 1):
		for x: int in range(floori(box.position.x), ceili(box.end.x) + 1):
			var offset := Vector2(x + 0.5, y + 0.5) - from
			var u := offset.dot(along)
			var v := offset.dot(across) + half
			if u < 0.0 or u >= length or v < 0.0 or v >= width:
				continue
			var pick := _pick(floori(u), steps, lengths)
			if pick.x < 0:
				continue
			var column := art.y + _column(floori(v), width, inner, 0)
			var color := _sources["%s:top:%s" % [slug, PARTS[pick.x]]].get_pixel(column, pick.y)
			if color.a <= 0.0:
				continue
			var lift := roundf(lerpf(lift_from, lift_to, u / length))
			var at := Vector2i(x - origin.x, y - int(lift) - origin.y)
			if at.y >= 0 and at.y < size.y:
				image.set_pixel(at.x, at.y, color)
	return _rows(image, origin, (from.x + to.x) / 2.0, (lift_from + lift_to) / 2.0, 0.0)


static func _standing(bridge: MapBridge, from: Vector2, to: Vector2, lift_from: float, lift_to: float) -> Array[Piece]:
	var slug := bridge.type
	var width := clampi(bridge.width, MIN_WIDTH, MAX_WIDTH)
	var art: Vector2i = TOP[slug]
	var steps := maxi(1, roundi(to.y - from.y))
	var lengths := _lengths(slug, "top", false)
	var lefts := PackedInt32Array()
	var ys := PackedInt32Array()
	var low_x := INF
	var low_y := INF
	var high_x := -INF
	var high_y := -INF
	for step: int in steps + 1:
		var part := float(step) / steps
		var lift := roundf(lerpf(lift_from, lift_to, part))
		var left := roundi(lerpf(from.x, to.x, part) - width / 2.0)
		var y := roundi(from.y + step - lift)
		lefts.append(left)
		ys.append(y)
		low_x = minf(low_x, left)
		high_x = maxf(high_x, left + width)
		low_y = minf(low_y, y)
		high_y = maxf(high_y, y + 1)
	var origin := Vector2i(int(low_x), int(low_y))
	var image := Image.create_empty(int(high_x - low_x), int(high_y - low_y), false, Image.FORMAT_RGBA8)
	for step: int in steps + 1:
		var pick := _pick(step, steps + 1, lengths)
		if pick.x < 0:
			continue
		var source := _sources["%s:top:%s" % [slug, PARTS[pick.x]]]
		for column: int in width:
			var color := source.get_pixel(_column(column, width, art.x, art.y), pick.y)
			if color.a > 0.0:
				image.set_pixel(lefts[step] - origin.x + column, ys[step] - origin.y, color)
	return _rows(image, origin, (from.x + to.x) / 2.0, (lift_from + lift_to) / 2.0, 0.0)


## Uma fatia por linha da imagem que tem algum pixel, com o pé no chão plano: a linha
## somada à altura do piso, mais `lead`.
static func _rows(image: Image, origin: Vector2i, key_x: float, lift: float, lead: float) -> Array[Piece]:
	var result: Array[Piece] = []
	var texture := ImageTexture.create_from_image(image)
	var used := image.get_used_rect()
	for row: int in range(used.position.y, used.end.y):
		result.append(_piece(texture, Rect2i(used.position.x, row, used.size.x, 1), Vector2(origin.x + used.position.x, origin.y + row), Vector2(key_x, origin.y + row + lift + lead)))
	return result


## A parte (0 começo, 1 meio, 2 fim) e a coluna (ou linha) dela no passo `index` de
## `count`; (-1, 0) sem arte. Numa ponte curta, o começo e o fim dividem o espaço.
static func _pick(index: int, count: int, lengths: Vector3i) -> Vector2i:
	var start := lengths.x
	var middle := lengths.y
	var end := lengths.z
	if start + end >= count:
		var cut := roundi(count * float(start) / maxf(1.0, start + end))
		if index < cut:
			return Vector2i(0, index)
		var into_end := end - (count - index)
		return Vector2i(2, into_end) if into_end >= 0 else Vector2i(-1, 0)
	if index < start:
		return Vector2i(0, index)
	if index >= count - end:
		return Vector2i(2, index - (count - end))
	return Vector2i(1, (index - start) % middle)


## O comprimento do começo, do meio e do fim: as larguras (vista de lado) ou as alturas.
static func _lengths(slug: String, view: String, wide: bool) -> Vector3i:
	var sizes: Array[int] = []
	for part: String in PARTS:
		var image := _sources["%s:%s:%s" % [slug, view, part]]
		sizes.append(image.get_width() if wide else image.get_height())
	return Vector3i(sizes[0], sizes[1], sizes[2])


## A coluna da arte para a coluna `index` de uma ponte de `width`: os corrimãos ficam,
## e o miolo do piso, sem as bordas sombreadas, se repete (ou encolhe).
static func _column(index: int, width: int, art_width: int, rails: int) -> int:
	if index < rails:
		return index
	if index >= width - rails:
		return art_width - (width - index)
	var inner := index - rails
	var inner_width := width - rails * 2
	var art_inner := art_width - rails * 2
	if inner < DECK_EDGE:
		return rails + inner
	if inner >= inner_width - DECK_EDGE:
		return art_width - rails - (inner_width - inner)
	var core := maxi(1, art_inner - DECK_EDGE * 2)
	return rails + DECK_EDGE + (inner - DECK_EDGE) % core


static func _load(slug: String) -> bool:
	if _front_rows.has(slug):
		return true
	var front_rows := Vector2i(1 << 30, 0)
	for view: String in ["top", "side_back", "side_front"]:
		for part: String in PARTS:
			var path := ART_PATH % [slug, view, part]
			var texture: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
			if texture == null:
				return false
			var image := texture.get_image()
			if image.is_compressed():
				image.decompress()
			image.convert(Image.FORMAT_RGBA8)
			_sources["%s:%s:%s" % [slug, view, part]] = image
			_textures["%s:%s:%s" % [slug, view, part]] = texture
			if view == "side_front":
				var used := image.get_used_rect()
				if used.has_area():
					front_rows = Vector2i(mini(front_rows.x, used.position.y), maxi(front_rows.y, used.end.y))
	_front_rows[slug] = front_rows if front_rows.y > 0 else Vector2i(0, 1)
	for side: String in ["back", "front"]:
		var rows := Vector2i(0, BACK_RAIL[slug]) if side == "back" else _front_rows[slug]
		var view := "side_%s" % side
		var middle := _sources["%s:%s:middle" % [slug, view]]
		var rail := middle.get_region(Rect2i(0, rows.x, middle.get_width(), rows.y - rows.x))
		_rail_textures["%s:%s" % [slug, side]] = ImageTexture.create_from_image(rail)
		var start := _sources["%s:%s:start" % [slug, view]].get_region(Rect2i(0, rows.x, _sources["%s:%s:start" % [slug, view]].get_width(), rows.y - rows.x))
		_post_textures["%s:%s" % [slug, side]] = ImageTexture.create_from_image(_post_of(start))
	return true


## O poste da cabeceira: as colunas em volta da mais alta, até 2 px mais baixas.
static func _post_of(image: Image) -> Image:
	var tops := PackedInt32Array()
	for x: int in image.get_width():
		var top := image.get_height()
		for y: int in image.get_height():
			if image.get_pixel(x, y).a > 0.0:
				top = y
				break
		tops.append(top)
	var best := 0
	for x: int in tops.size():
		if tops[x] < tops[best]:
			best = x
	var left := best
	var right := best
	while left > 0 and tops[left - 1] <= tops[best] + 2:
		left -= 1
	while right < tops.size() - 1 and tops[right + 1] <= tops[best] + 2:
		right += 1
	var used := image.get_region(Rect2i(left, 0, right - left + 1, image.get_height()))
	var rect := used.get_used_rect()
	return used.get_region(Rect2i(0, 0, used.get_width(), rect.end.y)) if rect.has_area() else used


static func _piece(texture: Texture2D, source: Rect2i, top_left: Vector2, key: Vector2) -> Piece:
	var piece := Piece.new()
	piece.texture = texture
	piece.source = source
	piece.top_left = top_left
	piece.key = key
	return piece
