@abstract
class_name GameService
extends RefCounted


@abstract func get_player() -> Result


@abstract func create_player(raw_name: String) -> Result


@abstract func set_tamer_name(raw_name: String) -> Result


@abstract func choose_starter(species_id: int) -> Result


@abstract func set_nickname(uid: String, raw_nickname: String) -> Result


@abstract func update_appearance(appearance: TamerAppearance) -> Result


@abstract func heal_team() -> Result


@abstract func buy_item(item_id: int) -> Result


@abstract func use_item(item_id: int, creature_uid: String) -> Result


@abstract func load_storage() -> Result


@abstract func reorder_team(uids: Array[String]) -> Result


@abstract func bring_to_team(uid: String, replace_uid: String) -> Result


@abstract func send_to_storage(uid: String) -> Result


@abstract func reset_progress() -> Result


@abstract func start_exploration(island_id: int = 0) -> Result


@abstract func list_islands() -> Result


## As ilhas do Arquipélago Auralis, em ordem (auralis/03).
@abstract func load_archipelago() -> Result


## Só com as rotas de teste ligadas no servidor.
@abstract func unlock_island(island_id: int) -> Result


## Grava hexágonos descobertos numa ilha (fog-of-war/03).
@abstract func add_island_discoveries(island_id: int, coords: Array[Vector2i]) -> Result


## Liga Marcos da história; `data` é a lista inteira depois (story/01).
@abstract func add_story_marks(marks: Array[String]) -> Result


## Só com as rotas de teste ligadas no servidor.
@abstract func forget_island_discoveries(island_id: int) -> Result


@abstract func start_board_wild_battle(coord: Vector2i, god: bool = false) -> Result


@abstract func start_board_tamer_battle(coord: Vector2i, god: bool = false) -> Result


@abstract func start_board_challenge() -> Result


## O Domador fixo do NPC da ilha explorada (auralis/04).
@abstract func start_board_island_tamer(npc_id: int, god: bool = false) -> Result


## A conversa da missão depois da última fala do NPC (auralis/06); `data` é um `QuestTalk`.
@abstract func talk_quest(npc_id: int) -> Result


## O Domador pisou num item no chão (auralis/09); `data` é a fala ("Você encontrou ...").
@abstract func pick_ground_item(key: int) -> Result


## O Domador pisou num lugar de missão; `data` é `{"reached": Array[String], "places": Dictionary[Vector2i, String]}`.
@abstract func reach_quest_place(coord: Vector2i) -> Result


@abstract func start_board_test_battle(enemies: Array[Dictionary], slots: int) -> Result


## A luta de teste da Técnica do F1 (skill-test/02): `skill_id`, `species_id`,
## `enemy_species_id`, `level`, `enemy_idle` e `slots`. Nada dela é gravado.
@abstract func start_board_skill_test(test: Dictionary) -> Result


@abstract func board_action(body: Dictionary) -> Result


@abstract func debug_almost_level_up() -> Result


@abstract func debug_spawn(species_id: int, coord: Vector2i) -> Result


@abstract func load_codex() -> Result


## Os contadores do Perfil; `data` é um `PlayerCounters` (player-stats/03).
@abstract func load_counters() -> Result


## O sinal de cada minuto, com os hexágonos andados por bioma (player-stats/02).
@abstract func send_counters_ping(hexes: Dictionary[String, int]) -> Result


@abstract func debug_clear_codex() -> Result


@abstract func debug_clear_spawns() -> Result


@abstract func debug_tamer(coord: Vector2i, size: int) -> Result


## O teleporte de depuração do mapa grande (minimap/03): a posição conferida vira `coord`.
@abstract func set_exploration_position(coord: Vector2i) -> Result


## A sala de um interior (interiors/01), com o `Interior` em `data`.
@abstract func load_interior(id: int) -> Result


@abstract func evolve(uid: String, accept: bool) -> Result


@abstract func learn_skill(uid: String, skill_id: int, forget_skill_id: int) -> Result
