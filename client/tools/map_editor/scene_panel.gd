class_name ScenePanel
extends VBoxContainer

## A ferramenta Cenas (story/04): as cenas da ilha aberta, os campos, o gatilho, os
## atores e os passos (`SceneSteps`), salvas em `res://story/scenes/<slug>.json`.

## Mudou algo que o mapa desenha.
signal changed
signal message(text: String, error: bool)
signal test_requested(scene: StoryScene, marks: Array[String])

const TRIGGERS: Array[Array] = [["Ao entrar na ilha", "auto"], ["Ao tocar no NPC", "npc"], ["Ao pisar na área", "area"]]
const PICK_TEXT := "Clique num hexágono da ilha. Esc ou o botão direito desistem."
const AREA_PICK_TEXT := "Cada clique põe ou tira um hexágono da área. Aperte Pronto no fim."
const OUTSIDE_TEXT := "Esse hexágono não é da ilha."
const NO_ISLAND_TEXT := "Salve a ilha para criar cenas."
const NO_EDITOR_TEXT := "Abra o jogo pelo Godot para salvar cenas."
const NOT_PUBLISHED_TEXT := "Publique a ilha para testar a cena."
const NO_PLAYER_TEXT := "Entre com um Domador para testar."

var picking_area := false

var _draft: IslandDraft = null
var _published := false
var _scene: StoryScene = null
var _slug := ""
var _dirty := false
var _pick: Callable = Callable()
var _pending_slug := ""

var _blocked := Label.new()
var _box := VBoxContainer.new()
var _list := OptionButton.new()
var _new_box := VBoxContainer.new()
var _new_slug := LineEdit.new()
var _new_name := LineEdit.new()
var _body := VBoxContainer.new()
var _name_edit := LineEdit.new()
var _repeatable := CheckBox.new()
var _priority := EditorNumberField.new(-99, 99, true, false)
var _requires := LineEdit.new()
var _forbids := LineEdit.new()
var _trigger := OptionButton.new()
var _npc_row := HBoxContainer.new()
var _npc_option := OptionButton.new()
var _area_row := HBoxContainer.new()
var _area_label := Label.new()
var _area_button := Button.new()
var _actors_box := VBoxContainer.new()
var _steps := SceneSteps.new()
var _test_marks := LineEdit.new()
var _save_button: Button
var _discard_button: Button
var _test_button: Button
var _delete_button: Button
var _hint := Label.new()
var _empty_hint := Label.new()
var _confirm := ConfirmationDialog.new()


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	_blocked.text = NO_ISLAND_TEXT
	_blocked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_blocked)
	_box.add_theme_constant_override(&"separation", 8)
	add_child(_box)
	_confirm.get_ok_button().text = "Sim"
	_confirm.get_cancel_button().text = "Não"
	add_child(_confirm)

	var top := HBoxContainer.new()
	_box.add_child(top)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.focus_mode = Control.FOCUS_NONE
	_list.clip_text = true
	_list.item_selected.connect(_on_list_selected)
	top.add_child(_list)
	top.add_child(_button("Nova cena", _show_new))
	_delete_button = _button("Apagar", _ask_delete)
	_delete_button.theme_type_variation = &"DangerButton"
	top.add_child(_delete_button)

	_new_box.visible = false
	_box.add_child(_new_box)
	_new_slug.placeholder_text = "slug (letras minúsculas, números e _)"
	_new_box.add_child(_new_slug)
	_new_name.placeholder_text = "Nome da cena"
	_new_box.add_child(_new_name)
	var new_row := HBoxContainer.new()
	_new_box.add_child(new_row)
	new_row.add_child(_button("Criar", _create))
	new_row.add_child(_button("Cancelar", func() -> void: _new_box.hide()))

	_empty_hint.text = "Escolha uma cena na lista acima ou crie uma com Nova cena. Os botões Salvar e Testar daqui ficam no fim do painel da cena."
	_empty_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty_hint.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	_box.add_child(_empty_hint)
	_body.add_theme_constant_override(&"separation", 6)
	_box.add_child(_body)
	_field_label("Nome")
	_name_edit.text_changed.connect(func(text: String) -> void: _edit(func() -> void: _scene.name = text))
	_body.add_child(_name_edit)
	var row := HBoxContainer.new()
	_body.add_child(row)
	_repeatable.text = "Repetível"
	_repeatable.tooltip_text = "Roda sempre que o gatilho disparar e não liga o próprio Marco."
	_repeatable.focus_mode = Control.FOCUS_NONE
	_repeatable.toggled.connect(func(on: bool) -> void: _edit(func() -> void: _scene.repeatable = on))
	_repeatable.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_repeatable)
	var priority_label := Label.new()
	priority_label.text = "Prioridade"
	row.add_child(priority_label)
	_priority.changed.connect(func() -> void: _edit(func() -> void: _scene.priority = int(_priority.value())))
	row.add_child(_priority)
	_marks_field("Precisa dos Marcos", _requires, func(marks: Array[String]) -> void: _scene.requires = marks)
	_marks_field("Não pode ter os Marcos", _forbids, func(marks: Array[String]) -> void: _scene.forbids = marks)

	_field_label("Gatilho")
	_trigger.focus_mode = Control.FOCUS_NONE
	for pair: Array in TRIGGERS:
		_trigger.add_item(pair[0])
	_trigger.item_selected.connect(_on_trigger_selected)
	_body.add_child(_trigger)
	_npc_option.focus_mode = Control.FOCUS_NONE
	_npc_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_npc_option.item_selected.connect(func(index: int) -> void: _edit(func() -> void: _scene.trigger["npc_id"] = _npc_option.get_item_id(index)))
	_npc_row.add_child(_npc_option)
	_body.add_child(_npc_row)
	_area_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_area_row.add_child(_area_label)
	_area_button.focus_mode = Control.FOCUS_NONE
	_area_button.pressed.connect(_toggle_area_pick)
	_area_row.add_child(_area_button)
	_body.add_child(_area_row)

	_field_label("Atores")
	_actors_box.add_theme_constant_override(&"separation", 4)
	_body.add_child(_actors_box)
	_body.add_child(_button("+ Ator", _add_actor))

	_steps.changed.connect(func() -> void: _edit(Callable()))
	_steps.pick_requested.connect(_start_pick)
	_body.add_child(_steps)

	_body.add_child(HSeparator.new())
	_field_label("Marcos do teste (separados por vírgula)")
	_body.add_child(_test_marks)
	var actions := HBoxContainer.new()
	_body.add_child(actions)
	_save_button = _button("Salvar", save)
	actions.add_child(_save_button)
	_discard_button = _button("Descartar", _discard)
	actions.add_child(_discard_button)
	_test_button = _button("Testar daqui", _test)
	actions.add_child(_test_button)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	_body.add_child(_hint)
	_refresh()


