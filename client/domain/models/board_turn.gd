class_name BoardTurn
extends RefCounted

var view: BoardBattleView = null
var events: Array[Dictionary] = []
var captured_to: String = ""
var spawn_id: int = 0
var tamer_id: int = 0
var progression: Array[CreatureProgress] = []
var registered_species_ids: Array[int] = []


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
	return turn
