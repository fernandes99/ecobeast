class_name NicknamePanel
extends Control
## Painel do apelido (creature-details/02, RF-13 a RF-16). Só exibe e repassa
## toques: quem chama o Session é a tela. Fica no terço de cima, para o teclado
## do celular não o cobrir.

## O jogador tocou em "Salvar". O texto vai como foi digitado: quem decide é o
## servidor.
signal save_pressed(nickname: String)

const SAVE_TEXT := "Salvar"
const SAVING_TEXT := "Salvando…"

var _busy: bool = false

@onready var _dim: ColorRect = %Dim
@onready var _edit: LineEdit = %Edit
@onready var _message: Label = %Message
@onready var _save_button: Button = %SaveButton
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
	hide()
	_dim.color = UiPalette.OVERLAY
	_dim.gui_input.connect(_on_dim_input)
	_edit.text_changed.connect(func(_text: String) -> void: _update_save())
	_edit.text_submitted.connect(func(_text: String) -> void: _submit())
	_save_button.pressed.connect(_submit)
	_cancel_button.pressed.connect(close)


func open(current: String) -> void:
	_edit.text = current
	_edit.caret_column = current.length()
	_message.hide()
	set_busy(false)
	show()
	_edit.grab_focus()


## Fecha sem salvar. Enquanto o apelido está sendo enviado, não fecha.
func close() -> void:
	if not _busy:
		_edit.release_focus()
		hide()


func set_busy(busy: bool) -> void:
	_busy = busy
	_edit.editable = not busy
	_cancel_button.disabled = busy
	_save_button.text = SAVING_TEXT if busy else SAVE_TEXT
	_update_save()


func show_error(message: String) -> void:
	_message.text = message
	_message.show()


## Vazio vale: remove o apelido. Fora isso, a mesma regra do nome do Domador,
## só para habilitar o botão na hora.
func _update_save() -> void:
	var nickname := Player.normalize_name(_edit.text)
	_save_button.disabled = _busy or not (nickname.is_empty() or Player.is_valid_name(nickname))


func _submit() -> void:
	if not _save_button.disabled:
		_message.hide()
		save_pressed.emit(_edit.text)


func _on_dim_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
		close()
