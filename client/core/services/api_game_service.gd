class_name ApiGameService
extends GameService
## As ações do jogador pelas rotas do servidor (.specs/auth-google/05-client-player.md).
## Quem decide as regras é o servidor, que manda os stats prontos em cada criatura.

const ME_PATH := "/v1/me"
const STARTER_PATH := "/v1/me/starter"


func get_player() -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_GET, ME_PATH, null, true))


func create_player(raw_name: String) -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_POST, ME_PATH, {"name": raw_name}, true))


func choose_starter(species_id: int) -> Result:
	return _player_result(await Api.request(HTTPClient.METHOD_POST, STARTER_PATH, {"species_id": species_id}, true))


func reset_progress() -> Result:
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_DELETE, ME_PATH, null, true)
	return Result.success() if response.ok else Result.failure(response.error)


## data: o Player da resposta, ou null se a conta ainda não tem Domador.
func _player_result(response: ApiResponse) -> Result:
	if not response.ok:
		return Result.failure(response.error)
	if not (response.data is Dictionary and response.data.has("player")):
		return Result.failure(ApiResponse.SERVER_ERROR)
	var player: Variant = response.data["player"]
	return Result.success(Player.from_dict(player) if player is Dictionary else null)
