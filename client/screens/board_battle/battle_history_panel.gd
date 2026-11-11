class_name BattleHistoryPanel
extends Control

const LINE_FONT_SIZE := 22

@onready var _dim: ColorRect = %Dim
@onready var _scroll: ScrollContainer = %Scroll
@onready var _lines: VBoxContainer = %Lines


func _ready() -> void:
	hide()
	_dim.color = UiPalette.OVERLAY
	%CloseButton.pressed.connect(close)
	_scroll.get_v_scroll_bar().changed.connect(_scroll_to_end)


func add_line(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", LINE_FONT_SIZE)
	_lines.add_child(label)


func open() -> void:
	show()
	_scroll_to_end.call_deferred()


func close() -> void:
	hide()


func _scroll_to_end() -> void:
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)