func set_draft(draft: IslandDraft) -> void:
	if draft != _draft and _dirty and _scene != null:
		message.emit("As mudanças da cena %s foram descartadas." % _scene.name, true)
	_draft = draft
	var scenes: Array[StoryScene] = []
	if draft != null and draft.id > 0:
		scenes = Story.library.for_island(draft.id)
	_open_scene(scenes[0].slug if not scenes.is_empty() else "")


func set_published(published: bool) -> void:
	_published = published
	_refresh()


func has_scene() -> bool:
	return _scene != null


func is_picking() -> bool:
	return _pick.is_valid() or picking_area


## Um clique no mapa com a ferramenta Cenas.
func pick(coord: Vector2i) -> void:
	if _draft == null or not _draft.tiles.has(coord):
		message.emit(OUTSIDE_TEXT, true)
		return
	if picking_area:
		var tiles: Array = DictFields.get_array(_scene.trigger, "tiles")
		var found := -1
		for index: int in tiles.size():
			if StoryValidator.coord_of(tiles[index]) == coord:
				found = index
		if found >= 0:
			tiles.remove_at(found)
		else:
			tiles.append({"q": coord.x, "r": coord.y})
		_scene.trigger["tiles"] = tiles
		_edit(Callable())
		return
	if _pick.is_valid():
		var done := _pick
		_pick = Callable()
		done.call(coord)
		message.emit("", false)
		changed.emit()


func cancel_pick() -> void:
	_pick = Callable()
	if picking_area:
		_toggle_area_pick()
	message.emit("", false)


