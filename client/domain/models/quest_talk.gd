class_name QuestTalk
extends RefCounted

## A resposta da conversa da missão (auralis/06): as falas do servidor e o que a entrega pagou.
## Com a auralis/10, também o momento da missão (`stage`), a conversa escrita dele e, depois
## da entrega, a próxima da fila para oferecer. A aceitação (`POST /v1/me/quests/accept`)
## volta no mesmo modelo, só com `lines` e os lugares.

const REWARD_TEXT := "Você ganhou %s."
const LEVEL_TEXT := "Nível de Domador %d!"
const ISLAND_UNLOCKED_TEXT := "Ilha nova aberta: %s!"

## `none`, `offer`, `ongoing` ou `done`.
var stage := &"none"
var quest_id := -1
## Os passos da conversa escrita, como o servidor manda (`say` e `choice`).
var dialogue: Array = []
var offer_scene := ""
var next_quest_id := -1
var next_dialogue: Array = []
var next_offer_scene := ""
var lines: Array[String] = []
var coins := 0
var item_id := -1
var item_quantity := 0
var xp := 0
var tamer_progress: TamerProgress = null
var island_unlocked_name := ""
## Os lugares das missões "Vá até" que faltam na ilha: o hexágono e o nome.
var places: Dictionary[Vector2i, String] = {}
var has_reward := false


## As falas para a caixa de fala: as do servidor, a recompensa, o nível e a ilha aberta.
## O nome do item vem do catálogo, pela tela.
func display_lines(item_name: String) -> Array[String]:
	var shown: Array[String] = lines.duplicate()
	if has_reward:
		var parts: Array[String] = []
		if coins > 0:
			parts.append("%d moedas" % coins)
		if item_id > 0 and item_quantity > 0:
			parts.append("%d× %s" % [item_quantity, item_name])
		if xp > 0:
			parts.append("%d XP de Domador" % xp)
		if not parts.is_empty():
			var last: String = parts.pop_back()
			shown.append(REWARD_TEXT % (last if parts.is_empty() else "%s e %s" % [", ".join(parts), last]))
	if tamer_progress != null and tamer_progress.leveled_up():
		shown.append(LEVEL_TEXT % tamer_progress.level_after)
	if not island_unlocked_name.is_empty():
		shown.append(ISLAND_UNLOCKED_TEXT % island_unlocked_name)
	return shown


static func places_from(items: Array) -> Dictionary[Vector2i, String]:
	var found: Dictionary[Vector2i, String] = {}
	for place: Variant in items:
		if not place is Dictionary:
			continue
		var place_name := DictFields.get_string(place, "name")
		for tile: Variant in DictFields.get_array(place, "tiles"):
			if tile is Dictionary:
				found[Vector2i(DictFields.get_int(tile, "q"), DictFields.get_int(tile, "r"))] = place_name
	return found


static func from_dict(d: Dictionary) -> QuestTalk:
	var talk := QuestTalk.new()
	talk.stage = StringName(DictFields.get_string(d, "stage", "none"))
	talk.quest_id = DictFields.get_id(d, "quest_id")
	talk.dialogue = DictFields.get_array(d, "dialogue")
	talk.offer_scene = DictFields.get_string(d, "offer_scene")
	var next := DictFields.get_dict(d, "next")
	if not next.is_empty():
		talk.next_quest_id = DictFields.get_id(next, "quest_id")
		talk.next_dialogue = DictFields.get_array(next, "dialogue")
		talk.next_offer_scene = DictFields.get_string(next, "offer_scene")
	for line: Variant in DictFields.get_array(d, "lines"):
		if line is String:
			talk.lines.append(line)
	var reward: Variant = d.get("reward")
	if reward is Dictionary:
		talk.has_reward = true
		talk.coins = DictFields.get_int(reward, "coins")
		talk.item_id = DictFields.get_id(reward, "item_id")
		talk.item_quantity = DictFields.get_int(reward, "item_quantity")
		talk.xp = DictFields.get_int(reward, "xp")
	var tamer: Variant = d.get("tamer_progress")
	if tamer is Dictionary:
		talk.tamer_progress = TamerProgress.from_dict(tamer)
	talk.island_unlocked_name = DictFields.get_string(DictFields.get_dict(d, "island_unlocked"), "name")
	talk.places = places_from(DictFields.get_array(d, "quest_places"))
	return talk
