extends Control
## Equipe (team-and-storage/03, TELAS.md #9): as 6 vagas, a ordem ao segurar e
## arrastar e o caminho até o Santuário. Quem grava é o servidor; a tela mostra a
## ordem nova na hora e volta atrás se ele recusar.
##
## Arrastar: a linha segurada sai do layout da lista (`top_level`) e segue o dedo,
## e uma lacuna do mesmo tamanho fica em seu lugar. Mover a lacuna entre as linhas
## é o que abre espaço. O toque chega como mouse, porque o Godot o converte.

const RowScene := preload("res://screens/team/team_row.tscn")

const MOVE_TEXT := "Mandar para o Santuário"
const LAST_CREATURE_TEXT := "A equipe precisa de ao menos 1 Ecobeast."

## O Ecobeast do painel aberto.
var _selected: CreatureInstance = null
## Há um pedido no servidor: as linhas não aceitam toques.
var _busy: bool = false
## A linha que está seguindo o dedo.
var _lifted: TeamRow = null
var _gap := Control.new()
## Onde a lacuna começou: voltar a ela é cancelar.
var _origin: int = 0
## A distância entre o topo da linha e o dedo.
var _grab_offset: float = 0.0

@onready var _list: VBoxContainer = %List
@onready var _message: Label = %Message
@onready var _back_button: Button = %BackButton
@onready var _actions_panel: CreatureActionsPanel = %ActionsPanel


func _ready() -> void:
	_back_button.pressed.connect(Router.back)
	_actions_panel.move_pressed.connect(_store)
	_actions_panel.details_pressed.connect(_open_details)
	for index: int in Player.PARTY_SIZE:
		var row: TeamRow = RowScene.instantiate()
		row.tapped.connect(_on_row_tapped.bind(row))
		row.hold_started.connect(_lift.bind(row))
		_list.add_child(row)
	_gap.size_flags_vertical = SIZE_EXPAND_FILL
	_gap.mouse_filter = MOUSE_FILTER_IGNORE
	_gap.hide()
	_list.add_child(_gap)
	Session.player_changed.connect(_show_team)
	_show_team()


## Chamado pelo Router no voltar do Android ou Esc: cancela o arrasto ou fecha o painel.
func handle_back() -> bool:
	if _lifted != null:
		_cancel_drag()
		return true
	if _busy:
		return true
	if _actions_panel.visible:
		_actions_panel.close()
		return true
	return false


func _input(event: InputEvent) -> void:
	if _lifted == null:
		return
	var motion := event as InputEventMouseMotion
	if motion != null:
		_follow_finger(motion.position.y)
		return
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
		if button.canceled:
			_cancel_drag()
		else:
			_drop()


func _notification(what: int) -> void:
	# O jogo saiu da frente com o dedo na tela: pode nunca chegar o soltar.
	if what == NOTIFICATION_APPLICATION_PAUSED and _lifted != null:
		_cancel_drag()


func _show_team() -> void:
	var player := Session.player
	# Sem jogador só depois de perder a sessão, quando o Router já está trocando de tela.
	if player == null or _lifted != null:
		return
	var party := player.party
	var rows := _rows_in_order()
	for index: int in rows.size():
		var creature: CreatureInstance = party[index] if index < party.size() else null
		rows[index].set_creature(creature)
		rows[index].can_hold = creature != null and party.size() > 1
	_mark_leader()


## As linhas de cima para baixo: quem está no ar conta no lugar da lacuna.
func _rows_in_order() -> Array[TeamRow]:
	var rows: Array[TeamRow] = []
	for child: Node in _list.get_children():
		if child == _gap:
			if _lifted != null:
				rows.append(_lifted)
		elif child != _lifted:
			rows.append(child as TeamRow)
	return rows


## É quem o servidor põe em campo: o primeiro com HP, não o primeiro da lista.
func _mark_leader() -> void:
	var is_found := false
	for row: TeamRow in _rows_in_order():
		var is_leader := not is_found and row.creature != null and row.creature.current_hp > 0
		row.set_leader(is_leader)
		is_found = is_found or is_leader


func _lift(finger_y: float, row: TeamRow) -> void:
	_message.hide()
	var rect := row.get_global_rect()
	_origin = row.get_index()
	_grab_offset = finger_y - rect.position.y
	_gap.show()
	_list.move_child(_gap, _origin)
	row.top_level = true
	row.global_position = rect.position
	row.size = rect.size
	_list.move_child(row, -1)
	row.set_lifted(true)
	_lifted = row


func _follow_finger(finger_y: float) -> void:
	var top := _list.global_position.y
	var step := _gap.size.y + _list.get_theme_constant(&"separation")
	var bottom := top + step * (Player.PARTY_SIZE - 1)
	_lifted.global_position.y = clampf(finger_y - _grab_offset, top, bottom)
	# Sobre as vagas livres, o Ecobeast fica no último lugar com alguém.
	var last := Session.player.party.size() - 1
	var slot := clampi(roundi((_lifted.global_position.y - top) / step), 0, last)
	if slot != _gap.get_index():
		_list.move_child(_gap, slot)
		_mark_leader()


func _drop() -> void:
	var is_moved := _gap.get_index() != _origin
	_land()
	if not is_moved:
		return
	var uids: Array[String] = []
	for row: TeamRow in _rows_in_order():
		if row.creature != null:
			uids.append(row.creature.uid)
	_set_busy(true)
	var result: Result = await Session.reorder_team(uids)
	_set_busy(false)
	if not result.ok:
		_show_team()
		_message.text = result.error
		_message.show()


func _cancel_drag() -> void:
	_list.move_child(_gap, _origin)
	_land()


## Devolve a linha à lista, no lugar da lacuna.
func _land() -> void:
	var row := _lifted
	_lifted = null
	row.set_lifted(false)
	row.top_level = false
	_list.move_child(row, _gap.get_index())
	_gap.hide()
	_list.move_child(_gap, -1)
	_mark_leader()


func _set_busy(busy: bool) -> void:
	_busy = busy
	for row: TeamRow in _rows_in_order():
		row.mouse_filter = MOUSE_FILTER_IGNORE if busy else MOUSE_FILTER_PASS


func _on_row_tapped(row: TeamRow) -> void:
	_message.hide()
	if row.creature == null:
		Router.push(&"storage")
		return
	_selected = row.creature
	var is_alone := Session.player.party.size() == 1
	_actions_panel.open(_selected, MOVE_TEXT, not is_alone, LAST_CREATURE_TEXT if is_alone else "")


func _open_details() -> void:
	_actions_panel.close()
	Router.push(&"creature_details", {"uid": _selected.uid})


func _store() -> void:
	_set_busy(true)
	_actions_panel.set_busy(true)
	var result: Result = await Session.send_to_storage(_selected.uid)
	_set_busy(false)
	_actions_panel.set_busy(false)
	if result.ok:
		_actions_panel.close()
	else:
		_actions_panel.show_error(result.error)
