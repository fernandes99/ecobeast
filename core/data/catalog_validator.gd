class_name CatalogValidator
extends RefCounted
## Confere as tabelas do catálogo contra o CatalogSchema e as regras de
## consistência (.specs/game-data/01-data-layer.md, RF-06 a RF-12).
## Cada erro é "<tabela>.json linha <n>: <motivo>" (n = posição da linha no
## array, a partir de 1) ou "<tabela>.json: <motivo>".

const TEMPERAMENT_COUNT := 25
const HIDDEN_TRAIT_SLOT := 3

var _errors: Array[String] = []
## Linhas que passaram na checagem de estrutura, normalizadas: tabela -> Array[Dictionary].
var _rows: Dictionary = {}
## Posição original (a partir de 1) de cada linha em _rows: tabela -> Array[int].
var _lines: Dictionary = {}
## Cache de ids por tabela: tabela -> {id: índice em _rows}.
var _id_index: Dictionary = {}
var _regex_cache: Dictionary = {}


## Valida as tabelas (nome -> Array de linhas) e devolve a lista de erros.
static func validate(tables: Dictionary) -> Array[String]:
	var validator := CatalogValidator.new()
	return validator._run(tables)


func _run(tables: Dictionary) -> Array[String]:
	for table_name: String in CatalogSchema.TABLES:
		var rows: Array = tables.get(table_name, [])
		_check_structure(table_name, rows)
	for table_name: String in CatalogSchema.TABLES:
		_check_keys_and_unique(table_name)
		_check_foreign_keys(table_name)
	_check_species_elements()
	_check_species_stats()
	_check_temperaments()
	_check_species_traits()
	_check_species_skills()
	_check_skills()
	_check_skill_effects()
	_check_evolutions()
	_check_starter_options()
	return _errors


# --- Estrutura, tipos e faixas (RF-06 a RF-08) ---------------------------------

func _check_structure(table_name: String, rows: Array) -> void:
	var columns: Dictionary = CatalogSchema.TABLES[table_name]["columns"]
	var valid_rows: Array[Dictionary] = []
	var lines: Array[int] = []
	for i: int in rows.size():
		var line := i + 1
		if not rows[i] is Dictionary:
			_row_error(table_name, line, "a linha não é um objeto")
			continue
		var row: Dictionary = rows[i]
		var is_valid := true
		for column: String in row:
			if not columns.has(column):
				_row_error(table_name, line, "coluna desconhecida '%s'" % column)
				is_valid = false
		for column: String in columns:
			if not row.has(column):
				_row_error(table_name, line, "coluna '%s' faltando" % column)
				is_valid = false
			elif not _check_value(table_name, line, column, columns[column], row[column]):
				is_valid = false
		if is_valid:
			valid_rows.append(CatalogSchema.normalize_row(table_name, row))
			lines.append(line)
	_rows[table_name] = valid_rows
	_lines[table_name] = lines


func _check_value(table_name: String, line: int, column: String, spec: Dictionary, value: Variant) -> bool:
	if value == null:
		if spec.get("nullable", false):
			return true
		_row_error(table_name, line, "coluna '%s' não pode ser nula" % column)
		return false

	if spec.has("fk_future"):
		_row_error(table_name, line, "coluna '%s' deve ser null até a tabela %s existir"
				% [column, spec["fk_future"]])
		return false

	var type: String = spec["type"]
	if not _has_type(value, type):
		_row_error(table_name, line, "coluna '%s' deve ser %s (valor: %s)" % [column, type, JSON.stringify(value)])
		return false

	if spec.has("min") and float(value) < float(spec["min"]):
		_row_error(table_name, line, "coluna '%s' = %s abaixo do mínimo %s" % [column, _show(value, type), spec["min"]])
		return false
	if spec.has("max") and float(value) > float(spec["max"]):
		_row_error(table_name, line, "coluna '%s' = %s acima do máximo %s" % [column, _show(value, type), spec["max"]])
		return false
	if spec.has("values") and not _is_allowed(value, spec["values"]):
		_row_error(table_name, line, "coluna '%s' = %s fora dos valores permitidos %s"
				% [column, _show(value, type), JSON.stringify(spec["values"])])
		return false
	if spec.has("pattern") and not _get_regex(spec["pattern"]).search(value):
		_row_error(table_name, line, "coluna '%s' = \"%s\" fora do formato %s" % [column, value, spec["pattern"]])
		return false
	return true


