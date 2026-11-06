extends Control
## Luta no tabuleiro (board-battle/04 a 08): o cartão do selvagem e a rodada em
## cima, o tabuleiro no meio, parado, e embaixo o cartão de quem joga e os botões.
## Na vez de um Ecobeast do jogador, ele anda (sem pedir nada
## ao servidor) e depois escolhe a Técnica e o alvo; a vez vai ao servidor no
## toque final, e a resposta traz as vezes dos selvagens, mostradas em ordem.
## O servidor decide tudo: a tela só acende o que dá para fazer e mostra o que
## aconteceu (.specs/board-battle/architecture.md, "Jogo").

const SkillButtonScene := preload("res://screens/battle/battle_skill_button.tscn")

const SKILL_SLOTS := 4
const SEARCHING_TEXT := "Procurando um Ecobeast..."
const GONE_TEXT := "Essa luta não existe mais."
const PICK_ENTRY_TEXT := "Toque no hexágono verde onde ele entra."
const CANNOT_ENTER_TEXT := "Esse Ecobeast não pode entrar."
const PICK_SPHERE_TEXT := "Toque no Ecobeast selvagem."
const FLEE_TEXT := "Fugir"
const FLEE_CONFIRM_TEXT := "Desfazer e fugir"
const FLEE_UNDO_TEXT := "Para fugir, o passo é desfeito. Toque de novo em Fugir."
const RESULT_TEXTS: Dictionary[String, String] = {
	"victory": "Você venceu!",
	"defeat": "Você perdeu.",
	"fled": "Você fugiu.",
	"captured": "Capturado!",
}
## Linhas dos eventos do tabuleiro, que o BattleNarrator não conhece. A revisar.
const BOARD_LINES: Dictionary[String, String] = {
	"moved": "%s andou.",
	"waited": "%s esperou.",
	"ground_damage": "%s se feriu no chão.",
}
## Frases que vão só para o histórico, sem passar pelo log: a rodada não é uma ação, e
## o log guarda a última ação da luta (board-battle/09).
const HISTORY_ONLY: Array[String] = ["round_started"]
const HP_EVENTS: Array[String] = ["damage", "recoil", "healed", "confused_hit", "status_damage", "ground_damage"]
const LOSS_EVENTS: Array[String] = ["damage", "recoil", "confused_hit", "status_damage", "ground_damage"]
## A largura do tabuleiro de 6 colunas: os hexágonos ficam do tamanho que tinham nele.
const REFERENCE_BOARD_WIDTH := 624.0
## Espera depois de cada frase completa no log, em segundos. A revisar.
const EVENT_DELAY := 0.35
## As frases aparecem no log letra por letra (board-battle/09). A revisar.
const CHARS_PER_SECOND := 60.0
## O efeito e o som de cada Técnica saem do slug dela, pelos caminhos do
## ContentFiles; sem o arquivo, ela não tem efeito ou som (board-battle/09).
## O som do dano, junto com a piscada, pela efetividade: normal, super ou weak.
## A Técnica de emergência é corpo a corpo.
const EMERGENCY_RANGE := 1

## O hexágono do Domador, de onde sai o selvagem; ou as vagas da luta de teste.
var _coord := Vector2i.ZERO
var _test_slots := 0
## O bioma e a forma do hexágono do Domador, para o chão do tabuleiro (board-battle/08).
var _biome := BoardView.DEFAULT_BIOME
var _shape := BoardView.DEFAULT_SHAPE
## O último estado do servidor; null até a abertura terminar.
var _view: BoardBattleView = null
## O estado da resposta que está sendo mostrada: dá os nomes de quem entra.
var _incoming: BoardBattleView = null
var _narrator := BattleNarrator.new()
var _busy: bool = false
## Um passo está sendo mostrado: os toques esperam.
var _walking: bool = false
var _needs_reload: bool = false
var _leaving: bool = false
## O golpe que está sendo mostrado: quem usou a Técnica e qual (board-battle/09).
## Vazio e -1 fora de um golpe; -1 também na Técnica de emergência.
var _attacker_key: String = ""
var _attack_skill_id := -1
var _typing: Tween = null
## A última frase da luta no log: quando um aviso sai, ela volta (board-battle/09).
var _last_line := ""
## Toca o som das Técnicas. Um AudioStreamPlayer toca um som de cada vez, sem lugar
## na tela, e cai no bus Master.
var _skill_sound := AudioStreamPlayer.new()
## Um segundo tocador, para o som do dano não cortar o da Técnica.
var _hit_sound := AudioStreamPlayer.new()

## Quem está no tabuleiro agora, pela chave da vaga ("player:0").
var _names: Dictionary[String, String] = {}
var _species: Dictionary[String, int] = {}
var _max_hp: Dictionary[String, int] = {}
var _team_index: Dictionary[String, int] = {}
var _level: Dictionary[String, int] = {}
var _hp: Dictionary[String, int] = {}
## Quem aparece nos cartões: o selvagem e o Ecobeast do jogador em foco.
var _enemy_focus: String = ""
var _player_focus: String = ""
## As marcas no chão, como estão na tela.
var _marks: Dictionary[Vector2i, int] = {}

