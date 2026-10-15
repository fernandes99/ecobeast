class_name LocalGameService
extends GameService
## As regras do jogador rodando no cliente, enquanto não há servidor.
## Cada método espera um frame antes de agir, para se comportar como uma
## chamada de rede (e o await de quem chama não ser redundante).
## Todo Player devolvido vem com stats calculado em cada criatura.

const START_LEVEL := 1
const START_COINS := 1000
const STARTER_LEVEL := 5

const INVALID_NAME := "Use de 2 a 16 letras, números ou espaços."
const PLAYER_EXISTS := "Você já tem um Domador."
const NO_PLAYER := "Crie seu Domador primeiro."
const STARTER_TAKEN := "Você já escolheu seu Ecobeast."
const NOT_A_STARTER := "Esse Ecobeast não pode ser escolhido."

var _repository: PlayerRepository
var _catalog: Catalog


func _init(repository: PlayerRepository, catalog: Catalog) -> void:
	_repository = repository
	_catalog = catalog


func get_player() -> Result:
	await _network_delay()
	return _with_stats(_repository.load_player())


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
	return _with_stats(_repository.save_player(player))


func choose_starter(species_id: int) -> Result:
	await _network_delay()
	var loaded := _repository.load_player()
	if not loaded.ok:
		return loaded
	var player: Player = loaded.data
	if player == null:
		return Result.failure(NO_PLAYER)
	if player.has_starter():
		return Result.failure(STARTER_TAKEN)
	if not _is_starter(species_id):
		return Result.failure(NOT_A_STARTER)

	player.party.append(CreatureFactory.create(_creation_params(species_id, STARTER_LEVEL, player.id)))
	return _with_stats(_repository.save_player(player))


func reset_progress() -> Result:
	await _network_delay()
	return _repository.clear_player()


func _is_starter(species_id: int) -> bool:
	for species: CreatureSpecies in _catalog.get_starters():
		if species.id == species_id:
			return true
	return false


## Os parâmetros do CreatureFactory, tirados do catálogo.
func _creation_params(species_id: int, level: int, owner_id: String) -> Dictionary:
	var species := _catalog.get_species(species_id)
	var learnset := _catalog.get_learnset(species_id)
	var max_pp_by_skill: Dictionary = {}
	for entry: LearnsetEntry in learnset:
		max_pp_by_skill[entry.skill_id] = _catalog.get_skill(entry.skill_id).max_pp
	var trait_ids: Array[int] = []
	for row: Dictionary in _catalog.get_species_traits(species_id):
		if not row["is_hidden"]:
			trait_ids.append(row["trait_id"])
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return {
		"species": species,
		"level": level,
		"uid": Uuid.v4(),
		"owner_id": owner_id,
		"now": _now(),
		"learnset": learnset,
		"max_pp_by_skill": max_pp_by_skill,
		"trait_ids": trait_ids,
		"temperaments": _catalog.get_temperaments(),
		"xp_multiplier": _catalog.get_growth_rate(species.growth_rate_id).xp_multiplier,
		"rng": rng,
	}


## Preenche stats nas criaturas do Player de um Result de sucesso.
## (No futuro, o servidor manda stats pronto.)
func _with_stats(result: Result) -> Result:
	if result.ok and result.data is Player:
		var player: Player = result.data
		for creature: CreatureInstance in player.party:
			var species := _catalog.get_species(creature.species_id)
			var temperament := _catalog.get_temperament(creature.temperament_id)
			creature.stats = StatCalculator.calculate(species.base_stats, creature.genes,
					creature.training_points, creature.level, temperament)
	return result


func _network_delay() -> void:
	await (Engine.get_main_loop() as SceneTree).process_frame


## Agora, em ISO 8601 UTC (ex.: "2026-10-14T12:00:00Z").
func _now() -> String:
	return Time.get_datetime_string_from_system(true) + "Z"
