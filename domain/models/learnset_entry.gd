class_name LearnsetEntry
extends RefCounted
## Uma Técnica aprendida por uma espécie (linha de species_skills).

var skill_id: int
## Nível em que aprende; 0 = ao ascender.
var level: int
## "level_up" ou "evolution".
var method_slug: String


static func create(skill_id: int, level: int, method_slug: String) -> LearnsetEntry:
	var entry := LearnsetEntry.new()
	entry.skill_id = skill_id
	entry.level = level
	entry.method_slug = method_slug
	return entry
