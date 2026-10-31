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


## data: null.
@abstract func reset_progress() -> Result
