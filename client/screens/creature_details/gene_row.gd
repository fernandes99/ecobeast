class_name GeneRow
extends HBoxContainer
## Uma linha da aba Genes (creature-details/03, RF-07 e RF-08): o nome curto do
## stat, a barra e o valor. Um Gene no máximo fica dourado.

const MAX_GENE := 31

var _short_name: String = ""
var _value: int = 0
## Cópia do preenchimento do tema, só desta barra (a cor muda no máximo).
var _fill: StyleBoxFlat

@onready var _name_label: Label = %NameLabel
@onready var _bar: ProgressBar = %Bar
@onready var _value_label: Label = %ValueLabel


func _ready() -> void:
	_bar.max_value = MAX_GENE
	_fill = (_bar.get_theme_stylebox(&"fill") as StyleBoxFlat).duplicate()
	_bar.add_theme_stylebox_override(&"fill", _fill)
	_refresh()


## Pode ser chamado antes ou depois de o componente entrar na árvore.
func set_gene(short_name: String, value: int) -> void:
	_short_name = short_name
	_value = value
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	var is_max := _value >= MAX_GENE
	_name_label.text = _short_name
	_bar.value = _value
	_value_label.text = str(_value)
	_fill.bg_color = UiPalette.WARNING if is_max else UiPalette.ACCENT
	_value_label.add_theme_color_override(&"font_color", UiPalette.WARNING if is_max else UiPalette.TEXT)
