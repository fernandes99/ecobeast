class_name HealCreatureRow
extends PanelContainer

const NO_STATUS := -1

var _creature: CreatureInstance = null

@onready var _portrait: CreaturePortrait = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _hp_bar: HpBar = %HpBar
@onready var _detail_label: Label = %DetailLabel


func _ready() -> void:
	_refresh()


func set_creature(creature: CreatureInstance) -> void:
	_creature = creature
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if _creature == null:
		return
	var species := GameData.get_species(_creature.species_id)
	_portrait.set_species(species.id)
	_name_label.text = _creature.display_name(species)
	_level_label.text = "Nv. %d" % _creature.level
	_hp_bar.set_hp(_creature.current_hp, _creature.stats.hp)
	_detail_label.text = _detail_text()


func _detail_text() -> String:
	var current_pp := 0
	var max_pp := 0
	for slot: SkillSlot in _creature.skills:
		current_pp += slot.current_pp
		max_pp += GameData.get_skill(slot.skill_id).max_pp
	var text := "PP %d/%d" % [current_pp, max_pp]
	if _creature.status_condition_id != NO_STATUS:
		var status: Dictionary = GameData.catalog.get_row("status_conditions", _creature.status_condition_id)
		text += " · %s" % status["name"]
	return text
