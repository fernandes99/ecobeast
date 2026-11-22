extends Node
## Autoload Session: o jogador atual e o serviço que o altera
## (.specs/onboarding/architecture.md). Telas falam só com o Session: nunca
## criam serviços nem leem user://. Todo método é chamado com await e devolve
## o Result do serviço.
##
## Os métodos do GameService são @abstract e o Godot não tem como saber que as
## implementações são assíncronas; daí o @warning_ignore("redundant_await").

signal player_changed
signal logged_in

const DISCOVERY_BATCH := 1000
const PING_INTERVAL := 60.0

var player: Player = null
## A ilha casa, onde o jogo abre; 0 sem casa (home-island/02).
var home_island_id: int = 0
var storage: Array[CreatureInstance] = []

var _service: GameService = ApiGameService.new()
var _auth := AuthService.new()
var _fought_spawn := 0
var _fought_tamer := 0
var debug_god := false
## Os hexágonos descobertos de cada ilha que ainda não foram para o servidor
## (fog-of-war/03). Moram aqui porque a tela de exploração some antes do envio.
var _pending_discoveries: Dictionary[int, Array] = {}
var _sending_discoveries := false
## Os hexágonos andados em Explorar por bioma, até o próximo sinal de cada minuto (player-stats/02).
var _pending_hexes: Dictionary[String, int] = {}
var _sending_ping := false
var _ping_timer := Timer.new()
var _app_active := true


func _ready() -> void:
	_ping_timer.wait_time = PING_INTERVAL
	_ping_timer.timeout.connect(send_counters_ping)
	add_child(_ping_timer)


## Ir para o fundo manda o que falta; voltar manda na hora, para o servidor recomeçar a contar dali.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_app_active = false
			if not _ping_timer.is_stopped():
				_ping_timer.stop()
				send_counters_ping()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			_app_active = true
			if player != null and _ping_timer.is_stopped():
				_ping_timer.start()
				send_counters_ping()


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


func set_tamer_name(raw_name: String) -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.set_tamer_name(raw_name)
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


func update_appearance(appearance: TamerAppearance) -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.update_appearance(appearance)
	if result.ok:
		_set_player(result.data)
	return result


func add_story_marks(marks: Array[String]) -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.add_story_marks(marks)
	if result.ok and player != null:
		player.story_marks = result.data
		player_changed.emit()
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


func load_codex() -> Result:
	@warning_ignore("redundant_await")
	return await _service.load_codex()


func load_counters() -> Result:
	@warning_ignore("redundant_await")
	return await _service.load_counters()


func debug_clear_codex() -> Result:
	@warning_ignore("redundant_await")
	return await _service.debug_clear_codex()


func reorder_team(uids: Array[String]) -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.reorder_team(uids)
	if result.ok:
		_set_player(result.data)
	return result


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


func start_exploration(island_id: int = 0) -> Result:
	@warning_ignore("redundant_await")
	return await _service.start_exploration(island_id)


func list_islands() -> Result:
	@warning_ignore("redundant_await")
	return await _service.list_islands()


func load_interior(id: int) -> Result:
	@warning_ignore("redundant_await")
	return await _service.load_interior(id)


## Lê qual ilha publicada é a casa do jogador.
func load_home() -> Result:
	var result := await list_islands()
	if result.ok:
		home_island_id = 0
		for island: IslandSummary in result.data:
			if island.home:
				home_island_id = island.id
	return result


func add_island_discoveries(island_id: int, coords: Array[Vector2i]) -> Result:
	@warning_ignore("redundant_await")
	return await _service.add_island_discoveries(island_id, coords)


func forget_island_discoveries(island_id: int) -> Result:
	_pending_discoveries.erase(island_id)
	@warning_ignore("redundant_await")
	return await _service.forget_island_discoveries(island_id)


