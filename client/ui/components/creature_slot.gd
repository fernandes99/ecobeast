class_name CreatureSlot
extends TapPanel
## Um lugar da equipe no Hub (hub/01, RF-06 e RF-07): retrato, nome, nível e
## HP da criatura, com a borda na cor do primeiro Elemento; ou "Vazio", que não
## reage a toque.

const BORDER_WIDTH := 3
const EMPTY_BORDER_WIDTH := 2
const CONTENT_MARGIN := 16

var _creature: CreatureInstance = null
## O estilo do tema, antes do override; base dos dois estados.
var _base_style: StyleBoxFlat

@onready var _content: VBoxContainer = %Content
@onready var _portrait: CreaturePortrait = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _hp_bar: HpBar = %HpBar
@onready var _empty_label: Label = %EmptyLabel


func _ready() -> void:
	_base_style = get_theme_stylebox(&"panel") as StyleBoxFlat
	_refresh()


## Pode ser chamado antes ou depois de o componente entrar na árvore.
func set_creature(creature: CreatureInstance) -> void:
	_creature = creature
	if is_node_ready():
		_refresh()


## Pode ser chamado antes ou depois de o componente entrar na árvore.
func set_empty() -> void:
	set_creature(null)


func _refresh() -> void:
	var style := _base_style.duplicate() as StyleBoxFlat
	style.set_content_margin_all(CONTENT_MARGIN)
	var is_empty := _creature == null
	# Vazio, o conteúdo continua no layout (transparente) para o slot ter o
	# mesmo tamanho dos ocupados.
	_content.modulate = Color.TRANSPARENT if is_empty else Color.WHITE
	_empty_label.visible = is_empty
	mouse_filter = MOUSE_FILTER_IGNORE if is_empty else MOUSE_FILTER_PASS
	mouse_default_cursor_shape = CURSOR_ARROW if is_empty else CURSOR_POINTING_HAND
	if is_empty:
		style.draw_center = false
		style.set_border_width_all(EMPTY_BORDER_WIDTH)
		style.border_color = UiPalette.BORDER
	else:
		var species := GameData.get_species(_creature.species_id)
		style.set_border_width_all(BORDER_WIDTH)
		style.border_color = GameData.get_element(species.element_ids[0]).color
		_portrait.set_species(species.id)
		_name_label.text = _creature.display_name(species)
		_level_label.text = "Nv. %d" % _creature.level
		_hp_bar.set_hp(_creature.current_hp, _creature.stats.hp)
	add_theme_stylebox_override(&"panel", style)
