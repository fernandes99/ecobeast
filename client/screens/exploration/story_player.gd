class_name StoryPlayer
extends Node

## Toca uma cena da história na tela de Explorar, passo por passo (story/02 e 03). A
## tela empresta a caixa de fala, as opções e o escurecer, e anda o Domador e a câmera
## pelos métodos `story_*` dela.

signal finished
signal fade_settled

const SAVE_ERROR := "Não deu para salvar a história. %s"
const RETRY_TEXT := "Tentar de novo"
const CLEAR_SECONDS := 0.3
const CAMERA_BACK_SECONDS := 0.5
const TAMER := "tamer"
const NARRATION_VOICE := "narration"
const TAMER_VOICE := "tamer"

var playing := false

var _screen: ExplorationScreen = null
var _greeting: TamerGreetingPanel = null
var _choices: StoryChoicePanel = null
var _fade: ColorRect = null
var _scene: StoryScene = null
var _set_marks: Array[String] = []
var _actors: Dictionary[String, NpcSprite] = {}
## Os atores que a cena pôs no mapa; os outros são NPCs da ilha ou seguidores.
var _created: Array[NpcSprite] = []
var _moving: Array[NpcSprite] = []
var _fade_tween: Tween = null


func setup(screen: ExplorationScreen, greeting: TamerGreetingPanel, choices: StoryChoicePanel, fade: ColorRect) -> void:
	_screen = screen
	_greeting = greeting
	_choices = choices
	_fade = fade


func play(scene: StoryScene, touched: NpcSprite = null) -> void:
	if playing:
		return
	playing = true
	_scene = scene.copy()
	_set_marks = []
	_screen.story_began()
	_place_actors(touched)
	await _run(_scene.steps)
	for sprite: NpcSprite in _moving.duplicate():
		if sprite.is_walking():
			await sprite.arrived
	_moving.clear()
	await _settle()
	await _screen.story_camera_back(CAMERA_BACK_SECONDS)
	if _fade.color.a > 0.0:
		await _fade_to(0.0, CLEAR_SECONDS)
	await _save()
	_greeting.close()
	_choices.close()
	_release_actors()
	_scene = null
	playing = false
	_screen.story_ended()
	finished.emit()


func _place_actors(touched: NpcSprite) -> void:
	_actors.clear()
	_created.clear()
	for actor: Dictionary in _scene.actors:
		var key := str(actor.get("key", ""))
		var npc_id := DictFields.get_int(actor, "npc_id")
		var sprite: NpcSprite = null
		if DictFields.get_bool(actor, "island_npc"):
			sprite = _screen.story_island_npc(npc_id, touched)
		else:
			var coord: Variant = StoryValidator.coord_of(actor)
			sprite = _screen.story_add_actor(npc_id, coord)
			if sprite != null:
				_created.append(sprite)
				sprite.visible = DictFields.get_bool(actor, "visible", true)
		if sprite == null:
			push_warning("Cena %s: o ator %s não está no mapa." % [_scene.slug, key])
			continue
		sprite.scripted = true
		sprite.walk_speed = NpcSprite.STORY_SPEED
		if sprite != touched:
			sprite.hold(false)
		_actors[key] = sprite


func _release_actors() -> void:
	for sprite: NpcSprite in _actors.values():
		_screen.story_release(sprite, _created.has(sprite))
	_actors.clear()
	_created.clear()


func _run(steps: Array) -> void:
	for i: int in steps.size():
		if not steps[i] is Dictionary:
			continue
		var step: Dictionary = steps[i]
		await _step(step)
		if step.get("type") == "say" and not _is_choice(steps[i + 1] if i + 1 < steps.size() else null):
			_greeting.close()


## A fala antes de uma escolha fica aberta, como a pergunta dela.
static func _is_choice(step: Variant) -> bool:
	return step is Dictionary and step.get("type") == "choice"


