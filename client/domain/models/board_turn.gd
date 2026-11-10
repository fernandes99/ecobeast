class_name BoardTurn
extends RefCounted
## O que uma chamada da luta no tabuleiro devolve: o estado e o que aconteceu
## desde a vez anterior do jogador, com as vezes dos selvagens.

var view: BoardBattleView = null
var events: Array[Dictionary] = []
## party ou storage, se esta chamada capturou um Ecobeast; "" nas outras.
var captured_to: String = ""
## O Ecobeast que saiu do mapa para esta luta; 0 nas outras chamadas.
var spawn_id: int = 0
## O Domador NPC que saiu do mapa para esta luta; 0 nas outras chamadas.
var tamer_id: int = 0
## Na vitória, quem recebeu XP, na ordem da equipe; vazio nas outras chamadas.
var progression: Array[CreatureProgress] = []


## null se a resposta não tiver `battle` ou `events`.
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
	return turn
