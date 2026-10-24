extends VBoxContainer
## Painel extra do placeholder do Perfil (hub/01, RF-11 e RF-12): o nome do
## Domador e, só em build de debug, "Apagar progresso" para refazer o
## onboarding. Apaga só com dois toques em até 3 s (%ConfirmTimer).

const RESET_TEXT := "Apagar progresso"
const CONFIRM_TEXT := "Toque de novo para apagar"

@onready var _name_label: Label = %NameLabel
@onready var _reset_button: Button = %ResetButton
@onready var _error_label: Label = %ErrorLabel
@onready var _confirm_timer: Timer = %ConfirmTimer


func _ready() -> void:
	if Session.player != null:
		_name_label.text = "Domador: %s" % Session.player.name
	_reset_button.visible = OS.is_debug_build()
	_reset_button.pressed.connect(_on_reset_pressed)
	_confirm_timer.timeout.connect(_disarm)


## Primeiro toque arma; o segundo, com o timer ainda correndo, apaga.
func _on_reset_pressed() -> void:
	if _confirm_timer.is_stopped():
		_reset_button.text = CONFIRM_TEXT
		_error_label.hide()
		_confirm_timer.start()
		return
	_confirm_timer.stop()
	_reset_button.disabled = true
	var result: Result = await Session.reset_progress()
	if result.ok:
		Router.go_to(&"title")
		return
	_reset_button.disabled = false
	_disarm()
	_error_label.text = result.error
	_error_label.show()


func _disarm() -> void:
	_reset_button.text = RESET_TEXT
