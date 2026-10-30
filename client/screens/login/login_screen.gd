extends Control
## Tela de login (.specs/auth-google/04-client-login.md, RF-08 a RF-10). O
## navegador faz o login; o jogo só espera. Com sucesso, a cena raiz abre a
## primeira tela, por isso esta não navega.

const LOGIN_TEXT := "Entrar com Google"
const RETRY_TEXT := "Tentar de novo"

@onready var _login_button: Button = %LoginButton
@onready var _error_label: Label = %ErrorLabel
@onready var _waiting_box: Control = %WaitingBox
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
	_login_button.pressed.connect(_on_login_pressed)
	_cancel_button.pressed.connect(Session.cancel_login)


func _on_login_pressed() -> void:
	_error_label.hide()
	_show_waiting(true)
	var result: Result = await Session.login()
	if result.ok:
		return
	_show_waiting(false)
	_login_button.text = LOGIN_TEXT if result.error.is_empty() else RETRY_TEXT
	_error_label.text = result.error
	_error_label.visible = not result.error.is_empty()


func _show_waiting(waiting: bool) -> void:
	_login_button.visible = not waiting
	_waiting_box.visible = waiting
