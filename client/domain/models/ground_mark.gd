class_name GroundMark
extends RefCounted

var cell := Vector2i.ZERO
var ground_effect_id: int = 0
var remaining: int = 0


static func create(mark_cell: Vector2i, effect_id: int, turns_left: int) -> GroundMark:
	var mark := GroundMark.new()
	mark.cell = mark_cell
	mark.ground_effect_id = effect_id
	mark.remaining = turns_left
	return mark


static func from_dict(d: Dictionary) -> GroundMark:
	return create(BoardBattleView.cell_of(d), DictFields.get_int(d, "ground_effect_id"), DictFields.get_int(d, "remaining"))