func _has_type(value: Variant, type: String) -> bool:
	match type:
		"int":
			return value is int or (value is float and is_equal_approx(value, roundf(value)))
		"float":
			return value is float or value is int
		"string":
			return value is String
		"bool":
			return value is bool
	return false


func _is_allowed(value: Variant, allowed: Array) -> bool:
	for option: Variant in allowed:
		if value is String or option is String:
			if typeof(value) == typeof(option) and value == option:
				return true
		elif is_equal_approx(float(value), float(option)):
			return true
	return false


func _show(value: Variant, type: String) -> String:
	if type == "int":
		return str(int(value))
	return str(value)


func _get_regex(pattern: String) -> RegEx:
	if not _regex_cache.has(pattern):
		_regex_cache[pattern] = RegEx.create_from_string(pattern)
	return _regex_cache[pattern]


# --- Chaves, únicos e FKs (RF-08 a RF-10) --------------------------------------

func _check_keys_and_unique(table_name: String) -> void:
	var schema: Dictionary = CatalogSchema.TABLES[table_name]
	var key_columns: Array = schema["key"]
	var columns: Dictionary = schema["columns"]
	var rows: Array[Dictionary] = _rows[table_name]
	var lines: Array[int] = _lines[table_name]

	var seen_keys: Dictionary = {}
	for i: int in rows.size():
		var key_values: Array = []
		for column: String in key_columns:
			key_values.append(rows[i][column])
		var key := str(key_values)
		if seen_keys.has(key):
			_row_error(table_name, lines[i], "chave %s = %s repetida (já usada na linha %d)"
					% [JSON.stringify(key_columns), key, seen_keys[key]])
		else:
			seen_keys[key] = lines[i]

	for column: String in columns:
		if not columns[column].get("unique", false):
			continue
		var seen: Dictionary = {}
		for i: int in rows.size():
			var value: Variant = rows[i][column]
			if value == null:
				continue
			if seen.has(value):
				_row_error(table_name, lines[i], "coluna '%s' = %s repetida (já usada na linha %d)"
						% [column, str(value), seen[value]])
			else:
				seen[value] = lines[i]


func _check_foreign_keys(table_name: String) -> void:
	var columns: Dictionary = CatalogSchema.TABLES[table_name]["columns"]
	var rows: Array[Dictionary] = _rows[table_name]
	var lines: Array[int] = _lines[table_name]
	for column: String in columns:
		if not columns[column].has("fk"):
			continue
		var target: String = columns[column]["fk"]
		for i: int in rows.size():
			var value: Variant = rows[i][column]
			if value != null and not _ids(target).has(value):
				_row_error(table_name, lines[i], "'%s' = %d não existe em %s.json" % [column, value, target])


## {id: índice da linha} das linhas válidas de uma tabela com coluna id.
func _ids(table_name: String) -> Dictionary:
	if not _id_index.has(table_name):
		var index: Dictionary = {}
		var rows: Array[Dictionary] = _rows.get(table_name, [] as Array[Dictionary])
		for i: int in rows.size():
			if rows[i].has("id"):
				index[rows[i]["id"]] = i
		_id_index[table_name] = index
	return _id_index[table_name]


func _row_by_id(table_name: String, id: Variant) -> Dictionary:
	var index: Dictionary = _ids(table_name)
	if id == null or not index.has(id):
		return {}
	var rows: Array[Dictionary] = _rows[table_name]
	return rows[index[id]]


func _slug_of(table_name: String, id: Variant) -> String:
	return String(_row_by_id(table_name, id).get("slug", ""))


## Agrupa os índices das linhas de uma tabela pelo valor de uma coluna.
func _group(table_name: String, column: String) -> Dictionary:
	var groups: Dictionary = {}
	var rows: Array[Dictionary] = _rows[table_name]
	for i: int in rows.size():
		var value: Variant = rows[i][column]
		if not groups.has(value):
			groups[value] = [] as Array[int]
		groups[value].append(i)
	return groups


# --- Consistência (RF-11 e RF-12) ----------------------------------------------

