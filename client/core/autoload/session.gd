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
## O Santuário, como veio na última leitura: quem o abre chama `load_storage`.
var storage: Array[CreatureInstance] = []

var _service: GameService = ApiGameService.new()
var _auth := AuthService.new()
var _fought_spawn := 0
## Depuração: o modo God, ligado no menu do mapa. Vale para as lutas que começarem
## depois e some ao fechar o jogo; o servidor só aceita com a rota de teste ligada.
var debug_god := false


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


func set_nickname(uid: String, raw_nickname: String) -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.set_nickname(uid, raw_nickname)
	if result.ok:
		# A resposta só traz a equipe: a tela só atualiza depois do Santuário.
		if _storage_has(uid):
			await load_storage()
		_set_player(result.data)
	return result


func heal_team() -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.heal_team()
	if result.ok:
		_set_player(result.data)
	return result


func buy_item(item_id: int) -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.buy_item(item_id)
	if result.ok:
		_set_player(result.data)
	return result


func use_item(item_id: int, creature_uid: String) -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.use_item(item_id, creature_uid)
	if result.ok:
		_set_player(result.data)
	return result


func load_storage() -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.load_storage()
	if result.ok:
		storage = result.data
	return result


func reorder_team(uids: Array[String]) -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.reorder_team(uids)
	if result.ok:
		_set_player(result.data)
	return result


## Sem `replace_uid`, o Ecobeast entra em uma vaga livre.
func bring_to_team(uid: String, replace_uid: String = "") -> Result:
	@warning_ignore("redundant_await")
	return await _apply_team_change(await _service.bring_to_team(uid, replace_uid))


func send_to_storage(uid: String) -> Result:
	@warning_ignore("redundant_await")
	return await _apply_team_change(await _service.send_to_storage(uid))


func reset_progress() -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.reset_progress()
	if result.ok:
		_set_player(null)
	return result


## O mapa não fica aqui: ele só vive enquanto a tela de exploração estiver aberta.
func start_exploration() -> Result:
	@warning_ignore("redundant_await")
	return await _service.start_exploration()


## A batalha não fica aqui: quem a mostra é a tela, e o jogador é relido no fim.
func start_wild_battle(coord: Vector2i) -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.start_wild_battle(coord, debug_god)
	if result.ok:
		_fought_spawn = (result.data as BattleTurn).spawn_id
	return result


## O Ecobeast que saiu do mapa desde a última leitura, ou 0: a tela do mapa, que
## ficou escondida durante a luta, usa isto para tirá-lo de lá.
func take_fought_spawn() -> int:
	var spawn_id := _fought_spawn
	_fought_spawn = 0
	return spawn_id


func battle_action(action: Dictionary) -> Result:
	@warning_ignore("redundant_await")
	return await _service.battle_action(action)


## A luta no tabuleiro (board-battle/04): como a de hoje, a tela guarda a luta.
func start_board_wild_battle(coord: Vector2i) -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.start_board_wild_battle(coord, debug_god)
	if result.ok:
		_fought_spawn = (result.data as BoardTurn).spawn_id
	return result


func start_board_test_battle(enemies: Array[Dictionary], slots: int) -> Result:
	@warning_ignore("redundant_await")
	return await _service.start_board_test_battle(enemies, slots)


func board_action(body: Dictionary) -> Result:
	@warning_ignore("redundant_await")
	return await _service.board_action(body)


func debug_spawn(species_id: int, coord: Vector2i) -> Result:
	@warning_ignore("redundant_await")
	return await _service.debug_spawn(species_id, coord)


func debug_clear_spawns() -> Result:
	@warning_ignore("redundant_await")
	return await _service.debug_clear_spawns()


func debug_almost_level_up() -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.debug_almost_level_up()
	if result.ok:
		_set_player(result.data)
	return result


## O jogador não muda aqui: a tela de batalha o relê no "Voltar".
func evolve(uid: String, accept: bool) -> Result:
	@warning_ignore("redundant_await")
	return await _service.evolve(uid, accept)


func learn_skill(uid: String, skill_id: int, forget_skill_id: int) -> Result:
	@warning_ignore("redundant_await")
	return await _service.learn_skill(uid, skill_id, forget_skill_id)


## O Santuário mudou com a equipe: as telas só atualizam depois de reler os dois.
func _apply_team_change(result: Result) -> Result:
	if not result.ok:
		return result
	var reloaded: Result = await load_storage()
	_set_player(result.data)
	return result if reloaded.ok else reloaded


func _storage_has(uid: String) -> bool:
	return storage.any(func(creature: CreatureInstance) -> bool: return creature.uid == uid)


func _set_player(value: Player) -> void:
	player = value
	if value == null:
		storage = []
	player_changed.emit()
