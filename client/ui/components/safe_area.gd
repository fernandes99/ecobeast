class_name SafeArea
extends MarginContainer
## Margem que mantém o conteúdo fora do notch e das barras do sistema
## (foundation/02, RF-10). Todo conteúdo de tela fica dentro de um SafeArea.

## Margem mínima nas laterais, mesmo sem recorte na tela.
const MIN_SIDE_MARGIN := 24


func _ready() -> void:
	get_viewport().size_changed.connect(_update_margins)
	_update_margins()


func _update_margins() -> void:
	var window := Rect2(DisplayServer.window_get_position(), DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area()).intersection(window)
	if window.size.x <= 0.0 or safe.size.x <= 0.0:
		safe = window
	# A área segura vem em pixels da tela; as margens são em unidades do viewport
	# (720 de largura), que o stretch "canvas_items" escala para a janela.
	var to_viewport := 1.0
	if window.size.x > 0.0:
		to_viewport = get_viewport().get_visible_rect().size.x / window.size.x
	var left := (safe.position.x - window.position.x) * to_viewport
	var top := (safe.position.y - window.position.y) * to_viewport
	var right := (window.end.x - safe.end.x) * to_viewport
	var bottom := (window.end.y - safe.end.y) * to_viewport
	add_theme_constant_override(&"margin_left", maxi(roundi(left), MIN_SIDE_MARGIN))
	add_theme_constant_override(&"margin_right", maxi(roundi(right), MIN_SIDE_MARGIN))
	add_theme_constant_override(&"margin_top", roundi(top))
	add_theme_constant_override(&"margin_bottom", roundi(bottom))