func _check_species_elements() -> void:
	var by_species := _group("species_elements", "species_id")
	var element_rows: Array[Dictionary] = _rows["species_elements"]
	var element_lines: Array[int] = _lines["species_elements"]
	_for_each_species(func(species: Dictionary, line: int) -> void:
		var indexes: Array = by_species.get(species["id"], [])
		if indexes.is_empty():
			_row_error("species", line, "espécie %d sem elemento em species_elements.json" % species["id"])
			return
		var slots: Array[int] = []
		var elements: Array[int] = []
		for i: int in indexes:
			slots.append(element_rows[i]["slot"])
			elements.append(element_rows[i]["element_id"])
		if not slots.has(1):
			_row_error("species", line, "espécie %d sem elemento no slot 1" % species["id"])
		if elements.size() == 2 and elements[0] == elements[1]:
			_row_error("species_elements", element_lines[indexes[1]],
					"espécie %d com o mesmo elemento nos dois slots" % species["id"]))


func _check_species_stats() -> void:
	var stat_rows: Array[Dictionary] = _rows["species_stats"]
	var stat_lines: Array[int] = _lines["species_stats"]
	var required: Array[int] = []
	for stat: Dictionary in _rows["stats"]:
		if not stat["is_battle_only"]:
			required.append(stat["id"])

	for i: int in stat_rows.size():
		if not required.has(stat_rows[i]["stat_id"]):
			_row_error("species_stats", stat_lines[i], "stat %d é exclusivo de batalha e não tem valor base"
					% stat_rows[i]["stat_id"])

	var by_species := _group("species_stats", "species_id")
	_for_each_species(func(species: Dictionary, line: int) -> void:
		var present: Array[int] = []
		for i: int in by_species.get(species["id"], []):
			present.append(stat_rows[i]["stat_id"])
		var missing: Array[String] = []
		for stat_id: int in required:
			if not present.has(stat_id):
				missing.append(_slug_of("stats", stat_id))
		if not missing.is_empty():
			_row_error("species", line, "espécie %d sem species_stats para: %s"
					% [species["id"], ", ".join(missing)]))


func _check_temperaments() -> void:
	var rows: Array[Dictionary] = _rows["temperaments"]
	var lines: Array[int] = _lines["temperaments"]
	if rows.size() != TEMPERAMENT_COUNT:
		_table_error("temperaments", "deve ter %d linhas (tem %d)" % [TEMPERAMENT_COUNT, rows.size()])
	var seen: Dictionary = {}
	for i: int in rows.size():
		var pair := "%d,%d" % [rows[i]["increased_stat_id"], rows[i]["decreased_stat_id"]]
		if seen.has(pair):
			_row_error("temperaments", lines[i], "par de stats (%s) repetido (já usado na linha %d)" % [pair, seen[pair]])
		else:
			seen[pair] = lines[i]
		for column: String in ["increased_stat_id", "decreased_stat_id"]:
			var stat := _row_by_id("stats", rows[i][column])
			if stat.is_empty():
				continue
			if stat["slug"] == "hp" or stat["is_battle_only"]:
				_row_error("temperaments", lines[i], "'%s' não pode ser %s" % [column, stat["slug"]])


func _check_species_traits() -> void:
	var rows: Array[Dictionary] = _rows["species_traits"]
	var lines: Array[int] = _lines["species_traits"]
	for i: int in rows.size():
		var should_be_hidden: bool = rows[i]["slot"] == HIDDEN_TRAIT_SLOT
		if rows[i]["is_hidden"] != should_be_hidden:
			_row_error("species_traits", lines[i], "is_hidden deve ser %s no slot %d"
					% [should_be_hidden, rows[i]["slot"]])

	var by_species := _group("species_traits", "species_id")
	_for_each_species(func(species: Dictionary, line: int) -> void:
		var has_slot_one := false
		for i: int in by_species.get(species["id"], []):
			if rows[i]["slot"] == 1:
				has_slot_one = true
		if not has_slot_one:
			_row_error("species", line, "espécie %d sem traço no slot 1" % species["id"]))


