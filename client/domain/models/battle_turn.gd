class_name BattleTurn
extends RefCounted
## O que uma chamada da batalha devolve: o estado final e o que aconteceu até ele.

var view: BattleView = null
var events: Array[Dictionary] = []


## null se a resposta não tiver `battle` ou `events`.
static func from_dict(d: Dictionary) -> BattleTurn:
	if not (d.get("battle") is Dictionary and d.get("events") is Array):
		return null
	var turn := BattleTurn.new()
	turn.view = BattleView.from_dict(d["battle"])
	for event: Variant in d["events"]:
		if event is Dictionary:
			turn.events.append(event)
	return turn
