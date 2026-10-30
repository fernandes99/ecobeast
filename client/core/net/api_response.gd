class_name ApiResponse
extends RefCounted
## Resposta de uma chamada do autoload Api (.specs/auth-google/04-client-login.md, RF-01).

const OFFLINE_ERROR := "Não foi possível conectar ao servidor."
const SERVER_ERROR := "O servidor teve um problema. Tente de novo."

## Código HTTP, ou 0 se o servidor não respondeu.
var code: int = 0
## O JSON da resposta, ou null se não veio JSON.
var data: Variant = null
## Verdadeiro para 2xx.
var ok: bool = false
## Mensagem em pt-BR, pronta para a tela. Vazia quando ok.
var error: String = ""


static func offline() -> ApiResponse:
	var response := ApiResponse.new()
	response.error = OFFLINE_ERROR
	return response


static func from_http(http_code: int, body: PackedByteArray) -> ApiResponse:
	var response := ApiResponse.new()
	response.code = http_code
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) == OK:
		response.data = json.data
	response.ok = http_code >= 200 and http_code < 300
	if not response.ok:
		response.error = _error_for(http_code, response.data)
	return response


## 4xx trazem a mensagem do servidor, em pt-BR; 5xx nunca mostram detalhes.
static func _error_for(http_code: int, json_body: Variant) -> String:
	if http_code < 500 and json_body is Dictionary and json_body.get("message") is String:
		return json_body["message"]
	return SERVER_ERROR
