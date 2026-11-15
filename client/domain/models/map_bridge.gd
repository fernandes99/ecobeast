class_name MapBridge
extends RefCounted

## Uma ponte da ilha (bridges/01): um trecho reto entre duas pontas em terra, com o
## estilo do catálogo `bridge_types` e a largura em pixels (bridges/05). As pontas são
## pixels da arte no chão plano, como os pontos do MapTrail.

const DEFAULT_WIDTH := 28

var type: String = ""
var from := Vector2.ZERO
var to := Vector2.ZERO
var width := DEFAULT_WIDTH


static func from_dict(d: Dictionary) -> MapBridge:
	var values := DictFields.get_array(d, "points")
	var bridge := MapBridge.new()
	bridge.type = DictFields.get_string(d, "type")
	if bridge.type.is_empty() or values.size() != 4:
		return null
	bridge.from = Vector2(float(values[0]), float(values[1])) + MapTrail.ORIGIN
	bridge.to = Vector2(float(values[2]), float(values[3])) + MapTrail.ORIGIN
	bridge.width = DictFields.get_int(d, "width", DEFAULT_WIDTH)
	return bridge


func to_dict() -> Dictionary:
	var a := (from - MapTrail.ORIGIN).round()
	var b := (to - MapTrail.ORIGIN).round()
	return {"type": type, "points": [int(a.x), int(a.y), int(b.x), int(b.y)], "width": width}


func copy() -> MapBridge:
	var bridge := MapBridge.new()
	bridge.type = type
	bridge.from = from
	bridge.to = to
	bridge.width = width
	return bridge
