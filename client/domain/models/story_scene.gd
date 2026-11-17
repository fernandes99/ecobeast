class_name StoryScene
extends RefCounted

## Uma cena da história (story/02), lida de `res://story/scenes/<slug>.json`. Os passos
## ficam como vieram do arquivo; quem os confere é o `StoryValidator`.
var slug := ""
var name := ""
var island_id: int = 0
var repeatable := false
var priority: int = 0
var requires: Array[String] = []
var forbids: Array[String] = []
var trigger: Dictionary = {"type": "auto"}
var actors: Array[Dictionary] = []
var steps: Array = []


func actor(key: String) -> Dictionary:
	for entry: Dictionary in actors:
		if str(entry.get("key", "")) == key:
			return entry
	return {}


func copy() -> StoryScene:
	return StoryScene.from_dict(to_dict().duplicate(true))


## Na ordem do arquivo salvo, para a diferença no git ficar fácil de ler.
func to_dict() -> Dictionary:
	return {
		"slug": slug,
		"name": name,
		"island_id": island_id,
		"repeatable": repeatable,
		"priority": priority,
		"requires": requires.duplicate(),
		"forbids": forbids.duplicate(),
		"trigger": trigger.duplicate(true),
		"actors": actors.duplicate(true),
		"steps": steps.duplicate(true),
	}


static func from_dict(d: Dictionary) -> StoryScene:
	var scene := StoryScene.new()
	scene.slug = DictFields.get_string(d, "slug")
	scene.name = DictFields.get_string(d, "name")
	scene.island_id = DictFields.get_int(d, "island_id")
	scene.repeatable = DictFields.get_bool(d, "repeatable")
	scene.priority = DictFields.get_int(d, "priority")
	scene.requires = strings(DictFields.get_array(d, "requires"))
	scene.forbids = strings(DictFields.get_array(d, "forbids"))
	scene.trigger = DictFields.get_dict(d, "trigger")
	for entry: Variant in DictFields.get_array(d, "actors"):
		if entry is Dictionary:
			scene.actors.append(entry)
	scene.steps = DictFields.get_array(d, "steps")
	return scene


static func strings(items: Array) -> Array[String]:
	var result: Array[String] = []
	for item: Variant in items:
		if item is String:
			result.append(item)
	return result
