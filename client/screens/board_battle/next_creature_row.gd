class_name NextCreatureRow
extends Button

var _creature: BattleCreature = null
var _display_name: String = ""
var _is_in_field: bool = false

@onready var _portrait: CreaturePortrait = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _hp_bar: HpBar = %HpBar


func _ready() -> void:
	_refresh()


func set_creature(creature: BattleCreature, display_name: String, is_in_field: bool = false) -> void:
	_creature = creature
	_display_name = display_name
	_is_in_field = is_in_field
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if _creature == null:
		return
	disabled = _creature.hp == 0 or _is_in_field
	_portrait.set_species(_creature.species_id)
	_name_label.text = _display_name
	_level_label.text = "Nv. %d" % _creature.level
	_hp_bar.set_hp(_creature.hp, _creature.max_hp)
