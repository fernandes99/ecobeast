class_name SceneSteps
extends VBoxContainer

## Os passos de uma cena na ferramenta Cenas (story/04): a árvore com os blocos, os
## botões e os campos do passo escolhido. Mexe direto nas listas da cena.

signal changed
## Pede um hexágono do mapa; `done` recebe o `Vector2i`.
signal pick_requested(done: Callable)

const TREE_HEIGHT := 260.0
const TEXT_HEIGHT := 90.0
const SHORT_TEXT := 34
const TAMER := "tamer"
const TYPE_NAMES: Dictionary[String, String] = {
	"say": "Fala", "choice": "Escolha", "if_mark": "Se tiver o Marco", "set_mark": "Ligar Marco",
	"wait": "Esperar", "fade": "Escurecer ou clarear", "show": "Mostrar ator", "hide": "Esconder ator",
	"move": "Andar", "face": "Virar", "camera": "Câmera", "camera_back": "Câmera volta",
	"follow": "Seguir o Domador", "unfollow": "Parar de seguir", "open_screen": "Abrir tela",
}
const SCREEN_NAMES: Dictionary[String, String] = {
	"appearance": "Aparência", "heal_station": "Refúgio", "shop": "Loja", "team": "Equipe",
	"bag": "Mochila", "codex": "Bestiário",
}

var _scene: StoryScene = null
var _start := Vector2i.ZERO
var _tree := Tree.new()
var _add_menu := MenuButton.new()
var _option_button := Button.new()
var _delete_button := Button.new()
var _up_button := Button.new()
var _down_button := Button.new()
var _fields := VBoxContainer.new()
## O que o item da árvore escolhido é: {"list": Array, "index": int} para um passo,
## {"list": Array} para um bloco.
var _chosen: Dictionary = {}


func _init() -> void:
	add_theme_constant_override(&"separation", 6)
	var title := Label.new()
	title.text = "Passos"
	EditorTools.section_title(title)
	add_child(title)
	_tree.custom_minimum_size.y = TREE_HEIGHT
	_tree.hide_root = true
	_tree.focus_mode = Control.FOCUS_CLICK
	_tree.item_selected.connect(_on_item_selected)
	add_child(_tree)
	var buttons := HFlowContainer.new()
	buttons.add_theme_constant_override(&"h_separation", 4)
	add_child(buttons)
	_add_menu.text = "+ Passo"
	_add_menu.flat = false
	for type: String in TYPE_NAMES:
		_add_menu.get_popup().add_item(TYPE_NAMES[type])
	_add_menu.get_popup().index_pressed.connect(func(index: int) -> void: _add_step(TYPE_NAMES.keys()[index]))
	buttons.add_child(_add_menu)
	for pair: Array in [[_option_button, "+ Opção", _add_option], [_delete_button, "Apagar", _delete], [_up_button, "Subir", _move.bind(-1)], [_down_button, "Descer", _move.bind(1)]]:
		var button: Button = pair[0]
		button.text = pair[1]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(pair[2])
		buttons.add_child(button)
	_fields.add_theme_constant_override(&"separation", 6)
	add_child(_fields)


func set_scene(scene: StoryScene, start: Vector2i) -> void:
	_scene = scene
	_start = start
	_chosen = {}
	rebuild()


## O passo escolhido, ou vazio.
func chosen_step() -> Dictionary:
	if not _chosen.has("index"):
		return {}
	var list: Array = _chosen["list"]
	var index: int = _chosen["index"]
	return list[index] if index < list.size() and list[index] is Dictionary else {}


func rebuild() -> void:
	_tree.clear()
	var root := _tree.create_item()
	if _scene != null:
		_add_items(root, _scene.steps)
	_refresh_buttons()
	_show_fields()


