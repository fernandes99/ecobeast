class_name MapCreature
extends RefCounted
## Um Ecobeast no mapa (biome-encounters/04). O servidor manda só o que o desenho
## precisa: nome e nível aparecem na luta.

var id: int = 0
var species_id: int = 0
var coord := Vector2i.ZERO


## null se faltar o id, a espécie ou a posição.
static func from_dict(d: Dictionary) -> MapCreature:
	if not (d.has("id") and d.has("species_id") and d.has("q") and d.has("r")):
		return null
	var creature := MapCreature.new()
	creature.id = DictFields.get_int(d, "id")
	creature.species_id = DictFields.get_int(d, "species_id")
	creature.coord = Vector2i(DictFields.get_int(d, "q"), DictFields.get_int(d, "r"))
	return creature
