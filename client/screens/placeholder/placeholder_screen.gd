extends Control
## Tela placeholder (foundation/02, RF-14 e RF-15): título, "Em construção" e
## Voltar. Parâmetros: {"title": String, "extra": PackedScene (opcional), que
## entra abaixo do texto}.

var _title: String = ""
var _extra: PackedScene = null

@onready var _title_label: Label = %Title
@onready var _extra_host: VBoxContainer = %ExtraHost
@onready var _back_button: Button = %BackButton


func setup(params: Dictionary) -> void:
	_title = params.get("title", "")
	_extra = params.get("extra", null)


func _ready() -> void:
	_title_label.text = _title
	if _extra != null:
		_extra_host.add_child(_extra.instantiate())
	_extra_host.visible = _extra != null
	_back_button.visible = Router.can_go_back()
	_back_button.pressed.connect(Router.back)
