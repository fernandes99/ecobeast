class_name SkillLearnOverlay
extends Control
## Técnicas novas depois da vitória (progression/04, TELAS.md #7): o aviso de
## quem aprendeu com vaga e, com as 4 ocupadas, a escolha de qual esquecer ou de
## não aprender. A escolha vai para o servidor depois da confirmação.

## A escolha do jogador: o id da Técnica esquecida, ou -1 para não aprender.
signal _picked(forget_skill_id: int)
## O "Sim" ou o "Não" da confirmação.
signal _answered(yes: bool)

const SkillButtonScene := preload("res://screens/battle/battle_skill_button.tscn")

const NO_CHOICE_TEXT := "Essa escolha não está mais disponível."

@onready var _dim: ColorRect = %Dim
@onready var _title: Label = %Title
@onready var _info: Label = %Info
@onready var _badge: ElementBadge = %Badge
@onready var _info_row: Control = %InfoRow
@onready var _choose_box: VBoxContainer = %ChooseBox
@onready var _known_list: VBoxContainer = %KnownList
@onready var _skip_button: Button = %SkipButton
@onready var _confirm_box: VBoxContainer = %ConfirmBox
@onready var _confirm_label: Label = %ConfirmLabel
@onready var _yes_button: Button = %YesButton
@onready var _no_button: Button = %NoButton
@onready var _error: Label = %Error
@onready var _retry_button: Button = %RetryButton
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	hide()
	_dim.color = UiPalette.OVERLAY
	_error.add_theme_color_override(&"font_color", UiPalette.DANGER)
	_skip_button.pressed.connect(func() -> void: _picked.emit(-1))
	_yes_button.pressed.connect(func() -> void: _answered.emit(true))
	_no_button.pressed.connect(func() -> void: _answered.emit(false))


## "<nome> aprendeu <Técnica>!". Só termina no "Continuar".
func play_learned(display_name: String, skill_id: int) -> void:
	_show_skill(skill_id)
	_title.text = "%s aprendeu %s!" % [display_name, GameData.get_skill(skill_id).name]
	_show_part(null)
	_show_footer(_continue_button)
	show()
	await _continue_button.pressed
	hide()


## A escolha de uma Técnica pendente. `known` são as 4 que ele sabe hoje.
## Devolve a resposta do servidor, ou null quando a escolha não existe mais.
func play_choice(uid: String, display_name: String, skill_id: int, known: Array[SkillSlot]) -> ProgressChoice:
	var new_name := GameData.get_skill(skill_id).name
	_show_skill(skill_id)
	_fill_known(known)
	_skip_button.text = "Não aprender %s" % new_name
	show()

	var forget_id := -1
	while true:
		_title.text = "%s quer aprender %s" % [display_name, new_name]
		_show_part(_choose_box)
		_show_footer(null)
		forget_id = await _picked
		_confirm_label.text = (
			"Não aprender %s?" % new_name
			if forget_id < 0
			else "Esquecer %s e aprender %s?" % [GameData.get_skill(forget_id).name, new_name]
		)
		_show_part(_confirm_box)
		var confirmed: bool = await _answered
		if confirmed:
			break

	_show_part(null)
	var choice := await _send(uid, skill_id, forget_id)
	if choice == null:
		_title.text = NO_CHOICE_TEXT
	elif forget_id < 0:
		_title.text = "%s não aprendeu %s." % [display_name, new_name]
	else:
		_title.text = "%s esqueceu %s e aprendeu %s!" % [display_name, GameData.get_skill(forget_id).name, new_name]
	_show_footer(_continue_button)
	await _continue_button.pressed
	hide()
	return choice


## O voltar do Android: na confirmação, é o "Não"; no resultado, o "Continuar".
func go_back() -> void:
	if _confirm_box.visible:
		_no_button.pressed.emit()
	elif _continue_button.visible:
		_continue_button.pressed.emit()


func _show_skill(skill_id: int) -> void:
	var skill := GameData.get_skill(skill_id)
	var category: String = GameData.get_row("skill_categories", skill.skill_category_id).get("name", "")
	var power := "—" if skill.power == 0 else str(skill.power)
	var accuracy := "—" if skill.accuracy == 0 else str(skill.accuracy)
	_badge.set_element(skill.element_id)
	_info.text = "%s · Poder %s · Precisão %s · PP %d" % [category, power, accuracy, skill.max_pp]
	_info_row.show()


func _fill_known(known: Array[SkillSlot]) -> void:
	for button: Node in _known_list.get_children():
		_known_list.remove_child(button)
		button.queue_free()
	for slot: SkillSlot in known:
		var button: BattleSkillButton = SkillButtonScene.instantiate()
		_known_list.add_child(button)
		button.set_skill(slot)
		# Uma Técnica sem PP também pode ser esquecida.
		button.disabled = false
		button.pressed.connect(func() -> void: _picked.emit(slot.skill_id))


## Tenta até o servidor responder: sem rede, mostra o erro e "Tentar de novo".
func _send(uid: String, skill_id: int, forget_id: int) -> ProgressChoice:
	var result: Result = await Session.learn_skill(uid, skill_id, forget_id)
	while not result.ok:
		_error.text = result.error
		_error.show()
		_show_footer(_retry_button)
		await _retry_button.pressed
		_error.hide()
		_show_footer(null)
		result = await Session.learn_skill(uid, skill_id, forget_id)
	return result.data


func _show_part(part: Control) -> void:
	for option: Control in [_choose_box, _confirm_box]:
		option.visible = option == part


func _show_footer(button: Button) -> void:
	for option: Button in [_retry_button, _continue_button]:
		option.visible = option == button
