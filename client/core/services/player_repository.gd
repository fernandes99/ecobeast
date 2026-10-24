@abstract
class_name PlayerRepository
extends RefCounted
## Onde o jogador é guardado. Hoje: LocalPlayerRepository (user://save.json).
## No futuro: a API. As mensagens de erro já vêm prontas para a tela.


## data: o Player salvo, ou null se não existe.
@abstract func load_player() -> Result


## data: o Player gravado.
@abstract func save_player(player: Player) -> Result


## Apaga o jogador; sem erro se ele não existe. data: null.
@abstract func clear_player() -> Result
