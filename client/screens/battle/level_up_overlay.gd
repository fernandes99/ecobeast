class_name LevelUpOverlay
extends Control
## A comemoração de quem subiu de nível depois da vitória (progression/03,
## TELAS.md #7): o retrato grande e animado, o nível antigo e o novo e os stats
## de antes e depois. Os números já vieram do servidor.

signal finished

## Tempos em segundos e escalas do retrato. A revisar.
const ENTER_TIME := 0.45
const PULSE_TIME := 0.8
const ENTER_SCALE := Vector2(0.6, 0.6)
const PULSE_SCALE := Vector2(1.06, 1.06)
## O brilho fica mais fraco no meio do pulso.
const PULSE_GLOW := 0.55
const STAT_FONT_SIZE := 26
const GAIN_WIDTH := 72.0

var _pulse: Tween = null
## Cada `play` conta uma vez: a animação de uma tela já fechada não recomeça.
var _round: int = 0

@onready var _dim: ColorRect = %Dim
@onready var _title: Label = %Title
@onready var _glow: Panel = %Glow
@onready var _portrait: CreaturePortrait = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _stats: VBoxContainer = %Stats
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	hide()
	_dim.color = UiPalette.OVERLAY
	_title.add_theme_color_override(&"font_color", UiPalette.WARNING)
	_continue_button.pressed.connect(close)


## Só termina quando o jogador toca em "Continuar": quem chama espera com `await`.
func play(progress: CreatureProgress, species_id: int, display_name: String) -> void:
	_round += 1
	_portrait.set_species(species_id)
	_name_label.text = display_name
	_level_label.text = "Nv. %d → Nv. %d" % [progress.level_before, progress.level_after]
	_fill_stats(progress.stats_before, progress.stats_after)
	show()
	_animate(_round)
	await finished


## O "Continuar", e também o voltar do Android.
func close() -> void:
	if not visible:
		return
	if _pulse != null:
		_pulse.kill()
		_pulse = null
	hide()
	finished.emit()


func _fill_stats(before: StatBlock, after: StatBlock) -> void:
	for row: Node in _stats.get_children():
		_stats.remove_child(row)
		row.queue_free()
	for slug: String in StatBlock.SLUGS:
		var old_value := before.get_value(slug)
		var new_value := after.get_value(slug)
		var row := HBoxContainer.new()
		var stat_name := _stat_label(GameData.get_stat_name(slug), UiPalette.TEXT_SECONDARY)
		stat_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(stat_name)
		row.add_child(_stat_label("%d → %d" % [old_value, new_value], UiPalette.TEXT))
		var gain := _stat_label("+%d" % (new_value - old_value), UiPalette.HP_HIGH)
		gain.custom_minimum_size.x = GAIN_WIDTH
		gain.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(gain)
		_stats.add_child(row)


func _stat_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", STAT_FONT_SIZE)
	label.add_theme_color_override(&"font_color", color)
	return label


## O retrato entra crescendo e depois pulsa com o brilho, até a tela fechar.
func _animate(round_id: int) -> void:
	_portrait.pivot_offset = _portrait.size / 2.0
	_portrait.scale = ENTER_SCALE
	_glow.modulate.a = 0.0
	var enter := create_tween().set_parallel()
	enter.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	enter.tween_property(_portrait, "scale", Vector2.ONE, ENTER_TIME)
	enter.tween_property(_glow, "modulate:a", 1.0, ENTER_TIME)
	await enter.finished
	if round_id != _round or not visible:
		return
	_pulse = create_tween().set_loops()
	_pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse.tween_property(_portrait, "scale", PULSE_SCALE, PULSE_TIME)
	_pulse.parallel().tween_property(_glow, "modulate:a", PULSE_GLOW, PULSE_TIME)
	_pulse.tween_property(_portrait, "scale", Vector2.ONE, PULSE_TIME)
	_pulse.parallel().tween_property(_glow, "modulate:a", 1.0, PULSE_TIME)