## O que o mapa desenha: a área, os atores com hexágono e o destino do passo escolhido.
func map_marks() -> Dictionary:
	var result := {"area": [] as Array[Vector2i], "actors": [], "target": null, "from": null}
	if _scene == null:
		return result
	if DictFields.get_string(_scene.trigger, "type") == "area":
		for tile: Variant in DictFields.get_array(_scene.trigger, "tiles"):
			var coord: Variant = StoryValidator.coord_of(tile)
			if coord != null:
				(result["area"] as Array[Vector2i]).append(coord)
	var positions: Dictionary[String, Vector2i] = {"tamer": _draft.start if _draft != null else Vector2i.ZERO}
	for actor: Dictionary in _scene.actors:
		var coord: Variant = StoryValidator.coord_of(actor)
		if coord != null:
			positions[str(actor.get("key", ""))] = coord
			(result["actors"] as Array).append({"coord": coord, "npc_id": DictFields.get_int(actor, "npc_id"), "hidden": not DictFields.get_bool(actor, "visible", true)})
	var chosen := _steps.chosen_step()
	if chosen.is_empty():
		return result
	# Onde cada um está até o passo escolhido, pelos "Andar" de antes.
	var reached := [false]
	StoryValidator.each_step(_scene.steps, func(step: Dictionary) -> void:
		if reached[0]:
			return
		if is_same(step, chosen):
			reached[0] = true
			return
		if DictFields.get_string(step, "type") == "move":
			var coord: Variant = StoryValidator.coord_of(step)
			if coord != null:
				positions[DictFields.get_string(step, "actor")] = coord)
	var type := DictFields.get_string(chosen, "type")
	if type == "move" or type == "camera":
		result["target"] = StoryValidator.coord_of(chosen)
	elif type == "face":
		result["target"] = StoryValidator.coord_of(chosen.get("toward"))
		var toward: Variant = chosen.get("toward")
		if result["target"] == null and toward is String and positions.has(toward):
			result["target"] = positions[toward]
	if type == "move" or type == "face":
		var actor := DictFields.get_string(chosen, "actor")
		if positions.has(actor):
			result["from"] = positions[actor]
	return result


## As cenas da ilha que usam um hexágono que não é mais dela.
static func stale_warnings(draft: IslandDraft) -> Array[String]:
	var warnings: Array[String] = []
	for scene: StoryScene in Story.library.for_island(draft.id):
		var coords: Array[Vector2i] = []
		for tile: Variant in DictFields.get_array(scene.trigger, "tiles"):
			if StoryValidator.coord_of(tile) != null:
				coords.append(StoryValidator.coord_of(tile))
		for actor: Dictionary in scene.actors:
			if StoryValidator.coord_of(actor) != null:
				coords.append(StoryValidator.coord_of(actor))
		StoryValidator.each_step(scene.steps, func(step: Dictionary) -> void:
			for value: Variant in [step, step.get("toward")]:
				if StoryValidator.coord_of(value) != null:
					coords.append(StoryValidator.coord_of(value)))
		for coord: Vector2i in coords:
			if not draft.tiles.has(coord):
				warnings.append("A cena %s usa (%d, %d), que não é mais da ilha." % [scene.name, coord.x, coord.y])
				break
	return warnings


func save() -> void:
	if _scene == null:
		return
	if not OS.has_feature("editor"):
		message.emit(NO_EDITOR_TEXT, true)
		return
	var scenes: Array[StoryScene] = []
	var files: Array[String] = []
	for other: StoryScene in Story.library.scenes:
		if other.slug != _scene.slug:
			scenes.append(other)
			files.append(other.slug + ".json")
	scenes.append(_scene)
	files.append(_scene.slug + ".json")
	for error: String in StoryValidator.validate(scenes, files):
		if error.begins_with("Cena %s:" % _scene.slug):
			message.emit(error, true)
			return
	var file := FileAccess.open(StoryLibrary.SCENES_DIR + _scene.slug + ".json", FileAccess.WRITE)
	if file == null:
		message.emit("Não deu para gravar o arquivo da cena.", true)
		return
	file.store_string(JSON.stringify(clean(_scene.to_dict()), "  ", false) + "\n")
	file.close()
	Story.replace_scene(_scene.copy())
	_dirty = false
	_slug = _scene.slug
	_fill_list()
	_refresh()
	message.emit("Cena salva em story/scenes/%s.json." % _scene.slug, false)


## Os números inteiros voltam a ser inteiros: o JSON do Godot lê todo número como float.
static func clean(value: Variant) -> Variant:
	if value is float and is_equal_approx(value, roundf(value)):
		return int(value)
	if value is Array:
		var list: Array = []
		for item: Variant in value:
			list.append(clean(item))
		return list
	if value is Dictionary:
		var d := {}
		for key: Variant in value:
			d[key] = clean(value[key])
		return d
	return value