func queue_island_discoveries(island_id: int, coords: Array[Vector2i]) -> void:
	if island_id <= 0 or coords.is_empty():
		return
	if not _pending_discoveries.has(island_id):
		_pending_discoveries[island_id] = []
	_pending_discoveries[island_id].append_array(coords)


## Manda os pendentes em lotes, um envio por vez. O que falha volta para a fila, sem aviso.
func send_island_discoveries() -> void:
	if _sending_discoveries:
		return
	_sending_discoveries = true
	while not _pending_discoveries.is_empty():
		var island_id: int = _pending_discoveries.keys()[0]
		var queued: Array = _pending_discoveries[island_id]
		var batch: Array[Vector2i] = []
		batch.assign(queued.slice(0, DISCOVERY_BATCH))
		var rest := queued.slice(DISCOVERY_BATCH)
		if rest.is_empty():
			_pending_discoveries.erase(island_id)
		else:
			_pending_discoveries[island_id] = rest
		@warning_ignore("redundant_await")
		var result: Result = await _service.add_island_discoveries(island_id, batch)
		if not result.ok:
			queue_island_discoveries(island_id, batch)
			break
	_sending_discoveries = false


func count_hex(biome: String, amount: int = 1) -> void:
	_pending_hexes[biome] = _pending_hexes.get(biome, 0) + amount


## O que falha volta para a fila do próximo sinal, sem aviso.
func send_counters_ping() -> void:
	if _sending_ping or player == null:
		return
	_sending_ping = true
	var hexes := _pending_hexes
	_pending_hexes = {}
	@warning_ignore("redundant_await")
	var result: Result = await _service.send_counters_ping(hexes)
	if not result.ok:
		for biome: String in hexes:
			count_hex(biome, hexes[biome])
	_sending_ping = false


func take_fought_spawn() -> int:
	var spawn_id := _fought_spawn
	_fought_spawn = 0
	return spawn_id


func start_board_wild_battle(coord: Vector2i) -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.start_board_wild_battle(coord, debug_god)
	if result.ok:
		_fought_spawn = (result.data as BoardTurn).spawn_id
	return result


func start_board_tamer_battle(coord: Vector2i) -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.start_board_tamer_battle(coord, debug_god)
	if result.ok:
		_fought_tamer = (result.data as BoardTurn).tamer_id
	return result


func take_fought_tamer() -> int:
	var tamer_id := _fought_tamer
	_fought_tamer = 0
	return tamer_id


func start_board_challenge() -> Result:
	@warning_ignore("redundant_await")
	return await _service.start_board_challenge()


func start_board_test_battle(enemies: Array[Dictionary], slots: int) -> Result:
	@warning_ignore("redundant_await")
	return await _service.start_board_test_battle(enemies, slots)


func start_board_skill_test(test: Dictionary) -> Result:
	@warning_ignore("redundant_await")
	return await _service.start_board_skill_test(test)


func board_action(body: Dictionary) -> Result:
	@warning_ignore("redundant_await")
	return await _service.board_action(body)


func debug_spawn(species_id: int, coord: Vector2i) -> Result:
	@warning_ignore("redundant_await")
	return await _service.debug_spawn(species_id, coord)


func debug_clear_spawns() -> Result:
	@warning_ignore("redundant_await")
	return await _service.debug_clear_spawns()


func debug_tamer(coord: Vector2i, size: int) -> Result:
	@warning_ignore("redundant_await")
	return await _service.debug_tamer(coord, size)


func set_exploration_position(coord: Vector2i) -> Result:
	@warning_ignore("redundant_await")
	return await _service.set_exploration_position(coord)


func debug_almost_level_up() -> Result:
	@warning_ignore("redundant_await")
	var result: Result = await _service.debug_almost_level_up()
	if result.ok:
		_set_player(result.data)
	return result


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
		_ping_timer.stop()
		_pending_hexes = {}
	elif _app_active and _ping_timer.is_stopped():
		_ping_timer.start()
		send_counters_ping.call_deferred()
	player_changed.emit()