func _add_items(parent: TreeItem, list: Array) -> void:
	for index: int in list.size():
		var step: Variant = list[index]
		if not step is Dictionary:
			continue
		var d: Dictionary = step
		var item := _tree.create_item(parent)
		item.set_text(0, _summary(d))
		item.set_metadata(0, {"list": list, "index": index})
		if _same(_chosen, list, index):
			item.select(0)
		match DictFields.get_string(d, "type"):
			"choice":
				var options := DictFields.get_array(d, "options")
				for option_index: int in options.size():
					var option: Dictionary = options[option_index]
					var header := _tree.create_item(item)
					header.set_text(0, "Opção: %s" % _short(DictFields.get_string(option, "text")))
					if not option.get("steps") is Array:
						option["steps"] = []
					header.set_metadata(0, {"list": option["steps"], "option": option, "options": options})
					if is_same(_chosen.get("option"), option):
						header.select(0)
					_add_items(header, option["steps"])
			"if_mark":
				for key: String in ["then", "else"]:
					if not d.get(key) is Array:
						d[key] = []
					var header := _tree.create_item(item)
					header.set_text(0, "Então" if key == "then" else "Senão")
					header.set_metadata(0, {"list": d[key]})
					if not _chosen.has("index") and not _chosen.has("option") and is_same(_chosen.get("list"), d[key]):
						header.select(0)
					_add_items(header, d[key])


func _same(chosen: Dictionary, list: Array, index: int) -> bool:
	return chosen.has("index") and is_same(chosen["list"], list) and chosen["index"] == index


func _summary(step: Dictionary) -> String:
	var type := DictFields.get_string(step, "type")
	var title: String = TYPE_NAMES.get(type, type)
	match type:
		"say":
			var speaker: Variant = step.get("speaker")
			var who := "Narração" if speaker == null else ("Domador" if speaker == TAMER else str(speaker))
			return "%s · %s: %s" % [title, who, _short(DictFields.get_string(step, "text"))]
		"if_mark", "set_mark":
			return "%s %s" % [title, DictFields.get_string(step, "mark")]
		"wait", "camera_back":
			return "%s · %s s" % [title, EditorNumberField.format(DictFields.get_float(step, "seconds"), false)]
		"fade":
			return "%s · %s" % ["Escurecer" if step.get("to") == "black" else "Clarear", EditorNumberField.format(DictFields.get_float(step, "seconds"), false)]
		"move":
			return "%s · %s → (%d, %d)" % [title, _actor_name(step.get("actor")), DictFields.get_int(step, "q"), DictFields.get_int(step, "r")]
		"camera":
			return "%s → (%d, %d)" % [title, DictFields.get_int(step, "q"), DictFields.get_int(step, "r")]
		"face":
			var toward: Variant = step.get("toward")
			var coord: Variant = StoryValidator.coord_of(toward)
			var target := "(%d, %d)" % [coord.x, coord.y] if coord != null else _actor_name(toward)
			return "%s · %s → %s" % [title, _actor_name(step.get("actor")), target]
		"show", "hide", "follow", "unfollow":
			return "%s · %s" % [title, _actor_name(step.get("actor"))]
		"open_screen":
			return "%s · %s" % [title, SCREEN_NAMES.get(str(step.get("screen")), str(step.get("screen")))]
	return title


func _actor_name(actor: Variant) -> String:
	return "Domador" if actor == TAMER else str(actor)


func _short(text: String) -> String:
	return text if text.length() <= SHORT_TEXT else text.substr(0, SHORT_TEXT - 3) + "..."


func _on_item_selected() -> void:
	var item := _tree.get_selected()
	_chosen = item.get_metadata(0) if item != null else {}
	_refresh_buttons()
	_show_fields()


func _refresh_buttons() -> void:
	var is_step := _chosen.has("index")
	_delete_button.disabled = not is_step and not _chosen.has("option")
	_up_button.disabled = not is_step
	_down_button.disabled = not is_step
	var step := chosen_step()
	_option_button.disabled = not (DictFields.get_string(step, "type") == "choice" and DictFields.get_array(step, "options").size() < StoryValidator.MAX_OPTIONS)
	_add_menu.disabled = _scene == null


## Depois do escolhido; num bloco escolhido, no fim dele.
func _add_step(type: String) -> void:
	if _scene == null:
		return
	var step := _new_step(type)
	var list: Array = _scene.steps
	var index := list.size()
	if _chosen.has("index"):
		list = _chosen["list"]
		index = int(_chosen["index"]) + 1
	elif _chosen.has("list"):
		list = _chosen["list"]
		index = list.size()
	list.insert(index, step)
	_chosen = {"list": list, "index": index}
	_changed()


