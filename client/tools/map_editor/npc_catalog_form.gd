class_name NpcCatalogForm
extends VBoxContainer

## Criar, editar e excluir NPCs do catálogo, no topo da ferramenta NPC (island-npcs/04).
## Salva na hora pelas rotas do editor e baixa o catálogo de novo antes de avisar.

signal saved(npc_id: int)
signal removed(npc_id: int)
signal message(text: String, error: bool)

enum Kind { CREATURE, PERSON }

const REMOVE_TEXT := "Excluir do catálogo"
const CONFIRM_TEXT := "Confirmar: excluir"
const MAX_NAME := 30
const MAX_DESCRIPTION := 200
const DIALOGUE_HEIGHT := 96.0
const IN_DRAFT_TEXT := "%s está posto nesta ilha: tire-o do mapa e salve a ilha antes de excluir."
const IN_SCENES_TEXT := "%s está nas cenas da história: %s. Tire-o de lá antes de excluir."

## Diz se o NPC está posto no rascunho aberto, que o servidor ainda não conhece.
var placed_in_draft: Callable = func(_id: int) -> bool: return false

var _target := 0
## -1 sem formulário, 0 o NPC novo, senão o id do que está sendo editado.
var _editing := -1
var _busy := false

var _edit_button: Button
var _remove_button: Button
var _form: VBoxContainer
var _form_title: Label
var _name: LineEdit
var _description: LineEdit
var _kind: OptionButton
var _species_row: HBoxContainer
var _species: OptionButton
var _species_slugs: Array[String] = []
var _body_row: HBoxContainer
var _body: OptionButton
var _dialogue: TextEdit
var _save_button: Button


func _init() -> void:
	add_theme_constant_override(&"separation", 6)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override(&"separation", 6)
	add_child(actions)
	actions.add_child(QuestEditorStyle.outline("+ Novo NPC", _open.bind(0)))
	_edit_button = QuestEditorStyle.outline("Editar", func() -> void: _open(_target))
	actions.add_child(_edit_button)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(gap)
	_remove_button = QuestEditorStyle.mini(REMOVE_TEXT, _remove, true)
	_remove_button.add_theme_font_size_override(&"font_size", QuestEditorStyle.SMALL_FONT)
	actions.add_child(_remove_button)
	_build_form()
	set_target(0)


func _build_form() -> void:
	_form = QuestEditorStyle.card(self, "")
	_form_title = Label.new()
	_form_title.theme_type_variation = &"BoldLabel"
	_form.add_child(_form_title)
	_name = LineEdit.new()
	_name.max_length = MAX_NAME
	_name.placeholder_text = "Dona Zélia"
	_form.add_child(QuestPanel._row("Nome", _name))
	_description = LineEdit.new()
	_description.max_length = MAX_DESCRIPTION
	_description.placeholder_text = "Só para o editor"
	_form.add_child(QuestPanel._row("Descrição", _description))
	_kind = OptionButton.new()
	_kind.add_item("Ecobeast", Kind.CREATURE)
	_kind.add_item("Pessoa", Kind.PERSON)
	_kind.item_selected.connect(func(_index: int) -> void: _refresh_kind())
	_form.add_child(QuestPanel._row("Tipo", _kind))
	_species = OptionButton.new()
	for row: Dictionary in GameData.get_rows("species"):
		_species.add_item(str(row.get("name", "")))
		_species_slugs.append(str(row.get("slug", "")))
	_species_row = QuestPanel._row("Ecobeast", _species)
	_form.add_child(_species_row)
	_body = OptionButton.new()
	for row: Dictionary in GameData.get_rows("body_types"):
		_body.add_item(str(row.get("name", "")), int(row.get("id", 0)))
	_body_row = QuestPanel._row("Corpo", _body)
	_form.add_child(_body_row)
	_form.add_child(QuestEditorStyle.secondary("Fala padrão: a que o NPC ganha ao ser posto no mapa; cada parágrafo é uma caixa."))
	_dialogue = TextEdit.new()
	_dialogue.custom_minimum_size.y = DIALOGUE_HEIGHT
	_dialogue.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_dialogue.placeholder_text = "Bom dia!\n\nQuer uma flor?"
	_dialogue.add_theme_font_size_override(&"font_size", QuestEditorStyle.FIELD_FONT)
	_form.add_child(_dialogue)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 6)
	_form.add_child(buttons)
	_save_button = QuestPanel._button("Criar", _save)
	buttons.add_child(_save_button)
	buttons.add_child(QuestEditorStyle.outline("Cancelar", _close))
	_form.get_parent().visible = false


