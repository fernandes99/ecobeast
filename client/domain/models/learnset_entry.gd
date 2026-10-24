class_name LearnsetEntry
extends RefCounted
## Uma Técnica aprendida por uma espécie (linha de species_skills).

var skill_id: int
## Nível em que aprende; 0 = ao ascender.
var level: int
## "level_up" ou "evolution".
var method_slug: String


static func create(skill: int, learn_level: int, method: String) -> LearnsetEntry:
	var entry := LearnsetEntry.new()
	entry.skill_id = skill
	entry.level = learn_level
	entry.method_slug = method
	return entry
