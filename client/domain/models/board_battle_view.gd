class_name BoardBattleView
extends RefCounted

var phase: String = ""
var result: String = ""
var round_number: int = 1
var can_flee: bool = false
var tamer_name_id: int = 0
var tamer_source: String = ""
var team: Array[BattleCreature] = []
var items: Array[InventorySlot] = []
var board_cells: Array[Vector2i] = []
var player_zone: Array[Vector2i] = []
var enemy_zone: Array[Vector2i] = []
var marks: Array[GroundMark] = []
var queue: Array[BoardSpot] = []
var player_actives: Array[int] = []
var player_cells: Dictionary[int, Vector2i] = {}
var enemy_cells: Dictionary[int, Vector2i] = {}
var enemies: Dictionary[int, BattleCreature] = {}
var enemy_team_size: int = 0
var pending_positions: Array[int] = []
var entry_cells: Array[Vector2i] = []


func current() -> BoardSpot:
	return queue[0] if phase == "choose_action" and not queue.is_empty() else null


func player_at(position: int) -> BattleCreature:
	if position < 0 or position >= player_actives.size() or player_actives[position] < 0:
		return null
	return team[player_actives[position]]


func occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.append_array(player_cells.values())
	cells.append_array(enemy_cells.values())
	return cells


static func cell_of(d: Dictionary) -> Vector2i:
	return Vector2i(DictFields.get_int(d, "q"), DictFields.get_int(d, "r"))


static func from_dict(d: Dictionary) -> BoardBattleView:
	var view := BoardBattleView.new()
	view.phase = DictFields.get_string(d, "phase")
	view.result = DictFields.get_string(d, "result")
	view.round_number = DictFields.get_int(d, "round", 1)
	view.can_flee = DictFields.get_bool(d, "can_flee")
	var tamer := DictFields.get_dict(d, "tamer")
	view.tamer_name_id = DictFields.get_int(tamer, "name_id")
	view.tamer_source = DictFields.get_string(tamer, "source")

	var board := DictFields.get_dict(d, "board")
	view.board_cells = _cells(DictFields.get_array(board, "cells"))
	var zones := DictFields.get_dict(board, "zones")
	view.player_zone = _cells(DictFields.get_array(zones, "player"))
	view.enemy_zone = _cells(DictFields.get_array(zones, "enemy"))
	for mark: Variant in DictFields.get_array(d, "marks"):
		if mark is Dictionary:
			view.marks.append(GroundMark.from_dict(mark))
	for spot: Variant in DictFields.get_array(d, "queue"):
		if spot is Dictionary:
			view.queue.append(BoardSpot.from_dict(spot))

	var player := DictFields.get_dict(d, "player")
	for creature_dict: Variant in DictFields.get_array(player, "team"):
		if creature_dict is Dictionary:
			view.team.append(BattleCreature.from_dict(creature_dict))
	for slot_dict: Variant in DictFields.get_array(player, "items"):
		if slot_dict is Dictionary:
			view.items.append(InventorySlot.from_dict(slot_dict))
	for index: Variant in DictFields.get_array(player, "active_indices"):
		view.player_actives.append(int(index) if index is float or index is int else -1)
	view.player_cells = _cells_by_slot(DictFields.get_array(player, "cells"))
	for position: Variant in DictFields.get_array(player, "pending_positions"):
		if position is float or position is int:
			view.pending_positions.append(int(position))
	view.entry_cells = _cells(DictFields.get_array(player, "entry_cells"))

	var enemy := DictFields.get_dict(d, "enemy")
	var actives := DictFields.get_array(enemy, "actives")
	for position: int in actives.size():
		if actives[position] is Dictionary:
			view.enemies[position] = BattleCreature.from_dict(actives[position])
	view.enemy_cells = _cells_by_slot(DictFields.get_array(enemy, "cells"))
	view.enemy_team_size = DictFields.get_int(enemy, "team_size")
	return view


static func _cells(list: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for item: Variant in list:
		if item is Dictionary:
			cells.append(cell_of(item))
	return cells


static func _cells_by_slot(list: Array) -> Dictionary[int, Vector2i]:
	var cells: Dictionary[int, Vector2i] = {}
	for position: int in list.size():
		if list[position] is Dictionary:
			cells[position] = cell_of(list[position])
	return cells
