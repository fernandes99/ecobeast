class_name ApiGameService
extends GameService

const ME_PATH := "/v1/me"
const NAME_PATH := "/v1/me/name"
const STARTER_PATH := "/v1/me/starter"
const CREATURE_PATH := "/v1/me/creatures/%s"
const APPEARANCE_PATH := "/v1/me/appearance"
const HEAL_PATH := "/v1/me/heal"
const STORY_MARKS_PATH := "/v1/me/story/marks"
const SHOP_BUY_PATH := "/v1/me/shop/buy"
const ITEM_USE_PATH := "/v1/me/items/use"
const STORAGE_PATH := "/v1/me/storage"
const INTERIOR_PATH := "/v1/interiors/%d"
const TEAM_ORDER_PATH := "/v1/me/team/order"
const TEAM_BRING_PATH := "/v1/me/team/bring"
const TEAM_STORE_PATH := "/v1/me/team/store"
const EXPLORATION_PATH := "/v1/me/exploration"
const BOARD_BATTLE_PATH := "/v1/me/board-battle"
const BOARD_WILD_PATH := "/v1/me/board-battle/wild"
const BOARD_TAMER_PATH := "/v1/me/board-battle/tamer"
const BOARD_CHALLENGE_PATH := "/v1/me/board-battle/challenge"
const BOARD_ACTION_PATH := "/v1/me/board-battle/action"
const DEBUG_XP_PATH := "/v1/me/debug/xp"
const DEBUG_SPAWNS_PATH := "/v1/me/exploration/spawns"
const DEBUG_TAMERS_PATH := "/v1/me/exploration/tamers"
const POSITION_PATH := "/v1/me/exploration/position"
const NOT_EDITOR_TELEPORT := "Debug: o teleporte é só para quem está em MAP_EDITOR_USER_IDS."
const ROUTE_NOT_FOUND := "Rota não encontrada."
const CODEX_PATH := "/v1/me/codex"
const ISLANDS_PATH := "/v1/me/islands"
const DISCOVERIES_PATH := "/v1/me/islands/%d/discoveries"
const EVOLUTION_PATH := "/v1/me/creatures/%s/evolution"
const LEARN_SKILL_PATH := "/v1/me/creatures/%s/skills"


func get_player() -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_GET, ME_PATH, null, true))


## Sem nome, o Domador nasce sem nome, e a introdução o nomeia (liora-intro/01).
func create_player(raw_name: String) -> Result:
	var body := {} if raw_name.is_empty() else {"name": raw_name}
	return _player_result(await Api.request(HTTPClient.METHOD_POST, ME_PATH, body, true))


func set_tamer_name(raw_name: String) -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_PUT, NAME_PATH, {"name": raw_name}, true))


func choose_starter(species_id: int) -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_POST, STARTER_PATH, {"species_id": species_id}, true))


func set_nickname(uid: String, raw_nickname: String) -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_PATCH, CREATURE_PATH % uid, {"nickname": raw_nickname}, true))


func update_appearance(appearance: TamerAppearance) -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_PUT, APPEARANCE_PATH, appearance.to_dict(), true))


func heal_team() -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_POST, HEAL_PATH, null, true))


func buy_item(item_id: int) -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_POST, SHOP_BUY_PATH, {"item_id": item_id}, true))


func use_item(item_id: int, creature_uid: String) -> Result:
	var body := {"item_id": item_id, "creature_uid": creature_uid}
	return _player_result(await Api.request(HTTPClient.METHOD_POST, ITEM_USE_PATH, body, true))


func load_storage() -> Result:
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_GET, STORAGE_PATH, null, true)
	if not response.ok:
		return Result.failure(response.error)
	var rows: Variant = response.data.get("creatures") if response.data is Dictionary else null
	if not rows is Array:
		return Result.failure(ApiResponse.SERVER_ERROR)
	var creatures: Array[CreatureInstance] = []
	for row: Variant in rows:
		if row is Dictionary:
			creatures.append(CreatureInstance.from_dict(row))
	return Result.success(creatures)


func reorder_team(uids: Array[String]) -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_POST, TEAM_ORDER_PATH, {"uids": uids}, true))


func bring_to_team(uid: String, replace_uid: String) -> Result:
	var body := {"uid": uid}
	if not replace_uid.is_empty():
		body["replace_uid"] = replace_uid
	return _player_result(await Api.request(HTTPClient.METHOD_POST, TEAM_BRING_PATH, body, true))


func send_to_storage(uid: String) -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_POST, TEAM_STORE_PATH, {"uid": uid}, true))


