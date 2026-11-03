class_name BattleSideCard
extends PanelContainer
## Um lado da batalha (battle-screen/03, RF-04 a RF-06). No inimigo, o retrato
## fica à direita e espelhado, e o HP aparece sem números e sem XP.

const ElementBadgeScene := preload("res://ui/components/element_badge.tscn")

## A ordem dos selos de estágio.
const STAGE_ORDER: Array[String] = ["atk", "def", "sp_atk", "sp_def", "spd", "accuracy", "evasion"]
const CONFUSION_SLUG := "confusion"
const CHIP_FONT_SIZE := 18
## Segundos para a barra de XP encher, a cada trecho. A revisar.
const XP_FILL_TIME := 0.8

@export var is_enemy: bool = false

var _creature: BattleCreature = null
var _display_name: String = ""
var _xp_ratio: float = 0.0

@onready var _row: HBoxContainer = %Row
@onready var _portrait: CreaturePortrait = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _tags: HFlowContainer = %Tags
@onready var _hp_bar: HpBar = %HpBar
@onready var _xp_bar: ProgressBar = %XpBar


func _ready() -> void:
	_portrait.flipped = is_enemy
	_hp_bar.show_numbers = not is_enemy
	_xp_bar.visible = not is_enemy
	if is_enemy:
		_row.move_child(_portrait, -1)
	_refresh()


## Pode ser chamado antes ou depois de o componente entrar na árvore.
func set_creature(creature: BattleCreature, display_name: String) -> void:
	_creature = creature
	_display_name = display_name
	if is_node_ready():
		_refresh()


func set_xp(ratio: float) -> void:
	_xp_ratio = ratio
	if is_node_ready():
		_xp_bar.value = ratio


## A barra enche até o XP novo. Quem subiu de nível enche até o fim, mostra o
## nível novo e recomeça do zero. Só termina quando a barra para.
func animate_xp(progress: CreatureProgress) -> void:
	if progress.leveled_up():
		await _fill_xp(1.0)
		_level_label.text = "Nv. %d" % progress.level_after
		_xp_bar.value = 0.0
	await _fill_xp(progress.xp_ratio())
	_xp_ratio = progress.xp_ratio()


func _fill_xp(ratio: float) -> void:
	var tween := create_tween()
	tween.tween_property(_xp_bar, "value", ratio, XP_FILL_TIME)
	await tween.finished


func _refresh() -> void:
	_xp_bar.value = _xp_ratio
	if _creature == null:
		return
	var species := GameData.get_species(_creature.species_id)
	_portrait.set_species(_creature.species_id)
	_name_label.text = _display_name
	_level_label.text = "Nv. %d" % _creature.level
	_hp_bar.set_hp(_creature.hp, _creature.max_hp)
	for tag: Node in _tags.get_children():
		_tags.remove_child(tag)
		tag.queue_free()
	for element_id: int in species.element_ids:
		var badge: ElementBadge = ElementBadgeScene.instantiate()
		badge.set_element(element_id)
		_tags.add_child(badge)
	if not _creature.status.is_empty():
		_add_chip(GameData.get_status_name(_creature.status), UiPalette.TEXT)
	if _creature.confused:
		_add_chip(GameData.get_status_name(CONFUSION_SLUG), UiPalette.TEXT)
	for slug: String in STAGE_ORDER:
		var stage: int = _creature.stages.get(slug, 0)
		if stage != 0:
			_add_chip(_stage_text(slug, stage), UiPalette.HP_HIGH if stage > 0 else UiPalette.WARNING)


## "Atq −1", "Vel +2".
func _stage_text(slug: String, stage: int) -> String:
	var short_name: String = GameData.get_row("stats", GameData.get_stat_id(slug))["short_name"]
	return "%s %s%d" % [short_name, "+" if stage > 0 else "−", absi(stage)]


func _add_chip(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"BoldLabel"
	label.add_theme_font_size_override(&"font_size", CHIP_FONT_SIZE)
	label.add_theme_color_override(&"font_color", color)
	var chip := PanelContainer.new()
	chip.theme_type_variation = &"ElementPill"
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(label)
	_tags.add_child(chip)
