class_name BattleView
extends RefCounted
## A batalha como o jogador a vê: o JSON `battle` do servidor. Do inimigo, só
## quem está em campo (.specs/battle-core/architecture.md, "API").

## choose_action, choose_next ou ended.
var phase: String = ""
## victory, defeat, fled ou captured; "" enquanto a luta dura.
var result: String = ""
var turn: int = 1
var can_flee: bool = false
var active_index: int = 0
var team: Array[BattleCreature] = []
## O que resta na Mochila, descontando o que já foi usado na luta.
var items: Array[InventorySlot] = []
var enemy: BattleCreature = null
var enemy_team_size: int = 0
var enemy_fainted: int = 0


## Quem está em campo do lado do jogador.
func active() -> BattleCreature:
	return team[active_index]


static func from_dict(d: Dictionary) -> BattleView:
	var view := BattleView.new()
	view.phase = DictFields.get_string(d, "phase")
	view.result = DictFields.get_string(d, "result")
	view.turn = DictFields.get_int(d, "turn", 1)
	view.can_flee = DictFields.get_bool(d, "can_flee")
	var player := DictFields.get_dict(d, "player")
	view.active_index = DictFields.get_int(player, "active_index")
	for creature_dict: Variant in DictFields.get_array(player, "team"):
		if creature_dict is Dictionary:
			view.team.append(BattleCreature.from_dict(creature_dict))
	for slot_dict: Variant in DictFields.get_array(player, "items"):
		if slot_dict is Dictionary:
			view.items.append(InventorySlot.from_dict(slot_dict))
	var enemy_side := DictFields.get_dict(d, "enemy")
	view.enemy = BattleCreature.from_dict(DictFields.get_dict(enemy_side, "active"))
	view.enemy_team_size = DictFields.get_int(enemy_side, "team_size")
	view.enemy_fainted = DictFields.get_int(enemy_side, "fainted")
	return view