## A vez do jogador: a vaga, de onde ele saiu e para onde andou.
var _actor := -1
var _origin := Vector2i.ZERO
var _moved: bool = false
var _destination := Vector2i.ZERO
var _reach: Dictionary[Vector2i, Array] = {}
## 0 sem Técnica escolhida; -1 é a emergência.
var _skill_slot := 0
## A Esfera escolhida na Mochila, à espera do selvagem; -1 sem nenhuma.
var _sphere_item := -1
var _targets: Array[Vector2i] = []
## Fugir depois de andar pede um segundo toque, que desfaz o passo.
var _flee_armed: bool = false

## Depois de uma queda: quem entra, um por vaga pendente.
var _entries: Array[Dictionary] = []
var _entry_team := -1

@onready var _enemy_card: BoardCreatureCard = %EnemyCard
@onready var _player_card: BoardCreatureCard = %PlayerCard
@onready var _board_area: Control = %BoardArea
@onready var _board_layer: Control = %BoardLayer
@onready var _board: BoardView = %Board
@onready var _message: Label = %Message
@onready var _log_box: PanelContainer = %LogBox
@onready var _more_icon: TextureRect = %MoreIcon
@onready var _bottom: VBoxContainer = %Bottom
@onready var _skills_box: Control = %SkillsBox
@onready var _skills_grid: GridContainer = %SkillsGrid
@onready var _attack_button: Button = %AttackButton
@onready var _emergency_button: Button = %EmergencyButton
@onready var _actions_row: Control = %ActionsRow
@onready var _bag_button: Button = %BagButton
@onready var _flee_button: Button = %FleeButton
@onready var _wait_button: Button = %WaitButton
@onready var _result_box: VBoxContainer = %ResultBox
@onready var _result_label: Label = %ResultLabel
@onready var _result_message: Label = %ResultMessage
@onready var _exit_button: Button = %ExitButton
@onready var _next_panel: NextCreaturePanel = %NextPanel
@onready var _items_panel: BattleItemsPanel = %ItemsPanel
@onready var _capture_overlay: CaptureOverlay = %CaptureOverlay
@onready var _level_up_overlay: LevelUpOverlay = %LevelUpOverlay
@onready var _evolution_overlay: EvolutionOverlay = %EvolutionOverlay
@onready var _skill_overlay: SkillLearnOverlay = %SkillLearnOverlay
@onready var _history: BattleHistoryPanel = %HistoryPanel


## `coord`: o encontro do mapa. `test_slots`: a luta de teste, com 2 ou 3 vagas.
## `biome` e `shape`: o terreno do hexágono do Domador, para o chão do tabuleiro.
func setup(params: Dictionary) -> void:
	_coord = params.get("coord", Vector2i.ZERO)
	_test_slots = params.get("test_slots", 0)
	_biome = params.get("biome", BoardView.DEFAULT_BIOME)
	_shape = params.get("shape", BoardView.DEFAULT_SHAPE)


func _ready() -> void:
	for index: int in SKILL_SLOTS:
		var button: BattleSkillButton = SkillButtonScene.instantiate()
		button.theme_type_variation = BattleTheme.BUTTON
		button.pressed.connect(_choose_skill.bind(index + 1))
		_skills_grid.add_child(button)
	_style_controls()
	_reserve_bottom()
	add_child(_skill_sound)
	add_child(_hit_sound)
	_enemy_card.clear()
	_player_card.clear()
	_emergency_button.pressed.connect(_choose_skill.bind(-1))
	_wait_button.pressed.connect(_wait)
	_attack_button.pressed.connect(_open_skills)
	%SkillsBackButton.pressed.connect(_close_skills)
	_bag_button.pressed.connect(_open_bag)
	_flee_button.pressed.connect(_flee)
	_items_panel.chosen.connect(_use_item)
	_items_panel.capture_chosen.connect(_aim_sphere)
	%InfoButton.pressed.connect(_history.open)
	_exit_button.pressed.connect(_leave)
	_board.cell_tapped.connect(_on_cell_tapped)
	# O tabuleiro mora numa camada atrás da interface (board-battle/08): a área na
	# coluna só diz onde ele fica.
	_board_area.item_rect_changed.connect(_fit_board)
	_next_panel.chosen.connect(_on_creature_chosen)
	_set_busy(true)
	_begin()


## Voltar do Android ou Esc: fecha painéis, desfaz a Técnica ou a Esfera
## escolhida ou, com a luta encerrada, volta ao mapa. Sair no meio da luta é Fugir.
func handle_back() -> bool:
	if _leaving:
		return false
	if _history.visible:
		_history.close()
	elif _level_up_overlay.visible:
		_level_up_overlay.close()
	elif _evolution_overlay.visible:
		_evolution_overlay.go_back()
	elif _skill_overlay.visible:
		_skill_overlay.go_back()
	elif _next_panel.visible:
		_next_panel.go_back()
	elif _items_panel.visible:
		_items_panel.go_back()
	elif _skill_slot != 0 or _sphere_item >= 0:
		_cancel_skill()
	elif _flee_armed:
		_disarm_flee()
	elif _skills_box.visible:
		_close_skills()
	elif _result_box.visible:
		_leave()
	return true


