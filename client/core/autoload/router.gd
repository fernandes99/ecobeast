extends Node
## Autoload Router: troca de telas em pilha dentro do %ScreenHost da cena raiz
## (.specs/foundation/architecture.md, "Navegação").
## Se a tela tiver setup(params: Dictionary), ele é chamado antes de a tela
## entrar na árvore, ou seja, antes do _ready dela.

## A tela visível mudou: abriu uma nova ou voltou para a anterior. `id` é o dela.
signal screen_changed(id: StringName)

## Onde cada tela guarda o id com que foi aberta.
const SCREEN_ID_META := &"screen_id"

## Telas registradas: id -> cena. Cada fase acrescenta a sua.
const SCREENS: Dictionary[StringName, String] = {
	&"bag": "res://screens/bag/bag_screen.tscn",
	&"battle": "res://screens/battle/battle_screen.tscn",
	&"board_battle": "res://screens/board_battle/board_battle_screen.tscn",
	&"codex": "res://screens/codex/codex_screen.tscn",
	&"creature_details": "res://screens/creature_details/creature_details_screen.tscn",
	&"exploration": "res://screens/exploration/exploration_screen.tscn",
	&"heal_station": "res://screens/heal_station/heal_station_screen.tscn",
	&"hub": "res://screens/hub/hub_screen.tscn",
	&"islands": "res://screens/islands/islands_screen.tscn",
	&"login": "res://screens/login/login_screen.tscn",
	&"placeholder": "res://screens/placeholder/placeholder_screen.tscn",
	&"shop": "res://screens/shop/shop_screen.tscn",
	&"starter_select": "res://screens/starter_select/starter_select_screen.tscn",
	&"storage": "res://screens/storage/storage_screen.tscn",
	&"team": "res://screens/team/team_screen.tscn",
	&"title": "res://screens/title/title_screen.tscn",
}

var _host: Control
## Telas abertas; a última é a visível.
var _stack: Array[Control] = []


## Chamado pela cena raiz no boot, antes de qualquer navegação.
func set_host(host: Control) -> void:
	_host = host


## Limpa a pilha e abre a tela (sem volta).
func go_to(id: StringName, params: Dictionary = {}) -> void:
	var screen := _instantiate(id, params)
	if screen == null:
		return
	for old: Control in _stack:
		old.queue_free()
	_stack.clear()
	_open(screen)


## Esconde a tela atual, sem destruir, e abre a nova por cima.
func push(id: StringName, params: Dictionary = {}) -> void:
	var screen := _instantiate(id, params)
	if screen == null:
		return
	if not _stack.is_empty():
		_stack.back().hide()
	_open(screen)


## Fecha a tela do topo e mostra a anterior. Na última tela, não faz nada.
## Se a tela do topo tiver handle_back() -> bool e ele devolver true, ela
## tratou o voltar sozinha (ex.: fechou um painel) e continua aberta.
func back() -> void:
	# Com a transição da luta cobrindo a tela, o voltar espera (battle-intro/01).
	if BattleIntro.is_covering():
		return
	if not _stack.is_empty():
		var current := _stack.back() as Control
		if current.has_method(&"handle_back") and current.call(&"handle_back"):
			return
	if not can_go_back():
		return
	var top: Control = _stack.pop_back()
	top.queue_free()
	_stack.back().show()
	screen_changed.emit(_stack.back().get_meta(SCREEN_ID_META, &""))


func can_go_back() -> bool:
	return _stack.size() > 1


func _instantiate(id: StringName, params: Dictionary) -> Control:
	if _host == null:
		push_error("Router: set_host() não foi chamado antes de abrir '%s'" % id)
		return null
	if not SCREENS.has(id):
		push_error("Router: tela '%s' não está registrada em Router.SCREENS" % id)
		return null
	var scene: PackedScene = load(SCREENS[id])
	var screen: Control = scene.instantiate()
	screen.set_meta(SCREEN_ID_META, id)
	if screen.has_method(&"setup"):
		screen.call(&"setup", params)
	return screen


func _open(screen: Control) -> void:
	# Entra na pilha antes da árvore, para can_go_back() já valer no _ready da tela.
	_stack.append(screen)
	_host.add_child(screen)
	screen_changed.emit(screen.get_meta(SCREEN_ID_META))
