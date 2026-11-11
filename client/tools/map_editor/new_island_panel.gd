class_name NewIslandPanel
extends VBoxContainer
## Ilha nova, no painel da esquerda do editor (map-editor/02): do zero (um
## hexágono de um raio) ou pelo gerador (a seed e os parâmetros dele). Gerar mostra
## a ilha no mapa sem gravar, quantas vezes for preciso; Criar grava.

## Uma ilha para mostrar no mapa, ainda sem gravar.
signal preview_ready(draft: IslandDraft)
signal create_requested(draft: IslandDraft)
signal cancelled

const DEFAULT_NAME := "Ilha nova"
const DEFAULT_RADIUS := 20
const MAX_RADIUS := 80
const MAX_SEED := 4294967295
## Os nomes dos parâmetros do gerador, na ordem do formulário. Um parâmetro novo
## no servidor aparece no fim, com o nome da API.
const PARAM_LABELS: Dictionary[String, String] = {
	"tile_count": "Hexágonos",
	"edge_roughness": "Recorte da borda",
	"noise_scale": "Escala das regiões (menor = maiores)",
	"water_fraction": "Parte de água",
	"deep_fraction": "Parte funda da água",
	"wet_limit": "Umidade para virar floresta",
	"stone_fraction": "Parte de pedra",
	"hill_from": "Crista para colina",
	"mountain_from": "Crista para montanha",
	"island_chance": "Chance de ilhota na água",
	"detail_chance": "Chance de detalhe no plano",
	"cleanup_passes": "Passadas de limpeza",
}

var _name_edit: LineEdit
var _from_scratch: CheckBox
var _from_generator: CheckBox
var _scratch_box: VBoxContainer
var _generator_box: VBoxContainer
var _radius: EditorNumberField
var _seed: EditorNumberField
var _params: Dictionary[String, EditorNumberField] = {}
var _defaults: Dictionary = {}
var _message: Label
var _generate_button: Button
var _create_button: Button
var _preview: IslandDraft = null
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	var title := Label.new()
	title.text = "Ilha nova"
	title.theme_type_variation = &"BoldLabel"
	add_child(title)

	_name_edit = LineEdit.new()
	_name_edit.text = DEFAULT_NAME
	_name_edit.max_length = 40
	_name_edit.placeholder_text = "Nome da ilha"
	add_child(_name_edit)

	var modes := ButtonGroup.new()
	_from_scratch = _mode_button("Do zero", modes)
	_from_generator = _mode_button("Pelo gerador", modes)

	_scratch_box = VBoxContainer.new()
	add_child(_scratch_box)
	_radius = _number(1, MAX_RADIUS, true)
	_radius.set_value(DEFAULT_RADIUS)
	_scratch_box.add_child(_row("Raio, em hexágonos", _radius))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_generator_box = VBoxContainer.new()
	_generator_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_generator_box)
	_seed = _number(0, MAX_SEED, true, false)
	var seed_row := _row("Seed", _seed)
	var roll := Button.new()
	roll.text = "Sortear"
	roll.pressed.connect(_roll_seed)
	_seed.add_child(roll)
	_generator_box.add_child(seed_row)

	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_color_override(&"font_color", UiPalette.DANGER)
	add_child(_message)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 8)
	add_child(buttons)
	_generate_button = _button("Gerar", buttons, _generate)
	_create_button = _button("Criar", buttons, _create)
	_button("Cancelar", buttons, cancelled.emit)
	_roll_seed()
	_from_scratch.button_pressed = true
	_show_mode()


## Os parâmetros do gerador (`{defaults, ranges}` de `GET /v1/editor/map-generator`).
func set_generator_params(params: Dictionary) -> void:
	_defaults = DictFields.get_dict(params, "defaults").duplicate()
	var ranges := DictFields.get_dict(params, "ranges")
	for field: String in _ordered_fields(_defaults.keys()):
		var range_dict := DictFields.get_dict(ranges, field)
		var integer := bool(range_dict.get("integer", false))
		var number := _number(float(range_dict.get("min", 0.0)), float(range_dict.get("max", 1.0)), integer)
		number.set_value(float(_defaults[field]))
		_params[field] = number
		_generator_box.add_child(_row(PARAM_LABELS.get(field, field), number))
	var restore := Button.new()
	restore.text = "Restaurar padrão"
	restore.pressed.connect(_restore_defaults)
	_generator_box.add_child(restore)