func _begin() -> void:
	_show_message(SEARCHING_TEXT)
	var result: Result
	if _test_slots > 0:
		result = await Session.start_board_test_battle(_test_enemies(), _test_slots)
	else:
		result = await Session.start_board_wild_battle(_coord)
	_show_message("")
	if not result.ok:
		_show_exit(result.error, false)
		return
	var turn: BoardTurn = result.data
	_board.set_board(turn.view.board_cells, _biome, _shape)
	_fit_board()
	await _show_turn(turn)
	_narrator.begin_turns()


## A luta de teste: Ecobeasts sorteados do catálogo, no nível do primeiro da equipe.
func _test_enemies() -> Array[Dictionary]:
	var level := 5
	if Session.player != null and not Session.player.party.is_empty():
		level = Session.player.party[0].level
	var all := GameData.get_all_species()
	var enemies: Array[Dictionary] = []
	for _index: int in _test_slots:
		var species: CreatureSpecies = all.pick_random()
		enemies.append({"species_id": species.id, "level": level})
	return enemies


## O visual da luta (board-battle/10): o tema vale para a tela inteira, mas só muda
## quem pede uma variação dele; os painéis que vêm da luta antiga ficam como estão.
func _style_controls() -> void:
	theme = BattleTheme.get_theme()
	BattleTheme.action_button(_attack_button, "attack")
	BattleTheme.action_button(_wait_button, "pass")
	BattleTheme.action_button(_bag_button, "bag")
	BattleTheme.action_button(_flee_button, "flee")
	for button: Button in [_emergency_button, _exit_button, %SkillsBackButton]:
		button.theme_type_variation = BattleTheme.BUTTON
	var info: Button = %InfoButton
	info.theme_type_variation = BattleTheme.ICON_BUTTON
	info.text = ""
	info.icon = BattleTheme.icon("help")
	info.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_log_box.theme_type_variation = BattleTheme.LOG
	%ChatIcon.texture = BattleTheme.icon("chat")
	_more_icon.texture = BattleTheme.icon("more")


## Um aviso inteiro no log, sem letra por letra e sem o triângulo de "continua".
## Vazio tira o aviso e volta a última frase da luta: o log nunca fica em branco
## depois que a luta começa.
func _show_message(text: String) -> void:
	if _typing != null:
		_typing.kill()
	_message.visible_characters = -1
	_message.text = text if not text.is_empty() else _last_line
	_more_icon.visible = false


## O tabuleiro fica parado (board-battle/08): o bloco de baixo guarda sempre a altura
## da mais alta das suas formas (os botões, as Técnicas ou o resultado), e a mensagem,
## 2 linhas. Assim a área do tabuleiro só muda com a janela.
func _reserve_bottom() -> void:
	var tallest := 0.0
	for form: Control in [_actions_row, _skills_box, _result_box]:
		tallest = maxf(tallest, form.get_combined_minimum_size().y)
	# A reserva fica no bloco todo, alinhado no pé: o cartão desce junto com os botões.
	# O log tem sempre uma linha (board-battle/09).
	var gap := _bottom.get_theme_constant(&"separation")
	_bottom.custom_minimum_size.y = _log_box.get_combined_minimum_size().y + _player_card.get_combined_minimum_size().y + tallest + gap * 2


## O tabuleiro inteiro cabe na área, centrado, sem passar do tamanho dos
## hexágonos do tabuleiro antigo, de 6 colunas: o dono achou maior grande demais.
func _fit_board() -> void:
	var board_size := _board.board_size()
	if board_size == Vector2.ZERO:
		return
	var area := _board_area.size
	var ratio := minf(minf(area.x / board_size.x, area.y / board_size.y), area.x / REFERENCE_BOARD_WIDTH)
	# Antes de a coluna ter tamanho, não há onde pôr o tabuleiro.
	if ratio <= 0.0:
		return
	var slot := _board_layer.get_global_transform().affine_inverse() * _board_area.get_global_rect()
	_board.scale = Vector2.ONE * ratio
	_board.size = board_size
	_board.position = slot.position + (area - board_size * ratio) / 2.0
	_board.cover_screen()


# --- Mostrar a resposta --------------------------------------------------------

## Mostra os eventos um a um; no fim, a resposta do servidor manda em tudo.
func _show_turn(turn: BoardTurn) -> void:
	_set_busy(true)
	_incoming = turn.view
	_board.light([], Color.TRANSPARENT)
	_narrator.set_team_names(_team_names(turn.view))
	for event: Dictionary in turn.events:
		await _play_event(event)
	var destination := _narrator.describe_captured_to(turn.captured_to)
	if not destination.is_empty():
		_history.add_line(destination)
	_view = turn.view
	_sync_board()
	match _view.phase:
		"choose_action":
			_begin_vez()
		"choose_next":
			_begin_entries()
		"ended":
			_show_controls(false)
			await _celebrate(turn.progression)
			_show_exit(RESULT_TEXTS.get(_view.result, ""), true)


