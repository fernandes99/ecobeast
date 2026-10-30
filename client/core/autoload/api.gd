extends Node
## Autoload Api: as chamadas HTTP do jogo e a sessão que vai nelas
## (.specs/auth-google/04-client-login.md, RF-01 e RF-02). É um Node porque o
## HTTPRequest precisa estar na árvore de cenas para funcionar.

## O servidor recusou a sessão: ela foi apagada, e o jogador precisa entrar de novo.
signal session_lost
signal _renewal_finished(response: ApiResponse)

const TIMEOUT_SECONDS := 10.0
const RENEW_MARGIN_S := 60
const REFRESH_PATH := "/v1/auth/refresh"
const UNAUTHORIZED := 401

var base_url: String
## A sessão atual, ou null se ninguém entrou.
var session: AuthSession = null

var _renewing := false


func _ready() -> void:
	base_url = str(ProjectSettings.get_setting(GameData.BASE_URL_SETTING)).trim_suffix("/")
	session = AuthSession.load_saved()


## Faz a chamada e devolve a resposta. Assíncrono: chame com await.
## Com authenticated, leva a sessão e cuida de renová-la.
func request(method: HTTPClient.Method, path: String, body: Variant = null, authenticated: bool = false) -> ApiResponse:
	if not authenticated:
		return await _send(method, path, body)
	if session == null:
		return ApiResponse.from_http(UNAUTHORIZED, PackedByteArray())
	if session.expires_within(RENEW_MARGIN_S):
		var renewed: ApiResponse = await _renew()
		if not renewed.ok:
			return renewed
	var response: ApiResponse = await _send(method, path, body, session.access_token)
	if response.code != UNAUTHORIZED or session == null:
		return response
	var retry: ApiResponse = await _renew()
	if not retry.ok:
		return retry
	response = await _send(method, path, body, session.access_token)
	if response.code == UNAUTHORIZED:
		_lose_session()
	return response


## Troca a sessão pela que veio do servidor e a guarda. Falso se o corpo não
## tiver os tokens.
func adopt_tokens(data: Variant) -> bool:
	var tokens: AuthSession = AuthSession.from_tokens(data) if data is Dictionary else null
	if tokens == null:
		return false
	session = tokens
	if not session.save():
		# Sem o arquivo o jogo funciona; só pede login na próxima abertura.
		push_warning("Não foi possível guardar a sessão em %s." % AuthSession.PATH)
	return true


func clear_session() -> void:
	session = null
	AuthSession.clear()


## Só uma renovação por vez: o refresh_token vale uma vez só, então quem chegar
## durante uma renovação espera o resultado dela.
func _renew() -> ApiResponse:
	if _renewing:
		return await _renewal_finished
	_renewing = true
	var response: ApiResponse = await _send(HTTPClient.METHOD_POST, REFRESH_PATH, {"refresh_token": session.refresh_token})
	_renewing = false
	if response.code == UNAUTHORIZED:
		_lose_session()
	elif response.ok and not adopt_tokens(response.data):
		response = ApiResponse.offline()
	_renewal_finished.emit(response)
	return response


func _lose_session() -> void:
	clear_session()
	session_lost.emit()


func _send(method: HTTPClient.Method, path: String, body: Variant, token: String = "") -> ApiResponse:
	var headers := PackedStringArray()
	var payload := ""
	if body != null:
		headers.append("Content-Type: application/json")
		payload = JSON.stringify(body)
	if not token.is_empty():
		headers.append("Authorization: Bearer %s" % token)

	var http := HTTPRequest.new()
	http.timeout = TIMEOUT_SECONDS
	add_child(http)
	# Os argumentos do sinal request_completed: resultado, código, cabeçalhos e corpo.
	var completed: Array = [HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray()]
	if http.request(base_url + path, headers, method, payload) == OK:
		completed = await http.request_completed
	http.queue_free()

	if completed[0] != HTTPRequest.RESULT_SUCCESS:
		return ApiResponse.offline()
	return ApiResponse.from_http(completed[1], completed[3])
