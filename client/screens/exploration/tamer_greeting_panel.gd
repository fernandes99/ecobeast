class_name TamerGreetingPanel
extends PanelContainer

signal tapped

const CHARS_PER_SECOND := 60.0
const ICON_SIZE := 36.0
const MORE_ICON_SIZE := 22.0
const FONT_SIZE := 24

var _label := Label.new()
var _more_icon := TextureRect.new()
var _typing: Tween = null


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


func say(text: String) -> void:
	if _typing != null:
		_typing.kill()
	_more_icon.visible = false
	_label.text = text
	_label.visible_characters = 0
	show()
	var count := _label.get_total_character_count()
	_typing = create_tween()
	_typing.tween_property(_label, ^"visible_characters", count, count / CHARS_PER_SECOND)
	_typing.finished.connect(_finish_line)


func close() -> void:
	if _typing != null:
		_typing.kill()
	hide()


func _on_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT or click.pressed:
		return
	if _more_icon.visible:
		tapped.emit()
	else:
		_finish_line()


func _finish_line() -> void:
	if _typing != null:
		_typing.kill()
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
