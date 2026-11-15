class_name HexWalls
extends RefCounted
## Os pedaços de uma cerca (free-fences/01, fence-art/01): postes a espaços iguais e, entre
## eles, fatias de 1 px da travessa deitada ou, num trecho em pé, linhas de 1 px da travessa
## vista de cima, no chão plano. A parede invisível não tem pedaços.

const ART_PATH := "res://assets/walls/%s.png"
## A folha (make_walls.py): a célula 0 é o poste, a 1 a travessa deitada entre dois postes,
## nas colunas 0 a RAIL_SPAN - 1, e a 2 a travessa vista de cima, centrada no pé.
const CELL_SIZE := Vector2i(96, 72)
const CELL_FOOT := Vector2i(48, 43)
const RAIL_SPAN := 16
## A arte passa até 3 px abaixo do pé, e o pilar com a sombra tem 10 px.
const ART_BELOW := 3.0
const POST_HALF_WIDTH := 5.0
const POST_GAP := 16.0
## Acima de 60°, a travessa deitada empilha e vira uma faixa: vai a vista de cima.
const STEEP_SLOPE := 1.73
## Por tipo: os postes de um trecho em pé, a largura e as linhas da travessa vista de cima.
const STEEP := {
	"wood_fence": {"gap": 16.0, "width": 4, "rows": 1},
	"stone_fence": {"gap": 24.0, "width": 8, "rows": 8},
}

enum Kind { POST, RAIL, TOP }

static var _visible: Dictionary[String, bool] = {}


class Piece:
	extends RefCounted
	var flat: Vector2i
	var kind := Kind.RAIL
	## A coluna da travessa deitada ou a linha da travessa vista de cima.
	var column := 0
	var slug := ""
	var post: bool:
		get:
			return kind == Kind.POST


static func is_visible(slug: String) -> bool:
	if _visible.is_empty():
		for row: Dictionary in GameData.get_rows("wall_types"):
			_visible[row["slug"]] = bool(row["visible"])
	return _visible.get(slug, false)


static func top_width(slug: String) -> int:
	return STEEP.get(slug, {}).get("width", 1)


static func pieces(wall: MapWall) -> Array[Piece]:
	var result: Array[Piece] = []
	if not is_visible(wall.type) or wall.points.is_empty():
		return result
	var steep_style: Dictionary = STEEP.get(wall.type, {"gap": POST_GAP, "rows": 1})
	for index: int in range(1, wall.points.size()):
		var from := wall.points[index - 1]
		var to := wall.points[index]
		var length := from.distance_to(to)
		if length < 0.5:
			continue
		var delta := to - from
		var steep := absf(delta.y) > absf(delta.x) * STEEP_SLOPE
		var posts := maxi(1, roundi(length / (float(steep_style["gap"]) if steep else POST_GAP)))
		var steps := ceili(maxf(absf(delta.x), absf(delta.y)))
		for step: int in steps:
			var t := float(step) / steps
			if steep:
				result.append(_piece(wall.type, from.lerp(to, t), Kind.TOP, step % int(steep_style["rows"])))
			else:
				var between := fposmod(t * posts, 1.0)
				result.append(_piece(wall.type, from.lerp(to, t), Kind.RAIL, mini(int(between * RAIL_SPAN), RAIL_SPAN - 1)))
		for post: int in posts:
			result.append(_piece(wall.type, from.lerp(to, float(post) / posts), Kind.POST, 0))
	result.append(_piece(wall.type, wall.points[wall.points.size() - 1], Kind.POST, 0))
	return result


static func _piece(slug: String, at: Vector2, kind: Kind, column: int) -> Piece:
	var piece := Piece.new()
	piece.flat = Vector2i(at.round())
	piece.kind = kind
	piece.column = column
	piece.slug = slug
	return piece