func _check_species_skills() -> void:
	var rows: Array[Dictionary] = _rows["species_skills"]
	var lines: Array[int] = _lines["species_skills"]
	var has_level_one: Dictionary = {}
	for i: int in rows.size():
		var level: Variant = rows[i]["level"]
		match _slug_of("skill_learn_methods", rows[i]["skill_learn_method_id"]):
			"level_up":
				if level == null or level < 1:
					_row_error("species_skills", lines[i], "técnica por nível precisa de level ≥ 1")
				elif level == 1:
					has_level_one[rows[i]["species_id"]] = true
			"evolution":
				if level != 0:
					_row_error("species_skills", lines[i], "técnica ao ascender precisa de level = 0")
			"teachable":
				if level != null:
					_row_error("species_skills", lines[i], "técnica ensinável precisa de level = null")

	_for_each_species(func(species: Dictionary, line: int) -> void:
		if not has_level_one.has(species["id"]):
			_row_error("species", line, "espécie %d sem técnica por nível no nível 1" % species["id"]))


func _check_skills() -> void:
	var rows: Array[Dictionary] = _rows["skills"]
	var lines: Array[int] = _lines["skills"]
	for i: int in rows.size():
		if rows[i]["max_hits"] < rows[i]["min_hits"]:
			_row_error("skills", lines[i], "max_hits menor que min_hits")


func _check_skill_effects() -> void:
	var rows: Array[Dictionary] = _rows["skill_effects"]
	var lines: Array[int] = _lines["skill_effects"]
	var seen_order: Dictionary = {}
	for i: int in rows.size():
		var row := rows[i]
		var order_key := "%d,%d" % [row["skill_id"], row["sort_order"]]
		if seen_order.has(order_key):
			_row_error("skill_effects", lines[i], "sort_order %d repetido na técnica %d (já usado na linha %d)"
					% [row["sort_order"], row["skill_id"], seen_order[order_key]])
		else:
			seen_order[order_key] = lines[i]

		if row["stages"] != null and row["stages"] == 0:
			_row_error("skill_effects", lines[i], "stages não pode ser 0")

		var effect_slug := _slug_of("effect_types", row["effect_type_id"])
		if effect_slug.is_empty():
			continue
		if not CatalogSchema.EFFECT_PARAMS.has(effect_slug):
			_row_error("skill_effects", lines[i], "tipo de efeito '%s' sem regra em CatalogSchema.EFFECT_PARAMS" % effect_slug)
			continue
		var params: Dictionary = CatalogSchema.EFFECT_PARAMS[effect_slug]
		for column: String in CatalogSchema.EFFECT_PARAM_COLUMNS:
			var required: bool = params["required"].has(column)
			var optional: bool = params["optional"].has(column)
			if required and row[column] == null:
				_row_error("skill_effects", lines[i], "efeito '%s' precisa de '%s'" % [effect_slug, column])
			elif not required and not optional and row[column] != null:
				_row_error("skill_effects", lines[i], "efeito '%s' não usa '%s' (deve ser null)" % [effect_slug, column])


func _check_evolutions() -> void:
	var rows: Array[Dictionary] = _rows["evolutions"]
	var lines: Array[int] = _lines["evolutions"]
	for i: int in rows.size():
		var row := rows[i]
		if row["species_id"] == row["evolved_species_id"]:
			_row_error("evolutions", lines[i], "espécie não pode ascender para ela mesma")
		if _slug_of("evolution_triggers", row["evolution_trigger_id"]) == "level" and row["min_level"] == null:
			_row_error("evolutions", lines[i], "gatilho 'level' precisa de min_level")
		var evolved := _row_by_id("species", row["evolved_species_id"])
		if not evolved.is_empty() and evolved["evolves_from_species_id"] != row["species_id"]:
			_row_error("evolutions", lines[i], "espécie %d deveria ter evolves_from_species_id = %d"
					% [row["evolved_species_id"], row["species_id"]])


func _check_starter_options() -> void:
	var rows: Array[Dictionary] = _rows["starter_options"]
	if rows.is_empty():
		_table_error("starter_options", "deve ter pelo menos 1 linha")


func _for_each_species(callback: Callable) -> void:
	var rows: Array[Dictionary] = _rows["species"]
	var lines: Array[int] = _lines["species"]
	for i: int in rows.size():
		callback.call(rows[i], lines[i])


# --- Mensagens ------------------------------------------------------------------

func _row_error(table_name: String, line: int, message: String) -> void:
	_errors.append("%s.json linha %d: %s" % [table_name, line, message])


func _table_error(table_name: String, message: String) -> void:
	_errors.append("%s.json: %s" % [table_name, message])
