class_name ApiGameService
extends GameService
## As ações do jogador pelas rotas do servidor (.specs/auth-google/05-client-player.md).
## Quem decide as regras é o servidor, que manda os stats prontos em cada criatura.

const ME_PATH := "/v1/me"
const STARTER_PATH := "/v1/me/starter"
const CREATURE_PATH := "/v1/me/creatures/%s"
const HEAL_PATH := "/v1/me/heal"
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


func reset_progress() -> Result:
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_DELETE, ME_PATH, null, true)
	return Result.success() if response.ok else Result.failure(response.error)


func start_exploration() -> Result:
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_POST, EXPLORATION_PATH, null, true)
	if not response.ok:
		return Result.failure(response.error)
	var map: Variant = response.data.get("map") if response.data is Dictionary else null
	return Result.success(ExplorationMap.from_dict(map)) if map is Dictionary else Result.failure(ApiResponse.SERVER_ERROR)


func start_wild_battle() -> Result:
	return _turn_result(await Api.request(HTTPClient.METHOD_POST, WILD_BATTLE_PATH, null, true))


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