## A chance de detalhe do gerador, para as variantes de uma ilha do zero.
func detail_chance() -> float:
	return float(_defaults.get("detail_chance", 0.0))


## Volta ao começo, para uma ilha nova de novo.
func reset() -> void:
	_preview = null
	_message.text = ""
	_name_edit.text = DEFAULT_NAME
	_set_busy(false)


func _ordered_fields(fields: Array) -> Array[String]:
	var ordered: Array[String] = []
	for field: String in PARAM_LABELS:
		if fields.has(field):
			ordered.append(field)
	for field: Variant in fields:
		if not ordered.has(str(field)):
			ordered.append(str(field))
	return ordered


func _generate() -> void:
	_message.text = ""
	if _from_scratch.button_pressed:
		var radius := _read(_radius, "Raio")
		if is_nan(radius):
			return
		_preview = IslandDraft.blank(_island_name(), int(radius), detail_chance(), _rng)
		preview_ready.emit(_preview)
		return
	var map_seed := _read(_seed, "Seed")
	if is_nan(map_seed):
		return
	var config: Dictionary = {}
	for field: String in _params:
		var number := _read(_params[field], PARAM_LABELS.get(field, field))
		if is_nan(number):
			return
		if _params[field].integer:
			config[field] = int(number)
		else:
			config[field] = number
	_set_busy(true)
	var response: ApiResponse = await EditorApi.generate(int(map_seed), config)
	_set_busy(false)
	if not response.ok:
		_message.text = response.error
		return
	_preview = IslandDraft.generated(_island_name(), response.data)
	preview_ready.emit(_preview)


func _create() -> void:
	if _preview == null:
		await _generate()
		if _preview == null:
			return
	_preview.name = _island_name()
	create_requested.emit(_preview)


## Quem cria avisa o fim, com ou sem erro.
func finish_create(error: String) -> void:
	_set_busy(false)
	_message.text = error


func begin_create() -> void:
	_set_busy(true)


func _island_name() -> String:
	var text := _name_edit.text.strip_edges()
	return text if not text.is_empty() else DEFAULT_NAME


## O número de um campo, ou NAN com a mensagem do que está errado nele.
func _read(field: EditorNumberField, label: String) -> float:
	var number := field.value()
	if is_nan(number):
		_message.text = "%s: escreva um número %s." % [label, field.range_text()]
	return number


func _roll_seed() -> void:
	_seed.set_value(_rng.randi())
	_preview = null


func _restore_defaults() -> void:
	for field: String in _params:
		_params[field].set_value(float(_defaults[field]))
	_preview = null


func _show_mode() -> void:
	if _generator_box == null or _message == null:
		return
	_scratch_box.visible = _from_scratch.button_pressed
	_generator_box.get_parent().visible = _from_generator.button_pressed
	_preview = null


func _set_busy(busy: bool) -> void:
	_generate_button.disabled = busy
	_create_button.disabled = busy


func _mode_button(label: String, group: ButtonGroup) -> CheckBox:
	var check := CheckBox.new()
	check.text = label
	check.button_group = group
	check.toggled.connect(func(_on: bool) -> void: _show_mode())
	add_child(check)
	return check


func _button(label: String, parent: Node, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _number(min_value: float, max_value: float, integer: bool, with_slider: bool = true) -> EditorNumberField:
	var number := EditorNumberField.new(min_value, max_value, integer, with_slider)
	number.changed.connect(func() -> void: _preview = null)
	return number


## O nome em cima e o campo embaixo: o painel é estreito.
func _row(label: String, control: Control) -> VBoxContainer:
	var row := VBoxContainer.new()
	row.add_theme_constant_override(&"separation", 2)
	var text := Label.new()
	text.text = label
	text.theme_type_variation = &"SecondaryLabel"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(text)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row
