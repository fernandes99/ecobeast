extends Control

const RowScene := preload("res://screens/heal_station/heal_creature_row.tscn")

const HEAL_TEXT := "Curar todos"
const HEALING_TEXT := "Curando..."
const ALREADY_HEALED_TEXT := "Equipe já curada"
const HEALED_MESSAGE := "Equipe curada!"
const NO_STATUS := -1

var _healing: bool = false

@onready var _team_list: VBoxContainer = %TeamList
@onready var _message: Label = %Message
@onready var _heal_button: Button = %HealButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_heal_button.pressed.connect(_heal)
	_back_button.pressed.connect(Router.back)
	_refresh()


func handle_back() -> bool:
	return _healing


func _heal() -> void:
	_healing = true
	_message.hide()
	_heal_button.text = HEALING_TEXT
	_heal_button.disabled = true
	_back_button.disabled = true
	var result: Result = await Session.heal_team()
	_healing = false
	_back_button.disabled = false
	_refresh()
	if result.ok:
		_show_message(HEALED_MESSAGE, &"BoldLabel")
	else:
		_show_message(result.error, &"DangerLabel")


func _refresh() -> void:
	var player := Session.player
	# Sem jogador só se o progresso foi apagado em outro aparelho.
	if player == null:
		return
	for row: Node in _team_list.get_children():
		row.queue_free()
	var needs_healing := false
	for creature: CreatureInstance in player.party:
		var row: HealCreatureRow = RowScene.instantiate()
		row.set_creature(creature)
		_team_list.add_child(row)
		needs_healing = needs_healing or _needs_healing(creature)
	_heal_button.text = HEAL_TEXT if needs_healing else ALREADY_HEALED_TEXT
	_heal_button.disabled = not needs_healing


func _show_message(text: String, variation: StringName) -> void:
	_message.text = text
	_message.theme_type_variation = variation
	_message.show()


static func _needs_healing(creature: CreatureInstance) -> bool:
	if creature.current_hp < creature.stats.hp or creature.status_condition_id != NO_STATUS:
		return true
	for slot: SkillSlot in creature.skills:
		if slot.current_pp < GameData.get_skill(slot.skill_id).max_pp:
			return true
	return false
