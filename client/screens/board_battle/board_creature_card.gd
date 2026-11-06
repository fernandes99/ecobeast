class_name BoardCreatureCard
extends PanelContainer
## O cartão de um lado da luta no tabuleiro (board-battle/06, RF-05 e RF-06): o
## retrato, o nome, o nível numa pílula, os Elementos e o HP, no painel do tema da
## luta (board-battle/10). O do selvagem fica em cima, e o do jogador embaixo do
## tabuleiro. Monta os nós no código: só exibe.

const PortraitScene := preload("res://ui/components/creature_portrait.tscn")
const HpBarScene := preload("res://ui/components/hp_bar.tscn")
const ElementBadgeScene := preload("res://ui/components/element_badge.tscn")

const PORTRAIT_SIZE := 84
const NAME_FONT_SIZE := 26
const SMALL_FONT_SIZE := 18
const BAR_HEIGHT := 14

@export var is_enemy: bool = false

var _portrait: CreaturePortrait = null
var _name_label := Label.new()
var _level_label := Label.new()
var _elements := HBoxContainer.new()
var _hp_bar: HpBar = null
var _hp_label := Label.new()


func _ready() -> void:
	theme_type_variation = BattleTheme.PANEL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	add_child(row)

	_portrait = PortraitScene.instantiate()
	_portrait.portrait_size = PORTRAIT_SIZE
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_portrait)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override(&"separation", 2)
	row.add_child(info)

	var title := HBoxContainer.new()
	info.add_child(title)
	_name_label.theme_type_variation = &"BoldLabel"
	_name_label.add_theme_font_size_override(&"font_size", NAME_FONT_SIZE)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.clip_text = true
	title.add_child(_name_label)
	var pill := PanelContainer.new()
	pill.theme_type_variation = BattleTheme.PILL
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_level_label.theme_type_variation = &"BoldLabel"
	_level_label.add_theme_font_size_override(&"font_size", SMALL_FONT_SIZE)
	pill.add_child(_level_label)
	title.add_child(pill)

	_elements.add_theme_constant_override(&"separation", 6)
	info.add_child(_elements)
	# A fila guarda a altura de um selo desde já: o cartão vazio tem a mesma altura do
	# cheio, e o tabuleiro não muda de lugar (board-battle/08).
	var sample: ElementBadge = ElementBadgeScene.instantiate()
	_elements.add_child(sample)
	_elements.custom_minimum_size.y = sample.get_combined_minimum_size().y
	_elements.remove_child(sample)
	sample.queue_free()

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override(&"separation", 8)
	info.add_child(hp_row)
	var caption := Label.new()
	caption.text = "HP"
	caption.theme_type_variation = &"BoldLabel"
	caption.add_theme_font_size_override(&"font_size", SMALL_FONT_SIZE)
	hp_row.add_child(caption)
	_hp_bar = HpBarScene.instantiate()
	_hp_bar.bar_height = BAR_HEIGHT
	_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hp_row.add_child(_hp_bar)
	_hp_label.theme_type_variation = &"BoldLabel"
	_hp_label.add_theme_font_size_override(&"font_size", SMALL_FONT_SIZE)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info.add_child(_hp_label)


func set_creature(species_id: int, display_name: String, level: int, hp: int, max_hp: int) -> void:
	var species := GameData.get_species(species_id)
	_portrait.set_species(species_id)
	_name_label.text = display_name
	_level_label.text = "Nv. %d" % level
	for child: Node in _elements.get_children():
		_elements.remove_child(child)
		child.queue_free()
	for element_id: int in species.element_ids:
		_elements.add_child(_element_badge(element_id))
	set_hp(hp, max_hp)
	modulate.a = 1.0


## Sem Ecobeast, o cartão fica transparente, mas guarda o lugar, para o tabuleiro
## não mudar de lugar quando ele aparece (board-battle/08).
func clear() -> void:
	modulate.a = 0.0


func set_hp(hp: int, max_hp: int) -> void:
	_hp_bar.set_hp(hp, max_hp)
	_hp_label.text = "%d / %d" % [hp, max_hp]


func _element_badge(element_id: int) -> ElementBadge:
	var badge: ElementBadge = ElementBadgeScene.instantiate()
	badge.set_element(element_id)
	return badge
