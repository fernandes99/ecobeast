class_name Codex
extends RefCounted

enum Status { UNKNOWN, SEEN, CAUGHT }

var _caught: Dictionary[int, bool] = {}


static func from_dict(d: Dictionary) -> Codex:
	var codex := Codex.new()
	for entry: Variant in DictFields.get_array(d, "entries"):
		if not entry is Dictionary:
			continue
		var species_id := DictFields.get_int(entry, "species_id")
		if species_id <= 0:
			continue
		codex._caught[species_id] = DictFields.get_bool(entry, "caught")
	return codex


func status(species_id: int) -> Status:
	if not _caught.has(species_id):
		return Status.UNKNOWN
	return Status.CAUGHT if _caught[species_id] else Status.SEEN


func seen_count() -> int:
	return _caught.size()


func caught_count() -> int:
	return _caught.values().count(true)