func _play_event(event: Dictionary) -> void:
	var type := DictFields.get_string(event, "type")
	var side := DictFields.get_string(event, "side")
	var key := "%s:%d" % [side, DictFields.get_int(event, "position")]
	if type == "capture_attempted":
		# O evento não tem lado: `target` é a vaga do selvagem.
		side = "enemy"
		key = "enemy:%d" % DictFields.get_int(event, "target")
	match type:
		"capture_attempted":
			var item := GameData.get_item(DictFields.get_id(event, "item_id"))
			await _capture_overlay.play(item, _species.get(key, 0), DictFields.get_bool(event, "success"))
		"creature_entered":
			_enter(key, side, event)
		"vez_started":
			_attacker_key = ""
			_attack_skill_id = -1
			_board.set_active(key)
			_focus(side, key)
		"moved":
			var path := _path_of(event)
			if not path.is_empty() and _board.has_token(key) and _board.token_cell(key) != path[-1]:
				await _board.walk(key, path)
		"skill_used":
			# Quem ataca treme, com a área acesa (board-battle/09).
			_attacker_key = key
			_attack_skill_id = DictFields.get_id(event, "skill_id")
			var area := _cells_of(DictFields.get_array(event, "cells"))
			_board.light(area, UiPalette.BOARD_AREA)
			await _board.attack_shake(key)
			_board.light([], Color.TRANSPARENT)
		"fainted":
			_board.fade(key)
		"creature_left":
			# O selvagem derrotado deixa uma moeda; o capturado já entrou na Esfera.
			var defeated: bool = side == "enemy" and _hp.get(key, 1) <= 0
			await _board.vanish(key, defeated)
			_refresh_cards()
		"mark_placed":
			_marks[BoardBattleView.cell_of(DictFields.get_dict(event, "cell"))] = DictFields.get_int(event, "ground_effect_id")
			_refresh_marks()
		"mark_ended":
			_marks.erase(BoardBattleView.cell_of(DictFields.get_dict(event, "cell")))
			_refresh_marks()
		"item_used":
			_update_team_hp(DictFields.get_int(event, "team_index"), DictFields.get_int(event, "hp"))
	if type in HP_EVENTS and _board.has_token(key):
		# O golpe (board-battle/09): o efeito da Técnica no alvo, o alvo treme e pisca
		# com a barra caindo, e o número sobe sem a sequência esperar por ele.
		if type == "damage":
			await _play_skill_effect(key)
		_hp[key] = DictFields.get_int(event, "hp")
		_board.set_hp(key, _hp[key], _max_hp.get(key, 0))
		_focus(side, key)
		var amount := DictFields.get_int(event, "amount") if type == "ground_damage" or type == "healed" else DictFields.get_int(event, "damage")
		if type in LOSS_EVENTS:
			_play_hit_sound(_hit_kind(type, event))
			await _board.hit(key)
			_board.float_number(key, "-%d" % amount, UiPalette.DANGER)
		else:
			_board.float_number(key, "+%d" % amount, UiPalette.HP_HIGH)
	var line := _line_for(type, side, key, event)
	if not line.is_empty():
		_history.add_line(line)
		if type in HISTORY_ONLY:
			return
		await _type_line(line)
		await get_tree().create_timer(EVENT_DELAY).timeout


## O som e o efeito da Técnica do golpe atual sobre o alvo, com o efeito espelhado
## se o atacante estiver à direita. Cada um só existe se o arquivo dele existir.
func _play_skill_effect(target_key: String) -> void:
	if _attack_skill_id < 0:
		return
	var skill := GameData.get_skill(_attack_skill_id)
	if skill == null:
		return
	var sound_path := ContentFiles.SKILL_SOUND_PATH % skill.slug
	if ResourceLoader.exists(sound_path):
		_skill_sound.stream = load(sound_path) as AudioStream
		_skill_sound.play()
	var path := ContentFiles.SKILL_EFFECT_PATH % skill.slug
	if not ResourceLoader.exists(path):
		return
	var from: Variant = _board.token_position(_attacker_key)
	var to: Variant = _board.token_position(target_key)
	var mirrored: bool = from != null and to != null and (from as Vector2).x > (to as Vector2).x
	await _board.play_effect(target_key, load(path) as Texture2D, mirrored)


## O tipo do som de dano: a efetividade da Técnica, ou normal para o dano que não
## vem de uma (recuo, estado, chão e confusão).
func _hit_kind(type: String, event: Dictionary) -> String:
	if type != "damage":
		return "normal"
	var multiplier := DictFields.get_float(event, "multiplier", 1.0)
	if multiplier > 1.0:
		return "super"
	if multiplier < 1.0:
		return "weak"
	return "normal"


func _play_hit_sound(kind: String) -> void:
	var path := ContentFiles.HIT_SOUND_PATH % kind
	if ResourceLoader.exists(path):
		_hit_sound.stream = load(path) as AudioStream
		_hit_sound.play()


