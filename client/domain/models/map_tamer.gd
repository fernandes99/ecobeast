class_name MapTamer
extends RefCounted
## Um Domador NPC no mapa (npc-tamers/04). O servidor manda só o que o mapa
## precisa: a equipe e o tamanho da luta aparecem nela.

var id: int = 0
var coord := Vector2i.ZERO
## Ids de `npc_tamer_names` e `npc_tamer_greetings`; quem mostra lê o texto no GameData.
var name_id: int = 0
var greeting_id: int = 0


## null se faltar o id, a posição, o nome ou a fala.
static func from_dict(d: Dictionary) -> MapTamer:
	for key: String in ["id", "q", "r", "name_id", "greeting_id"]:
		if not d.has(key):
			return null
	var tamer := MapTamer.new()
	tamer.id = DictFields.get_int(d, "id")
	tamer.coord = Vector2i(DictFields.get_int(d, "q"), DictFields.get_int(d, "r"))
	tamer.name_id = DictFields.get_int(d, "name_id")
	tamer.greeting_id = DictFields.get_int(d, "greeting_id")
	return tamer

