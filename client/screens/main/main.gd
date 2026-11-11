extends Control
## Cena raiz do jogo: carrega o catálogo, passa pelo login se preciso, carrega o
## jogador, abre a primeira tela dentro de %ScreenHost e trata o voltar (Android
## e Esc). (.specs/foundation/architecture.md, "Boot")

const OFFLINE_MESSAGE := "Não foi possível conectar ao servidor. Confira sua internet e tente de novo."
## O save de quando o jogador morava no aparelho (auth-google/05, RF-06).
const OLD_SAVE_FILES: Array[String] = ["user://save.json", "user://save.tmp.json", "user://save.corrupted.json"]

## O "Tentar de novo" refaz só a etapa que falhou.
var _catalog_loaded := false
## O visualizador de conteúdo (content-viewer/01), criado no primeiro F1.
var _content_viewer: ContentViewer = null
## O editor de ilhas (map-editor/02), criado no primeiro F2.
var _map_editor: MapEditor = null


func _ready() -> void:
	%Background.texture = _background_gradient()
	Router.set_host(%ScreenHost)
	%RetryButton.pressed.connect(_boot)
	Session.logged_in.connect(_load_player)
	Api.session_lost.connect(_open_login)
	_delete_old_saves()
	_boot()


func _delete_old_saves() -> void:
	for path: String in OLD_SAVE_FILES:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


## Gradiente vertical do fundo: BACKGROUND em cima, BACKGROUND_DEEP embaixo.
func _background_gradient() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, UiPalette.BACKGROUND)
	gradient.set_color(1, UiPalette.BACKGROUND_DEEP)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	return texture


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Router.back()


func _unhandled_input(event: InputEvent) -> void:
	if _is_content_viewer_key(event):
		get_viewport().set_input_as_handled()
		_toggle_content_viewer()
		return
	if _is_dev_key(event, KEY_F2):
		get_viewport().set_input_as_handled()
		_toggle_map_editor()
		return
	# Esc no editor faz o papel do voltar do Android.
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		Router.back()


## F1, só com o jogo rodando pelo editor: a tag "editor" não existe em nenhum jogo
## exportado, nem no de depuração. A tecla fica fora do Input Map para não aparecer
## nas configurações do jogo.
func _is_content_viewer_key(event: InputEvent) -> bool:
	return _is_dev_key(event, KEY_F1)


## Uma tecla das ferramentas de desenvolvimento (F1 e F2), só pelo editor do Godot.
func _is_dev_key(event: InputEvent, keycode: Key) -> bool:
	var key := event as InputEventKey
	return key != null and key.pressed and not key.echo and key.keycode == keycode and OS.has_feature("editor")


## A janela é criada uma vez e depois só aparece e some, guardando a aba escolhida.
func _toggle_content_viewer() -> void:
	if _content_viewer == null:
		_content_viewer = ContentViewer.new()
		add_child(_content_viewer)
		_content_viewer.show()
	else:
		_content_viewer.visible = not _content_viewer.visible


## Como o visualizador: criado uma vez, depois só aparece. Fechar com mudanças não
## salvas pergunta antes (MapEditor.close).
func _toggle_map_editor() -> void:
	if _map_editor == null:
		_map_editor = MapEditor.new()
		add_child(_map_editor)
		_map_editor.show()
	elif _map_editor.visible:
		_map_editor.close()
	else:
		_map_editor.show()


## Catálogo (do servidor), login e jogador; a etapa que falha mostra o erro.
func _boot() -> void:
	_hide_load_error()
	if not _catalog_loaded:
		%LoadingLabel.visible = true
		var status: int = await GameData.load_catalog()
		%LoadingLabel.visible = false
		if status == GameData.LOAD_INVALID:
			_show_data_errors(GameData.errors)
			return
		if status == GameData.LOAD_OFFLINE:
			_show_load_error(OFFLINE_MESSAGE)
			return
		_catalog_loaded = true

	if Session.has_auth_session():
		_load_player()
	else:
		_open_login()


## O fim do boot, também chamado quando o login termina.
func _load_player() -> void:
	var result: Result = await Session.load_player()
	if result.ok:
		_open_first_screen(Session.player)
	elif Session.has_auth_session():
		_show_load_error(result.error)
	# Sem sessão, o Api.session_lost já levou à tela de login.


func _open_login() -> void:
	_hide_load_error()
	Router.go_to(&"login")


## O erro tampa o %ScreenHost, que pode ter a tela de login aberta.
func _show_load_error(message: String) -> void:
	%LoadErrorMessage.text = message
	%LoadErrorView.visible = true
	%ScreenHost.visible = false


func _hide_load_error() -> void:
	%LoadErrorView.visible = false
	%ScreenHost.visible = true


## Sem jogador: entrada. Sem inicial: escolha. Com equipe: Hub.
func _open_first_screen(player: Player) -> void:
	if player == null:
		Router.go_to(&"title")
	elif not player.has_starter():
		Router.go_to(&"starter_select")
	else:
		Router.go_to(&"hub")


## Erro nos dados é de quem editou o catálogo, não do jogador: a lista aparece
## na tela e no console, e nenhuma tela é aberta.
func _show_data_errors(errors: Array[String]) -> void:
	for error: String in errors:
		push_error(error)
	%ErrorList.text = "\n".join(errors)
	%ErrorView.visible = true