## Escreve a frase no log letra por letra; termina com ela inteira (board-battle/09).
## Espera um timer, e não o Tween, para nunca ficar presa se o Tween for trocado.
func _type_line(text: String) -> void:
	if _typing != null:
		_typing.kill()
	_more_icon.visible = false
	_last_line = text
	_message.text = text
	_message.visible_characters = 0
	var count := _message.get_total_character_count()
	var seconds := count / CHARS_PER_SECOND
	_typing = create_tween()
	_typing.tween_property(_message, ^"visible_characters", count, seconds)
	await get_tree().create_timer(seconds).timeout
	_message.visible_characters = -1
	# A frase terminou: o triângulo avisa que a luta continua.
	_more_icon.visible = true


func _enter(key: String, side: String, event: Dictionary) -> void:
	var species_id := DictFields.get_int(event, "species_id")
	var team_index := DictFields.get_int(event, "team_index")
	var display_name := GameData.get_species(species_id).name
	if side == "player" and _incoming != null and team_index < _incoming.team.size():
		display_name = _player_name(_incoming.team[team_index])
	_names[key] = display_name
	_species[key] = species_id
	_max_hp[key] = DictFields.get_int(event, "max_hp")
	_level[key] = DictFields.get_int(event, "level")
	_hp[key] = DictFields.get_int(event, "hp")
	_team_index[key] = team_index
	var cell := BoardBattleView.cell_of(DictFields.get_dict(event, "cell"))
	_board.place(key, side, species_id, _hp[key], _max_hp[key], cell)
	_refresh_cards()


## O texto do evento, com o nome de quem o sofre; vazio sem linha.
func _line_for(type: String, side: String, key: String, event: Dictionary) -> String:
	var who: String = _names.get(key, "")
	if BOARD_LINES.has(type):
		return BOARD_LINES[type] % who
	match type:
		"round_started":
			return "Rodada %d." % DictFields.get_int(event, "round")
		"mark_placed":
			return "%s!" % GameData.get_ground_effect(DictFields.get_int(event, "ground_effect_id")).name
		"coins_gained":
			var species := GameData.get_species(DictFields.get_int(event, "species_id"))
			return "Você recebeu %d moedas por derrotar %s." % [DictFields.get_int(event, "amount"), species.name]
		"coins_lost":
			return "Você perdeu %d moedas." % DictFields.get_int(event, "amount")
		"vez_started", "mark_ended", "creature_left":
			return ""
	if side == "player" or side == "enemy":
		_narrator.set_side_name(side, who)
	return _narrator.describe(event)


## No fim da resposta, a tela fica igual ao estado do servidor.
func _sync_board() -> void:
	var present: Dictionary[String, bool] = {}
	for slot: int in _view.player_cells:
		var creature := _view.player_at(slot)
		if creature != null:
			_sync_token("player:%d" % slot, "player", creature, _view.player_cells[slot], _view.player_actives[slot])
			present["player:%d" % slot] = true
	for slot: int in _view.enemy_cells:
		if _view.enemies.has(slot):
			_sync_token("enemy:%d" % slot, "enemy", _view.enemies[slot], _view.enemy_cells[slot], -1)
			present["enemy:%d" % slot] = true
	for key: String in _names.keys():
		if not present.has(key):
			_board.remove(key)
			_names.erase(key)
	_marks.clear()
	for mark: GroundMark in _view.marks:
		_marks[mark.cell] = mark.ground_effect_id
	_refresh_marks()
	var current := _view.current()
	_board.set_active(current.key() if current != null else "")
	if current != null:
		_player_focus = current.key()
	_refresh_cards()


func _sync_token(key: String, side: String, creature: BattleCreature, cell: Vector2i, team_index: int) -> void:
	var display_name := _player_name(creature) if side == "player" else GameData.get_species(creature.species_id).name
	var same: bool = _board.has_token(key) and _species.get(key, -1) == creature.species_id and _names.get(key, "") == display_name
	if not same:
		_names[key] = display_name
		_species[key] = creature.species_id
		_team_index[key] = team_index
		_board.place(key, side, creature.species_id, creature.hp, creature.max_hp, cell)
	elif _board.token_cell(key) != cell:
		_board.snap(key, cell)
	_max_hp[key] = creature.max_hp
	_level[key] = creature.level
	_hp[key] = creature.hp
	_board.set_hp(key, creature.hp, creature.max_hp)


## Quem joga ou sofre algo passa a aparecer no cartão do lado dele.
func _focus(side: String, key: String) -> void:
	if side == "enemy":
		_enemy_focus = key
	elif side == "player":
		_player_focus = key
	_refresh_cards()


## Cada cartão mostra quem está em foco; sem ele no tabuleiro, o primeiro do lado.
func _refresh_cards() -> void:
	_enemy_focus = _focus_or_first(_enemy_focus, "enemy:")
	_player_focus = _focus_or_first(_player_focus, "player:")
	_show_card(_enemy_card, _enemy_focus)
	_show_card(_player_card, _player_focus)