func reset_progress() -> Result:
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_DELETE, ME_PATH, null, true)
	return Result.success() if response.ok else Result.failure(response.error)


func start_exploration(island_id: int = 0) -> Result:
	var body := {}
	if island_id > 0:
		body["island_id"] = island_id
	# Com a hora de debug mexida, o servidor sorteia os selvagens nela (só com as rotas de teste ligadas).
	if WorldClock.debug_offset_minutes != 0.0:
		body["debug_minute"] = floori(WorldClock.minute_of_day())
	var payload: Variant = null
	if not body.is_empty():
		payload = body
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_POST, EXPLORATION_PATH, payload, true)
	if not response.ok:
		return Result.failure(response.error)
	var map: Variant = response.data.get("map") if response.data is Dictionary else null
	if not map is Dictionary:
		return Result.failure(ApiResponse.SERVER_ERROR)
	var exploration := ExplorationMap.from_dict(map)
	exploration.discovered = _coords(DictFields.get_array(response.data, "discovered"))
	return Result.success(exploration)


func add_island_discoveries(island_id: int, coords: Array[Vector2i]) -> Result:
	var tiles: Array[Dictionary] = []
	for coord: Vector2i in coords:
		tiles.append({"q": coord.x, "r": coord.y})
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_POST, DISCOVERIES_PATH % island_id, {"tiles": tiles}, true)
	if not response.ok:
		return Result.failure(response.error)
	return Result.success(null)


func add_story_marks(marks: Array[String]) -> Result:
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_POST, STORY_MARKS_PATH, {"marks": marks}, true)
	if not response.ok:
		return Result.failure(response.error)
	if not response.data is Dictionary:
		return Result.failure(ApiResponse.SERVER_ERROR)
	var result: Array[String] = []
	for mark: Variant in DictFields.get_array(response.data, "story_marks"):
		if mark is String:
			result.append(mark)
	return Result.success(result)


func forget_island_discoveries(island_id: int) -> Result:
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_DELETE, DISCOVERIES_PATH % island_id, null, true)
	if not response.ok:
		return Result.failure(response.error)
	return Result.success(null)


static func _coords(items: Array) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for item: Variant in items:
		if item is Dictionary and (item.get("q") is int or item.get("q") is float) and (item.get("r") is int or item.get("r") is float):
			coords.append(Vector2i(int(item["q"]), int(item["r"])))
	return coords


func list_islands() -> Result:
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_GET, ISLANDS_PATH, null, true)
	if not response.ok:
		return Result.failure(response.error)
	if not response.data is Dictionary:
		return Result.failure(ApiResponse.SERVER_ERROR)
	var islands: Array[IslandSummary] = []
	for island_dict: Variant in DictFields.get_array(response.data, "islands"):
		var island: IslandSummary = IslandSummary.from_dict(island_dict) if island_dict is Dictionary else null
		if island != null:
			islands.append(island)
	return Result.success(islands)


func start_board_wild_battle(coord: Vector2i, god: bool = false) -> Result:
	var body := {"q": coord.x, "r": coord.y}
	if god:
		body["god"] = true
	return _board_result(await Api.request(HTTPClient.METHOD_POST, BOARD_WILD_PATH, body, true))


func start_board_tamer_battle(coord: Vector2i, god: bool = false) -> Result:
	var body := {"q": coord.x, "r": coord.y}
	if god:
		body["god"] = true
	return _board_result(await Api.request(HTTPClient.METHOD_POST, BOARD_TAMER_PATH, body, true))


func start_board_challenge() -> Result:
	return _board_result(await Api.request(HTTPClient.METHOD_POST, BOARD_CHALLENGE_PATH, null, true))


func start_board_test_battle(enemies: Array[Dictionary], slots: int) -> Result:
	var body := {"enemies": enemies, "slots": slots}
	return _board_result(await Api.request(HTTPClient.METHOD_POST, BOARD_BATTLE_PATH, body, true))


func board_action(body: Dictionary) -> Result:
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_POST, BOARD_ACTION_PATH, body, true)
	# A luta expirou ou o servidor reiniciou: a tela oferece a saída.
	if response.code == HTTPClient.RESPONSE_NOT_FOUND:
		return Result.success(null)
	return _board_result(response)


func set_exploration_position(coord: Vector2i) -> Result:
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_PUT, POSITION_PATH, {"q": coord.x, "r": coord.y}, true)
	if response.code == HTTPClient.RESPONSE_FORBIDDEN or (response.code == HTTPClient.RESPONSE_NOT_FOUND and response.error == ROUTE_NOT_FOUND):
		return Result.failure(NOT_EDITOR_TELEPORT)
	if not response.ok:
		return Result.failure(response.error)
	return Result.success(coord)


