extends Control
## Tela de entrada (onboarding/01, TELAS.md #1): logo e nome do Domador.

const HINT := "De 2 a 16 letras ou números."

var _busy: bool = false

@onready var _name_edit: LineEdit = %NameEdit
@onready var _hint: Label = %Hint
@onready var _start_button: Button = %StartButton
@onready var _keyboard_spacer: Control = %KeyboardSpacer


func _ready() -> void:
	_name_edit.text_changed.connect(func(_text: String) -> void: _update_form())
	_name_edit.text_submitted.connect(func(_text: String) -> void: _submit())
	_start_button.pressed.connect(_submit)
	_update_form()
	set_process(DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD))


func _process(_delta: float) -> void:
	_follow_virtual_keyboard()


## Valida a cada tecla: o botão só habilita com nome válido, e a dica fica na
## cor de perigo quando há algo digitado que não vale.
func _update_form() -> void:
	var player_name := Player.normalize_name(_name_edit.text)
	var is_valid := Player.is_valid_name(player_name)
	_start_button.disabled = _busy or not is_valid
	_show_hint(HINT, not is_valid and not player_name.is_empty())


func _submit() -> void:
	if _start_button.disabled:
		return
	_set_busy(true)
	var result: Result = await Session.create_player(_name_edit.text)
	if result.ok:
		Router.go_to(&"placeholder", {"title": "Escolha do inicial"})
		return
	_set_busy(false)
	_show_hint(result.error, true)


func _set_busy(busy: bool) -> void:
	_busy = busy
	_name_edit.editable = not busy
	_start_button.text = "Criando…" if busy else "Começar"
	_update_form()


func _show_hint(text: String, is_error: bool) -> void:
	_hint.text = text
	if is_error:
		_hint.add_theme_color_override(&"font_color", UiPalette.DANGER)
	else:
		_hint.remove_theme_color_override(&"font_color")


## No celular, o teclado virtual cobre a parte de baixo da tela; um espaço da
## altura dele no fim da coluna sobe o conteúdo (RF-13).
func _follow_virtual_keyboard() -> void:
	var window_height := float(DisplayServer.window_get_size().y)
	if window_height <= 0.0:
		return
	var to_viewport := get_viewport().get_visible_rect().size.y / window_height
	var height := DisplayServer.virtual_keyboard_get_height() * to_viewport
	if not is_equal_approx(_keyboard_spacer.custom_minimum_size.y, height):
		_keyboard_spacer.custom_minimum_size.y = height
