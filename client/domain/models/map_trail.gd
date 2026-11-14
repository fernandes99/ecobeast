class_name MapTrail
extends RefCounted

## Um traço de caminho da ilha: só desenho (free-trails/03). Os pontos são pixels da
## arte no chão plano, a partir do centro plano do hexágono (0, 0).
## O centro plano do hexágono (0, 0), em pixels da arte (HexMapView.flat_center).
const ORIGIN := Vector2(32.0, 29.0)

var ground: String = ""
var width: int = 22
var points := PackedVector2Array()
## Os pontos suavizados, guardados por quem desenha; vazio depois de mudar `points`.
var smoothed := PackedVector2Array()


static func from_dict(d: Dictionary) -> MapTrail:
	var trail := MapTrail.new()
	trail.ground = DictFields.get_string(d, "ground")
	trail.width = DictFields.get_int(d, "width", 22)
	var values := DictFields.get_array(d, "points")
	for index: int in range(0, values.size() - 1, 2):
		trail.points.append(Vector2(float(values[index]), float(values[index + 1])) + ORIGIN)
	return trail if not trail.ground.is_empty() and trail.points.size() >= 2 else null


func to_dict() -> Dictionary:
	var values: Array[int] = []
	for point: Vector2 in points:
		var relative := (point - ORIGIN).round()
		values.append(int(relative.x))
		values.append(int(relative.y))
	return {"ground": ground, "width": width, "points": values}


func copy() -> MapTrail:
	var trail := MapTrail.new()
	trail.ground = ground
	trail.width = width
	trail.points = points.duplicate()
	return trail
