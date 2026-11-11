class_name EditorHistory
extends Node

signal applied(coords: Array[Vector2i])

const RENAME_ACTION := "Renomear"


class Step:
	var label := ""
	var before: Dictionary[Vector2i, Array] = {}
	var after: Dictionary[Vector2i, Array] = {}
	var buildings_before: Variant = null
	var buildings_after: Variant = null
	var areas_before: Variant = null
	var areas_after: Variant = null
	var start_before: Variant = null
	var start_after: Variant = null
	var name_before: Variant = null
	var name_after: Variant = null

	func is_empty() -> bool:
		return after.is_empty() and buildings_after == null and areas_after == null and start_after == null and name_after == null


var _undo_redo := UndoRedo.new()
var _draft: IslandDraft = null


func _exit_tree() -> void:
	_undo_redo.free()


func reset(draft: IslandDraft) -> void:
	_draft = draft
	_undo_redo.clear_history(false)


func version() -> int:
	return _undo_redo.get_version()


func record(step: Step, merge: bool = false) -> void:
	if step == null or step.is_empty():
		return
	_undo_redo.create_action(step.label, UndoRedo.MERGE_ENDS if merge else UndoRedo.MERGE_DISABLE)
	_undo_redo.add_do_method(_apply.bind(step, true))
	_undo_redo.add_undo_method(_apply.bind(step, false))
	_undo_redo.commit_action(false)


func record_rename(before: String, after: String) -> void:
	var step := Step.new()
	step.label = RENAME_ACTION
	step.name_before = before
	step.name_after = after
	_undo_redo.create_action(RENAME_ACTION, UndoRedo.MERGE_ENDS)
	_undo_redo.add_do_method(_apply.bind(step, true))
	_undo_redo.add_undo_method(_apply.bind(step, false))
	_undo_redo.commit_action(false)


func undo() -> bool:
	return _undo_redo.undo()


func redo() -> bool:
	return _undo_redo.redo()


func _apply(step: Step, forward: bool) -> void:
	if _draft == null:
		return
	var tiles: Dictionary[Vector2i, Array] = step.after if forward else step.before
	var coords: Array[Vector2i] = []
	for coord: Vector2i in tiles:
		_draft.restore(coord, tiles[coord])
		coords.append(coord)
	var buildings: Variant = step.buildings_after if forward else step.buildings_before
	if buildings != null:
		_draft.buildings = (buildings as Array).duplicate(true)
	var areas: Variant = step.areas_after if forward else step.areas_before
	if areas != null:
		_draft.areas = (areas as Array).duplicate(true)
	var start: Variant = step.start_after if forward else step.start_before
	if start != null:
		coords.append(_draft.start)
		_draft.start = start
		coords.append(_draft.start)
	var island_name: Variant = step.name_after if forward else step.name_before
	if island_name != null:
		_draft.name = island_name
	applied.emit(coords)