func _new_step(type: String) -> Dictionary:
	var first_actor := str(_scene.actors[0].get("key", "")) if not _scene.actors.is_empty() else ""
	match type:
		"say":
			var speaker: Variant = null
			if not first_actor.is_empty():
				speaker = first_actor
			return {"type": type, "speaker": speaker, "text": "Nova fala."}
		"choice":
			return {"type": type, "options": [{"text": "Opção 1", "steps": []}, {"text": "Opção 2", "steps": []}]}
		"if_mark":
			return {"type": type, "mark": "marco", "then": [], "else": []}
		"set_mark":
			return {"type": type, "mark": "marco"}
		"wait", "camera_back":
			return {"type": type, "seconds": 1.0}
		"fade":
			return {"type": type, "to": "black", "seconds": 1.0}
		"show", "hide", "follow", "unfollow":
			return {"type": type, "actor": first_actor}
		"move":
			return {"type": type, "actor": first_actor if not first_actor.is_empty() else TAMER, "q": _start.x, "r": _start.y, "wait": true}
		"face":
			var toward: Variant = {"q": _start.x, "r": _start.y}
			if not first_actor.is_empty():
				toward = first_actor
			return {"type": type, "actor": TAMER, "toward": toward}
		"camera":
			return {"type": type, "q": _start.x, "r": _start.y, "seconds": 1.5}
		"open_screen":
			return {"type": type, "screen": "appearance"}
	return {"type": type}


func _add_option() -> void:
	var options := DictFields.get_array(chosen_step(), "options")
	if options.size() >= StoryValidator.MAX_OPTIONS:
		return
	options.append({"text": "Opção %d" % (options.size() + 1), "steps": []})
	_changed()


func _delete() -> void:
	if _chosen.has("option"):
		var options: Array = _chosen["options"]
		if options.size() > StoryValidator.MIN_OPTIONS:
			options.erase(_chosen["option"])
		_chosen = {}
		_changed()
		return
	if not _chosen.has("index"):
		return
	var list: Array = _chosen["list"]
	list.remove_at(int(_chosen["index"]))
	_chosen = {}
	_changed()


func _move(offset: int) -> void:
	if not _chosen.has("index"):
		return
	var list: Array = _chosen["list"]
	var index: int = _chosen["index"]
	var target := index + offset
	if target < 0 or target >= list.size():
		return
	var step: Variant = list[index]
	list[index] = list[target]
	list[target] = step
	_chosen = {"list": list, "index": target}
	_changed()


func _changed() -> void:
	rebuild()
	changed.emit()


## Mudou um campo: a árvore só troca o texto, sem perder a escolha.
func _field_changed() -> void:
	var item := _tree.get_selected()
	if item != null and _chosen.has("index"):
		item.set_text(0, _summary(chosen_step()))
	elif item != null and _chosen.has("option"):
		item.set_text(0, "Opção: %s" % _short(DictFields.get_string(_chosen["option"], "text")))
	changed.emit()


# Os campos do passo escolhido.

func _show_fields() -> void:
	for child: Node in _fields.get_children():
		child.queue_free()
	if _chosen.has("option"):
		var option: Dictionary = _chosen["option"]
		_text_field("Texto da opção", option, "text", false)
		return
	var step := chosen_step()
	if step.is_empty():
		return
	match DictFields.get_string(step, "type"):
		"say":
			_choice_field("Quem fala", step, "speaker", _speaker_options())
			_text_field("Fala · {nome} vira o nome do Domador", step, "text", true)
		"if_mark", "set_mark":
			_text_field("Marco", step, "mark", false)
		"wait", "camera_back":
			_number_field("Segundos", step, "seconds")
		"fade":
			_choice_field("Para", step, "to", [["Escuro", "black"], ["Claro", "clear"]])
			_number_field("Segundos", step, "seconds")
		"show", "hide", "follow", "unfollow":
			_choice_field("Ator", step, "actor", _actor_options(false))
		"move":
			_choice_field("Quem anda", step, "actor", _actor_options(true))
			_hex_field("Até", step)
			var wait := CheckBox.new()
			wait.text = "Esperar chegar"
			wait.button_pressed = DictFields.get_bool(step, "wait", true)
			wait.focus_mode = Control.FOCUS_NONE
			wait.toggled.connect(func(on: bool) -> void:
				step["wait"] = on
				_field_changed())
			_fields.add_child(wait)
		"face":
			_choice_field("Quem vira", step, "actor", _actor_options(true))
			var options := _actor_options(true)
			options.push_front(["Um hexágono", "__hex"])
			var toward: Variant = step.get("toward")
			if StoryValidator.coord_of(toward) != null:
				step["__toward"] = "__hex"
			else:
				step["__toward"] = toward
			_choice_field("Para", step, "__toward", options, func(value: Variant) -> void:
				step.erase("__toward")
				step["toward"] = {"q": _start.x, "r": _start.y} if value == "__hex" else value
				_show_fields())
			step.erase("__toward")
			if StoryValidator.coord_of(toward) != null:
				_hex_field("Hexágono", step["toward"])
		"camera":
			_hex_field("Até", step)
			_number_field("Segundos", step, "seconds")
		"open_screen":
			var screens: Array = []
			for key: String in SCREEN_NAMES:
				screens.append([SCREEN_NAMES[key], key])
			_choice_field("Tela", step, "screen", screens)


