class_name ObjectBar
extends PanelContainer
## A barra logo abaixo do objeto escolhido no mapa (map-editor/05): variante, espelho,
## bloqueio e apagar, pelos mesmos métodos do ObjectPanel.

var _panel: ObjectPanel
var _variant: Label
var _mirror: Button
var _blocks: Button


func _init(panel: ObjectPanel) -> void:
	_panel = panel
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = UiPalette.SURFACE
	style.border_color = UiPalette.ACCENT
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(4.0)
	add_theme_stylebox_override(&"panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	add_child(row)
	row.add_child(_button("chevron_left", "Variante anterior (←)", _panel.change_variant.bind(-1)))
	_variant = Label.new()
	_variant.custom_minimum_size.x = 44.0
	_variant.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_variant)
	row.add_child(_button("chevron_right", "Próxima variante (→)", _panel.change_variant.bind(1)))
	row.add_child(VSeparator.new())
	_mirror = _toggle("mirror", "Espelhar (M)", _panel.toggle_mirror)
	row.add_child(_mirror)
	_blocks = _toggle("lock", "Editar bloqueio: o clique num hexágono do objeto troca o bloqueio dele.", _panel.toggle_blocks)
	row.add_child(_blocks)
	var delete := _button("trash", "Apagar (Delete)", _panel.delete_selected)
	delete.theme_type_variation = &"DangerButton"
	row.add_child(delete)


func refresh() -> void:
	_variant.text = _panel.variant_text()
	_mirror.set_pressed_no_signal(_panel.is_mirrored())
	_blocks.set_pressed_no_signal(_panel.editing_blocks)


func _toggle(icon_name: String, tip: String, action: Callable) -> Button:
	var button := EditorTools.tool_button("", null)
	button.icon = load(MapEditor.ICONS % icon_name) as Texture2D
	button.add_theme_constant_override(&"icon_max_width", 20)
	button.tooltip_text = tip
	button.size_flags_horizontal = Control.SIZE_FILL
	button.pressed.connect(action)
	return button


func _button(icon_name: String, tip: String, action: Callable) -> Button:
	var button := Button.new()
	button.icon = load(MapEditor.ICONS % icon_name) as Texture2D
	button.add_theme_constant_override(&"icon_max_width", 20)
	button.tooltip_text = tip
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button
