extends Node
## Autoload Router: troca de telas em pilha dentro do %ScreenHost da cena raiz
## (.specs/foundation/architecture.md, "Navegação").
## Se a tela tiver setup(params: Dictionary), ele é chamado antes de a tela
## entrar na árvore, ou seja, antes do _ready dela.

## Telas registradas: id -> cena. Cada fase acrescenta a sua.
const SCREENS: Dictionary[StringName, String] = {
	&"placeholder": "res://screens/placeholder/placeholder_screen.tscn",
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
func back() -> void:
	if not can_go_back():
		return
	var top: Control = _stack.pop_back()
	top.queue_free()
	_stack.back().show()


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
	if screen.has_method(&"setup"):
		screen.call(&"setup", params)
	return screen


func _open(screen: Control) -> void:
	# Entra na pilha antes da árvore, para can_go_back() já valer no _ready da tela.
	_stack.append(screen)
	_host.add_child(screen)
