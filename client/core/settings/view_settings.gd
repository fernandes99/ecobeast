class_name ViewSettings
extends RefCounted
## As preferências de vista guardadas no aparelho (camera-zoom/01).

const PATH := "user://view.json"


static func explore_zoom() -> int:
	var level: Variant = _read().get("explore_zoom")
	if (level is int or level is float) and float(level) == floorf(level) and level >= HexMapView.MIN_ZOOM and level <= HexMapView.MAX_ZOOM:
		return int(level)
	return HexMapView.DEFAULT_ZOOM


static func set_explore_zoom(level: int) -> void:
	_write("explore_zoom", level)


## Se o mapa do editor de ilhas anima o vento, a água e a fumaça (editor-performance/01).
static func editor_motion() -> bool:
	var on: Variant = _read().get("editor_motion")
	return bool(on) if on is bool else true


static func set_editor_motion(on: bool) -> void:
	_write("editor_motion", on)


static func _write(key: String, value: Variant) -> void:
	var data := _read()
	data[key] = value
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_warning("ViewSettings: não deu para gravar %s: %s" % [PATH, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(data))
	file.close()


static func _read() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(PATH)) != OK or not json.data is Dictionary:
		return {}
	return json.data
