class_name PlayerCounters
extends RefCounted
## Os contadores do Domador, como o servidor manda em `GET /v1/me/counters` (.specs/player-stats/).

var created_at: String = ""
var walkable_biomes: int = 0
## 0 enquanto nenhum Ecobeast lutou.
var partner_species_id: int = 0
var partner_battles: int = 0
var _values: Dictionary[Vector2i, int] = {}


static func from_dict(d: Dictionary) -> PlayerCounters:
	var counters := PlayerCounters.new()
	counters.created_at = DictFields.get_string(d, "created_at")
	counters.walkable_biomes = DictFields.get_int(d, "walkable_biomes")
	var partner := DictFields.get_dict(d, "partner")
	counters.partner_species_id = DictFields.get_int(partner, "species_id")
	counters.partner_battles = DictFields.get_int(partner, "battles")
	for row: Variant in DictFields.get_array(d, "counters"):
		if row is Dictionary:
			var key := Vector2i(DictFields.get_int(row, "counter_id"), DictFields.get_int(row, "subject_id"))
			counters._values[key] = DictFields.get_int(row, "value")
	return counters


func value(counter_id: int, subject_id: int = 0) -> int:
	return _values.get(Vector2i(counter_id, subject_id), 0)


## Recorte -> valor, só os acima de 0.
func by_subject(counter_id: int) -> Dictionary[int, int]:
	var found: Dictionary[int, int] = {}
	for key: Vector2i in _values:
		if key.x == counter_id and key.y != 0 and _values[key] > 0:
			found[key.y] = _values[key]
	return found
