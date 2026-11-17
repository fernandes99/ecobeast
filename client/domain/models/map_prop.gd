class_name MapProp
extends RefCounted

## Uma peça solta da ilha (free-props). O pé fica em `offset` pixels da arte a partir
## do centro plano de `coord`. Ela bloqueia pelas linhas do tipo, ou pelas suas quando
## `custom_block` (free-objects/01).

const MAX_LINES := 8
const MAX_POINTS := 64
const MAX_COORD := 512

var prop_type_id: int = 0
var coord := Vector2i.ZERO
var offset := Vector2i.ZERO
var variant: int = 1
var mirrored := false
var custom_block := false
## A ação que acontece quando o Domador encosta no bloqueio (free-objects/03), ou 0.
var action_type_id: int = 0
## A casa fica sem a fumaça da chaminé (chimney-smoke/01).
var no_smoke := false
## As linhas ajustadas, como o servidor manda: `{"closed": bool, "points": [x0, y0, …]}`.
var block: Array[Dictionary] = []


static func from_dict(d: Dictionary) -> MapProp:
	var prop := MapProp.new()
	prop.prop_type_id = DictFields.get_int(d, "prop_type_id")
	prop.coord = Vector2i(DictFields.get_int(d, "q"), DictFields.get_int(d, "r"))
	prop.offset = Vector2i(DictFields.get_int(d, "dx"), DictFields.get_int(d, "dy"))
	prop.variant = maxi(1, DictFields.get_int(d, "variant", 1))
	prop.mirrored = DictFields.get_bool(d, "mirrored")
	prop.action_type_id = DictFields.get_int(d, "action_type_id")
	prop.no_smoke = DictFields.get_bool(d, "no_smoke")
	if d.get("block") is Array:
		prop.custom_block = true
		prop.block = MapProp.lines_from(d["block"])
	return prop if prop.prop_type_id > 0 else null


static func lines_from(values: Array) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	for entry: Variant in values:
		if not entry is Dictionary:
			continue
		var points: Array[int] = []
		for value: Variant in DictFields.get_array(entry, "points"):
			points.append(int(value))
		if points.size() >= 4:
			lines.append({"closed": DictFields.get_bool(entry, "closed"), "points": points})
	return lines


func foot() -> Vector2:
	return HexMapView.flat_center(coord) + Vector2(offset)


## As linhas no chão plano, com o espelho; a fechada repete o primeiro ponto no fim.
## `type_lines` são as do tipo, usadas quando a peça não tem as próprias.
func world_lines(type_lines: Array[Dictionary]) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var origin := foot()
	var mirror := -1.0 if mirrored else 1.0
	for line: Dictionary in (block if custom_block else type_lines):
		var values: Array = line["points"]
		var points := PackedVector2Array()
		for index: int in range(0, values.size() - 1, 2):
			points.append(origin + Vector2(mirror * float(values[index]), float(values[index + 1])))
		if bool(line["closed"]) and points.size() >= 3:
			points.append(points[0])
		if points.size() >= 2:
			result.append(points)
	return result
