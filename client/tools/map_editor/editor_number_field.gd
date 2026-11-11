class_name EditorNumberField
extends HBoxContainer
## Um número do editor de ilhas (map-editor/02): um campo de texto e, quando a faixa
## é pequena, uma barra deslizante ao lado. O `SpinBox` do Godot não serviu: com
## vírgula ("0,5") ele lê 0, e o que foi digitado só vale depois do Enter ou de
## sair do campo. Aqui o texto é lido na hora de usar, com vírgula ou ponto.

signal changed

const DECIMALS := 3
const FIELD_WIDTH := 96.0
const SLIDER_WIDTH := 120.0

var min_value: float
var max_value: float
var integer: bool

var _edit: LineEdit
var _slider: HSlider = null
## Ao mexer na barra, o texto muda; isto evita a volta do texto para a barra.
var _syncing := false


func _init(minimum: float, maximum: float, is_integer: bool, with_slider: bool = true) -> void:
	min_value = minimum
	max_value = maximum
	integer = is_integer
	add_theme_constant_override(&"separation", 6)
	if with_slider:
		_slider = HSlider.new()
		_slider.min_value = minimum
		_slider.max_value = maximum
		_slider.step = 1.0 if is_integer else (maximum - minimum) / 100.0
		_slider.custom_minimum_size.x = SLIDER_WIDTH
		_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_slider.value_changed.connect(_on_slider_changed)
		add_child(_slider)
	_edit = LineEdit.new()
	_edit.custom_minimum_size.x = FIELD_WIDTH
	if not with_slider:
		_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edit.text_changed.connect(_on_text_changed)
	add_child(_edit)


## Um número de um texto, com vírgula ou ponto; NAN se não for número.
static func parse(text: String) -> float:
	var clean := text.strip_edges().replace(",", ".")
	return float(clean) if clean.is_valid_float() else NAN


## O texto de um número como o editor mostra: inteiro sem casas, e fração com
## vírgula e sem zeros sobrando.
static func format(number: float, is_integer: bool) -> String:
	if is_integer:
		return str(roundi(number))
	var text := String.num(number, DECIMALS)
	if text.contains("."):
		text = text.rstrip("0").trim_suffix(".")
	return text.replace(".", ",")


func set_value(number: float) -> void:
	_syncing = true
	_edit.text = format(number, integer)
	if _slider != null:
		_slider.value = number
	_syncing = false


## O número escrito agora, ou NAN se ele não é número, não é inteiro quando
## precisa ser, ou está fora da faixa.
func value() -> float:
	var number := parse(_edit.text)
	if is_nan(number) or number < min_value or number > max_value:
		return NAN
	if integer and not is_equal_approx(number, roundf(number)):
		return NAN
	return number


## "entre 0 e 1", para a mensagem de um valor fora da faixa.
func range_text() -> String:
	return "entre %s e %s" % [format(min_value, integer), format(max_value, integer)]


func _on_slider_changed(number: float) -> void:
	if _syncing:
		return
	_syncing = true
	_edit.text = format(number, integer)
	_syncing = false
	changed.emit()


func _on_text_changed(text: String) -> void:
	if _syncing:
		return
	var number := parse(text)
	if _slider != null and not is_nan(number):
		_syncing = true
		_slider.value = number
		_syncing = false
	changed.emit()
