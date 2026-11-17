class_name TamerGreetingPanel
extends PanelContainer

signal tapped
## Um bipe da voz tocou, na letra `letter` da fala (dialogue-voices/02).
signal blipped(letter: int)

const CHARS_PER_SECOND := 60.0
const VOICE_PATH := "res://assets/sounds/voices/%s.wav"
const VOICE_BUS := &"Voices"
const ICON_SIZE := 36.0
const MORE_ICON_SIZE := 22.0
const FONT_SIZE := 24

var _label := Label.new()
var _more_icon := TextureRect.new()
var _typing: Tween = null
var _player := AudioStreamPlayer.new()
var _voice: Dictionary = {}
## A letra de cada caractere da fala, ou -1 no espaço e na pontuação.
var _letters: PackedInt32Array = []
var _shown := 0

static var _streams: Dictionary[String, AudioStream] = {}


func _init() -> void:
	theme = BattleTheme.get_theme()
	theme_type_variation = BattleTheme.LOG
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	row.add_child(_icon(BattleTheme.icon("chat"), ICON_SIZE, Control.SIZE_SHRINK_CENTER))
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	row.add_child(_label)
	_more_icon = _icon(BattleTheme.icon("more"), MORE_ICON_SIZE, Control.SIZE_SHRINK_END)
	_more_icon.visible = false
	row.add_child(_more_icon)
	gui_input.connect(_on_input)
	_player.bus = VOICE_BUS
	_player.max_polyphony = 2
	add_child(_player)


## A fala aparece no ritmo da voz (`GameData.get_voice`), com os bipes dela; sem voz,
## a 60 letras por segundo e calada.
func say(text: String, voice: Dictionary = {}) -> void:
	if _typing != null:
		_typing.kill()
	_player.stop()
	_more_icon.visible = false
	_label.text = text
	_label.visible_characters = 0
	show()
	_voice = voice
	_player.stream = _stream(str(voice.get("slug", ""))) if not voice.is_empty() else null
	_letters = _letter_indexes(text)
	_shown = 0
	var count := _label.get_total_character_count()
	var speed := float(voice.get("chars_per_second", CHARS_PER_SECOND))
	_typing = create_tween()
	_typing.tween_method(_reveal, 0.0, float(count), count / speed)
	_typing.finished.connect(_finish_line.bind(false))


func close() -> void:
	if _typing != null:
		_typing.kill()
	_player.stop()
	hide()


## Ruído de -1 a 1 que só depende da letra, para a mesma fala soar igual.
static func pitch_noise(letter: int) -> float:
	var hashed := (letter * 1103515245 + 12345) & 0x7fffffff
	return float(hashed % 2001) / 1000.0 - 1.0


static func _letter_indexes(text: String) -> PackedInt32Array:
	var indexes := PackedInt32Array()
	var letter := 0
	for i: int in text.length():
		var c := text[i]
		if c.to_upper() != c.to_lower() or (c >= "0" and c <= "9"):
			indexes.append(letter)
			letter += 1
		else:
			indexes.append(-1)
	return indexes


func _reveal(characters: float) -> void:
	var shown := int(characters)
	if shown == _shown:
		return
	_label.visible_characters = shown
	var blip := -1
	if _player.stream != null:
		var every := maxi(1, int(_voice.get("letters_per_blip", 1)))
		for i: int in range(_shown, mini(shown, _letters.size())):
			if _letters[i] >= 0 and _letters[i] % every == 0:
				blip = _letters[i]
				break
	_shown = shown
	if blip >= 0:
		_player.pitch_scale = 1.0 + float(_voice.get("pitch_variation", 0)) / 100.0 * pitch_noise(blip)
		_player.play()
		blipped.emit(blip)


static func _stream(slug: String) -> AudioStream:
	if not _streams.has(slug):
		var path := VOICE_PATH % slug
		_streams[slug] = load(path) as AudioStream if ResourceLoader.exists(path) else null
	return _streams[slug]


func _on_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT or click.pressed:
		return
	if _more_icon.visible:
		tapped.emit()
	else:
		_finish_line()


## No fim do texto, o último bipe soa até o fim; o toque o corta.
func _finish_line(cut_voice := true) -> void:
	if _typing != null:
		_typing.kill()
	if cut_voice:
		_player.stop()
	_label.visible_characters = -1
	_more_icon.visible = true


func _icon(texture: Texture2D, side: float, vertical: Control.SizeFlags) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(side, side)
	icon.size_flags_vertical = vertical
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon
