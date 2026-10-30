class_name AuthService
extends RefCounted
## O login com Google pelo navegador (.specs/auth-google/04-client-login.md,
## RF-04 a RF-06): começa no servidor, abre o navegador e pergunta até a sessão
## sair. As telas chegam aqui só pelo Session.

signal _login_finished(result: Result)

const START_PATH := "/v1/auth/google/start"
const POLL_PATH := "/v1/auth/google/poll"
const LOGOUT_PATH := "/v1/auth/logout"
const POLL_INTERVAL_S := 2.0
const LOGIN_TIMEOUT_S := 300.0
const MAX_POLL_FAILURES := 3
const LOGIN_FAILED := "Não foi possível entrar. Tente de novo."
const LOGIN_TIMED_OUT := "O login demorou demais. Tente de novo."
const BROWSER_FAILED := "Não foi possível abrir o navegador."

var timeout_s := LOGIN_TIMEOUT_S

## Cada login() e cancel() muda o número. Um login antigo, ao acordar de um
## await, vê que não é mais o atual e para sem responder.
var _attempt := 0


## Assíncrono: chame com await. Sucesso: a sessão já está no Api.
func login() -> Result:
	_attempt += 1
	# Deferido porque _run pode terminar sem esperar nada, e o sinal só pode
	# sair depois do await abaixo.
	_run.call_deferred(_attempt)
	return await _login_finished


## O login em andamento devolve na hora uma falha com error vazio.
func cancel() -> void:
	_attempt += 1
	_login_finished.emit(Result.failure(""))


func logout() -> Result:
	# Falha de rede não impede a saída: a sessão some do aparelho do mesmo jeito.
	await Api.request(HTTPClient.METHOD_POST, LOGOUT_PATH, null, true)
	Api.clear_session()
	return Result.success()


func _run(attempt: int) -> void:
	var start: ApiResponse = await Api.request(HTTPClient.METHOD_POST, START_PATH)
	if attempt != _attempt:
		return
	if not (start.ok and start.data is Dictionary):
		_login_finished.emit(Result.failure(LOGIN_FAILED if start.ok else start.error))
		return
	if not _open_browser(start.data["url"]):
		_login_finished.emit(Result.failure(BROWSER_FAILED))
		return

	var body := {"login_id": start.data["login_id"], "poll_secret": start.data["poll_secret"]}
	var deadline := Time.get_ticks_msec() + int(timeout_s * 1000.0)
	var failures := 0
	while true:
		await Api.get_tree().create_timer(POLL_INTERVAL_S).timeout
		if attempt != _attempt:
			return
		if Time.get_ticks_msec() >= deadline:
			_login_finished.emit(Result.failure(LOGIN_TIMED_OUT))
			return
		var poll: ApiResponse = await Api.request(HTTPClient.METHOD_POST, POLL_PATH, body)
		if attempt != _attempt:
			return
		match poll.code:
			200:
				_login_finished.emit(Result.success() if Api.adopt_tokens(poll.data) else Result.failure(LOGIN_FAILED))
				return
			202:
				failures = 0
			404, 410:
				_login_finished.emit(Result.failure(LOGIN_FAILED))
				return
			_:
				failures += 1
				if failures >= MAX_POLL_FAILURES:
					_login_finished.emit(Result.failure(poll.error))
					return


func _open_browser(url: String) -> bool:
	return OS.shell_open(url) == OK
