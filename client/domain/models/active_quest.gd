class_name ActiveQuest
extends RefCounted

## Uma missão aceita e não entregue, para o quadro de Explorar (explore-hud/01).

var id := -1
var island_id := -1
var island_name := ""
var npc_id := -1
var npc_name := ""
var title := ""
## O `slug` do tipo (`quest_types`).
var type := &""
var progress := 0
var target := 1
## "2/3", "40%/60%" ou "3/5 min", pronto do servidor.
var progress_text := ""
var done := false


static func from_dict(data: Dictionary) -> ActiveQuest:
	var quest := ActiveQuest.new()
	quest.id = DictFields.get_int(data, "id", -1)
	quest.island_id = DictFields.get_int(data, "island_id", -1)
	quest.island_name = DictFields.get_string(data, "island_name")
	quest.npc_id = DictFields.get_int(data, "npc_id", -1)
	quest.npc_name = DictFields.get_string(data, "npc_name")
	quest.title = DictFields.get_string(data, "title")
	quest.type = StringName(DictFields.get_string(data, "type"))
	quest.progress = DictFields.get_int(data, "progress")
	quest.target = maxi(1, DictFields.get_int(data, "target", 1))
	quest.progress_text = DictFields.get_string(data, "progress_text")
	quest.done = DictFields.get_bool(data, "done")
	return quest


static func list_from(items: Array) -> Array[ActiveQuest]:
	var quests: Array[ActiveQuest] = []
	for item: Variant in items:
		if item is Dictionary:
			quests.append(from_dict(item))
	return quests


func ratio() -> float:
	return clampf(float(progress) / float(target), 0.0, 1.0)
