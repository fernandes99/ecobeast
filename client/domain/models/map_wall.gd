class_name MapWall
extends RefCounted

## Uma parede da ilha (free-fences/01): uma cerca ou a parede invisível, que bloqueia
## o Domador. Os pontos são pixels da arte no chão plano, como os do MapTrail.

var type: String = ""
var points := PackedVector2Array()


static func from_dict(d: Dictionary) -> MapWall:
	var wall := MapWall.new()
	wall.type = DictFields.get_string(d, "type")
	var values := DictFields.get_array(d, "points")
	for index: int in range(0, values.size() - 1, 2):
		wall.points.append(Vector2(float(values[index]), float(values[index + 1])) + MapTrail.ORIGIN)
	return wall if not wall.type.is_empty() and wall.points.size() >= 2 else null


func to_dict() -> Dictionary:
	var values: Array[int] = []
	for point: Vector2 in points:
		var relative := (point - MapTrail.ORIGIN).round()
		values.append(int(relative.x))
		values.append(int(relative.y))
	return {"type": type, "points": values}


func copy() -> MapWall:
	var wall := MapWall.new()
	wall.type = type
	wall.points = points.duplicate()
	return wall
