extends Node

## As cenas da história e os Marcos do jogador (story/02). As cenas moram no jogo; o
## servidor só guarda os Marcos.

var library := StoryLibrary.new()
var _test_scene: StoryScene = null
var _test_marks: Array[String] = []
## As cenas `auto` repetíveis que já tocaram nesta entrada na ilha (liora-intro/03).
var _auto_played: Dictionary[String, bool] = {}


func load_scenes() -> Array[String]:
	return library.load_all()


func marks() -> Array[String]:
	if _test_scene != null:
		return _test_marks
	if Session.player == null:
		return []
	return Session.player.story_marks


func has_mark(mark: String) -> bool:
	return marks().has(mark)


func can_run(scene: StoryScene, island_id: int) -> bool:
	if scene.island_id != island_id:
		return false
	var have := marks()
	if not scene.repeatable and have.has(scene.slug):
		return false
	for mark: String in scene.requires:
		if not have.has(mark):
			return false
	for mark: String in scene.forbids:
		if have.has(mark):
			return false
	return true


## Uma `auto` repetível roda uma vez por entrada: o fim de toda cena procura outra `auto`,
## e ela voltaria logo depois de si mesma.
func scene_for_auto(island_id: int) -> StoryScene:
	return _best(island_id, func(trigger: Dictionary) -> bool: return DictFields.get_string(trigger, "type") == "auto", true)


func begin_entry() -> void:
	_auto_played.clear()


func note_auto_played(scene: StoryScene) -> void:
	if scene.repeatable:
		_auto_played[scene.slug] = true


func scene_for_npc(island_id: int, npc_id: int) -> StoryScene:
	return _best(island_id, func(trigger: Dictionary) -> bool:
		return DictFields.get_string(trigger, "type") == "npc" and DictFields.get_int(trigger, "npc_id") == npc_id)


func scene_for_tile(island_id: int, coord: Vector2i) -> StoryScene:
	return _best(island_id, func(trigger: Dictionary) -> bool:
		if DictFields.get_string(trigger, "type") != "area":
			return false
		for tile: Variant in DictFields.get_array(trigger, "tiles"):
			if StoryValidator.coord_of(tile) == coord:
				return true
		return false)


## Grava os Marcos que a cena ligou; sem nenhum novo, nem chama o servidor.
func finish(scene: StoryScene, set_marks: Array[String]) -> Result:
	var have := marks()
	var fresh: Array[String] = []
	var candidates: Array[String] = []
	if not scene.repeatable:
		candidates.append(scene.slug)
	candidates.append_array(set_marks)
	for mark: String in candidates:
		if not have.has(mark) and not fresh.has(mark):
			fresh.append(mark)
	if _test_scene != null:
		_test_marks.append_array(fresh)
		return Result.success(_test_marks)
	if fresh.is_empty():
		return Result.success(have)
	return await Session.add_story_marks(fresh)


func is_testing() -> bool:
	return _test_scene != null


func test_scene() -> StoryScene:
	return _test_scene


## No teste, os Marcos são só estes, nada vai ao servidor e nenhum gatilho procura cena.
func begin_test(scene: StoryScene, test_marks: Array[String]) -> void:
	_test_scene = scene
	_test_marks = test_marks.duplicate()


func end_test() -> void:
	_test_scene = null
	_test_marks = []


## Troca a cena na biblioteca, sem reabrir o jogo (story/04).
func replace_scene(scene: StoryScene) -> void:
	library.replace(scene)


func remove_scene(slug: String) -> void:
	library.remove(slug)


## Os Marcos que alguma cena liga ou pede, em ordem alfabética.
func used_marks() -> Array[String]:
	var result: Array[String] = []
	for scene: StoryScene in library.scenes:
		var marks_of: Array[String] = StoryValidator.marks_set_by(scene)
		marks_of.append_array(scene.requires)
		marks_of.append_array(scene.forbids)
		for mark: String in marks_of:
			if not result.has(mark):
				result.append(mark)
	result.sort()
	return result


func _best(island_id: int, matches: Callable, once_per_entry: bool = false) -> StoryScene:
	if _test_scene != null or island_id <= 0:
		return null
	var best: StoryScene = null
	for scene: StoryScene in library.scenes:
		if not matches.call(scene.trigger) or not can_run(scene, island_id):
			continue
		if once_per_entry and _auto_played.has(scene.slug):
			continue
		if best == null or scene.priority > best.priority or (scene.priority == best.priority and scene.slug < best.slug):
			best = scene
	return best
