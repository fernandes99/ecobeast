class_name StoryValidator
extends RefCounted

## Confere as cenas da história (story/02). Cada erro começa com "Cena <slug>:" e diz o
## caminho do passo, com os blocos separados por ponto ("passo 5.2.1").

const SLUG_PATTERN := "^[a-z0-9_]{1,48}$"
const KEY_PATTERN := "^[a-z0-9_]{1,24}$"
const TRIGGERS: Array[String] = ["auto", "npc", "area", "quest"]
const MAX_TEXT := 300
const MIN_SECONDS := 0.1
const MAX_SECONDS := 10.0
const MAX_DEPTH := 8
const MIN_OPTIONS := 2
const MAX_OPTIONS := 4
const TAMER := "tamer"
const SCREENS: Array[String] = ["appearance", "heal_station", "shop", "team", "bag", "codex"]
## O que o campo `actor` de cada passo aceita: "" (não tem), só ator, ou ator e Domador.
const STEPS: Dictionary[String, String] = {
	"say": "", "choice": "", "if_mark": "", "set_mark": "", "wait": "", "fade": "",
	"show": "actor", "hide": "actor", "move": "actor_or_tamer", "face": "actor_or_tamer",
	"camera": "", "camera_back": "", "follow": "actor", "unfollow": "actor", "open_screen": "",
	"create_tamer": "", "choose_starter": "",
}
## Os passos da introdução (liora-intro/03), que só valem na ilha casa.
const HOME_STEPS: Array[String] = ["create_tamer", "choose_starter"]
const HOME_ONLY := "só vale em cenas da ilha casa."

static var _slug_regex := RegEx.create_from_string(SLUG_PATTERN)
static var _key_regex := RegEx.create_from_string(KEY_PATTERN)


static func has_npc(id: int) -> bool:
	for row: Dictionary in GameData.get_rows("npcs"):
		if int(row.get("id", 0)) == id:
			return true
	return false


static func is_mark(value: Variant) -> bool:
	return value is String and _slug_regex.search(value) != null


static func validate(scenes: Array[StoryScene], file_names: Array[String]) -> Array[String]:
	var errors: Array[String] = []
	var seen: Dictionary[String, bool] = {}
	for index: int in scenes.size():
		var scene := scenes[index]
		var file := file_names[index] if index < file_names.size() else ""
		var label := scene.slug if not scene.slug.is_empty() else file
		var add := func(message: String) -> void: errors.append("Cena %s: %s" % [label, message])
		if _slug_regex.search(scene.slug) == null:
			add.call("o slug \"%s\" tem caracteres inválidos." % scene.slug)
		elif seen.has(scene.slug):
			add.call("o slug se repete em outra cena.")
		seen[scene.slug] = true
		if not file.is_empty() and file.get_basename() != scene.slug:
			add.call("o arquivo se chama %s, e o slug é %s." % [file, scene.slug])
		check_scene(scene, add)
	return errors


static func check_scene(scene: StoryScene, add: Callable) -> void:
	if scene.name.strip_edges().is_empty():
		add.call("falta o nome.")
	if scene.island_id <= 0:
		add.call("falta a ilha.")
	for mark: String in scene.requires + scene.forbids:
		if not is_mark(mark):
			add.call("o Marco \"%s\" tem caracteres inválidos." % mark)
	for mark: String in scene.requires:
		if scene.forbids.has(mark):
			add.call("exige e proíbe o Marco %s." % mark)
	_check_trigger(scene.trigger, add)
	var keys: Dictionary[String, bool] = {}
	for actor: Dictionary in scene.actors:
		var key := str(actor.get("key", ""))
		if _key_regex.search(key) == null or key == TAMER:
			add.call("o ator \"%s\" tem uma key inválida." % key)
		elif keys.has(key):
			add.call("o ator %s se repete." % key)
		keys[key] = true
		if not has_npc(DictFields.get_int(actor, "npc_id")):
			add.call("o ator %s usa um NPC que não existe." % key)
		var on_island := DictFields.get_bool(actor, "island_npc")
		var has_coord := coord_of(actor) != null
		if on_island == has_coord:
			add.call("o ator %s precisa de um hexágono ou de \"Da ilha\", só um dos dois." % key)
	_check_steps(scene.steps, "", 1, keys, add)