# A lista e a cena aberta.

func _open_scene(slug: String) -> void:
	_pick = Callable()
	picking_area = false
	_slug = slug
	var saved := Story.library.find(slug)
	_scene = saved.copy() if saved != null else null
	_dirty = false
	if _scene != null:
		_test_marks.text = ", ".join(_scene.requires)
	_fill_list()
	_fill_scene()
	changed.emit()


func _fill_list() -> void:
	_list.clear()
	if _draft == null or _draft.id <= 0:
		_refresh()
		return
	var scenes := Story.library.for_island(_draft.id)
	if _scene != null and Story.library.find(_scene.slug) == null:
		scenes.append(_scene)
	if scenes.is_empty():
		_list.add_item("Nenhuma cena nesta ilha")
		_list.set_item_disabled(0, true)
	for index: int in scenes.size():
		var scene := scenes[index]
		var is_open := _scene != null and scene.slug == _scene.slug
		var label := (_scene.name if is_open else scene.name)
		_list.add_item(("• " if is_open and _dirty else "") + label)
		_list.set_item_metadata(_list.item_count - 1, scene.slug)
		if is_open:
			_list.select(_list.item_count - 1)
	if _scene == null:
		_list.select(-1)
	_refresh()


func _on_list_selected(index: int) -> void:
	var slug := str(_list.get_item_metadata(index))
	if _scene != null and slug == _scene.slug:
		return
	if _dirty and _scene != null:
		_pending_slug = slug
		_ask("Descartar as mudanças da cena %s?" % _scene.name, func() -> void: _open_scene(_pending_slug))
		_fill_list()
		return
	_open_scene(slug)


func _fill_scene() -> void:
	if _scene == null:
		_refresh()
		return
	_name_edit.text = _scene.name
	_repeatable.set_pressed_no_signal(_scene.repeatable)
	_priority.set_value(_scene.priority)
	_requires.text = ", ".join(_scene.requires)
	_forbids.text = ", ".join(_scene.forbids)
	var type := DictFields.get_string(_scene.trigger, "type", "auto")
	for index: int in TRIGGERS.size():
		if TRIGGERS[index][1] == type:
			_trigger.select(index)
	_fill_npc_option()
	_fill_actors()
	_steps.set_scene(_scene, _draft.start if _draft != null else Vector2i.ZERO)
	_refresh()


func _fill_npc_option() -> void:
	_npc_option.clear()
	var seen: Dictionary[int, bool] = {}
	if _draft != null:
		for npc: MapNpc in _draft.map_npcs():
			if seen.has(npc.npc_id):
				continue
			seen[npc.npc_id] = true
			_npc_option.add_item(str(GameData.get_npc(npc.npc_id).get("name", "")), npc.npc_id)
	if _npc_option.item_count == 0:
		_npc_option.add_item("Ponha um NPC na ilha antes", 0)
		_npc_option.set_item_disabled(0, true)
	var current := DictFields.get_int(_scene.trigger, "npc_id")
	var index := _npc_option.get_item_index(current)
	_npc_option.select(index if index >= 0 else 0)


func _fill_actors() -> void:
	for child: Node in _actors_box.get_children():
		child.queue_free()
	for actor: Dictionary in _scene.actors:
		_actors_box.add_child(_actor_row(actor))