func _focus_or_first(focus: String, prefix: String) -> String:
	if _board.has_token(focus):
		return focus
	var found := ""
	for key: String in _names:
		if key.begins_with(prefix) and _board.has_token(key) and (found.is_empty() or key < found):
			found = key
	return found


func _show_card(card: BoardCreatureCard, key: String) -> void:
	if key.is_empty() or not _species.has(key):
		card.clear()
		return
	card.set_creature(_species[key], _names[key], _level.get(key, 1), _hp.get(key, 0), _max_hp.get(key, 0))


func _refresh_marks() -> void:
	var colors: Dictionary[Vector2i, Color] = {}
	for cell: Vector2i in _marks:
		var color := GameData.get_ground_effect(_marks[cell]).color
		color.a = 0.55
		colors[cell] = color
	_board.set_marks(colors)


func _update_team_hp(team_index: int, hp: int) -> void:
	for key: String in _team_index:
		if key.begins_with("player:") and _team_index[key] == team_index:
			_hp[key] = hp
			_board.set_hp(key, hp, _max_hp.get(key, 0))
	_refresh_cards()


# --- A vez do jogador ----------------------------------------------------------

func _begin_vez() -> void:
	var current := _view.current()
	if current == null or not current.is_player() or not _view.player_cells.has(current.position):
		return
	_actor = current.position
	_player_focus = current.key()
	_refresh_cards()
	_origin = _view.player_cells[_actor]
	_moved = false
	_skill_slot = 0
	_sphere_item = -1
	_disarm_flee()
	var blocked := _view.occupied_cells()
	blocked.erase(_origin)
	_reach = BoardGeometry.reachable(_view.board_cells, blocked, _origin)
	_fill_skills(_view.player_at(_actor))
	_light_reach()
	_show_message("")
	_show_controls(true)
	_set_busy(false)


func _fill_skills(creature: BattleCreature) -> void:
	var has_pp := false
	for index: int in SKILL_SLOTS:
		var slot: SkillSlot = creature.skills[index] if index < creature.skills.size() else null
		(_skills_grid.get_child(index) as BattleSkillButton).set_skill(slot)
		has_pp = has_pp or (slot != null and slot.current_pp > 0)
	_skills_grid.visible = has_pp
	_emergency_button.visible = not has_pp


func _here() -> Vector2i:
	return _destination if _moved else _origin


func _actor_key() -> String:
	return "player:%d" % _actor


func _light_reach() -> void:
	var cells: Array[Vector2i] = []
	cells.append_array(_reach.keys())
	if _moved:
		cells.append(_origin)
	_board.light(cells, UiPalette.BOARD_REACH)


func _on_cell_tapped(cell: Vector2i) -> void:
	if _busy or _walking or _view == null:
		return
	if _view.phase == "choose_next":
		_pick_entry_cell(cell)
		return
	if _view.phase != "choose_action":
		return
	_disarm_flee()
	if _sphere_item >= 0:
		if _targets.has(cell):
			_send({"type": "capture", "item_id": _sphere_item, "target": {"q": cell.x, "r": cell.y}})
			return
		_cancel_skill()
	if _skill_slot != 0:
		if _targets.has(cell):
			var action := {"type": "emergency"} if _skill_slot == -1 else {"type": "skill", "slot": _skill_slot}
			action["target"] = {"q": cell.x, "r": cell.y}
			_send(action)
			return
		_cancel_skill()
	if cell == _here():
		return
	if cell == _origin:
		_board.snap(_actor_key(), _origin)
		_moved = false
		_light_reach()
	elif _reach.has(cell):
		_step_to(cell)


## Anda sem pedir nada ao servidor: o passo só vai junto com a ação.
func _step_to(cell: Vector2i) -> void:
	_walking = true
	_board.light([], Color.TRANSPARENT)
	_board.snap(_actor_key(), _origin)
	var path: Array[Vector2i] = []
	path.assign(_reach[cell])
	await _board.walk(_actor_key(), path)
	_moved = true
	_destination = cell
	_walking = false
	_light_reach()


## Tocar numa Técnica acende os alvos; tocar de novo desliga. A Técnica em si
## mesmo vai direto, sem alvo.
func _choose_skill(slot: int) -> void:
	if _busy or _walking:
		return
	_disarm_flee()
	if _skill_slot == slot:
		_cancel_skill()
		return
	_sphere_item = -1
	_show_message("")
	var foes: Array[Vector2i] = []
	foes.append_array(_view.enemy_cells.values())
	if slot == -1:
		_skill_slot = -1
		_targets.clear()
		for foe: Vector2i in foes:
			if BoardGeometry.distance(_here(), foe) <= EMERGENCY_RANGE:
				_targets.append(foe)
	else:
		var skill := GameData.get_skill(_view.player_at(_actor).skills[slot - 1].skill_id)
		if GameData.get_row("skill_targets", skill.skill_target_id).get("slug", "") == "self":
			_send({"type": "skill", "slot": slot})
			return
		_skill_slot = slot
		_targets = BoardGeometry.targets(skill, _view.board_cells, foes, _here())
	_board.light(_targets, UiPalette.BOARD_TARGET)