static func _check_trigger(trigger: Dictionary, add: Callable) -> void:
	var type := DictFields.get_string(trigger, "type")
	if not TRIGGERS.has(type):
		add.call("o gatilho \"%s\" não existe." % type)
	elif type == "npc" and not has_npc(DictFields.get_int(trigger, "npc_id")):
		add.call("o gatilho usa um NPC que não existe.")
	elif type == "area":
		var tiles := DictFields.get_array(trigger, "tiles")
		if tiles.is_empty():
			add.call("o gatilho de área não tem hexágonos.")
		var seen: Dictionary[Vector2i, bool] = {}
		for tile: Variant in tiles:
			var coord: Variant = coord_of(tile)
			if coord == null:
				add.call("o gatilho de área tem um hexágono inválido.")
			elif seen.has(coord):
				add.call("o gatilho de área repete o hexágono (%d, %d)." % [coord.x, coord.y])
			else:
				seen[coord] = true


static func _check_steps(steps: Variant, prefix: String, depth: int, keys: Dictionary[String, bool], add: Callable) -> void:
	if not steps is Array:
		add.call("%s não é uma lista de passos." % ("os passos" if prefix.is_empty() else "o bloco %s" % prefix))
		return
	if depth > MAX_DEPTH:
		add.call("o passo %s passa de %d níveis de blocos." % [prefix, MAX_DEPTH])
		return
	var list: Array = steps
	for index: int in list.size():
		var path := str(index + 1) if prefix.is_empty() else "%s.%d" % [prefix, index + 1]
		var step: Variant = list[index]
		if not step is Dictionary:
			add.call("passo %s: não é um passo." % path)
			continue
		_check_step(step, path, depth, keys, add)


static func _check_step(step: Dictionary, path: String, depth: int, keys: Dictionary[String, bool], add: Callable) -> void:
	var type := DictFields.get_string(step, "type")
	var fail := func(message: String) -> void: add.call("passo %s: %s" % [path, message])
	if not STEPS.has(type):
		fail.call("o tipo \"%s\" não existe." % type)
		return
	match STEPS[type]:
		"actor":
			_check_actor(step, keys, false, fail)
		"actor_or_tamer":
			_check_actor(step, keys, true, fail)
	match type:
		"say":
			var speaker: Variant = step.get("speaker")
			if not step.has("speaker") or not (speaker == null or speaker == TAMER or (speaker is String and keys.has(speaker))):
				fail.call("quem fala precisa ser a narração, o Domador ou um ator.")
			_check_text(step.get("text"), fail)
		"choice":
			var options := DictFields.get_array(step, "options")
			if options.size() < MIN_OPTIONS or options.size() > MAX_OPTIONS:
				fail.call("a escolha precisa de %d a %d opções." % [MIN_OPTIONS, MAX_OPTIONS])
			for index: int in options.size():
				var option: Variant = options[index]
				if not option is Dictionary:
					fail.call("a opção %d não é uma opção." % (index + 1))
					continue
				var d: Dictionary = option
				_check_text(d.get("text"), fail)
				_check_steps(d.get("steps", []), "%s.%d" % [path, index + 1], depth + 1, keys, add)
		"if_mark":
			_check_mark(step.get("mark"), fail)
			_check_steps(step.get("then", []), "%s.1" % path, depth + 1, keys, add)
			if step.has("else"):
				_check_steps(step.get("else"), "%s.2" % path, depth + 1, keys, add)
		"set_mark":
			_check_mark(step.get("mark"), fail)
		"wait":
			_check_seconds(step, fail)
		"camera_back":
			_check_seconds(step, fail)
			_check_wait(step, fail)
		"fade":
			_check_seconds(step, fail)
			_check_wait(step, fail)
			if not ["black", "clear"].has(step.get("to")):
				fail.call("o escurecer vai para \"black\" ou \"clear\".")
		"move":
			if coord_of(step) == null:
				fail.call("falta o hexágono de destino.")
			_check_wait(step, fail)
		"face":
			var toward: Variant = step.get("toward")
			if not (coord_of(toward) != null or toward == TAMER or (toward is String and keys.has(toward))):
				fail.call("falta para onde virar: um hexágono, o Domador ou um ator.")
		"camera":
			_check_seconds(step, fail)
			_check_wait(step, fail)
			if coord_of(step) == null:
				fail.call("falta o hexágono da câmera.")
			if step.has("zoom") and not _is_zoom(step.get("zoom")):
				fail.call("o zoom vai de %d a %d." % [HexMapView.MIN_ZOOM, HexMapView.STORY_MAX_ZOOM])
		"open_screen":
			if not SCREENS.has(step.get("screen")):
				fail.call("a tela \"%s\" não existe." % str(step.get("screen")))


static func _check_wait(step: Dictionary, fail: Callable) -> void:
	if step.has("wait") and not step.get("wait") is bool:
		fail.call("o \"esperar\" precisa ser sim ou não.")


