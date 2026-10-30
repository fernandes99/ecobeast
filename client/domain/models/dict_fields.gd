class_name DictFields
extends RefCounted
## Leitura de campos de um Dictionary vindo do JSON da API. O JSON do Godot lê
## todo número como float, e um campo pode estar ausente ou null: nesses casos
## vale o padrão.


static func get_int(d: Dictionary, key: String, default: int = 0) -> int:
	var value: Variant = d.get(key)
	return int(value) if value is int or value is float else default


## Ids opcionais: null ou ausente vira -1.
static func get_id(d: Dictionary, key: String) -> int:
	return get_int(d, key, -1)


static func get_string(d: Dictionary, key: String, default: String = "") -> String:
	var value: Variant = d.get(key)
	return value if value is String else default


static func get_bool(d: Dictionary, key: String, default: bool = false) -> bool:
	var value: Variant = d.get(key)
	return value if value is bool else default


static func get_dict(d: Dictionary, key: String) -> Dictionary:
	var value: Variant = d.get(key)
	return value if value is Dictionary else {}


static func get_array(d: Dictionary, key: String) -> Array:
	var value: Variant = d.get(key)
	return value if value is Array else []
