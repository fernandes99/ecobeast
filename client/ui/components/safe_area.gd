class_name SafeArea
extends MarginContainer

const MIN_SIDE_MARGIN := 24

## Dentro de uma aba do Hub, a margem de baixo é só a folga da aba levantada, porque a
## barra de abas já cuida da área segura (hub-start/03); -1 usa a área segura.
var bottom_override: int = -1


func _ready() -> void:
	get_viewport().size_changed.connect(_update_margins)
	_update_margins()


func _update_margins() -> void:
	var insets := screen_insets(get_viewport())
	add_theme_constant_override(&"margin_left", maxi(insets[0], MIN_SIDE_MARGIN))
	add_theme_constant_override(&"margin_right", maxi(insets[2], MIN_SIDE_MARGIN))
	add_theme_constant_override(&"margin_top", insets[1])
	add_theme_constant_override(&"margin_bottom", bottom_override if bottom_override >= 0 else insets[3])


## As margens da área segura (esquerda, cima, direita, baixo), em unidades do viewport.
static func screen_insets(viewport: Viewport) -> Array[int]:
	var window := Rect2(DisplayServer.window_get_position(), DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area()).intersection(window)
	if window.size.x <= 0.0 or safe.size.x <= 0.0:
		safe = window
	# A área segura vem em pixels da tela; as margens são em unidades do viewport
	# (720 de largura), que o stretch "canvas_items" escala para a janela.
	var to_viewport := 1.0
	if window.size.x > 0.0:
		to_viewport = viewport.get_visible_rect().size.x / window.size.x
	return [
		roundi((safe.position.x - window.position.x) * to_viewport),
		roundi((safe.position.y - window.position.y) * to_viewport),
		roundi((window.end.x - safe.end.x) * to_viewport),
		roundi((window.end.y - safe.end.y) * to_viewport),
	]
