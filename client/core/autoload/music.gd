extends Node

const BUS := &"Music"
const BATTLE_TRACKS: Dictionary[StringName, AudioStream] = {
	&"wild": preload("res://assets/music/battle_wild.ogg"),
	&"tamer": preload("res://assets/music/battle_tamer.ogg"),
}
const VICTORY := preload("res://assets/music/victory.ogg")
const EXPLORE := preload("res://assets/music/explore.ogg")
const SILENT_DB := -60.0

var _player := AudioStreamPlayer.new()
var _fade: Tween = null
var _fading_out: bool = false


func _ready() -> void:
	_player.bus = BUS
	add_child(_player)


func play_battle(opponent: StringName) -> void:
	var stream: AudioStream = BATTLE_TRACKS.get(opponent)
	if stream == null or _is_playing(stream):
		return
	_start(stream)


func play_victory() -> void:
	_start(VICTORY)


func play_explore(fade_in: float = 0.0) -> void:
	if _is_playing(EXPLORE):
		return
	_start(EXPLORE)
	if fade_in > 0.0:
		_player.volume_db = SILENT_DB
		_fade = create_tween()
		_fade.tween_property(_player, "volume_db", 0.0, fade_in)


func fade_out(seconds: float = 1.0) -> void:
	if not _player.playing or _fading_out:
		return
	_stop_fade()
	_fading_out = true
	_fade = create_tween()
	_fade.tween_property(_player, "volume_db", SILENT_DB, seconds)
	_fade.tween_callback(stop)


func stop() -> void:
	_stop_fade()
	_player.stop()
	_player.volume_db = 0.0


func _is_playing(stream: AudioStream) -> bool:
	return _player.playing and _player.stream == stream and not _fading_out


func _start(stream: AudioStream) -> void:
	_stop_fade()
	_player.volume_db = 0.0
	_player.stream = stream
	_player.play()


func _stop_fade() -> void:
	_fading_out = false
	if _fade != null:
		_fade.kill()
		_fade = null
