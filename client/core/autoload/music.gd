extends Node
## Autoload Music: a música do jogo, no canal de áudio `Music` (battle-intro/02).
## Um autoload continua tocando enquanto as telas trocam. Tocam música a luta (uma
## contra selvagem, outra contra Domador e o toque de vitória) e o mapa de Explorar
## zona (battle-intro/03).
## As músicas são geradas por res://assets/music/compose.py.

const BUS := &"Music"
const BATTLE_TRACKS: Dictionary[StringName, AudioStream] = {
	&"wild": preload("res://assets/music/battle_wild.ogg"),
	&"tamer": preload("res://assets/music/battle_tamer.ogg"),
}
const VICTORY := preload("res://assets/music/victory.ogg")
const EXPLORE := preload("res://assets/music/explore.ogg")
## Até onde o volume desce no sumir aos poucos, antes de parar.
const SILENT_DB := -60.0

var _player := AudioStreamPlayer.new()
## O volume subindo (entrar aos poucos) ou descendo (sumir aos poucos).
var _fade: Tween = null
## A música está sumindo: no fim, ela para.
var _fading_out: bool = false


func _ready() -> void:
	_player.bus = BUS
	add_child(_player)


## Toca em loop a música da luta de `&"wild"` ou `&"tamer"`. Se ela já toca, segue.
func play_battle(opponent: StringName) -> void:
	var stream: AudioStream = BATTLE_TRACKS.get(opponent)
	if stream == null or _is_playing(stream):
		return
	_start(stream)


## Para a música da luta e toca o toque de vitória uma vez.
func play_victory() -> void:
	_start(VICTORY)


## Toca em loop a música de Explorar zona. Se ela já toca, segue. Com `fade_in`,
## ela entra aos poucos nesse tempo, em segundos.
func play_explore(fade_in: float = 0.0) -> void:
	if _is_playing(EXPLORE):
		return
	_start(EXPLORE)
	if fade_in > 0.0:
		_player.volume_db = SILENT_DB
		_fade = create_tween()
		_fade.tween_property(_player, "volume_db", 0.0, fade_in)


## Baixa o volume até sumir e para. Interrompe uma entrada aos poucos.
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


## A música toca e não está sumindo.
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
