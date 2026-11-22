class_name QuestConversation
extends RefCounted

## A conversa com um NPC numa ilha (auralis/06 e 10), em Explorar e nas salas: pergunta ao
## servidor em que ponto está a missão dele e toca a conversa escrita daquele momento
## no lugar da fala padrão, com as escolhas, a recusa e as falas automáticas no fim.
## A tela empresta a caixa de fala e as opções, e ignora os toques na caixa enquanto
## `run` não acaba.

enum Outcome { CONTINUE, ACCEPT, DECLINE }

const NPC := "npc"
const TAMER := "tamer"
const OUTCOME_ACCEPT := "accept"
const OUTCOME_DECLINE := "decline"
const ITEM_FALLBACK := "item"

var _greeting: TamerGreetingPanel = null
var _choices: StoryChoicePanel = null
var _npc_id := 0


func _init(greeting: TamerGreetingPanel, choices: StoryChoicePanel) -> void:
	_greeting = greeting
	_choices = choices


## `play_scene(slug)` toca a cena do início e devolve se tocou; inválido onde não há cena.
func run(npc: MapNpc, play_scene: Callable = Callable()) -> void:
	_npc_id = npc.npc_id
	var result: Result = await Session.talk_quest(npc.npc_id)
	var talk: QuestTalk = result.data if result.ok else null
	if talk == null or talk.stage == &"none":
		await _say_all(_default_lines(npc))
	elif talk.stage == &"offer":
		await _offer(npc, talk.quest_id, talk.dialogue, talk.offer_scene, play_scene)
	else:
		if talk.dialogue.is_empty():
			await _say_all(_default_lines(npc))
		else:
			await _play(talk.dialogue)
		await _narrate(talk.display_lines(_item_name(talk.item_id)))
		if talk.next_quest_id > 0:
			await _offer(npc, talk.next_quest_id, talk.next_dialogue, talk.next_offer_scene, play_scene, false)
	_greeting.close()
	_choices.close()


## Sem conversa nem cena, a fala padrão vem antes da aceitação (como na auralis/06), menos
## na próxima da fila, logo depois da entrega.
func _offer(npc: MapNpc, quest_id: int, dialogue: Array, scene: String, play_scene: Callable, default_first := true) -> void:
	var outcome := Outcome.CONTINUE
	var played := false
	if not scene.is_empty() and play_scene.is_valid():
		_greeting.close()
		played = await play_scene.call(scene)
	if not played:
		if not dialogue.is_empty():
			outcome = await _play(dialogue)
		elif default_first:
			await _say_all(_default_lines(npc))
	if outcome == Outcome.DECLINE:
		return
	var accepted: Result = await Session.accept_quest(quest_id)
	if accepted.ok:
		await _narrate((accepted.data as QuestTalk).lines)
	else:
		var failed: Array[String] = [accepted.error]
		await _narrate(failed)


## Uma opção com "Aceita" ou "Recusa" encerra a conversa depois das falas dela; sem isso,
## a conversa segue do passo seguinte à escolha.
func _play(steps: Array) -> Outcome:
	for i: int in steps.size():
		if not steps[i] is Dictionary:
			continue
		var step: Dictionary = steps[i]
		if step.get("type") == "say":
			_greeting.say(_line(step), _voice(step))
			await _greeting.tapped
			if not StoryPlayer._is_choice(steps[i + 1] if i + 1 < steps.size() else null):
				_greeting.close()
			continue
		var options := DictFields.get_array(step, "options")
		if options.is_empty():
			continue
		var texts: Array[String] = []
		for option: Variant in options:
			texts.append(StoryText.render(DictFields.get_string(option as Dictionary, "text"), Session.player))
		_choices.show_options(texts)
		var index: int = await _choices.chosen
		_greeting.close()
		var chosen: Dictionary = options[index]
		var inner := await _play(DictFields.get_array(chosen, "steps"))
		match DictFields.get_string(chosen, "outcome"):
			OUTCOME_ACCEPT:
				return Outcome.ACCEPT if inner != Outcome.DECLINE else inner
			OUTCOME_DECLINE:
				return Outcome.DECLINE
		if inner != Outcome.CONTINUE:
			return inner
	return Outcome.CONTINUE


func _line(step: Dictionary) -> String:
	var text := StoryText.render(DictFields.get_string(step, "text"), Session.player)
	var speaker := _speaker_name(DictFields.get_string(step, "speaker"))
	return "%s: %s" % [speaker, text] if not speaker.is_empty() else text


func _speaker_name(speaker: String) -> String:
	if speaker == NPC:
		return str(GameData.get_npc(_npc_id).get("name", ""))
	if speaker == TAMER:
		return Session.player.name if Session.player != null else ""
	return ""


func _voice(step: Dictionary) -> Dictionary:
	match DictFields.get_string(step, "speaker"):
		NPC:
			return GameData.npc_voice(_npc_id)
		TAMER:
			return GameData.voice_by_slug(StoryPlayer.TAMER_VOICE)
	return GameData.voice_by_slug(StoryPlayer.NARRATION_VOICE)


func _default_lines(npc: MapNpc) -> Array[String]:
	var npc_name := str(GameData.get_npc(npc.npc_id).get("name", ""))
	var shown: Array[String] = []
	for line: String in npc.lines():
		shown.append("%s: %s" % [npc_name, line])
	return shown


func _say_all(lines: Array[String]) -> void:
	var voice := GameData.npc_voice(_npc_id)
	for line: String in lines:
		_greeting.say(line, voice)
		await _greeting.tapped
	_greeting.close()


func _narrate(lines: Array[String]) -> void:
	var voice := GameData.voice_by_slug(StoryPlayer.NARRATION_VOICE)
	for line: String in lines:
		_greeting.say(line, voice)
		await _greeting.tapped
	_greeting.close()


func _item_name(item_id: int) -> String:
	var item := GameData.get_item(item_id) if item_id > 0 else null
	return item.name if item != null else ITEM_FALLBACK