func _actor_row(actor: Dictionary) -> Control:
	var box := VBoxContainer.new()
	var top := HBoxContainer.new()
	box.add_child(top)
	var key := LineEdit.new()
	key.text = str(actor.get("key", ""))
	key.placeholder_text = "key"
	key.custom_minimum_size.x = 90.0
	key.text_changed.connect(func(text: String) -> void: _edit(func() -> void: actor["key"] = text.strip_edges()))
	top.add_child(key)
	var npc := OptionButton.new()
	npc.focus_mode = Control.FOCUS_NONE
	npc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc.clip_text = true
	for row: Dictionary in GameData.get_rows("npcs"):
		npc.add_item(str(row.get("name", "")), int(row.get("id", 0)))
	npc.select(maxi(npc.get_item_index(DictFields.get_int(actor, "npc_id")), 0))
	actor["npc_id"] = npc.get_selected_id()
	npc.item_selected.connect(func(index: int) -> void: _edit(func() -> void: actor["npc_id"] = npc.get_item_id(index)))
	top.add_child(npc)
	top.add_child(_button("X", func() -> void:
		_scene.actors.erase(actor)
		_fill_actors()
		_edit(Callable())))
	var bottom := HBoxContainer.new()
	box.add_child(bottom)
	var island := CheckBox.new()
	island.text = "Da ilha"
	island.tooltip_text = "O NPC da ilha com este NPC do catálogo (o tocado, no gatilho de NPC)."
	island.focus_mode = Control.FOCUS_NONE
	island.button_pressed = DictFields.get_bool(actor, "island_npc")
	bottom.add_child(island)
	var where := Button.new()
	where.focus_mode = Control.FOCUS_NONE
	var hidden_check := CheckBox.new()
	hidden_check.text = "Começa escondido"
	hidden_check.focus_mode = Control.FOCUS_NONE
	hidden_check.button_pressed = not DictFields.get_bool(actor, "visible", true)
	var refresh_where := func() -> void:
		var coord: Variant = StoryValidator.coord_of(actor)
		where.text = "Hexágono (%d, %d)" % [coord.x, coord.y] if coord != null else "Escolher hexágono"
		where.visible = not island.button_pressed
		hidden_check.visible = not island.button_pressed
	refresh_where.call()
	island.toggled.connect(func(on: bool) -> void:
		_edit(func() -> void:
			if on:
				actor["island_npc"] = true
				actor.erase("q")
				actor.erase("r")
				actor.erase("visible")
			else:
				actor.erase("island_npc")
				var start: Vector2i = _draft.start if _draft != null else Vector2i.ZERO
				actor["q"] = start.x
				actor["r"] = start.y)
		refresh_where.call())
	where.pressed.connect(func() -> void:
		_start_pick(func(coord: Vector2i) -> void:
			actor["q"] = coord.x
			actor["r"] = coord.y
			refresh_where.call()
			_edit(Callable())))
	bottom.add_child(where)
	hidden_check.toggled.connect(func(on: bool) -> void:
		_edit(func() -> void:
			if on:
				actor["visible"] = false
			else:
				actor.erase("visible")))
	bottom.add_child(hidden_check)
	box.add_child(HSeparator.new())
	return box


func _add_actor() -> void:
	if _scene == null:
		return
	var number := _scene.actors.size() + 1
	while not _scene.actor("ator%d" % number).is_empty():
		number += 1
	var start: Vector2i = _draft.start if _draft != null else Vector2i.ZERO
	var rows := GameData.get_rows("npcs")
	_scene.actors.append({"key": "ator%d" % number, "npc_id": int(rows[0].get("id", 0)) if not rows.is_empty() else 0, "q": start.x, "r": start.y})
	_fill_actors()
	_edit(Callable())


func _on_trigger_selected(index: int) -> void:
	var type: String = TRIGGERS[index][1]
	_edit(func() -> void:
		var trigger := {"type": type}
		if type == "npc":
			trigger["npc_id"] = _npc_option.get_selected_id()
		elif type == "area":
			trigger["tiles"] = DictFields.get_array(_scene.trigger, "tiles")
		_scene.trigger = trigger)
	if picking_area and type != "area":
		_toggle_area_pick()


func _toggle_area_pick() -> void:
	picking_area = not picking_area
	_pick = Callable()
	message.emit(AREA_PICK_TEXT if picking_area else "", false)
	_refresh()


func _start_pick(done: Callable) -> void:
	picking_area = false
	_pick = done
	message.emit(PICK_TEXT, false)
	_refresh()


func _show_new() -> void:
	_new_slug.text = ""
	_new_name.text = ""
	_new_box.show()
	_new_slug.grab_focus()


func _create() -> void:
	var slug := _new_slug.text.strip_edges()
	if not StoryValidator.is_mark(slug):
		message.emit("O slug precisa de letras minúsculas, números e _, até 48.", true)
		return
	if Story.library.find(slug) != null:
		message.emit("Já existe uma cena %s." % slug, true)
		return
	if _new_name.text.strip_edges().is_empty():
		message.emit("Dê um nome à cena.", true)
		return
	_new_box.hide()
	_scene = StoryScene.new()
	_scene.slug = slug
	_scene.name = _new_name.text.strip_edges()
	_scene.island_id = _draft.id
	_scene.trigger = {"type": "auto"}
	_slug = slug
	_dirty = true
	_test_marks.text = ""
	_fill_list()
	_fill_scene()
	changed.emit()


