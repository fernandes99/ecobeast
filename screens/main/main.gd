extends Control
## Cena raiz do jogo: carrega o catálogo, abre a primeira tela dentro de
## %ScreenHost e trata o voltar (Android e Esc).
## Boot provisório (foundation/02): sempre abre o placeholder "Ecobeast"; a
## escolha da primeira tela entra em onboarding/01.


func _ready() -> void:
	Router.set_host(%ScreenHost)
	if not GameData.load_catalog():
		_show_data_errors(GameData.errors)
		return
	Router.go_to(&"placeholder", {"title": "Ecobeast"})


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Router.back()


func _unhandled_input(event: InputEvent) -> void:
	# Esc no editor faz o papel do voltar do Android.
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		Router.back()


## Erro nos dados é de quem editou o catálogo, não do jogador: a lista aparece
## na tela e no console, e nenhuma tela é aberta.
func _show_data_errors(errors: Array[String]) -> void:
	for error: String in errors:
		push_error(error)
	%ErrorList.text = "\n".join(errors)
	%ErrorView.visible = true
