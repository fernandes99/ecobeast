extends CanvasLayer

const FLASH_SECONDS := 0.45
const ZOOM_SECONDS := 0.8
const REVEAL_SECONDS := 0.65
const FLASH_PEAK := 0.9
const MAX_ZOOM := 3.5
## O lado do bloco no fim do zoom e no começo do revelar, em pixels da tela de
## 720 × 1280: 120 é um sexto da largura, como na prévia.
const MAX_BLOCK := 120.0
const REVEAL_BLOCK := 96.0
const DARKEN_FROM := 0.6
const WAITING_DELAY := 0.4
const WAITING_TEXT := "Procurando..."
const BATTLE_SCREEN := &"board_battle"

enum State { IDLE, COVERING, COVERED, REVEALING }

var _state := State.IDLE
var _tween: Tween = null
var _cover_count: int = 0

@onready var _effect: ColorRect = %Effect
@onready var _waiting: Label = %Waiting
@onready var _shader: ShaderMaterial = _effect.material as ShaderMaterial


func _ready() -> void:
	_waiting.text = WAITING_TEXT
	_hide_layer()
	Router.screen_changed.connect(_on_screen_changed)


func is_covering() -> bool:
	return _state == State.COVERING or _state == State.COVERED


## Chame com await. `focus` é um ponto da tela do projeto (o
## `get_global_transform_with_canvas().origin` de quem está no centro). Devolve
## false, sem fazer nada, se outra transição já está correndo: aí não abra a luta.
## `opponent` (`&"wild"` ou `&"tamer"`) escolhe a música da luta, que começa junto.
func cover(focus: Vector2, opponent: StringName) -> bool:
	if _state != State.IDLE:
		return false
	_state = State.COVERING
	_cover_count += 1
	_shader.set_shader_parameter(&"focus", focus / _visible_size())
	_apply(1.0, 1.0, 0.0, 0.0)
	_effect.show()
	visible = true
	Music.play_battle(opponent)
	_tween = create_tween()
	_tween.tween_method(_flash_step, 0.0, 1.0, FLASH_SECONDS)
	_tween.tween_method(_zoom_step, 0.0, 1.0, ZOOM_SECONDS)
	await _tween.finished
	if _state != State.COVERING:
		return true
	_state = State.COVERED
	_show_waiting_later(_cover_count)
	return true


func reveal() -> void:
	if not is_covering():
		return
	_state = State.REVEALING
	_waiting.hide()
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_reveal_step, 1.0, 0.0, REVEAL_SECONDS)
	_tween.tween_callback(_hide_layer)


func _flash_step(progress: float) -> void:
	_apply(1.0, 1.0, absf(sin(progress * TAU)) * FLASH_PEAK, 0.0)


func _zoom_step(progress: float) -> void:
	var darken := clampf((progress - DARKEN_FROM) / (1.0 - DARKEN_FROM), 0.0, 1.0)
	_apply(1.0 + progress * (MAX_ZOOM - 1.0), 1.0 + progress * progress * (MAX_BLOCK - 1.0), 0.0, darken)


func _reveal_step(progress: float) -> void:
	_apply(1.0, 1.0 + progress * progress * (REVEAL_BLOCK - 1.0), 0.0, 0.0)


## `block` vem em pixels da tela do projeto e vai ao shader em pixels de verdade.
func _apply(zoom: float, block: float, flash: float, darken: float) -> void:
	var pixels_per_unit := float(get_window().size.x) / _visible_size().x
	_shader.set_shader_parameter(&"zoom", zoom)
	_shader.set_shader_parameter(&"block", maxf(1.0, block * pixels_per_unit))
	_shader.set_shader_parameter(&"flash", flash)
	_shader.set_shader_parameter(&"darken", darken)


func _visible_size() -> Vector2:
	return get_viewport().get_visible_rect().size


func _show_waiting_later(cover_count: int) -> void:
	await get_tree().create_timer(WAITING_DELAY).timeout
	if _state == State.COVERED and cover_count == _cover_count:
		_waiting.show()


func _hide_layer() -> void:
	_state = State.IDLE
	_waiting.hide()
	visible = false


## Nada pode deixar a tela preta para sempre: abrir qualquer tela que não seja a
## luta (a do login, quando a sessão cai) revela na hora.
func _on_screen_changed(id: StringName) -> void:
	if is_covering() and id != BATTLE_SCREEN:
		reveal()
		Music.fade_out()
