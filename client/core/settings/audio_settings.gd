class_name AudioSettings
extends RefCounted
## Os volumes da Música e dos Sons, guardados no aparelho (hub-start/02). Cada volume vai
## de 0 a 1 e multiplica o volume de partida do barramento, o do `default_bus_layout.tres`.

const PATH := "user://audio.json"
const MUSIC_BUS := &"Music"
const VOICES_BUS := &"Voices"
const SFX_BUS := &"Sfx"
const MUSIC_KEY := "music"
const SOUNDS_KEY := "sounds"

static var _base_db: Dictionary[StringName, float] = {}


static func music_volume() -> float:
	return _volume(MUSIC_KEY)


static func sounds_volume() -> float:
	return _volume(SOUNDS_KEY)


static func set_music_volume(volume: float) -> void:
	_store(MUSIC_KEY, volume)
	_set_bus(MUSIC_BUS, volume)


static func set_sounds_volume(volume: float) -> void:
	_store(SOUNDS_KEY, volume)
	_set_bus(VOICES_BUS, volume)
	_set_bus(SFX_BUS, volume)


## Na abertura do app, antes de qualquer som.
static func apply() -> void:
	_set_bus(MUSIC_BUS, music_volume())
	_set_bus(VOICES_BUS, sounds_volume())
	_set_bus(SFX_BUS, sounds_volume())


static func _set_bus(bus: StringName, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	if not _base_db.has(bus):
		_base_db[bus] = AudioServer.get_bus_volume_db(index)
	AudioServer.set_bus_mute(index, volume <= 0.0)
	AudioServer.set_bus_volume_db(index, _base_db[bus] + linear_to_db(maxf(volume, 0.0001)))


static func _volume(key: String) -> float:
	var value: Variant = _read().get(key)
	return clampf(float(value), 0.0, 1.0) if value is float or value is int else 1.0


static func _store(key: String, volume: float) -> void:
	var data := _read()
	data[key] = clampf(volume, 0.0, 1.0)
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_warning("AudioSettings: não deu para gravar %s: %s" % [PATH, error_string(FileAccess.get_open_error())])
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
