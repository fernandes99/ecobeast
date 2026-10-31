class_name NextCreatureRow
extends Button
## Uma criatura no painel do próximo Ecobeast (battle-screen/03, RF-22 e RF-23).
## Com 0 HP, fica desativada.

var _creature: BattleCreature = null
var _display_name: String = ""

@onready var _portrait: CreaturePortrait = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _hp_bar: HpBar = %HpBar


func _ready() -> void:
	_refresh()


## Pode ser chamado antes ou depois de o componente entrar na árvore.
func set_creature(creature: BattleCreature, display_name: String) -> void:
	_creature = creature
	_display_name = display_name
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if _creature == null:
		return
	disabled = _creature.hp == 0
	_portrait.set_species(_creature.species_id)
	_name_label.text = _display_name
	_level_label.text = "Nv. %d" % _creature.level
	_hp_bar.set_hp(_creature.hp, _creature.max_hp)
