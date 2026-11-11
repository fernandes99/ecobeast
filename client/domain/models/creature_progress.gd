class_name CreatureProgress
extends RefCounted

var uid: String = ""
var team_index: int = 0
var xp_gained: int = 0
var level_before: int = 1
var level_after: int = 1
var current_xp: int = 0
var level_xp: int = 0
var next_level_xp: int = -1
var stats_before := StatBlock.new()
var stats_after := StatBlock.new()
var evolution_species_id: int = -1
var learned_skill_ids: Array[int] = []
var pending_skill_ids: Array[int] = []


func leveled_up() -> bool:
	return level_after > level_before


func xp_ratio() -> float:
	if next_level_xp < 0:
		return 1.0
	return float(current_xp - level_xp) / (next_level_xp - level_xp)


static func from_dict(d: Dictionary) -> CreatureProgress:
	var progress := CreatureProgress.new()
	progress.uid = DictFields.get_string(d, "uid")
	progress.team_index = DictFields.get_int(d, "team_index")
	progress.xp_gained = DictFields.get_int(d, "xp_gained")
	progress.level_before = DictFields.get_int(d, "level_before", 1)
	progress.level_after = DictFields.get_int(d, "level_after", 1)
	progress.current_xp = DictFields.get_int(d, "current_xp")
	progress.level_xp = DictFields.get_int(d, "level_xp")
	progress.next_level_xp = DictFields.get_id(d, "next_level_xp")
	progress.stats_before = StatBlock.from_dict(DictFields.get_dict(d, "stats_before"))
	progress.stats_after = StatBlock.from_dict(DictFields.get_dict(d, "stats_after"))
	progress.evolution_species_id = DictFields.get_id(DictFields.get_dict(d, "evolution"), "species_id")
	progress.learned_skill_ids = _ids(DictFields.get_array(d, "learned_skill_ids"))
	progress.pending_skill_ids = _ids(DictFields.get_array(d, "pending_skill_ids"))
	return progress


static func _ids(values: Array) -> Array[int]:
	var ids: Array[int] = []
	for value: Variant in values:
		if value is int or value is float:
			ids.append(int(value))
	return ids
