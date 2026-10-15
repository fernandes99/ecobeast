extends Control
## Cena raiz do jogo: carrega o catálogo e o jogador, abre a primeira tela
## dentro de %ScreenHost e trata o voltar (Android e Esc).
## (.specs/foundation/architecture.md e .specs/onboarding/architecture.md, "Boot")


func _ready() -> void:
	Router.set_host(%ScreenHost)
	%RetryButton.pressed.connect(_load_player)
	if not GameData.load_catalog():
		_show_data_errors(GameData.errors)
		return
	_load_player()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Router.back()


func _unhandled_input(event: InputEvent) -> void:
	# Esc no editor faz o papel do voltar do Android.
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		Router.back()


func _load_player() -> void:
	%LoadErrorView.visible = false
	var result: Result = await Session.load_player()
	if not result.ok:
		%LoadErrorMessage.text = result.error
		%LoadErrorView.visible = true
		return
	_open_first_screen(Session.player)


## Sem jogador: entrada. Sem inicial: escolha. Com equipe: Hub.
## Escolha e Hub abrem o placeholder até existirem (onboarding/02 e hub/01).
func _open_first_screen(player: Player) -> void:
	if player == null:
		Router.go_to(&"title")
	elif not player.has_starter():
		Router.go_to(&"placeholder", {"title": "Escolha do inicial"})
	else:
		Router.go_to(&"placeholder", {"title": "Hub"})


## Erro nos dados é de quem editou o catálogo, não do jogador: a lista aparece
## na tela e no console, e nenhuma tela é aberta.
func _show_data_errors(errors: Array[String]) -> void:
	for error: String in errors:
		push_error(error)
	%ErrorList.text = "\n".join(errors)
	%ErrorView.visible = true
