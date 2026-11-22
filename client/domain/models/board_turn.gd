class_name BoardTurn
extends RefCounted

var view: BoardBattleView = null
var events: Array[Dictionary] = []
var captured_to: String = ""
var spawn_id: int = 0
var tamer_id: int = 0
var progression: Array[CreatureProgress] = []
var registered_species_ids: Array[int] = []
## O XP do Domador no fim da luta; nulo nas outras respostas (tamer-level/02).
var tamer_progress: TamerProgress = null
## A ilha que a vitória contra o Domador da ilha abriu (auralis/04); vazio sem.
var island_unlocked_name: String = ""
## A Arena cujo Mestre foi vencido pela primeira vez (auralis/05): o nome e a sala da seguinte (0 sem).
var arena_won_name: String = ""
var arena_next_interior_id: int = 0


static func from_dict(d: Dictionary) -> BoardTurn:
	if not (d.get("battle") is Dictionary and d.get("events") is Array):
		return null
	var turn := BoardTurn.new()
	turn.view = BoardBattleView.from_dict(d["battle"])
	turn.captured_to = DictFields.get_string(d, "captured_to")
	turn.spawn_id = DictFields.get_int(d, "spawn_id")
	turn.tamer_id = DictFields.get_int(d, "tamer_id")
	for event: Variant in d["events"]:
		if event is Dictionary:
			turn.events.append(event)
	for item: Variant in DictFields.get_array(d, "progression"):
		if item is Dictionary:
			turn.progression.append(CreatureProgress.from_dict(item))
	for value: Variant in DictFields.get_array(d, "registered_species_ids"):
		if value is int or value is float:
			turn.registered_species_ids.append(int(value))
	var tamer: Variant = d.get("tamer_progress")
	if tamer is Dictionary:
		turn.tamer_progress = TamerProgress.from_dict(tamer)
	turn.island_unlocked_name = DictFields.get_string(DictFields.get_dict(d, "island_unlocked"), "name")
	var arena := DictFields.get_dict(d, "arena_won")
	turn.arena_won_name = DictFields.get_string(arena, "name")
	turn.arena_next_interior_id = DictFields.get_int(arena, "next_interior_id")
	return turn