func _speaker_options() -> Array:
	var options: Array = [["Narração", null], ["Domador", TAMER]]
	for actor: Dictionary in _scene.actors:
		options.append([str(actor.get("key", "")), str(actor.get("key", ""))])
	return options


func _actor_options(with_tamer: bool) -> Array:
	var options: Array = [["Domador", TAMER]] if with_tamer else []
	for actor: Dictionary in _scene.actors:
		options.append([str(actor.get("key", "")), str(actor.get("key", ""))])
	return options


func _label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fields.add_child(label)


func _text_field(title: String, target: Dictionary, key: String, multiline: bool) -> void:
	_label(title)
	if multiline:
		var edit := TextEdit.new()
		edit.custom_minimum_size.y = TEXT_HEIGHT
		edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		edit.text = DictFields.get_string(target, key)
		var count := Label.new()
		count.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
		var update_count := func() -> void: count.text = "%d / %d" % [edit.text.length(), StoryValidator.MAX_TEXT]
		update_count.call()
		edit.text_changed.connect(func() -> void:
			target[key] = edit.text
			update_count.call()
			_field_changed())
		_fields.add_child(edit)
		_fields.add_child(count)
		return
	var line := LineEdit.new()
	line.text = DictFields.get_string(target, key)
	line.text_changed.connect(func(text: String) -> void:
		target[key] = text.strip_edges()
		_field_changed())
	_fields.add_child(line)


func _number_field(title: String, target: Dictionary, key: String) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var field := EditorNumberField.new(StoryValidator.MIN_SECONDS, StoryValidator.MAX_SECONDS, false, false)
	field.set_value(DictFields.get_float(target, key, 1.0))
	field.changed.connect(func() -> void:
		target[key] = field.value()
		_field_changed())
	row.add_child(field)
	_fields.add_child(row)


## `options` é uma lista de [texto, valor].
func _choice_field(title: String, target: Dictionary, key: String, options: Array, on_change: Callable = Callable()) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var option := OptionButton.new()
	option.focus_mode = Control.FOCUS_NONE
	var current: Variant = target.get(key)
	for index: int in options.size():
		var pair: Array = options[index]
		option.add_item(str(pair[0]))
		if pair[1] == current:
			option.select(index)
	if option.selected < 0 and not options.is_empty():
		option.select(0)
		target[key] = options[0][1]
	option.item_selected.connect(func(index: int) -> void:
		var value: Variant = options[index][1]
		if on_change.is_valid():
			on_change.call(value)
		else:
			target[key] = value
		_field_changed())
	row.add_child(option)
	_fields.add_child(row)


func _hex_field(title: String, target: Dictionary) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = "%s (%d, %d)" % [title, DictFields.get_int(target, "q"), DictFields.get_int(target, "r")]
	row.add_child(label)
	var pick := Button.new()
	pick.text = "Escolher no mapa"
	pick.focus_mode = Control.FOCUS_NONE
	pick.pressed.connect(func() -> void:
		pick_requested.emit(func(coord: Vector2i) -> void:
			target["q"] = coord.x
			target["r"] = coord.y
			label.text = "%s (%d, %d)" % [title, coord.x, coord.y]
			_field_changed()))
	row.add_child(pick)
	_fields.add_child(row)
