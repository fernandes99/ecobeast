class_name BagTargetRow
extends Button
## Um Ecobeast na escolha do alvo (inventory-shop/03, RF-17). Fica ativo mesmo
## com 0 HP: a recusa do servidor explica o motivo.

var _creature: CreatureInstance = null

@onready var _portrait: CreaturePortrait = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _hp_bar: HpBar = %HpBar


func _ready() -> void:
	_refresh()


## Pode ser chamado antes ou depois de o componente entrar na árvore.
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
