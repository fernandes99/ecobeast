class_name LocalGameService
extends GameService
## As regras do jogador rodando no cliente, enquanto não há servidor.
## Cada método espera um frame antes de agir, para se comportar como uma
## chamada de rede (e o await de quem chama não ser redundante).

const START_LEVEL := 1
const START_COINS := 1000

const INVALID_NAME := "Use de 2 a 16 letras, números ou espaços."
const PLAYER_EXISTS := "Você já tem um Domador."

var _repository: PlayerRepository
var _catalog: Catalog


func _init(repository: PlayerRepository, catalog: Catalog) -> void:
	_repository = repository
	_catalog = catalog


func get_player() -> Result:
	await _network_delay()
	return _repository.load_player()


func create_player(raw_name: String) -> Result:
	await _network_delay()
	var player_name := Player.normalize_name(raw_name)
	if not Player.is_valid_name(player_name):
		return Result.failure(INVALID_NAME)
	var existing := _repository.load_player()
	if not existing.ok:
		return existing
	if existing.data != null:
		return Result.failure(PLAYER_EXISTS)

	var player := Player.new()
	player.id = Uuid.v4()
	player.name = player_name
	player.level = START_LEVEL
	player.coins = START_COINS
	player.created_at = _now()
	return _repository.save_player(player)


## Implementado em onboarding/02.
func choose_starter(_species_id: int) -> Result:
	await _network_delay()
	return Result.failure("Ainda não disponível.")


func reset_progress() -> Result:
	await _network_delay()
	return _repository.clear_player()


func _network_delay() -> void:
	await (Engine.get_main_loop() as SceneTree).process_frame


## Agora, em ISO 8601 UTC (ex.: "2026-10-14T12:00:00Z").
func _now() -> String:
	return Time.get_datetime_string_from_system(true) + "Z"