func debug_almost_level_up() -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_POST, DEBUG_XP_PATH, null, true))


func debug_spawn(species_id: int, coord: Vector2i) -> Result:
	var body := {"species_id": species_id, "q": coord.x, "r": coord.y}
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_POST, DEBUG_SPAWNS_PATH, body, true)
	if not response.ok:
		return Result.failure(response.error)
	var data: Variant = response.data.get("creature") if response.data is Dictionary else null
	if not data is Dictionary:
		return Result.failure(ApiResponse.SERVER_ERROR)
	var creature := MapCreature.from_dict(data)
	return Result.success(creature) if creature != null else Result.failure(ApiResponse.SERVER_ERROR)


func load_interior(id: int) -> Result:
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_GET, INTERIOR_PATH % id, null, true)
	if not response.ok:
		return Result.failure(response.error)
	var room: Interior = Interior.from_dict(response.data) if response.data is Dictionary else null
	if room == null:
		return Result.failure(ApiResponse.SERVER_ERROR)
	return Result.success(room)


func load_codex() -> Result:
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_GET, CODEX_PATH, null, true)
	if not response.ok:
		return Result.failure(response.error)
	if not response.data is Dictionary:
		return Result.failure(ApiResponse.SERVER_ERROR)
	return Result.success(Codex.from_dict(response.data))


func debug_clear_codex() -> Result:
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_DELETE, CODEX_PATH, null, true)
	if not response.ok:
		return Result.failure(response.error)
	return Result.success(null)


func debug_clear_spawns() -> Result:
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_DELETE, DEBUG_SPAWNS_PATH, null, true)
	if not response.ok:
		return Result.failure(response.error)
	var data: Dictionary = response.data if response.data is Dictionary else {}
	return Result.success({
		"creature_ids": _ids(DictFields.get_array(data, "removed_ids")),
		"tamer_ids": _ids(DictFields.get_array(data, "removed_tamer_ids")),
	})


func debug_tamer(coord: Vector2i, size: int) -> Result:
	var body := {"q": coord.x, "r": coord.y, "size": size}
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_POST, DEBUG_TAMERS_PATH, body, true)
	if not response.ok:
		return Result.failure(response.error)
	var data: Variant = response.data.get("tamer") if response.data is Dictionary else null
	var tamer: MapTamer = MapTamer.from_dict(data) if data is Dictionary else null
	return Result.success(tamer) if tamer != null else Result.failure(ApiResponse.SERVER_ERROR)


func _ids(items: Array) -> Array[int]:
	var ids: Array[int] = []
	for id: Variant in items:
		if id is float or id is int:
			ids.append(int(id))
	return ids


func evolve(uid: String, accept: bool) -> Result:
	var body := {"accept": accept}
	return _choice_result(await Api.request(HTTPClient.METHOD_POST, EVOLUTION_PATH % uid, body, true))


func learn_skill(uid: String, skill_id: int, forget_skill_id: int) -> Result:
	var forget: Variant = null
	if forget_skill_id >= 0:
		forget = forget_skill_id
	var body := {"skill_id": skill_id, "forget_skill_id": forget}
	return _choice_result(await Api.request(HTTPClient.METHOD_POST, LEARN_SKILL_PATH % uid, body, true))


func _choice_result(response: ApiResponse) -> Result:
	if response.code == HTTPClient.RESPONSE_NOT_FOUND:
		return Result.success(null)
	if not response.ok:
		return Result.failure(response.error)
	var choice: ProgressChoice = ProgressChoice.from_dict(response.data) if response.data is Dictionary else null
	return Result.success(choice) if choice != null else Result.failure(ApiResponse.SERVER_ERROR)


func _board_result(response: ApiResponse) -> Result:
	if not response.ok:
		return Result.failure(response.error)
	var turn: BoardTurn = BoardTurn.from_dict(response.data) if response.data is Dictionary else null
	return Result.success(turn) if turn != null else Result.failure(ApiResponse.SERVER_ERROR)


func _player_result(response: ApiResponse) -> Result:
	if not response.ok:
		return Result.failure(response.error)
	if not (response.data is Dictionary and response.data.has("player")):
		return Result.failure(ApiResponse.SERVER_ERROR)
	var player: Variant = response.data["player"]
	return Result.success(Player.from_dict(player) if player is Dictionary else null)