func _ask_delete() -> void:
	if _scene == null:
		return
	_ask("Apagar a cena %s? O arquivo sai da pasta." % _scene.name, _delete)


func _delete() -> void:
	if not OS.has_feature("editor"):
		message.emit(NO_EDITOR_TEXT, true)
		return
	var path := StoryLibrary.SCENES_DIR + _scene.slug + ".json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Story.remove_scene(_scene.slug)
	message.emit("Cena %s apagada." % _scene.name, false)
	_open_scene("")


func _discard() -> void:
	if Story.library.find(_slug) == null:
		_open_scene("")
	else:
		_open_scene(_slug)


func _test() -> void:
	if _scene == null:
		return
	var marks: Array[String] = []
	for mark: String in _test_marks.text.split(",", false):
		if not mark.strip_edges().is_empty():
			marks.append(mark.strip_edges())
	test_requested.emit(_scene.copy(), marks)


# Ajudas.

func _edit(change: Callable) -> void:
	if _scene == null:
		return
	if change.is_valid():
		change.call()
	if not _dirty:
		_dirty = true
		_fill_list()
	_refresh()
	changed.emit()


func _refresh() -> void:
	var has_island := _draft != null and _draft.id > 0
	_blocked.visible = not has_island
	_box.visible = has_island
	_body.visible = _scene != null
	_empty_hint.visible = _scene == null
	_delete_button.disabled = _scene == null or Story.library.find(_scene.slug) == null
	if _scene == null:
		return
	var type := DictFields.get_string(_scene.trigger, "type", "auto")
	_npc_row.visible = type == "npc"
	_area_row.visible = type == "area"
	_area_label.text = "%d hexágono(s)" % DictFields.get_array(_scene.trigger, "tiles").size()
	_area_button.text = "Pronto" if picking_area else "Escolher no mapa"
	var can_write := OS.has_feature("editor")
	_save_button.disabled = not can_write
	_discard_button.disabled = not _dirty
	var reason := ""
	if not can_write:
		reason = NO_EDITOR_TEXT
	elif not _published:
		reason = NOT_PUBLISHED_TEXT
	elif Session.player == null:
		reason = NO_PLAYER_TEXT
	_test_button.disabled = not _published or Session.player == null
	_hint.text = reason


func _marks_field(title: String, edit: LineEdit, apply: Callable) -> void:
	_field_label(title)
	var row := HBoxContainer.new()
	_body.add_child(row)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.placeholder_text = "separados por vírgula"
	edit.text_changed.connect(func(text: String) -> void:
		_edit(func() -> void: apply.call(_split(text))))
	row.add_child(edit)
	var menu := MenuButton.new()
	menu.text = "Marcos…"
	menu.flat = false
	menu.about_to_popup.connect(func() -> void:
		menu.get_popup().clear()
		for mark: String in Story.used_marks():
			menu.get_popup().add_item(mark))
	menu.get_popup().index_pressed.connect(func(index: int) -> void:
		var mark := menu.get_popup().get_item_text(index)
		var marks := _split(edit.text)
		if not marks.has(mark):
			marks.append(mark)
		edit.text = ", ".join(marks)
		_edit(func() -> void: apply.call(marks)))
	row.add_child(menu)


func _split(text: String) -> Array[String]:
	var marks: Array[String] = []
	for part: String in text.split(",", false):
		var mark := part.strip_edges()
		if not mark.is_empty() and not marks.has(mark):
			marks.append(mark)
	return marks


func _field_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	_body.add_child(label)


func _button(text: String, pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(pressed)
	return button


func _ask(text: String, confirmed: Callable) -> void:
	for connection: Dictionary in _confirm.confirmed.get_connections():
		_confirm.confirmed.disconnect(connection["callable"])
	_confirm.dialog_text = text
	_confirm.confirmed.connect(confirmed, CONNECT_ONE_SHOT)
	_confirm.popup_centered()


## Abre a cena pelo slug, se ela é da ilha aberta (story/05).
func select_scene(slug: String) -> void:
	var scene := Story.library.find(slug)
	if scene != null and _draft != null and scene.island_id == _draft.id:
		_open_scene(slug)

