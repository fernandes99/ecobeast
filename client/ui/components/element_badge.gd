class_name ElementBadge
extends PanelContainer
## Pílula com o nome do Elemento na cor dele (foundation/02, RF-11).

## Acima desta luminância, a cor do Elemento é clara demais para texto branco.
const LIGHT_LUMINANCE := 0.6

var _element_id: int = -1
## Cópia do estilo do tema, só deste selo (o fundo é a cor do Elemento).
var _style: StyleBoxFlat

@onready var _name_label: Label = %NameLabel


func _ready() -> void:
	_style = (get_theme_stylebox(&"panel") as StyleBoxFlat).duplicate()
	add_theme_stylebox_override(&"panel", _style)
	_refresh()


## Pode ser chamado antes ou depois de o componente entrar na árvore.
func set_element(element_id: int) -> void:
	_element_id = element_id
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if _element_id < 0:
		return
	var element := GameData.get_element(_element_id)
	if element == null:
		return
	_style.bg_color = element.color
	_name_label.text = element.name
	var is_light := element.color.get_luminance() > LIGHT_LUMINANCE
	_name_label.add_theme_color_override(&"font_color", UiPalette.BACKGROUND if is_light else UiPalette.TEXT)
