class_name TamerCreatorPanel
extends PanelContainer

## A criação do Domador por cima do mapa (liora-intro/03): o `TamerEditor` na metade de
## baixo da tela, e o Domador do mapa vestindo cada mudança. O "Pronto" grava o nome (se
## faltava) e a aparência.

signal appearance_changed(appearance: TamerAppearance)
signal done

## Do meio para baixo da tela.
const TOP_RATIO := 0.48
const READY_TEXT := "Pronto"
const SAVING_TEXT := "Salvando..."
const BUTTON_HEIGHT := 88.0

var _editor := TamerEditor.new()
var _message := Label.new()
var _ready_button := Button.new()
var _saving := false


func _init() -> void:
	theme_type_variation = &"SectionPanel"
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = TOP_RATIO
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	add_child(column)
	_editor.size_flags_vertical = SIZE_EXPAND_FILL
	_editor.changed.connect(func(appearance: TamerAppearance) -> void: appearance_changed.emit(appearance))
	_editor.name_changed.connect(_update_button)
	column.add_child(_editor)
	_message.theme_type_variation = &"DangerLabel"
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.visible = false
	column.add_child(_message)
	_ready_button.text = READY_TEXT
	_ready_button.custom_minimum_size.y = BUTTON_HEIGHT
	_ready_button.pressed.connect(_save)
	column.add_child(_ready_button)


func _ready() -> void:
	var player := Session.player
	var appearance := player.appearance if player != null else TamerAppearance.standard()
	_editor.open(appearance, player != null and not player.has_name())
	_update_button()


func _update_button() -> void:
	_ready_button.disabled = _saving or not _editor.is_ready()


func _save() -> void:
	if _saving or not _editor.is_ready():
		return
	_saving = true
	_message.hide()
	_ready_button.text = SAVING_TEXT
	_update_button()
	var result := await _store()
	_saving = false
	_ready_button.text = READY_TEXT
	_update_button()
	if not result.ok:
		_message.text = result.error
		_message.show()
		return
	done.emit()


func _store() -> Result:
	if _editor.asks_name():
		var named: Result = await Session.set_tamer_name(_editor.tamer_name())
		if not named.ok:
			return named
		# O nome já ficou: se a aparência falhar, o "Pronto" grava só ela.
		_editor.open(_editor.draft, false)
	return await Session.update_appearance(_editor.draft)
