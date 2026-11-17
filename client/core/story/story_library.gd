class_name StoryLibrary
extends RefCounted

## As cenas da história lidas da pasta do jogo (story/02).

const SCENES_DIR := "res://story/scenes/"

var scenes: Array[StoryScene] = []
var file_names: Array[String] = []


func load_all() -> Array[String]:
	scenes.clear()
	file_names.clear()
	var errors: Array[String] = []
	var files := Array(DirAccess.get_files_at(SCENES_DIR))
	files.sort()
	for file: String in files:
		if file.get_extension() != "json":
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCENES_DIR + file))
		if not parsed is Dictionary:
			errors.append("Cena %s: o arquivo não é um JSON válido." % file)
			continue
		scenes.append(StoryScene.from_dict(parsed))
		file_names.append(file)
	errors.append_array(StoryValidator.validate(scenes, file_names))
	return errors


func for_island(island_id: int) -> Array[StoryScene]:
	var result: Array[StoryScene] = []
	for scene: StoryScene in scenes:
		if scene.island_id == island_id:
			result.append(scene)
	result.sort_custom(func(a: StoryScene, b: StoryScene) -> bool: return a.slug < b.slug)
	return result


func find(slug: String) -> StoryScene:
	for scene: StoryScene in scenes:
		if scene.slug == slug:
			return scene
	return null


func replace(scene: StoryScene) -> void:
	for index: int in scenes.size():
		if scenes[index].slug == scene.slug:
			scenes[index] = scene
			return
	scenes.append(scene)
	file_names.append(scene.slug + ".json")


func remove(slug: String) -> void:
	for index: int in scenes.size():
		if scenes[index].slug == slug:
			scenes.remove_at(index)
			file_names.remove_at(index)
			return
