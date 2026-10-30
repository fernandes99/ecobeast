extends Node
## Autoload Session: o jogador atual e o serviço que o altera
## (.specs/onboarding/architecture.md). Telas falam só com o Session: nunca
## criam serviços nem leem user://. Todo método é chamado com await e devolve
## o Result do serviço.
##
## Os métodos do GameService são @abstract e o Godot não tem como saber que as
## implementações são assíncronas; daí o @warning_ignore("redundant_await").

signal player_changed
## O login terminou: a cena raiz carrega o jogador e abre a primeira tela.
signal logged_in

## O último Player recebido do serviço, ou null se ainda não existe.
var player: Player = null

var _service: GameService
var _auth := AuthService.new()


func _ready() -> void:
	_service = LocalGameService.new(LocalPlayerRepository.new(), GameData.catalog)


func has_auth_session() -> bool:
	return Api.session != null


func login() -> Result:
	var result: Result = await _auth.login()
	if result.ok:
		logged_in.emit()
	return result


func cancel_login() -> void:
	_auth.cancel()


func logout() -> Result:
	var result: Result = await _auth.logout()
	_set_player(null)
	return result


func load_player() -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.get_player()
	if result.ok:
		_set_player(result.data)
	return result


func create_player(raw_name: String) -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.create_player(raw_name)
	if result.ok:
		_set_player(result.data)
	return result


func choose_starter(species_id: int) -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.choose_starter(species_id)
	if result.ok:
		_set_player(result.data)
	return result


func reset_progress() -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.reset_progress()
	if result.ok:
		_set_player(null)
	return result


func _set_player(value: Player) -> void:
	player = value
	player_changed.emit()
