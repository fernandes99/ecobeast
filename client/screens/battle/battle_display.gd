class_name BattleDisplay
extends RefCounted
## O que a tela mostra enquanto as linhas do turno aparecem
## (.specs/battle-screen/architecture.md, "Mostrar um turno"). Só copia campos
## dos eventos, sem calcular regra; no fim, o BattleView da resposta manda.

const HP_EVENTS: Array[String] = ["damage", "recoil", "healed", "confused_hit", "status_damage"]
## Status que o cartão não mostra: valem só no turno ou impedem a fuga.
const UNSHOWN_STATUSES: Array[String] = ["fear", "trapped"]
const CONFUSION := "confusion"

var player: BattleCreature = null
var enemy: BattleCreature = null


func reset(view: BattleView) -> void:
	player = view.active().copy()
	enemy = view.enemy.copy()


## `final_view` é a resposta do turno: uma criatura só entra depois de tudo o
## que aconteceu nele, e o evento não traz o uid nem o HP dela.
func apply(event: Dictionary, final_view: BattleView) -> void:
	var side := DictFields.get_string(event, "side")
	if side != "player" and side != "enemy":
		return
	var type := DictFields.get_string(event, "type")
	if type == "creature_entered":
		_enter(side, final_view)
		return
	if type == "item_used":
		_apply_item(event, final_view)
		return

	var creature := player if side == "player" else enemy
	if type in HP_EVENTS:
		creature.hp = DictFields.get_int(event, "hp")
	match type:
		"status_applied":
			_apply_status(creature, DictFields.get_string(event, "status"))
		"status_ended":
			if DictFields.get_string(event, "status") == CONFUSION:
				creature.confused = false
		"woke_up", "thawed":
			creature.status = ""
		"fainted":
			creature.status = ""
			creature.confused = false
		"stat_changed":
			creature.stages[DictFields.get_string(event, "stat")] = DictFields.get_int(event, "value")


## O item pode ter sido usado em um reserva, que o cartão não mostra.
func _apply_item(event: Dictionary, final_view: BattleView) -> void:
	if DictFields.get_int(event, "team_index") != final_view.active_index:
		return
	player.hp = DictFields.get_int(event, "hp")
	if not DictFields.get_string(event, "cured_status").is_empty():
		player.status = ""


func _enter(side: String, final_view: BattleView) -> void:
	if side == "player":
		player = final_view.active().copy()
	else:
		enemy = final_view.enemy.copy()


func _apply_status(creature: BattleCreature, status: String) -> void:
	if status == CONFUSION:
		creature.confused = true
	elif not status in UNSHOWN_STATUSES:
		creature.status = status
