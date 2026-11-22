class_name MapNpc
extends RefCounted

## Um NPC posto numa ilha (island-npcs). `tiles` são os hexágonos do passeio, sem o
## de nascimento, que sempre conta.
var id: int = 0
var npc_id: int = 0
var coord := Vector2i.ZERO
var still := false
var tiles: Array[Vector2i] = []
var dialogue := ""
var action_type_id: int = -1


func walk_tiles() -> Array[Vector2i]:
	var all: Array[Vector2i] = [coord]
	for tile: Vector2i in tiles:
		if not all.has(tile):
			all.append(tile)
	return all


func lines() -> Array[String]:
	return MapNpc.paragraphs(dialogue)


## Cada parágrafo do texto, separado por linha em branco, é uma fala.
static func paragraphs(text: String) -> Array[String]:
	var result: Array[String] = []
	var current := PackedStringArray()
	for line: String in text.replace("\r", "").split("\n"):
		if line.strip_edges().is_empty():
			if not current.is_empty():
				result.append(" ".join(current))
				current.clear()
		else:
			current.append(line.strip_edges())
	if not current.is_empty():
		result.append(" ".join(current))
	return result


func has_talk() -> bool:
	return not lines().is_empty() or action_type_id > 0


static func from_dict(d: Dictionary) -> MapNpc:
	var npc := MapNpc.new()
	npc.id = DictFields.get_int(d, "id")
	npc.npc_id = DictFields.get_int(d, "npc_id")
	npc.coord = Vector2i(DictFields.get_int(d, "q"), DictFields.get_int(d, "r"))
	npc.still = DictFields.get_bool(d, "still")
	for tile: Variant in DictFields.get_array(d, "tiles"):
		if tile is Dictionary:
			npc.tiles.append(Vector2i(DictFields.get_int(tile, "q"), DictFields.get_int(tile, "r")))
	npc.dialogue = DictFields.get_string(d, "dialogue")
	npc.action_type_id = DictFields.get_id(d, "action_type_id")
	return npc if npc.npc_id > 0 else null
