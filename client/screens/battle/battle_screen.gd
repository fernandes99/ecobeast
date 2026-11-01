extends Control
## Batalha (battle-screen/03, TELAS.md #5): o inimigo em cima, o Ecobeast do
## jogador embaixo, o histórico entre eles e as ações. O servidor decide tudo; a
## tela só revela o turno aos poucos (.specs/battle-screen/architecture.md).

const SkillButtonScene := preload("res://screens/battle/battle_skill_button.tscn")

const SKILL_SLOTS := 4
## Espera depois de cada linha do turno, em segundos. A revisar.
const LINE_DELAY := 0.9
const MAX_LOG_LINES := 50
const LOG_FONT_SIZE := 24
const SEARCHING_TEXT := "Procurando um Ecobeast..."
const GONE_TEXT := "Essa batalha não existe mais."
const RESULT_TEXTS: Dictionary[String, String] = {
	"victory": "Você venceu!",
	"defeat": "Você perdeu.",
	"fled": "Você fugiu.",
	"captured": "Capturado!",
}

## O último estado do servidor; null até a abertura terminar.
var _view: BattleView = null
var _display := BattleDisplay.new()
var _narrator := BattleNarrator.new()
## Um turno está indo ou voltando do servidor, ou aparecendo na tela.
var _busy: bool = false
## O fim da luta gravou HP e PP: é preciso reler o jogador.
var _needs_reload: bool = false
## "Voltar" já terminou: o próximo Router.back fecha esta tela.
var _leaving: bool = false

@onready var _turn_row: Control = %TurnRow
@onready var _turn_label: Label = %TurnLabel
@onready var _enemy_card: BattleSideCard = %EnemyCard
@onready var _player_card: BattleSideCard = %PlayerCard
@onready var _scroll: ScrollContainer = %Scroll
@onready var _log_lines: VBoxContainer = %LogLines
@onready var _actions_grid: GridContainer = %ActionsGrid
@onready var _attack_button: Button = %AttackButton
@onready var _items_button: Button = %ItemsButton
@onready var _flee_button: Button = %FleeButton
@onready var _skills_box: VBoxContainer = %SkillsBox
@onready var _skills_grid: GridContainer = %SkillsGrid
@onready var _emergency_box: VBoxContainer = %EmergencyBox
@onready var _result_box: VBoxContainer = %ResultBox
@onready var _result_label: Label = %ResultLabel
@onready var _result_message: Label = %ResultMessage
@onready var _exit_button: Button = %ExitButton
@onready var _next_panel: NextCreaturePanel = %NextPanel
@onready var _items_panel: BattleItemsPanel = %ItemsPanel
@onready var _capture_overlay: CaptureOverlay = %CaptureOverlay


func _ready() -> void:
	for index: int in SKILL_SLOTS:
		var button: BattleSkillButton = SkillButtonScene.instantiate()
		button.pressed.connect(_act.bind({"type": "skill", "slot": index + 1}))
		_skills_grid.add_child(button)
	_scroll.get_v_scroll_bar().changed.connect(_scroll_to_end)
	_attack_button.pressed.connect(_open_skills)
	_items_button.pressed.connect(_open_items)
	_items_panel.chosen.connect(_use_item)
	_items_panel.capture_chosen.connect(_capture)
	_flee_button.pressed.connect(_act.bind({"type": "flee"}))
	%EmergencyButton.pressed.connect(_act.bind({"type": "emergency"}))
	%SkillsBackButton.pressed.connect(_show_controls.bind(_actions_grid))
	_exit_button.pressed.connect(_leave)
	_next_panel.chosen.connect(_choose_next)
	_begin()


## Chamado pelo Router no voltar do Android ou Esc. Sair da luta é Correr; o
## voltar só fecha os itens e as Técnicas ou, com a luta encerrada, volta ao mapa.
func handle_back() -> bool:
	if _leaving:
		return false
	if _next_panel.visible:
		return true
	if _items_panel.visible:
		_items_panel.go_back()
		return true
	if _skills_box.visible:
		_show_controls(_actions_grid)
	elif _result_box.visible:
		_leave()
	return true


func _begin() -> void:
	_add_line(SEARCHING_TEXT)
	var result: Result = await Session.start_wild_battle()
	_clear_log()
	if not result.ok:
		_show_exit(result.error, false)
		return
	var turn: BattleTurn = result.data
	_display.reset(turn.view)
	_show_turn_number(turn.view.turn)
	_turn_row.show()
	_enemy_card.show()
	_player_card.show()
	await _show_turn(turn)


func _act(action: Dictionary) -> void:
	if _busy:
		return
	_set_busy(true)
	_show_controls(_actions_grid)
	var result: Result = await Session.battle_action(action)
	if not result.ok:
		_add_line(result.error, UiPalette.DANGER)
		_set_busy(false)
	elif result.data == null:
		_show_battle_gone()
	else:
		await _show_turn(result.data)


func _choose_next(team_index: int) -> void:
	if _busy:
		return
	_busy = true
	var result: Result = await Session.battle_action({"type": "switch", "team_index": team_index})
	if not result.ok:
		_next_panel.show_error(result.error)
		_busy = false
		return
	_next_panel.close()
	if result.data == null:
		_show_battle_gone()
	else:
		await _show_turn(result.data)


