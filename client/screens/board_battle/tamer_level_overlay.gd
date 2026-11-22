class_name TamerLevelOverlay
extends Control

signal finished

const ENTER_TIME := 0.45
const PULSE_TIME := 0.8
const ENTER_SCALE := 0.6
const PULSE_GLOW := 0.55
const TAMER_SCALE := 6.0
const TAMER_FOOT_GAP := 24.0
const REWARD_FONT_SIZE := 28
const REWARD_ICON_SIZE := 64
const COIN_ICON := preload("res://ui/icons/coin.svg")
const ITEM_ICON_SCENE := preload("res://ui/components/item_icon.tscn")

var _pulse: Tween = null
var _round: int = 0

@onready var _dim: ColorRect = %Dim
@onready var _title: Label = %Title
@onready var _stage: Control = %Stage
@onready var _glow: Panel = %Glow
@onready var _tamer: TamerSprite = %Tamer
@onready var _level_label: Label = %LevelLabel
@onready var _rewards: VBoxContainer = %Rewards
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	hide()
	_dim.color = UiPalette.OVERLAY
	_title.add_theme_color_override(&"font_color", UiPalette.WARNING)
	_continue_button.pressed.connect(close)
	_stage.resized.connect(_place_tamer)


func play(progress: TamerProgress, appearance: TamerAppearance) -> void:
	_round += 1
	_title.text = "Domador nível %d!" % progress.level_after
	_level_label.text = "Nv. %d → Nv. %d" % [progress.level_before, progress.level_after]
	_tamer.set_appearance(appearance)
	_tamer.play_idle()
	_fill_rewards(progress)
	show()
	_place_tamer()
	_animate(_round)
	await finished


func close() -> void:
	if not visible:
		return
	if _pulse != null:
		_pulse.kill()
		_pulse = null
	hide()
	finished.emit()


func _place_tamer() -> void:
	_tamer.position = Vector2(_stage.size.x / 2.0, _stage.size.y - TAMER_FOOT_GAP).round()


func _fill_rewards(progress: TamerProgress) -> void:
	for row: Node in _rewards.get_children():
		_rewards.remove_child(row)
		row.queue_free()
	var coins := progress.reward_coins()
	if coins > 0:
		var icon := TextureRect.new()
		icon.texture = COIN_ICON
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(REWARD_ICON_SIZE, REWARD_ICON_SIZE)
		_add_reward(icon, "+%s moedas" % NumberFormat.thousands(coins))
	var items := progress.reward_items()
	for item_id: int in items:
		var item := GameData.get_item(item_id)
		if item == null:
			continue
		var icon: ItemIcon = ITEM_ICON_SCENE.instantiate()
		icon.icon_size = REWARD_ICON_SIZE
		icon.set_item(item)
		_add_reward(icon, "%s × %d" % [item.name, int(items[item_id])])
	_rewards.get_parent().visible = _rewards.get_child_count() > 0


func _add_reward(icon: Control, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 16)
	row.add_child(icon)
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", REWARD_FONT_SIZE)
	row.add_child(label)
	_rewards.add_child(row)


func _animate(round_id: int) -> void:
	_tamer.scale = Vector2.ONE * TAMER_SCALE * ENTER_SCALE
	_glow.modulate.a = 0.0
	var enter := create_tween().set_parallel()
	enter.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	enter.tween_property(_tamer, "scale", Vector2.ONE * TAMER_SCALE, ENTER_TIME)
	enter.tween_property(_glow, "modulate:a", 1.0, ENTER_TIME)
	await enter.finished
	if round_id != _round or not visible:
		return
	_pulse = create_tween().set_loops()
	_pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse.tween_property(_glow, "modulate:a", PULSE_GLOW, PULSE_TIME)
	_pulse.tween_property(_glow, "modulate:a", 1.0, PULSE_TIME)
