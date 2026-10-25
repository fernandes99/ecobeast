class_name CreatureSlot
extends TapPanel
## Um lugar da equipe no Hub (visual-theme/02, RF-10 e RF-11): card vertical
## com a arte sobre a cor do primeiro Elemento e, numa faixa escura embaixo,
## nome, nível e HP; ou "Vazio", que não reage a toque.

const BORDER_WIDTH := 2
const CORNER_RADIUS := 12
## Quanto a cor do Elemento escurece no fundo do card.
const ELEMENT_DARKEN := 0.45
## Opacidade da faixa escura das informações.
const INFO_ALPHA := 0.85
## Opacidade do fundo do slot vazio.
const EMPTY_ALPHA := 0.5

var _creature: CreatureInstance = null

@onready var _content: VBoxContainer = %Content
@onready var _portrait: CreaturePortrait = %Portrait
@onready var _info: PanelContainer = %Info
@onready var _name_label: Label = %NameLabel
@onready var _element_dot: Panel = %ElementDot
@onready var _level_label: Label = %LevelLabel
@onready var _hp_label: Label = %HpLabel
@onready var _hp_bar: HpBar = %HpBar
@onready var _empty_label: Label = %EmptyLabel


func _ready() -> void:
	_empty_label.add_theme_color_override(&"font_color", UiPalette.TEXT_MUTED)
	var info_style := StyleBoxFlat.new()
	info_style.bg_color = _with_alpha(UiPalette.SURFACE, INFO_ALPHA)
	info_style.corner_radius_bottom_left = CORNER_RADIUS - BORDER_WIDTH
	info_style.corner_radius_bottom_right = CORNER_RADIUS - BORDER_WIDTH
	info_style.content_margin_left = 6
	info_style.content_margin_right = 6
	info_style.content_margin_top = 4
	info_style.content_margin_bottom = 6
	_info.add_theme_stylebox_override(&"panel", info_style)
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
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(CORNER_RADIUS)
	var is_empty := _creature == null
	# Vazio, o conteúdo continua no layout (transparente) para o slot ter o
	# mesmo tamanho dos ocupados.
	_content.modulate = Color.TRANSPARENT if is_empty else Color.WHITE
	_empty_label.visible = is_empty
	mouse_filter = MOUSE_FILTER_IGNORE if is_empty else MOUSE_FILTER_PASS
	mouse_default_cursor_shape = CURSOR_ARROW if is_empty else CURSOR_POINTING_HAND
	if is_empty:
		style.bg_color = _with_alpha(UiPalette.SURFACE_RAISED, EMPTY_ALPHA)
	else:
		var species := GameData.get_species(_creature.species_id)
		var element_color := GameData.get_element(species.element_ids[0]).color
		style.bg_color = element_color.darkened(ELEMENT_DARKEN)
		style.set_border_width_all(BORDER_WIDTH)
		style.border_color = element_color
		style.set_content_margin_all(BORDER_WIDTH)
		var dot := StyleBoxFlat.new()
		dot.bg_color = element_color
		dot.set_corner_radius_all(7)
		_element_dot.add_theme_stylebox_override(&"panel", dot)
		_portrait.set_species(species.id)
		_name_label.text = _creature.display_name(species)
		_level_label.text = "Nv. %d" % _creature.level
		_hp_label.text = "HP %d/%d" % [_creature.current_hp, _creature.stats.hp]
		_hp_bar.set_hp(_creature.current_hp, _creature.stats.hp)
	add_theme_stylebox_override(&"panel", style)


static func _with_alpha(color: Color, alpha: float) -> Color:
	var result := color
	result.a = alpha
	return result
