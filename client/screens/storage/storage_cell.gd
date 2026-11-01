class_name StorageCell
extends TapPanel
## Um Ecobeast na grade do Santuário (team-and-storage/02, RF-03).

var creature: CreatureInstance = null

@onready var _portrait: CreaturePortrait = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _hp_bar: HpBar = %HpBar


func _ready() -> void:
	var species := GameData.get_species(creature.species_id)
	_portrait.set_species(species.id)
	_name_label.text = creature.display_name(species)
	_level_label.text = "Nv. %d" % creature.level
	_hp_bar.set_hp(creature.current_hp, creature.stats.hp)