## Revela os eventos um a um; no fim, a resposta do servidor manda em tudo.
func _show_turn(turn: BattleTurn) -> void:
	_set_busy(true)
	_show_controls(_actions_grid)
	_narrator.set_team_names(_team_names(turn.view))
	for event: Dictionary in turn.events:
		_display.apply(event, turn.view)
		_refresh_cards()
		if DictFields.get_string(event, "type") == "capture_attempted":
			await _play_capture(event)
		var line := _narrator.describe(event)
		if not line.is_empty():
			_add_line(line)
			await get_tree().create_timer(LINE_DELAY).timeout
	var destination := _narrator.describe_captured_to(turn.captured_to)
	if not destination.is_empty():
		_add_line(destination)
	_view = turn.view
	_display.reset(_view)
	_refresh_cards()
	_narrator.begin_turns()
	_show_turn_number(_view.turn)
	_set_busy(false)
	match _view.phase:
		"choose_next":
			_next_panel.open(_view.team, _team_names(_view))
		"ended":
			_show_exit(RESULT_TEXTS.get(_view.result, ""), true)


func _set_busy(busy: bool) -> void:
	_busy = busy
	_attack_button.disabled = busy
	_items_button.disabled = busy
	_flee_button.disabled = busy or _view == null or not _view.can_flee


func _show_controls(controls: Control) -> void:
	for option: Control in [_actions_grid, _skills_box, _result_box]:
		option.visible = option == controls


func _open_skills() -> void:
	if _busy:
		return
	var skills := _view.active().skills
	var has_pp := false
	for index: int in SKILL_SLOTS:
		var slot: SkillSlot = skills[index] if index < skills.size() else null
		(_skills_grid.get_child(index) as BattleSkillButton).set_skill(slot)
		has_pp = has_pp or (slot != null and slot.current_pp > 0)
	_skills_grid.visible = has_pp
	_emergency_box.visible = not has_pp
	_show_controls(_skills_box)


func _open_items() -> void:
	if not _busy:
		_items_panel.open(_view.items, _view.team, _team_names(_view))


func _use_item(item_id: int, team_index: int) -> void:
	_items_panel.close()
	_act({"type": "item", "item_id": item_id, "team_index": team_index})


func _capture(item_id: int) -> void:
	_items_panel.close()
	_act({"type": "capture", "item_id": item_id})


func _play_capture(event: Dictionary) -> void:
	var item := GameData.get_item(DictFields.get_id(event, "item_id"))
	await _capture_overlay.play(item, _display.enemy.species_id, DictFields.get_bool(event, "success"))


func _refresh_cards() -> void:
	var player_name := _player_name(_display.player)
	var enemy_name := GameData.get_species(_display.enemy.species_id).name
	_narrator.set_side_name("player", player_name)
	_narrator.set_side_name("enemy", enemy_name)
	_player_card.set_creature(_display.player, player_name)
	_player_card.set_xp(_xp_ratio(_display.player))
	_enemy_card.set_creature(_display.enemy, enemy_name)


## A criatura do jogador com esse uid, ou null.
func _party_creature(uid: String) -> CreatureInstance:
	for creature: CreatureInstance in Session.player.party:
		if creature.uid == uid:
			return creature
	return null


func _player_name(creature: BattleCreature) -> String:
	var species := GameData.get_species(creature.species_id)
	var party_creature := _party_creature(creature.uid)
	return party_creature.display_name(species) if party_creature != null else species.name


func _team_names(view: BattleView) -> Array[String]:
	var names: Array[String] = []
	for creature: BattleCreature in view.team:
		names.append(_player_name(creature))
	return names


## O XP não muda na luta: vem do jogador, como na tela de detalhes.
func _xp_ratio(creature: BattleCreature) -> float:
	var party_creature := _party_creature(creature.uid)
	if party_creature == null or party_creature.next_level_xp < 0:
		return 1.0
	var span := party_creature.next_level_xp - party_creature.level_xp
	return float(party_creature.current_xp - party_creature.level_xp) / span


func _show_turn_number(turn: int) -> void:
	_turn_label.text = "Turno %d" % turn


func _add_line(text: String, color: Color = UiPalette.TEXT) -> void:
	var count := _log_lines.get_child_count()
	if count > 0:
		var previous := _log_lines.get_child(count - 1) as Label
		if previous.get_theme_color(&"font_color") == UiPalette.TEXT:
			previous.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	if count >= MAX_LOG_LINES:
		_remove_line(_log_lines.get_child(0))
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", LOG_FONT_SIZE)
	label.add_theme_color_override(&"font_color", color)
	_log_lines.add_child(label)


func _clear_log() -> void:
	for line: Node in _log_lines.get_children():
		_remove_line(line)


func _remove_line(line: Node) -> void:
	_log_lines.remove_child(line)
	line.queue_free()


func _scroll_to_end() -> void:
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func _show_battle_gone() -> void:
	_add_line(GONE_TEXT)
	_show_exit("", true)


## Só a saída. `needs_reload`: a luta chegou a existir, e o jogador é relido.
func _show_exit(text: String, needs_reload: bool) -> void:
	_needs_reload = needs_reload
	_result_label.text = text
	_result_label.visible = not text.is_empty()
	_show_controls(_result_box)


func _leave() -> void:
	if _exit_button.disabled:
		return
	if _needs_reload:
		_exit_button.disabled = true
		_result_message.hide()
		var result: Result = await Session.load_player()
		_exit_button.disabled = false
		if not result.ok:
			_result_message.text = result.error
			_result_message.show()
			return
	_leaving = true
	Router.back()
