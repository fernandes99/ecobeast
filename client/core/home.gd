class_name Home
extends RefCounted

## A ilha casa do jogador (.specs/home-island/architecture.md#navegação). Sair dela
## e voltar a ela usam sempre o `go_to`: o servidor guarda uma exploração só.


static func has_home() -> bool:
	return Session.home_island_id > 0


static func is_home(island_id: int) -> bool:
	return has_home() and island_id == Session.home_island_id


## A primeira tela: sem Domador, cria um sem nome; sem casa (hub-start/01), a Aparência com o
## nome, a escolha do inicial e o Hub; com a casa, ela, onde as cenas cuidam do nome e do inicial.
static func start() -> Result:
	if Session.player == null:
		var created: Result = await Session.create_player("")
		if not created.ok:
			return created
	var player := Session.player
	if has_home():
		go()
	elif not player.has_name():
		Router.go_to(&"appearance", {"onboarding": true})
	elif not player.has_starter():
		Router.go_to(&"starter_select")
	else:
		go()
	return Result.success(null)


static func go() -> void:
	if has_home():
		Router.go_to(&"exploration", {"island_id": Session.home_island_id})
	else:
		Router.go_to(&"hub")