func _cancel_skill() -> void:
	if _sphere_item >= 0:
		_show_message("")
	_skill_slot = 0
	_sphere_item = -1
	_targets.clear()
	_light_reach()


## Atacar troca os botões pelas Técnicas; Voltar desfaz.
func _open_skills() -> void:
	if not _can_choose():
		return
	_disarm_flee()
	_cancel_skill()
	_actions_row.hide()
	_skills_box.show()


func _close_skills() -> void:
	if _skill_slot != 0:
		_cancel_skill()
	_skills_box.hide()
	_actions_row.show()


func _wait() -> void:
	_disarm_flee()
	_send({"type": "wait"})


## As ações do painel de baixo só valem na vez de um Ecobeast do jogador.
func _can_choose() -> bool:
	return not _busy and not _walking and _view != null and _view.phase == "choose_action" and _actor >= 0


func _open_bag() -> void:
	if not _can_choose():
		return
	_disarm_flee()
	_cancel_skill()
	_items_panel.open(_view.items, _view.team, _team_names(_view))


## Um item de cura serve para qualquer um da equipe, e gasta a vez.
func _use_item(item_id: int, team_index: int) -> void:
	_items_panel.close()
	_send({"type": "item", "item_id": item_id, "team_index": team_index})


## A Esfera pede o selvagem: todos acendem, a qualquer distância.
func _aim_sphere(item_id: int) -> void:
	_items_panel.close()
	_skill_slot = 0
	_sphere_item = item_id
	_targets.clear()
	_targets.append_array(_view.enemy_cells.values())
	_board.light(_targets, UiPalette.BOARD_TARGET)
	_show_message(PICK_SPHERE_TEXT)


## A troca está sem botão: o dono tirou o Trocar do pé da tela e ainda vai decidir
## onde ele fica (board-battle/08).
func _open_switch() -> void:
	if not _can_choose():
		return
	_disarm_flee()
	_cancel_skill()
	_next_panel.open(_view.team, _team_names(_view), _view.player_actives[_actor], true)


## O mesmo painel serve à troca e à escolha depois de uma queda.
func _on_creature_chosen(team_index: int) -> void:
	if _view == null:
		return
	if _view.phase == "choose_next":
		_on_entry_chosen(team_index)
		return
	var creature := _view.team[team_index]
	if creature.hp <= 0 or _view.player_actives.has(team_index):
		_next_panel.show_error(CANNOT_ENTER_TEXT)
		return
	_next_panel.close()
	_send({"type": "switch", "team_index": team_index})


## O servidor recusa andar e fugir juntos: depois de andar, o primeiro toque
## avisa, e o segundo desfaz o passo e foge.
func _flee() -> void:
	if not _can_choose():
		return
	_cancel_skill()
	if _moved and not _flee_armed:
		_flee_armed = true
		_flee_button.text = FLEE_CONFIRM_TEXT
		_show_message(FLEE_UNDO_TEXT)
		return
	_disarm_flee()
	if _moved:
		_board.snap(_actor_key(), _origin)
		_moved = false
	_send({"type": "flee"})


func _disarm_flee() -> void:
	_flee_armed = false
	_flee_button.text = FLEE_TEXT
	if _message.text == FLEE_UNDO_TEXT:
		_show_message("")


## Alguém da equipe de pé e fora do tabuleiro, para a troca.
func _has_reserve() -> bool:
	if _view == null:
		return false
	for index: int in _view.team.size():
		if _view.team[index].hp > 0 and not _view.player_actives.has(index):
			return true
	return false


## A vez vai ao servidor; uma recusa devolve o Ecobeast para onde estava.
func _send(action: Dictionary) -> void:
	if _busy or _walking:
		return
	var body := {"position": _actor, "action": action}
	if _moved:
		body["move"] = {"q": _destination.x, "r": _destination.y}
	_set_busy(true)
	_board.light([], Color.TRANSPARENT)
	var result: Result = await Session.board_action(body)
	if not result.ok:
		_board.snap(_actor_key(), _origin)
		_begin_vez()
		_show_message(result.error)
		return
	if result.data == null:
		_show_battle_gone()
		return
	await _show_turn(result.data)


# --- Quem entra depois de uma queda --------------------------------------------

func _begin_entries() -> void:
	_entries.clear()
	_ask_entry()


func _ask_entry() -> void:
	_entry_team = -1
	_board.light([], Color.TRANSPARENT)
	_set_busy(false)
	_next_panel.open(_view.team, _team_names(_view))


func _on_entry_chosen(team_index: int) -> void:
	if _view == null or _view.phase != "choose_next":
		return
	var creature := _view.team[team_index]
	var taken := _view.player_actives.has(team_index) or _entries.any(func(entry: Dictionary) -> bool: return entry["team_index"] == team_index)
	if creature.hp <= 0 or taken:
		_next_panel.show_error(CANNOT_ENTER_TEXT)
		return
	_next_panel.close()
	_entry_team = team_index
	_show_message(PICK_ENTRY_TEXT)
	_board.light(_free_entry_cells(), UiPalette.BOARD_TARGET)


