class_name InteriorNpcPanel
extends VBoxContainer

## O painel da ferramenta NPC do modo Interiores (interiors/03): o NPC do catálogo, a fala
## (uma linha em branco separa as falas) e a ação depois da última fala. Com um NPC
## escolhido, mostra e edita o dele; sem, guarda o que o próximo vai ter.

signal changed(npc_id: int, dialogue: String, action_type_id: int)

var _npc_select: OptionButton
var _npc_ids: Array[int] = []
var _dialogue: TextEdit
var _action_select: OptionButton
var _action_ids: Array[int] = []
var _title: Label
var _editing := false


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	_title = Label.new()
	_title.theme_type_variation = &"BoldLabel"
	add_child(_title)
	_npc_select = OptionButton.new()
	_npc_select.focus_mode = Control.FOCUS_NONE
	_npc_select.item_selected.connect(func(_item: int) -> void: _emit())
	add_child(_npc_select)
	var dialogue_title := Label.new()
	dialogue_title.text = "Fala"
	add_child(dialogue_title)
	_dialogue = TextEdit.new()
	_dialogue.custom_minimum_size = Vector2(0.0, 180.0)
	_dialogue.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_dialogue.placeholder_text = "Uma linha em branco separa as falas."
	_dialogue.focus_exited.connect(_emit)
	add_child(_dialogue)
	var action_title := Label.new()
	action_title.text = "Ação depois da última fala"
	add_child(action_title)
	_action_select = OptionButton.new()
	_action_select.focus_mode = Control.FOCUS_NONE
	_action_select.item_selected.connect(func(_item: int) -> void: _emit())
	add_child(_action_select)
	var hint := Label.new()
	hint.theme_type_variation = &"SecondaryLabel"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = "Botão esquerdo: pôr um NPC num quadrado livre, ou escolher e arrastar um. Botão direito ou Delete: apagar."
	add_child(hint)
	show_npc(null)


## Recarrega as listas do catálogo (chamado ao abrir o modo).
func refresh_lists() -> void:
	var npc_before := _selected_npc_id()
	_npc_select.clear()
	_npc_ids.clear()
	for row: Dictionary in GameData.get_rows("npcs"):
		var id := int(row.get("id", 0))
		_npc_select.add_icon_item(NpcSprite.icon_frame(id), str(row.get("name", "")))
		_npc_ids.append(id)
	_npc_select.select(maxi(0, _npc_ids.find(npc_before)))
	var action_before := _selected_action_id()
	_action_select.clear()
	_action_ids.clear()
	_action_select.add_item("Nenhuma")
	_action_ids.append(0)
	for row: Dictionary in GameData.get_rows("action_types"):
		_action_select.add_item(str(row.get("name", "")))
		_action_ids.append(int(row.get("id", 0)))
	_action_select.select(maxi(0, _action_ids.find(action_before)))


func show_npc(npc: InteriorNpc) -> void:
	_editing = npc != null
	_title.text = "NPC escolhido" if _editing else "Próximo NPC"
	if npc == null:
		return
	_npc_select.select(maxi(0, _npc_ids.find(npc.npc_id)))
	_dialogue.text = npc.dialogue
	_action_select.select(maxi(0, _action_ids.find(npc.action_type_id)))


func values() -> Dictionary:
	return {"npc_id": _selected_npc_id(), "dialogue": _dialogue.text, "action_type_id": _selected_action_id()}


func _selected_npc_id() -> int:
	var item := _npc_select.selected
	return _npc_ids[item] if item >= 0 and item < _npc_ids.size() else 0


func _selected_action_id() -> int:
	var item := _action_select.selected
	return _action_ids[item] if item >= 0 and item < _action_ids.size() else 0


func _emit() -> void:
	if _editing:
		changed.emit(_selected_npc_id(), _dialogue.text, _selected_action_id())
