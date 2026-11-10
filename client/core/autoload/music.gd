extends Node
## Autoload Music: a música do jogo, no canal de áudio `Music` (battle-intro/02).
## Um autoload continua tocando enquanto as telas trocam. Por enquanto só a luta
## tem música: uma contra selvagem, outra contra Domador e o toque de vitória.
## As músicas são geradas por res://assets/music/compose.py.

const BUS := &"Music"
const BATTLE_TRACKS: Dictionary[StringName, AudioStream] = {
	&"wild": preload("res://assets/music/battle_wild.ogg"),
	&"tamer": preload("res://assets/music/battle_tamer.ogg"),
}
const VICTORY := preload("res://assets/music/victory.ogg")
## Até onde o volume desce no sumir aos poucos, antes de parar.
const SILENT_DB := -60.0

var _player := AudioStreamPlayer.new()
var _fade: Tween = null


func _ready() -> void:
	_player.bus = BUS
	add_child(_player)


## Toca em loop a música da luta de `&"wild"` ou `&"tamer"`. Se ela já toca, segue.
func play_battle(opponent: StringName) -> void:
	var stream: AudioStream = BATTLE_TRACKS.get(opponent)
	if stream == null:
		return
	if _player.playing and _player.stream == stream and _fade == null:
		return
	_start(stream)


## Para a música da luta e toca o toque de vitória uma vez.
func play_victory() -> void:
	_start(VICTORY)


## Baixa o volume até sumir e para.
func fade_out(seconds: float = 1.0) -> void:
	if not _player.playing or _fade != null:
		return
	_fade = create_tween()
	_fade.tween_property(_player, "volume_db", SILENT_DB, seconds)
	_fade.tween_callback(stop)


func stop() -> void:
	_stop_fade()
	_player.stop()
	_player.volume_db = 0.0


func _start(stream: AudioStream) -> void:
	_stop_fade()
	_player.volume_db = 0.0
	_player.stream = stream
	_player.play()


func _stop_fade() -> void:
	if _fade != null:
		_fade.kill()
		_fade = null
