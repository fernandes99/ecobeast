class_name InteriorNpc
extends RefCounted

## Um NPC parado num quadrado da sala (interiors/01).

var id: int = 0
var npc_id: int = 0
var cell := Vector2i.ZERO
var dialogue := ""
## 0 é sem ação.
var action_type_id: int = 0


static func from_dict(d: Dictionary) -> InteriorNpc:
	var npc := InteriorNpc.new()
	npc.id = DictFields.get_int(d, "id")
	npc.npc_id = DictFields.get_int(d, "npc_id")
	npc.cell = Vector2i(DictFields.get_int(d, "x"), DictFields.get_int(d, "y"))
	npc.dialogue = DictFields.get_string(d, "dialogue")
	npc.action_type_id = maxi(0, DictFields.get_int(d, "action_type_id"))
	return npc


func to_dict() -> Dictionary:
	return {"id": id, "npc_id": npc_id, "x": cell.x, "y": cell.y, "dialogue": dialogue, "action_type_id": action_type_id if action_type_id > 0 else null}


## O NPC parado que o `NpcSprite` desenha, com a fala partida em parágrafos.
func to_map_npc() -> MapNpc:
	var npc := MapNpc.new()
	npc.id = id
	npc.npc_id = npc_id
	npc.coord = cell
	npc.still = true
	npc.dialogue = dialogue
	npc.action_type_id = action_type_id if action_type_id > 0 else -1
	return npc
