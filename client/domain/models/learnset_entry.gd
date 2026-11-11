class_name LearnsetEntry
extends RefCounted

var skill_id: int
var level: int
var method_slug: String


static func create(skill: int, learn_level: int, method: String) -> LearnsetEntry:
	var entry := LearnsetEntry.new()
	entry.skill_id = skill
	entry.level = learn_level
	entry.method_slug = method
	return entry
