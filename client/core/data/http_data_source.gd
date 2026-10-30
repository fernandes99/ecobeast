class_name HttpDataSource
extends DataSource
## Baixa o catálogo de GET <base_url>/v1/catalog
## (.specs/backend-api/07-client-remote-catalog.md). A última cópia fica em
## user://catalog_cache.json: o jogo manda a versão dela e, se nada mudou, o
## servidor responde 304 e a cópia é usada. O jogo é só online: sem resposta
## do servidor, fetch() falha mesmo com a cópia guardada.

const DEFAULT_CACHE_PATH := "user://catalog_cache.json"
const CATALOG_PATH := "/v1/catalog"
const TIMEOUT_SECONDS := 10.0
const FETCH_ERROR := "Não foi possível baixar o catálogo do servidor."

## As tabelas da última chamada a fetch() vieram da cópia guardada (304).
var used_cache := false

var _base_url: String
var _cache_path: String
var _temp_path: String
var _tables: Dictionary = {}
var _errors: Array[String] = []


func _init(base_url: String, cache_path: String = DEFAULT_CACHE_PATH) -> void:
	_base_url = base_url.trim_suffix("/")
	_cache_path = cache_path
	# Grava aqui e renomeia: um fechamento no meio não corrompe a cópia.
	_temp_path = cache_path.get_basename() + ".tmp.json"


## Baixa o catálogo. Assíncrono: chame com await. O HTTPRequest precisa estar
## na árvore de cenas para funcionar, por isso entra como filho de host.
func fetch(host: Node) -> bool:
	used_cache = false
	_tables = {}
	_errors.clear()
	var cache := _read_cache()
	var headers := PackedStringArray()
	if not cache.is_empty():
		headers.append('If-None-Match: "%s"' % cache["version"])

	var request := HTTPRequest.new()
	request.timeout = TIMEOUT_SECONDS
	host.add_child(request)
	# Os argumentos do sinal request_completed: resultado, código, cabeçalhos e corpo.
	var response: Array = [HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray()]
	if request.request(_base_url + CATALOG_PATH, headers) == OK:
		response = await request.request_completed
	request.queue_free()

	var result: int = response[0]
	var code: int = response[1]
	var body: PackedByteArray = response[3]
	if result == HTTPRequest.RESULT_SUCCESS:
		if code == 304 and not cache.is_empty():
			_tables = cache["tables"]
			used_cache = true
			return true
		if code == 200:
			var text := body.get_string_from_utf8()
			var bundle := _parse_bundle(text)
			if not bundle.is_empty():
				_tables = bundle["tables"]
				_write_cache(text)
				return true
	push_warning("Catálogo: GET %s falhou (resultado %d, código %d)." % [_base_url + CATALOG_PATH, result, code])
	_errors.append(FETCH_ERROR)
	return false


func load_tables(names: PackedStringArray) -> Dictionary:
	_errors.clear()
	var tables: Dictionary = {}
	for table_name: String in names:
		tables[table_name] = _table(table_name)
	return tables


func get_errors() -> Array[String]:
	return _errors


## Apaga a cópia guardada; o próximo fetch() baixa tudo de novo.
func clear_cache() -> void:
	if FileAccess.file_exists(_cache_path):
		DirAccess.remove_absolute(_cache_path)


func _table(table_name: String) -> Array:
	var table: Variant = _tables.get(table_name)
	if not table is Array:
		_errors.append("%s: a tabela não veio no catálogo" % table_name)
		return []
	var rows: Array = table
	for i: int in rows.size():
		if not rows[i] is Dictionary:
			_errors.append("%s linha %d: a linha não é um objeto" % [table_name, i + 1])
			return []
	return rows


## A cópia guardada, ou {} se ela não existe ou é ilegível.
func _read_cache() -> Dictionary:
	if not FileAccess.file_exists(_cache_path):
		return {}
	return _parse_bundle(FileAccess.get_file_as_string(_cache_path))


## {version, tables} se o texto é um catálogo válido; senão, {}.
func _parse_bundle(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return {}
	var bundle: Dictionary = json.data
	if not bundle.get("version") is String or not bundle.get("tables") is Dictionary:
		return {}
	return bundle


func _write_cache(text: String) -> void:
	var file := FileAccess.open(_temp_path, FileAccess.WRITE)
	var written := file != null and file.store_string(text)
	if file != null:
		file.close()
	if not written or DirAccess.rename_absolute(_temp_path, _cache_path) != OK:
		# Sem a cópia o jogo funciona; só baixa tudo de novo na próxima abertura.
		push_warning("Catálogo: não foi possível guardar a cópia em %s." % _cache_path)
