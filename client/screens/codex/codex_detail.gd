class_name CodexDetail
extends Control

const ElementBadgeScene := preload("res://ui/components/element_badge.tscn")
const CreaturePortraitScene := preload("res://ui/components/creature_portrait.tscn")

const NUMBER_TEXT := "#%03d"
const UNKNOWN_TEXT := "???"
const SEEN_HINT_TEXT := "Capture um %s para ver os dados dele."
const NO_HABITAT_TEXT := "Desconhecido"
const HEIGHT_TEXT := "%s m"
const WEIGHT_TEXT := "%s kg"
const LEVEL_TEXT := "nv. %d"
const ARROW_TEXT := "›"
const LINE_PORTRAIT_SIZE := 88
const LINE_NAME_FONT_SIZE := 18

var _codex: Codex = null

@onready var _background: ColorRect = %Background
@onready var _number_label: Label = %NumberLabel
@onready var _scroll: ScrollContainer = %Scroll
@onready var _portrait: CreaturePortrait = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _element_row: HBoxContainer = %ElementRow
@onready var _seen_hint: Label = %SeenHint
@onready var _caught_info: VBoxContainer = %CaughtInfo
@onready var _description_label: Label = %DescriptionLabel
@onready var _height_label: Label = %HeightLabel
@onready var _weight_label: Label = %WeightLabel
@onready var _habitat_label: Label = %HabitatLabel
@onready var _line_row: HFlowContainer = %LineRow
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_background.color = UiPalette.BACKGROUND
	_back_button.pressed.connect(close)
	hide()


func open(species_id: int, codex: Codex) -> void:
	_codex = codex
	_show(species_id)
	show()


func close() -> void:
	hide()


func _show(species_id: int) -> void:
	var species := GameData.get_species(species_id)
	var caught := _codex.status(species_id) == Codex.Status.CAUGHT
	_number_label.text = NUMBER_TEXT % species_id
	_portrait.set_silhouette(not caught)
	_portrait.set_species(species_id)
	_name_label.text = species.name
	_seen_hint.text = SEEN_HINT_TEXT % species.name
	_seen_hint.visible = not caught
	_element_row.visible = caught
	_caught_info.visible = caught
	if caught:
		_show_elements(species)
		_description_label.text = species.description
		_height_label.text = HEIGHT_TEXT % _decimal(species.height_m)
		_weight_label.text = WEIGHT_TEXT % _decimal(species.weight_kg)
		var habitat := GameData.get_habitat_names(species_id)
		_habitat_label.text = ", ".join(habitat) if not habitat.is_empty() else NO_HABITAT_TEXT
		_show_line(species_id)
	_scroll.scroll_vertical = 0


func _show_elements(species: CreatureSpecies) -> void:
	_clear(_element_row)
	for element_id: int in species.element_ids:
		var badge: ElementBadge = ElementBadgeScene.instantiate()
		badge.set_element(element_id)
		_element_row.add_child(badge)


func _decimal(value: float) -> String:
	return ("%.1f" % value).replace(".", ",")


func _show_line(current_id: int) -> void:
	_clear(_line_row)
	for step: Dictionary in GameData.get_evolution_line(current_id):
		var rule: EvolutionRule = step["rule"]
		if rule != null:
			_line_row.add_child(_make_arrow(rule))
		_line_row.add_child(_make_form(step["species_id"], step["species_id"] == current_id))


func _make_arrow(rule: EvolutionRule) -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var arrow := _make_label(ARROW_TEXT, &"TitleLabel", 36)
	box.add_child(arrow)
	var condition := LEVEL_TEXT % rule.min_level if rule.trigger_slug == "level" and rule.min_level > 0 else ""
	box.add_child(_make_label(condition, &"SecondaryLabel", LINE_NAME_FONT_SIZE))
	return box


func _make_form(species_id: int, is_current: bool) -> Control:
	var status := _codex.status(species_id)
	var form := TapPanel.new()
	form.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", 2)
	form.add_child(box)
	if status == Codex.Status.UNKNOWN:
		var unknown := _make_label(UNKNOWN_TEXT, &"TitleLabel", 32)
		unknown.custom_minimum_size = Vector2(LINE_PORTRAIT_SIZE, LINE_PORTRAIT_SIZE)
		unknown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		unknown.add_theme_color_override(&"font_color", UiPalette.TEXT_MUTED)
		box.add_child(unknown)
		box.add_child(_make_label(UNKNOWN_TEXT, &"SecondaryLabel", LINE_NAME_FONT_SIZE))
		return form
	var portrait: CreaturePortrait = CreaturePortraitScene.instantiate()
	portrait.portrait_size = LINE_PORTRAIT_SIZE
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.set_silhouette(status == Codex.Status.SEEN)
	portrait.set_species(species_id)
	box.add_child(portrait)
	var name_label := _make_label(GameData.get_species(species_id).name, &"BoldLabel", LINE_NAME_FONT_SIZE)
	if is_current:
		name_label.add_theme_color_override(&"font_color", UiPalette.ACCENT)
	box.add_child(name_label)
	if not is_current:
		form.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		form.pressed.connect(_show.bind(species_id))
	return form


func _make_label(text: String, variation: StringName, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.add_theme_font_size_override(&"font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _clear(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
