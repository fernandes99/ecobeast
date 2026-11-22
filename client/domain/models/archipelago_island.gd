class_name ArchipelagoIsland
extends RefCounted

## Uma ilha do Arquipélago Auralis para o Domador (auralis/01): o servidor decide o estado.

const OPEN := &"open"
const NEXT := &"next"
const HIDDEN := &"hidden"

## 0 nas escondidas.
var id: int = 0
var order: int = 0
var state: StringName = HIDDEN
## Vazio nas escondidas.
var name: String = ""


static func from_dict(d: Dictionary) -> ArchipelagoIsland:
	var island := ArchipelagoIsland.new()
	island.id = DictFields.get_int(d, "id")
	island.order = DictFields.get_int(d, "order")
	island.state = StringName(DictFields.get_string(d, "state"))
	island.name = DictFields.get_string(d, "name")
	if island.state not in [OPEN, NEXT, HIDDEN]:
		return null
	if island.state != HIDDEN and (island.id <= 0 or island.name.is_empty()):
		return null
	return island
