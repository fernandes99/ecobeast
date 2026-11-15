class_name BlocksPanel
extends VBoxContainer
## O bloco da ferramenta Bloqueios (prop-depth-blocks/03): a peça escolhida por um ponto,
## um trecho ou a arte dela, e os botões do bloqueio, os mesmos do cadeado do `ObjectPanel`.

const EMPTY_TEXT := "Clique num ponto ou numa peça."

var _objects: ObjectPanel
var _target: Label
var _buttons: Array[Button] = []
var _close_button: Button
var _default_button: Button


func _init(objects: ObjectPanel) -> void:
	_objects = objects
	add_theme_constant_override(&"separation", 8)
	_target = Label.new()
	_target.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_target)
	var line_row := _row()
	line_row.add_child(_button("Nova linha", "Desenha uma linha a cliques: Enter ou o botão direito termina, e clicar no primeiro ponto fecha.", _objects.start_line))
	_close_button = _button("Fechar linha", "Liga o último ponto ao primeiro da linha mexida por último, ou desfaz isso.", _objects.toggle_closed)
	line_row.add_child(_close_button)
	_default_button = _button("Usar o padrão", "Volta a peça para as linhas padrão da variante dela.", _objects.use_type_block)
	_row().add_child(_default_button)
	var save_row := _row()
	save_row.add_child(_button("Salvar para esta variante", "As linhas desta peça viram o padrão desta variante do tipo, em todas as ilhas. Não se desfaz.", _objects.request_type_save.bind(false)))
	save_row.add_child(_button("Salvar para todas", "As linhas desta peça viram o padrão das variantes do tipo sem padrão próprio, em todas as ilhas. Não se desfaz.", _objects.request_type_save.bind(true)))
	_objects.selection_changed.connect(func(_index: int) -> void: refresh())
	_objects.edited.connect(func(_step: EditorHistory.Step) -> void: refresh())
	refresh()


func refresh() -> void:
	var index := _objects.selected_prop
	var draft := _objects.current_draft()
	var chosen := draft != null and index >= 0 and index < draft.props.size()
	for button: Button in _buttons:
		button.disabled = not chosen
	if not chosen:
		_target.text = EMPTY_TEXT
		return
	var piece: Dictionary = draft.props[index]
	var type_id := int(piece.get("prop_type_id", 0))
	var custom := draft.prop_is_custom(index)
	_target.text = "%s · variante %d · %s" % [str(GameData.get_row("prop_types", type_id).get("name", "?")), int(piece.get("variant", 1)), "ajustada" if custom else "padrão"]
	_default_button.disabled = not custom
	_close_button.text = "Abrir linha" if _objects.active_line_closed() else "Fechar linha"


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	add_child(row)
	return row


func _button(text: String, tip: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tip
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	_buttons.append(button)
	return button
