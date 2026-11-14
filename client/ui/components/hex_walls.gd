class_name HexWalls
extends RefCounted
## Os pedaços de uma cerca (free-fences/01): fatias de 1 px da travessa ao longo da
## linha e postes a espaços iguais, no chão plano. A parede invisível não tem pedaços.

const ART_PATH := "res://assets/walls/%s.png"
## A folha: a célula 0 é o poste, a 1 a travessa reta, com o pé em CELL_FOOT.
const CELL_SIZE := Vector2i(96, 72)
const CELL_FOOT := Vector2i(48, 43)
## A emenda do muro de pedra se repete a cada 7 px; 28 fecha as duas cercas.
const RAIL_SPAN := 28
## A arte passa até 3 px abaixo do pé, e o poste mais largo tem 10 px.
const ART_BELOW := 3.0
const POST_HALF_WIDTH := 5.0
const POST_GAP := 20.0
## Num trecho que anda mais na vertical, a fatia de 1 px vira um fio: postes mais juntos.
const STEEP_POST_GAP := 10.0

static var _visible: Dictionary[String, bool] = {}


class Piece:
	extends RefCounted
	var flat: Vector2i
	var post := false
	var column := 0
	var slug := ""


static func is_visible(slug: String) -> bool:
	if _visible.is_empty():
		for row: Dictionary in GameData.get_rows("wall_types"):
			_visible[row["slug"]] = bool(row["visible"])
	return _visible.get(slug, false)


static func pieces(wall: MapWall) -> Array[Piece]:
	var result: Array[Piece] = []
	if not is_visible(wall.type) or wall.points.is_empty():
		return result
	var along := 0.0
	for index: int in range(1, wall.points.size()):
		var from := wall.points[index - 1]
		var to := wall.points[index]
		var length := from.distance_to(to)
		if length < 0.5:
			continue
		var delta := to - from
		var steps := ceili(maxf(absf(delta.x), absf(delta.y)))
		for step: int in steps:
			result.append(_piece(wall.type, from.lerp(to, float(step) / steps), false, along + length * step / steps))
		var gap := STEEP_POST_GAP if absf(delta.y) > absf(delta.x) else POST_GAP
		var posts := maxi(1, roundi(length / gap))
		for post: int in posts:
			result.append(_piece(wall.type, from.lerp(to, float(post) / posts), true, 0.0))
		along += length
	var last := wall.points[wall.points.size() - 1]
	if not result.is_empty():
		result.append(_piece(wall.type, last, false, along))
	result.append(_piece(wall.type, last, true, 0.0))
	return result


static func _piece(slug: String, at: Vector2, post: bool, along: float) -> Piece:
	var piece := Piece.new()
	piece.flat = Vector2i(at.round())
	piece.post = post
	piece.column = int(along) % RAIL_SPAN
	piece.slug = slug
	return piece
