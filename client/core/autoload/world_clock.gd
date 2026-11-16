extends Node
## O relógio do mundo (.specs/day-night/): a hora vem do servidor e daí em diante o
## jogo conta sozinho, sem o relógio do celular, que o jogador pode mudar.

signal phase_changed(phase: DayPhase)
signal synced

const PATH := "/v1/world-clock"
const MINUTES_PER_DAY := 1440.0
## 1 segundo real é 1 minuto do jogo.
const MINUTES_PER_MS := 0.001

## Só para testar: soma à hora deste aparelho, até fechar o jogo.
var debug_offset_minutes := 0.0

var _synced := false
var _syncing := false
var _base_minute := 0.0
var _base_ticks := 0
var _phase: DayPhase = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and _synced:
		sync()


func _process(_delta: float) -> void:
	if not _synced:
		return
	var current := DayPhase.at(minute_of_day(), GameData.get_day_phases())
	if current != _phase:
		_phase = current
		phase_changed.emit(current)


## Pede a hora ao servidor. Falhou, fica como estava e tenta na próxima vez.
func sync() -> bool:
	if _syncing:
		return false
	_syncing = true
	var sent := Time.get_ticks_msec()
	var response: ApiResponse = await Api.request(HTTPClient.METHOD_GET, PATH)
	_syncing = false
	var data: Dictionary = response.data if response.ok and response.data is Dictionary else {}
	if not (data.get("minute_of_day") is float or data.get("minute_of_day") is int):
		return false
	var now := Time.get_ticks_msec()
	_base_minute = float(data["minute_of_day"]) + (now - sent) * 0.5 * MINUTES_PER_MS
	_base_ticks = now
	var first := not _synced
	_synced = true
	if first:
		synced.emit()
	return true


func is_synced() -> bool:
	return _synced


func minute_of_day() -> float:
	return fposmod(_server_minute() + debug_offset_minutes, MINUTES_PER_DAY)


## Só para testar: põe o relógio deste aparelho no minuto, e ele segue andando dali.
func debug_set_minute(minute: float) -> void:
	debug_offset_minutes = minute - _server_minute()


func _server_minute() -> float:
	var elapsed := (Time.get_ticks_msec() - _base_ticks) * MINUTES_PER_MS
	return fposmod(_base_minute + elapsed, MINUTES_PER_DAY)


func hour() -> float:
	return minute_of_day() / 60.0


## A parte do dia agora; null antes de sincronizar.
func phase() -> DayPhase:
	if not _synced:
		return null
	return DayPhase.at(minute_of_day(), GameData.get_day_phases())


## "19h05": a hora do jogo, para o debug.
func clock_text() -> String:
	var minute := int(minute_of_day())
	return "%02dh%02d" % [floori(minute / 60.0), minute % 60]
