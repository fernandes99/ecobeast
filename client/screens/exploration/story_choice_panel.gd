class_name StoryChoicePanel
extends VBoxContainer

## As opções de uma escolha da cena, logo acima da caixa de fala (story/02).

signal chosen(index: int)

const BUTTON_HEIGHT := 64.0
const FONT_SIZE := 22


func _init() -> void:
	theme = BattleTheme.get_theme()
	add_theme_constant_override(&"separation", 10)
	visible = false


func show_options(texts: Array[String]) -> void:
	for child: Node in get_children():
		child.queue_free()
	for index: int in texts.size():
		var button := Button.new()
		button.text = texts[index]
		button.theme_type_variation = BattleTheme.BUTTON
		button.custom_minimum_size.y = BUTTON_HEIGHT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override(&"font_size", FONT_SIZE)
		button.pressed.connect(_choose.bind(index))
		add_child(button)
	show()


func close() -> void:
	hide()


func _choose(index: int) -> void:
	hide()
	chosen.emit(index)
