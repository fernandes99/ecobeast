class_name ApiGameService
extends GameService
## As ações do jogador pelas rotas do servidor (.specs/auth-google/05-client-player.md).
## Quem decide as regras é o servidor, que manda os stats prontos em cada criatura.

const ME_PATH := "/v1/me"
const STARTER_PATH := "/v1/me/starter"
const CREATURE_PATH := "/v1/me/creatures/%s"
const HEAL_PATH := "/v1/me/heal"
const SHOP_BUY_PATH := "/v1/me/shop/buy"
const ITEM_USE_PATH := "/v1/me/items/use"
const STORAGE_PATH := "/v1/me/storage"
const TEAM_ORDER_PATH := "/v1/me/team/order"
const TEAM_BRING_PATH := "/v1/me/team/bring"
const TEAM_STORE_PATH := "/v1/me/team/store"
const EXPLORATION_PATH := "/v1/me/exploration"
const WILD_BATTLE_PATH := "/v1/me/battle/wild"
const BATTLE_ACTION_PATH := "/v1/me/battle/action"


func get_player() -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_GET, ME_PATH, null, true))


func create_player(raw_name: String) -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_POST, ME_PATH, {"name": raw_name}, true))


func choose_starter(species_id: int) -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_POST, STARTER_PATH, {"species_id": species_id}, true))


func set_nickname(uid: String, raw_nickname: String) -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_PATCH, CREATURE_PATH % uid, {"nickname": raw_nickname}, true))


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


func start_exploration() -> Result:
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_POST, EXPLORATION_PATH, null, true)
	if not response.ok:
		return Result.failure(response.error)
	var map: Variant = response.data.get("map") if response.data is Dictionary else null
	return Result.success(ExplorationMap.from_dict(map)) if map is Dictionary else Result.failure(ApiResponse.SERVER_ERROR)


func start_wild_battle(coord: Vector2i) -> Result:
	var body := {"q": coord.x, "r": coord.y}
	return _turn_result(await Api.request(HTTPClient.METHOD_POST, WILD_BATTLE_PATH, body, true))


func battle_action(action: Dictionary) -> Result:
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_POST, BATTLE_ACTION_PATH, action, true)
	# A batalha expirou ou o servidor reiniciou: a tela oferece a saída.
	if response.code == HTTPClient.RESPONSE_NOT_FOUND:
		return Result.success(null)
	return _turn_result(response)


## data: o BattleTurn da resposta.
func _turn_result(response: ApiResponse) -> Result:
	if not response.ok:
		return Result.failure(response.error)
	var turn: BattleTurn = BattleTurn.from_dict(response.data) if response.data is Dictionary else null
	return Result.success(turn) if turn != null else Result.failure(ApiResponse.SERVER_ERROR)


## data: o Player da resposta, ou null se a conta ainda não tem Domador.
func _player_result(response: ApiResponse) -> Result:
	if not response.ok:
		return Result.failure(response.error)
	if not (response.data is Dictionary and response.data.has("player")):
		return Result.failure(ApiResponse.SERVER_ERROR)
	var player: Variant = response.data["player"]
	return Result.success(Player.from_dict(player) if player is Dictionary else null)
