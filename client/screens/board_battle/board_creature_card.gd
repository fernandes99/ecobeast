class_name BoardCreatureCard
extends PanelContainer

const HpBarScene := preload("res://ui/components/hp_bar.tscn")
const ElementBadgeScene := preload("res://ui/components/element_badge.tscn")

const PORTRAIT_SIZE := 104
const NAME_FONT_SIZE := 26
const SMALL_FONT_SIZE := 18
const BAR_HEIGHT := 14
const XP_HEIGHT := 4
const LEVEL_BUMP := Vector2(1.25, 1.25)
const BUMP_TIME := 0.12

@export var is_enemy: bool = false

var _face := CreatureFace.new()
var _name_label := Label.new()
var _level_label := Label.new()
var _elements := HBoxContainer.new()
var _hp_bar: HpBar = null
var _hp_label := Label.new()
var _pill: PanelContainer = null
var _xp_line: XpLine = null


func _ready() -> void:
	theme_type_variation = BattleTheme.PANEL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	add_child(row)

	_face.face_size = PORTRAIT_SIZE
	_face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_face)

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
	_pill = PanelContainer.new()
	_pill.theme_type_variation = BattleTheme.PILL
	_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_level_label.theme_type_variation = &"BoldLabel"
	_level_label.add_theme_font_size_override(&"font_size", SMALL_FONT_SIZE)
	_pill.add_child(_level_label)
	title.add_child(_pill)

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
	var bars := VBoxContainer.new()
	bars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bars.add_theme_constant_override(&"separation", 3)
	hp_row.add_child(bars)
	_hp_bar = HpBarScene.instantiate()
	_hp_bar.bar_height = BAR_HEIGHT
	bars.add_child(_hp_bar)
	if not is_enemy:
		_xp_line = XpLine.new(XP_HEIGHT)
		bars.add_child(_xp_line)
	_hp_label.theme_type_variation = &"BoldLabel"
	_hp_label.add_theme_font_size_override(&"font_size", SMALL_FONT_SIZE)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info.add_child(_hp_label)


func set_creature(species_id: int, display_name: String, level: int, hp: int, max_hp: int) -> void:
	var species := GameData.get_species(species_id)
	_face.set_species(species_id)
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
	_face.set_hp(hp, max_hp)
	_hp_label.text = "%d / %d" % [hp, max_hp]


## Negativo esconde a linha, mas guarda o lugar dela.
func set_xp(ratio: float) -> void:
	if _xp_line == null:
		return
	_xp_line.modulate.a = 1.0 if ratio >= 0.0 else 0.0
	_xp_line.set_ratio(maxf(ratio, 0.0))


func fill_xp(ratio: float) -> void:
	if _xp_line == null:
		return
	_xp_line.modulate.a = 1.0
	await _xp_line.fill_to(ratio)


func level_up_to(level: int) -> void:
	if _xp_line == null:
		return
	_level_label.text = "Nv. %d" % level
	_pill.pivot_offset = _pill.size / 2.0
	var bump := create_tween()
	bump.tween_property(_pill, ^"scale", LEVEL_BUMP, BUMP_TIME)
	bump.tween_property(_pill, ^"scale", Vector2.ONE, BUMP_TIME)
	await _xp_line.flash()
	_xp_line.set_ratio(0.0)


func _element_badge(element_id: int) -> ElementBadge:
	var badge: ElementBadge = ElementBadgeScene.instantiate()
	badge.set_element(element_id)
	return badge