func _free_entry_cells() -> Array[Vector2i]:
	var free: Array[Vector2i] = []
	for cell: Vector2i in _view.entry_cells:
		if not _entries.any(func(entry: Dictionary) -> bool: return entry["cell"] == {"q": cell.x, "r": cell.y}):
			free.append(cell)
	return free


func _pick_entry_cell(cell: Vector2i) -> void:
	if _entry_team < 0 or not _free_entry_cells().has(cell):
		return
	_entries.append({
		"position": _view.pending_positions[_entries.size()],
		"team_index": _entry_team,
		"cell": {"q": cell.x, "r": cell.y},
	})
	_show_message("")
	if _entries.size() < _view.pending_positions.size():
		_ask_entry()
		return
	_set_busy(true)
	_board.light([], Color.TRANSPARENT)
	var result: Result = await Session.board_action({"entries": _entries})
	if not result.ok:
		_show_message(result.error)
		_begin_entries()
		return
	if result.data == null:
		_show_battle_gone()
		return
	await _show_turn(result.data)


# --- Fim da luta ---------------------------------------------------------------

## Como na luta de hoje (progression/03 e 04): cada um que subiu de nível ganha
## a comemoração, a evolução, os avisos de Técnica aprendida e as escolhas.
func _celebrate(progression: Array[CreatureProgress]) -> void:
	for progress: CreatureProgress in progression:
		if not progress.leveled_up():
			continue
		var creature: BattleCreature = _view.team[progress.team_index]
		var display_name := _player_name(creature)
		await _level_up_overlay.play(progress, creature.species_id, display_name)
		var learned := progress.learned_skill_ids
		var pending := progress.pending_skill_ids
		var known := _known_skills(progress.uid, learned)
		if progress.evolution_species_id >= 0:
			var evolved := await _evolution_overlay.play(
				progress.uid, creature.species_id, progress.evolution_species_id, display_name
			)
			if evolved == null:
				continue
			var species := GameData.get_species(evolved.creature.species_id)
			display_name = evolved.creature.display_name(species)
			learned = evolved.learned_skill_ids
			pending = evolved.pending_skill_ids
			known = evolved.creature.skills
		for skill_id: int in learned:
			await _skill_overlay.play_learned(display_name, skill_id)
		for skill_id: int in pending:
			var chosen := await _skill_overlay.play_choice(progress.uid, display_name, skill_id, known)
			if chosen != null:
				known = chosen.creature.skills


func _known_skills(uid: String, learned: Array[int]) -> Array[SkillSlot]:
	var known: Array[SkillSlot] = []
	var party_creature := _party_creature(uid)
	if party_creature != null:
		known.append_array(party_creature.skills)
	for skill_id: int in learned:
		known.append(SkillSlot.create(skill_id, GameData.get_skill(skill_id).max_pp))
	return known


func _show_battle_gone() -> void:
	_history.add_line(GONE_TEXT)
	_show_exit(GONE_TEXT, true)


## Só a saída. `needs_reload`: a luta chegou a existir, e o jogador é relido.
func _show_exit(text: String, needs_reload: bool) -> void:
	_needs_reload = needs_reload
	_board.light([], Color.TRANSPARENT)
	_result_label.text = text
	_result_label.visible = not text.is_empty()
	_show_controls(false)
	_result_box.show()


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


# --- Ajudantes -----------------------------------------------------------------

func _set_busy(busy: bool) -> void:
	_busy = busy
	_attack_button.disabled = busy
	_wait_button.disabled = busy
	_emergency_button.disabled = busy
	_bag_button.disabled = busy
	_flee_button.disabled = busy or _view == null or not _view.can_flee
	for button: Node in _skills_grid.get_children():
		if busy:
			(button as Button).disabled = true
	if not busy and _actor >= 0 and _view != null and _view.player_at(_actor) != null:
		_fill_skills(_view.player_at(_actor))


func _show_controls(playing: bool) -> void:
	_actions_row.visible = playing
	_skills_box.visible = false
	_result_box.visible = false


## O caminho do evento `moved`, sem a origem.
func _path_of(event: Dictionary) -> Array[Vector2i]:
	return _cells_of(DictFields.get_array(event, "path"))


func _cells_of(items: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for item: Variant in items:
		if item is Dictionary:
			cells.append(BoardBattleView.cell_of(item))
	return cells


## A criatura do jogador com esse uid, ou null.
func _party_creature(uid: String) -> CreatureInstance:
	if Session.player == null:
		return null
	for creature: CreatureInstance in Session.player.party:
		if creature.uid == uid:
			return creature
	return null


func _player_name(creature: BattleCreature) -> String:
	var species := GameData.get_species(creature.species_id)
	var party_creature := _party_creature(creature.uid)
	return party_creature.display_name(species) if party_creature != null else species.name


func _team_names(view: BoardBattleView) -> Array[String]:
	var names: Array[String] = []
	for creature: BattleCreature in view.team:
		names.append(_player_name(creature))
	return names