## O NPC escolhido na lista, que o Editar e o Excluir usam.
func set_target(id: int) -> void:
	if id != _target:
		_remove_button.text = REMOVE_TEXT
	_target = id
	var npc_name := _npc_name(id)
	_edit_button.disabled = id <= 0
	_remove_button.disabled = id <= 0
	_edit_button.tooltip_text = "Edita %s no catálogo." % npc_name if id > 0 else "Escolha um NPC na lista."
	_remove_button.tooltip_text = "Apaga %s do catálogo, se ele não estiver em uso." % npc_name if id > 0 else "Escolha um NPC na lista."


func is_open() -> bool:
	return _editing >= 0


func _open(id: int) -> void:
	_editing = id
	var npc := GameData.get_npc(id) if id > 0 else {}
	_form_title.text = "Novo NPC" if id == 0 else "Editar %s" % npc.get("name", "")
	_save_button.text = "Criar" if id == 0 else "Salvar"
	_name.text = str(npc.get("name", ""))
	_description.text = str(npc.get("description", ""))
	_dialogue.text = str(npc.get("default_dialogue", ""))
	var sprite: Variant = npc.get("sprite")
	var person := id > 0 and sprite == null
	_kind.select(Kind.PERSON if person else Kind.CREATURE)
	_kind.disabled = id > 0
	_species.select(maxi(0, _species_slugs.find(str(sprite)) if sprite is String else 0))
	_form.get_parent().visible = true
	_refresh_kind()
	_name.grab_focus.call_deferred()


func _close() -> void:
	_editing = -1
	_form.get_parent().visible = false


func _refresh_kind() -> void:
	var person := _kind.get_selected_id() == Kind.PERSON
	_species_row.visible = not person
	_body_row.visible = person and _editing == 0


func _save() -> void:
	if _busy or _editing < 0:
		return
	var body := {
		"name": _name.text,
		"description": _description.text,
		"default_dialogue": _dialogue.text,
	}
	var person := _kind.get_selected_id() == Kind.PERSON
	if not person and _species.selected >= 0:
		body["sprite"] = _species_slugs[_species.selected]
	if person and _editing == 0:
		body["body_type_id"] = _body.get_selected_id()
	var editing := _editing
	_busy = true
	var response: ApiResponse
	if editing == 0:
		response = await EditorApi.create_npc(body)
	else:
		response = await EditorApi.update_npc(editing, body)
	if not response.ok:
		_busy = false
		message.emit(response.error, true)
		return
	await GameData.load_catalog()
	_busy = false
	var id := DictFields.get_int(response.data as Dictionary, "id")
	_close()
	message.emit(("NPC criado: %s." if editing == 0 else "NPC salvo: %s.") % _npc_name(id), false)
	saved.emit(id)


func _remove() -> void:
	if _busy or _target <= 0:
		return
	var id := _target
	var npc_name := _npc_name(id)
	if placed_in_draft.call(id):
		message.emit(IN_DRAFT_TEXT % npc_name, true)
		return
	var scenes := scenes_using(id)
	if not scenes.is_empty():
		message.emit(IN_SCENES_TEXT % [npc_name, ", ".join(scenes)], true)
		return
	if _remove_button.text != CONFIRM_TEXT:
		_remove_button.text = CONFIRM_TEXT
		return
	_remove_button.text = REMOVE_TEXT
	_busy = true
	var response: ApiResponse = await EditorApi.delete_npc(id)
	if not response.ok:
		_busy = false
		message.emit(response.error, true)
		return
	await GameData.load_catalog()
	_busy = false
	if _editing == id:
		_close()
	message.emit("NPC excluído: %s." % npc_name, false)
	removed.emit(id)


## Os nomes das cenas da história que citam o NPC (`npc_id` no gatilho, nos atores ou nos passos).
static func scenes_using(id: int) -> Array[String]:
	var names: Array[String] = []
	for scene: StoryScene in Story.library.scenes:
		if _mentions(scene.to_dict(), id):
			names.append(scene.name if not scene.name.is_empty() else scene.slug)
	return names


static func _mentions(value: Variant, id: int) -> bool:
	if value is Dictionary:
		for key: Variant in value:
			if key == "npc_id" and (value[key] is int or value[key] is float) and int(value[key]) == id:
				return true
			if _mentions(value[key], id):
				return true
	elif value is Array:
		for item: Variant in value:
			if _mentions(item, id):
				return true
	return false


static func _npc_name(id: int) -> String:
	if id <= 0:
		return ""
	return str(GameData.get_npc(id).get("name", "NPC %d" % id))
