class_name EditorHistory
extends Node

signal applied(coords: Array[Vector2i])

const RENAME_ACTION := "Renomear"


class Step:
	var label := ""
	var before: Dictionary[Vector2i, Array] = {}
	var after: Dictionary[Vector2i, Array] = {}
	var actions_before: Variant = null
	var actions_after: Variant = null
	var objects_before: Variant = null
	var objects_after: Variant = null
	var props_before: Variant = null
	var props_after: Variant = null
	var trails_before: Variant = null
	var trails_after: Variant = null
	var areas_before: Variant = null
	var areas_after: Variant = null
	var start_before: Variant = null
	var start_after: Variant = null
	var name_before: Variant = null
	var name_after: Variant = null

	func is_empty() -> bool:
		return after.is_empty() and actions_after == null and objects_after == null and props_after == null and trails_after == null and areas_after == null and start_after == null and name_after == null


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


func can_undo() -> bool:
	return _undo_redo.has_undo()


func can_redo() -> bool:
	return _undo_redo.has_redo()


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
	var actions: Variant = step.actions_after if forward else step.actions_before
	if actions != null:
		_draft.actions = (actions as Array).duplicate(true)
	var objects: Variant = step.objects_after if forward else step.objects_before
	if objects != null:
		_draft.objects = (objects as Array).duplicate(true)
	var props: Variant = step.props_after if forward else step.props_before
	if props != null:
		_draft.props = (props as Array).duplicate(true)
	var trails: Variant = step.trails_after if forward else step.trails_before
	if trails != null:
		_draft.trails = IslandDraft.copy_trails(trails)
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
