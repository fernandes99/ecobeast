class_name HpBar
extends HBoxContainer
## Barra de HP com a cor da faixa (foundation/02, RF-13): verde acima de 50%,
## amarela acima de 20% e vermelha até 20%.

const MID_RATIO := 0.5
const LOW_RATIO := 0.2

## Mostra "atual/máximo" ao lado da barra.
@export var show_numbers: bool = false

var _current: int = 0
var _maximum: int = 0
## Cópia do preenchimento do tema, só desta barra (a cor muda com a faixa).
var _fill: StyleBoxFlat

@onready var _bar: ProgressBar = %Bar
@onready var _numbers: Label = %Numbers


func _ready() -> void:
	_fill = (_bar.get_theme_stylebox(&"fill") as StyleBoxFlat).duplicate()
	_bar.add_theme_stylebox_override(&"fill", _fill)
	_refresh()


## Pode ser chamado antes ou depois de o componente entrar na árvore.
func set_hp(current: int, maximum: int) -> void:
	_maximum = maxi(maximum, 0)
	_current = clampi(current, 0, _maximum)
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	var ratio := 0.0
	if _maximum > 0:
		ratio = float(_current) / _maximum
	_bar.value = ratio
	if ratio > MID_RATIO:
		_fill.bg_color = UiPalette.HP_HIGH
	elif ratio > LOW_RATIO:
		_fill.bg_color = UiPalette.HP_MID
	else:
		_fill.bg_color = UiPalette.HP_LOW
	_numbers.visible = show_numbers
	_numbers.text = "%d/%d" % [_current, _maximum]