func _step(step: Dictionary) -> void:
	match DictFields.get_string(step, "type"):
		"say":
			_greeting.say(_line(step), _speaker_voice(step))
			await _greeting.tapped
		"choice":
			var options := DictFields.get_array(step, "options")
			var texts: Array[String] = []
			for option: Variant in options:
				texts.append(_text(DictFields.get_string(option as Dictionary, "text")))
			_choices.show_options(texts)
			var index: int = await _choices.chosen
			_greeting.close()
			await _run(DictFields.get_array(options[index] as Dictionary, "steps"))
		"if_mark":
			var mark := DictFields.get_string(step, "mark")
			var on := Story.has_mark(mark) or _set_marks.has(mark)
			await _run(DictFields.get_array(step, "then" if on else "else"))
		"set_mark":
			var mark := DictFields.get_string(step, "mark")
			if not _set_marks.has(mark):
				_set_marks.append(mark)
		"wait":
			await get_tree().create_timer(DictFields.get_float(step, "seconds")).timeout
		"fade":
			var alpha := 1.0 if step.get("to") == "black" else 0.0
			if _waits(step):
				await _fade_to(alpha, DictFields.get_float(step, "seconds"))
			else:
				_fade_to(alpha, DictFields.get_float(step, "seconds"))
		"show", "hide":
			var sprite := _actor(step)
			if sprite != null:
				sprite.visible = step.get("type") == "show"
		"move":
			await _move(step)
		"face":
			_face(step)
		"camera":
			var coord: Vector2i = StoryValidator.coord_of(step)
			var seconds := DictFields.get_float(step, "seconds")
			if _waits(step):
				await _screen.story_camera_to(coord, seconds, DictFields.get_int(step, "zoom"))
			else:
				_screen.story_camera_to(coord, seconds, DictFields.get_int(step, "zoom"))
		"camera_back":
			if _waits(step):
				await _screen.story_camera_back(DictFields.get_float(step, "seconds"))
			else:
				_screen.story_camera_back(DictFields.get_float(step, "seconds"))
		"follow", "unfollow":
			var sprite := _actor(step)
			if sprite != null:
				_screen.story_set_follow(sprite, step.get("type") == "follow")
		"open_screen":
			await _settle()
			await _screen.story_open_screen(StringName(DictFields.get_string(step, "screen")))
		"create_tamer":
			await _settle()
			await _screen.story_create_tamer()
		"choose_starter":
			await _settle()
			await _screen.story_choose_starter()


func _move(step: Dictionary) -> void:
	var target: Vector2i = StoryValidator.coord_of(step)
	var wait := DictFields.get_bool(step, "wait", true)
	if step.get("actor") == TAMER:
		if wait:
			await _screen.story_walk_tamer(target)
		else:
			_screen.story_walk_tamer(target)
		return
	var sprite := _actor(step)
	if sprite == null:
		return
	var result := sprite.walk_to(target)
	if result == NpcSprite.JUMPED:
		push_warning("Cena %s: %s não acha caminho até (%d, %d)." % [_scene.slug, step.get("actor"), target.x, target.y])
	elif result == NpcSprite.WALKING:
		if wait:
			await sprite.arrived
		elif not _moving.has(sprite):
			_moving.append(sprite)


func _face(step: Dictionary) -> void:
	var toward: Variant = step.get("toward")
	var point := Vector2.INF
	var coord: Variant = StoryValidator.coord_of(toward)
	if coord != null:
		point = _screen.story_hex_point(coord)
	elif toward == TAMER:
		point = _screen.story_tamer_point()
	elif toward is String and _actors.has(toward):
		point = _actors[toward].position
	if not point.is_finite():
		return
	if step.get("actor") == TAMER:
		_screen.story_face_tamer(point)
		return
	var sprite := _actor(step)
	if sprite != null and point != sprite.position:
		sprite.face_toward(point - sprite.position)


func _actor(step: Dictionary) -> NpcSprite:
	return _actors.get(DictFields.get_string(step, "actor"), null)


## A narração, o Domador ou o NPC do ator (dialogue-voices/02).
func _speaker_voice(step: Dictionary) -> Dictionary:
	var speaker: Variant = step.get("speaker")
	if speaker == null:
		return GameData.voice_by_slug(NARRATION_VOICE)
	if speaker == TAMER:
		return GameData.voice_by_slug(TAMER_VOICE)
	return GameData.npc_voice(DictFields.get_int(_scene.actor(str(speaker)), "npc_id"))


func _line(step: Dictionary) -> String:
	var text := _text(DictFields.get_string(step, "text"))
	var speaker: Variant = step.get("speaker")
	if speaker == null:
		return text
	var speaker_name := ""
	if speaker == TAMER:
		speaker_name = Session.player.name if Session.player != null else ""
	else:
		speaker_name = str(GameData.get_npc(DictFields.get_int(_scene.actor(str(speaker)), "npc_id")).get("name", ""))
	return "%s: %s" % [speaker_name, text] if not speaker_name.is_empty() else text


func _text(text: String) -> String:
	return StoryText.render(text, Session.player)


func _waits(step: Dictionary) -> bool:
	return DictFields.get_bool(step, "wait", true)


## Um escurecer novo para o anterior e parte da cor em que ele está.
func _fade_to(alpha: float, seconds: float) -> void:
	if _fade_tween != null:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade, ^"color:a", alpha, maxf(seconds, 0.01))
	_fade_tween.finished.connect(_fade_arrived)
	await fade_settled


func _fade_arrived() -> void:
	_fade_tween = null
	fade_settled.emit()


## Espera a câmera e o escurecer que ficaram andando sem esperar (story/07).
func _settle() -> void:
	await _screen.story_camera_idle()
	if _fade_tween != null:
		await fade_settled


## A cena só termina com os Marcos gravados.
func _save() -> void:
	while true:
		var result: Result = await Story.finish(_scene, _set_marks)
		if result.ok:
			return
		_greeting.say(SAVE_ERROR % result.error)
		var retry: Array[String] = [RETRY_TEXT]
		_choices.show_options(retry)
		await _choices.chosen
