class_name ProgressChoice
extends RefCounted

var creature: CreatureInstance = null
var learned_skill_ids: Array[int] = []
var pending_skill_ids: Array[int] = []
var registered_species_ids: Array[int] = []


static func from_dict(d: Dictionary) -> ProgressChoice:
	var row := DictFields.get_dict(d, "creature")
	if row.is_empty():
		return null
	var choice := ProgressChoice.new()
	choice.creature = CreatureInstance.from_dict(row)
	choice.learned_skill_ids = _ids(DictFields.get_array(d, "learned_skill_ids"))
	choice.pending_skill_ids = _ids(DictFields.get_array(d, "pending_skill_ids"))
	choice.registered_species_ids = _ids(DictFields.get_array(d, "registered_species_ids"))
	return choice


static func _ids(values: Array) -> Array[int]:
	var ids: Array[int] = []
	for value: Variant in values:
		if value is int or value is float:
			ids.append(int(value))
	return ids
