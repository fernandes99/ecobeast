class_name StaticJsonDataSource
extends DataSource
## Lê cada tabela de res://data/<tabela>.json (um array de objetos).

const DEFAULT_DATA_DIR := "res://data/"

var _data_dir: String
var _errors: Array[String] = []


func _init(data_dir: String = DEFAULT_DATA_DIR) -> void:
	_data_dir = data_dir


func load_tables(names: PackedStringArray) -> Dictionary:
	_errors.clear()
	var tables: Dictionary = {}
	for table_name: String in names:
		tables[table_name] = _load_table(table_name)
	return tables


func get_errors() -> Array[String]:
	return _errors


func _load_table(table_name: String) -> Array:
	var file_name := table_name + ".json"
	var path := _data_dir + file_name
	if not FileAccess.file_exists(path):
		_errors.append("%s: arquivo não encontrado" % file_name)
		return []

	var json := JSON.new()
	var parse_error := json.parse(FileAccess.get_file_as_string(path))
	if parse_error != OK:
		# get_error_line() conta a partir de 0.
		_errors.append("%s: JSON inválido na linha %d do arquivo (%s)"
				% [file_name, json.get_error_line() + 1, json.get_error_message()])
		return []

	if not json.data is Array:
		_errors.append("%s: a raiz deve ser uma lista de linhas" % file_name)
		return []

	var rows: Array = json.data
	for i: int in rows.size():
		if not rows[i] is Dictionary:
			_errors.append("%s linha %d: a linha não é um objeto" % [file_name, i + 1])
			return []
	return rows
