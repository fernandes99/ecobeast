class_name LocalPlayerRepository
extends PlayerRepository
## Guarda o jogador em user://save.json (.specs/onboarding/architecture.md,
## "Save local"). No Windows: %APPDATA%\Godot\app_userdata\Ecobeast\.

const SCHEMA_VERSION := 1
const SAVE_PATH := "user://save.json"
## Grava aqui e renomeia, para um fechamento no meio da escrita não corromper o save.
const TEMP_PATH := "user://save.tmp.json"
## Save ilegível é movido para cá, para investigar, e o jogo começa do zero.
const CORRUPTED_PATH := "user://save.corrupted.json"

const LOAD_ERROR := "Não foi possível carregar seu progresso."
const SAVE_ERROR := "Não foi possível salvar. Tente de novo."
const CLEAR_ERROR := "Não foi possível apagar o progresso."


func load_player() -> Result:
	if not FileAccess.file_exists(SAVE_PATH):
		return Result.success(null)
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return Result.failure(LOAD_ERROR)
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var problem := ""
	if json.parse(text) != OK:
		problem = "JSON inválido na linha %d: %s" % [json.get_error_line() + 1, json.get_error_message()]
	elif not json.data is Dictionary:
		problem = "o conteúdo não é um objeto"
	else:
		var save: Dictionary = json.data
		if DictFields.get_int(save, "schema_version", -1) != SCHEMA_VERSION:
			problem = "schema_version diferente de %d" % SCHEMA_VERSION
		elif DictFields.get_dict(save, "player").is_empty():
			problem = "sem 'player'"
		else:
			return Result.success(Player.from_dict(save["player"]))

	_quarantine(problem)
	return Result.success(null)


func save_player(player: Player) -> Result:
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		return Result.failure(SAVE_ERROR)
	var save := {"schema_version": SCHEMA_VERSION, "player": player.to_dict()}
	var written := file.store_string(JSON.stringify(save, "\t", false))
	file.close()
	if not written or DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH) != OK:
		return Result.failure(SAVE_ERROR)
	return Result.success(player)


func clear_player() -> Result:
	if FileAccess.file_exists(SAVE_PATH) and DirAccess.remove_absolute(SAVE_PATH) != OK:
		return Result.failure(CLEAR_ERROR)
	return Result.success(null)


func _quarantine(problem: String) -> void:
	push_warning("Save ilegível (%s); movido para %s e o jogo começa do zero." % [problem, CORRUPTED_PATH])
	if FileAccess.file_exists(CORRUPTED_PATH):
		DirAccess.remove_absolute(CORRUPTED_PATH)
	DirAccess.rename_absolute(SAVE_PATH, CORRUPTED_PATH)
