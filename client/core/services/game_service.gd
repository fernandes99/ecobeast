@abstract
class_name GameService
extends RefCounted
## As ações do jogador (.specs/onboarding/architecture.md, "Contrato do
## GameService"). Chame sempre com await; cada método devolve um Result com a
## mensagem de erro pronta para a tela. Hoje: ApiGameService.


## data: o Player, ou null se ainda não existe.
@abstract func get_player() -> Result


## data: o Player novo, sem equipe.
@abstract func create_player(raw_name: String) -> Result


## data: o Player com a criatura no slot 1 da equipe.
@abstract func choose_starter(species_id: int) -> Result


## data: o Player com o apelido novo; vazio remove o apelido.
@abstract func set_nickname(uid: String, raw_nickname: String) -> Result


## data: o Player com a equipe curada.
@abstract func heal_team() -> Result


## data: o Player com as moedas e a Mochila depois da compra.
@abstract func buy_item(item_id: int) -> Result


## data: o Player depois do uso, fora da luta.
@abstract func use_item(item_id: int, creature_uid: String) -> Result


## data: os Ecobeasts do Santuário, um Array[CreatureInstance].
@abstract func load_storage() -> Result


## data: o Player com a equipe na ordem nova.
@abstract func reorder_team(uids: Array[String]) -> Result


## data: o Player com o Ecobeast na equipe. Com `replace_uid`, os dois trocam de lugar.
@abstract func bring_to_team(uid: String, replace_uid: String) -> Result


## data: o Player sem o Ecobeast na equipe.
@abstract func send_to_storage(uid: String) -> Result


## data: null.
@abstract func reset_progress() -> Result


## data: o ExplorationMap, um mapa novo a cada chamada.
@abstract func start_exploration() -> Result


## data: o BattleTurn da abertura, contra um Ecobeast do hexágono do Domador.
## `god`: depuração, todo golpe do jogador que acerta derruba o inimigo.
@abstract func start_wild_battle(coord: Vector2i, god: bool = false) -> Result


## data: o BattleTurn da ação, ou null se a batalha não existe mais.
@abstract func battle_action(action: Dictionary) -> Result


## data: o BoardTurn da abertura da luta no tabuleiro (board-battle/04), contra
## um Ecobeast do hexágono do Domador.
@abstract func start_board_wild_battle(coord: Vector2i, god: bool = false) -> Result


## data: o BoardTurn da abertura da luta de teste no tabuleiro. `enemies`: cada
## um com species_id e level.
@abstract func start_board_test_battle(enemies: Array[Dictionary], slots: int) -> Result


## data: o BoardTurn da vez, ou null se a luta não existe mais. `body`: a vez
## ({position, move?, action}) ou quem entra ({entries}).
@abstract func board_action(body: Dictionary) -> Result


## Só para testar: cada um da equipe fica a 1 XP do próximo nível.
## data: o Player atualizado.
@abstract func debug_almost_level_up() -> Result


## Responde à evolução oferecida na última vitória.
## data: o ProgressChoice, ou null se a escolha não existe mais.
@abstract func evolve(uid: String, accept: bool) -> Result


## Troca `forget_skill_id` pela Técnica pendente; com -1, não aprende a nova.
## data: o ProgressChoice, ou null se a escolha não existe mais.
@abstract func learn_skill(uid: String, skill_id: int, forget_skill_id: int) -> Result
