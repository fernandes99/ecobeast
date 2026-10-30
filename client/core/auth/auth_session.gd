class_name AuthSession
extends RefCounted
## A sessão da conta guardada no aparelho (.specs/auth-google/04-client-login.md,
## RF-03). A cifra só evita que o arquivo seja lido por engano: quem protege a
## conta é o servidor, que confere cada token.

const PATH := "user://session.json"

var access_token: String = ""
var refresh_token: String = ""
## Quando o access_token vence (Unix, em segundos).
var expires_at: int = 0


## A sessão vinda do servidor ({access_token, refresh_token, expires_in}), ou
## null se faltar algum campo.
static func from_tokens(data: Dictionary) -> AuthSession:
	var expires_in: Variant = data.get("expires_in")
	if not (expires_in is int or expires_in is float):
		return null
	return _build(data.get("access_token"), data.get("refresh_token"), _now() + int(expires_in))


## A sessão guardada, ou null. Arquivo ilegível conta como sem sessão e é apagado.
static func load_saved() -> AuthSession:
	if not FileAccess.file_exists(PATH):
		return null
	var session: AuthSession = null
	var file := FileAccess.open_encrypted_with_pass(PATH, FileAccess.READ, OS.get_unique_id())
	if file != null:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
			var data: Dictionary = json.data
			session = _build(data.get("access_token"), data.get("refresh_token"), int(data.get("expires_at", 0)))
		file.close()
	if session == null:
		clear()
	return session


static func clear() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)


func save() -> bool:
	var file := FileAccess.open_encrypted_with_pass(PATH, FileAccess.WRITE, OS.get_unique_id())
	if file == null:
		return false
	var written := file.store_string(JSON.stringify({
		"access_token": access_token,
		"refresh_token": refresh_token,
		"expires_at": expires_at,
	}))
	file.close()
	return written


## Falta menos que isso para o access_token vencer?
func expires_within(seconds: int) -> bool:
	return expires_at - _now() < seconds


static func _build(access: Variant, refresh: Variant, expires: int) -> AuthSession:
	if not (access is String and refresh is String):
		return null
	var session := AuthSession.new()
	session.access_token = access
	session.refresh_token = refresh
	session.expires_at = expires
	return session


static func _now() -> int:
	return int(Time.get_unix_time_from_system())