## O JSON lê todo número como float; 3.0 vale, 3.5 não.
static func _is_zoom(value: Variant) -> bool:
	if not (value is int or value is float) or float(value) != floorf(float(value)):
		return false
	return int(value) >= HexMapView.MIN_ZOOM and int(value) <= HexMapView.STORY_MAX_ZOOM


static func _check_actor(step: Dictionary, keys: Dictionary[String, bool], tamer_ok: bool, fail: Callable) -> void:
	var actor: Variant = step.get("actor")
	if actor is String and (keys.has(actor) or (tamer_ok and actor == TAMER)):
		return
	fail.call("o ator \"%s\" não está na cena." % str(actor))


static func _check_text(text: Variant, fail: Callable) -> void:
	if not text is String or (text as String).strip_edges().is_empty():
		fail.call("falta o texto.")
	elif (text as String).length() > MAX_TEXT:
		fail.call("o texto passa de %d caracteres." % MAX_TEXT)
	else:
		var error := StoryText.check(text)
		if not error.is_empty():
			fail.call(error)


## Os erros dos passos da introdução numa cena fora da ilha casa (liora-intro/03). A casa
## é do servidor: isto roda ao tocar a cena e no F2, e não no `load_scenes()`.
static func home_errors(scene: StoryScene, home_island_id: int) -> Array[String]:
	var errors: Array[String] = []
	if home_island_id > 0 and scene.island_id == home_island_id:
		return errors
	_home_steps(scene.steps, "", errors, scene.slug)
	return errors


static func _home_steps(steps: Variant, prefix: String, errors: Array[String], slug: String) -> void:
	if not steps is Array:
		return
	var list: Array = steps
	for index: int in list.size():
		var step: Variant = list[index]
		if not step is Dictionary:
			continue
		var d: Dictionary = step
		var path := "%s%d" % [prefix, index + 1]
		var type := DictFields.get_string(d, "type")
		if HOME_STEPS.has(type):
			errors.append("Cena %s: passo %s: %s" % [slug, path, HOME_ONLY])
		elif type == "choice":
			var options := DictFields.get_array(d, "options")
			for option_index: int in options.size():
				if options[option_index] is Dictionary:
					_home_steps((options[option_index] as Dictionary).get("steps", []), "%s.%d." % [path, option_index + 1], errors, slug)
		elif type == "if_mark":
			_home_steps(d.get("then", []), "%s.1." % path, errors, slug)
			_home_steps(d.get("else", []), "%s.2." % path, errors, slug)


static func _check_mark(mark: Variant, fail: Callable) -> void:
	if not is_mark(mark):
		fail.call("o Marco \"%s\" tem caracteres inválidos." % str(mark))


static func _check_seconds(step: Dictionary, fail: Callable) -> void:
	var seconds: Variant = step.get("seconds")
	if not (seconds is int or seconds is float) or float(seconds) < MIN_SECONDS or float(seconds) > MAX_SECONDS:
		fail.call("o tempo precisa ficar entre 0,1 e 10 segundos.")


## `{q, r}` inteiros como `Vector2i`, ou null.
static func coord_of(value: Variant) -> Variant:
	if not value is Dictionary:
		return null
	var d: Dictionary = value
	if not (_is_int(d.get("q")) and _is_int(d.get("r"))):
		return null
	return Vector2i(int(d["q"]), int(d["r"]))


static func _is_int(value: Variant) -> bool:
	return value is int or (value is float and is_equal_approx(value, roundf(value)))


## Cada passo, entrando nos blocos, na ordem em que aparece.
static func each_step(steps: Variant, visit: Callable) -> void:
	if not steps is Array:
		return
	for step: Variant in steps:
		if not step is Dictionary:
			continue
		var d: Dictionary = step
		visit.call(d)
		match DictFields.get_string(d, "type"):
			"choice":
				for option: Variant in DictFields.get_array(d, "options"):
					if option is Dictionary:
						each_step((option as Dictionary).get("steps", []), visit)
			"if_mark":
				each_step(d.get("then", []), visit)
				each_step(d.get("else", []), visit)


## Os Marcos que a cena liga ao terminar, por qualquer caminho dela.
static func marks_set_by(scene: StoryScene) -> Array[String]:
	var result: Array[String] = []
	if not scene.repeatable:
		result.append(scene.slug)
	each_step(scene.steps, func(step: Dictionary) -> void:
		if DictFields.get_string(step, "type") == "set_mark":
			var mark := DictFields.get_string(step, "mark")
			if not mark.is_empty() and not result.has(mark):
				result.append(mark))
	return result
