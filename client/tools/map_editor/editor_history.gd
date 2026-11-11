class_name EditorHistory
extends Node
## Desfazer e refazer do editor de ilhas (map-editor/03), sobre o `UndoRedo` do
## Godot. Cada passo guarda só o que mudou: os hexágonos de antes e de depois, as
## construções (quando um hexágono delas saiu), a chegada e o nome.

## O rascunho mudou por desfazer ou refazer: estes hexágonos precisam ser redesenhados.
signal applied(coords: Array[Vector2i])

const RENAME_ACTION := "Renomear"


## Um passo. Os campos que o passo não mexe ficam null.
class Step:
	var label := ""
	## O hexágono como `IslandDraft.snapshot` devolve, antes e depois.
	var before: Dictionary[Vector2i, Array] = {}
	var after: Dictionary[Vector2i, Array] = {}
	var buildings_before: Variant = null
	var buildings_after: Variant = null
	var start_before: Variant = null
	var start_after: Variant = null
	var name_before: Variant = null
	var name_after: Variant = null

	func is_empty() -> bool:
		return after.is_empty() and buildings_after == null and start_after == null and name_after == null


var _undo_redo := UndoRedo.new()
var _draft: IslandDraft = null


func _exit_tree() -> void:
	_undo_redo.free()


## Uma ilha nova, aberta ou descartada: o histórico começa do zero.
func reset(draft: IslandDraft) -> void:
	_draft = draft
	_undo_redo.clear_history(false)


## O número da posição no histórico: igual ao do último salvar, nada mudou.
func version() -> int:
	return _undo_redo.get_version()


## Guarda um passo que já foi feito no rascunho.
func record(step: Step) -> void:
	if step == null or step.is_empty():
		return
	_undo_redo.create_action(step.label)
	_undo_redo.add_do_method(_apply.bind(step, true))
	_undo_redo.add_undo_method(_apply.bind(step, false))
	_undo_redo.commit_action(false)


## Renomear, já feito. Letras seguidas viram um passo só.
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
	var start: Variant = step.start_after if forward else step.start_before
	if start != null:
		coords.append(_draft.start)
		_draft.start = start
		coords.append(_draft.start)
	var island_name: Variant = step.name_after if forward else step.name_before
	if island_name != null:
		_draft.name = island_name
	applied.emit(coords)
