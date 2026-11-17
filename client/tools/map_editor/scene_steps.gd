class_name SceneSteps
extends VBoxContainer

## Os passos de uma cena na ferramenta Cenas (story/04 e 06): o passo escolhido, os
## campos dele e as regras de pôr, apagar e mover. A faixa (`SceneTimeline`) mostra os
## cartões e chama estas regras. Mexe direto nas listas da cena.

## A cena mudou (algum campo ou a ordem dos passos).
signal changed
## Os passos foram postos, apagados ou mudados de lugar: a faixa monta de novo.
signal structure_changed
signal selection_changed
## Pede um hexágono do mapa; `done` recebe o `Vector2i`.
signal pick_requested(done: Callable)

const TEXT_HEIGHT := 120.0
const TAMER := "tamer"
const ICONS := "res://tools/map_editor/icons/story/%s.svg"
const TYPE_NAMES: Dictionary[String, String] = {
	"say": "Fala", "choice": "Escolha", "if_mark": "Se tiver o Marco", "set_mark": "Ligar Marco",
	"wait": "Esperar", "fade": "Escurecer ou clarear", "show": "Mostrar ator", "hide": "Esconder ator",
	"move": "Andar", "face": "Virar", "camera": "Câmera", "camera_back": "Câmera volta",
	"follow": "Seguir o Domador", "unfollow": "Parar de seguir", "open_screen": "Abrir tela",
}
## Os grupos de cor, na ordem do menu, com os tipos de cada um (story/06).
const GROUPS: Dictionary[String, Array] = {
	"talk": ["say"],
	"choice": ["choice", "if_mark"],
	"mark": ["set_mark"],
	"actor": ["show", "hide", "move", "face", "follow", "unfollow"],
	"camera": ["camera", "camera_back", "fade", "wait"],
	"screen": ["open_screen"],
}
const ICON_NAMES: Dictionary[String, String] = {"set_mark": "mark", "open_screen": "screen"}
const SCREEN_NAMES: Dictionary[String, String] = {
	"appearance": "Aparência", "heal_station": "Refúgio", "shop": "Loja", "team": "Equipe",
	"bag": "Mochila", "codex": "Bestiário",
}
const NOTHING_CHOSEN := "Toque num cartão embaixo do mapa para editar o passo."

## O que está escolhido: {"list": Array, "index": int} para um passo,
## {"option": Dictionary, "options": Array, "list": Array} para uma opção de escolha.
var chosen: Dictionary = {}

var _scene: StoryScene = null
var _start := Vector2i.ZERO
var _title := Label.new()
var _actions := HBoxContainer.new()
var _add_after := MenuButton.new()
var _fields := VBoxContainer.new()


func _init() -> void:
	add_theme_constant_override(&"separation", 6)
	_title.theme_type_variation = &"BoldLabel"
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_title)
	_actions.add_theme_constant_override(&"separation", 4)
	add_child(_actions)
	_add_after.text = "+ depois deste"
	_add_after.flat = false
	fill_type_menu(_add_after.get_popup(), func(type: String) -> void: add_after(type))
	_actions.add_child(_add_after)
	_actions.add_child(_button("← Mover", func() -> void: move_chosen(-1)))
	_actions.add_child(_button("Mover →", func() -> void: move_chosen(1)))
	var delete := _button("Apagar", delete_chosen)
	delete.theme_type_variation = &"DangerButton"
	_actions.add_child(delete)
	_fields.add_theme_constant_override(&"separation", 6)
	add_child(_fields)


func set_scene(value: StoryScene, start: Vector2i) -> void:
	_scene = value
	_start = start
	chosen = {}
	_show_fields()
	structure_changed.emit()


func scene() -> StoryScene:
	return _scene


func select(target: Dictionary) -> void:
	chosen = target
	_show_fields()
	selection_changed.emit()


## O passo escolhido, ou vazio.
func chosen_step() -> Dictionary:
	if not chosen.has("index"):
		return {}
	var list: Array = chosen["list"]
	var index: int = chosen["index"]
	return list[index] if index < list.size() and list[index] is Dictionary else {}


func is_chosen(list: Array, index: int) -> bool:
	return chosen.has("index") and is_same(chosen["list"], list) and chosen["index"] == index


# As regras de mexer nos passos.

func add_step(type: String, list: Array, index: int) -> void:
	if _scene == null:
		return
	index = clampi(index, 0, list.size())
	list.insert(index, new_step(type))
	_restructured({"list": list, "index": index})


func add_after(type: String) -> void:
	if not chosen.has("index"):
		return
	add_step(type, chosen["list"], int(chosen["index"]) + 1)


func delete_chosen() -> void:
	if chosen.has("option"):
		delete_option()
		return
	if not chosen.has("index"):
		return
	var list: Array = chosen["list"]
	var index: int = chosen["index"]
	list.remove_at(index)
	_restructured({"list": list, "index": mini(index, list.size() - 1)} if not list.is_empty() else {})


func move_chosen(offset: int) -> void:
	if not chosen.has("index"):
		return
	var list: Array = chosen["list"]
	var index: int = chosen["index"]
	var target := index + offset
	if target < 0 or target >= list.size():
		return
	var step: Variant = list[index]
	list[index] = list[target]
	list[target] = step
	_restructured({"list": list, "index": target})


func add_option(choice: Dictionary) -> void:
	var options := DictFields.get_array(choice, "options")
	if options.size() >= StoryValidator.MAX_OPTIONS:
		return
	var option := {"text": "Opção %d" % (options.size() + 1), "steps": []}
	options.append(option)
	_restructured({"option": option, "options": options, "list": option["steps"]})


func delete_option() -> void:
	var options: Array = chosen.get("options", [])
	if options.size() <= StoryValidator.MIN_OPTIONS:
		return
	options.erase(chosen["option"])
	_restructured({})


func new_step(type: String) -> Dictionary:
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


func _restructured(target: Dictionary) -> void:
	chosen = target
	_show_fields()
	structure_changed.emit()
	selection_changed.emit()
	changed.emit()


# Nomes, grupos, ícones e resumos, também usados pela faixa.

static func type_group(type: String) -> String:
	for group: String in GROUPS:
		if (GROUPS[group] as Array).has(type):
			return group
	return "screen"


static func type_color(type: String) -> Color:
	return UiPalette.STORY_STEP_COLORS.get(type_group(type), UiPalette.SURFACE_RAISED)


static func type_icon(type: String) -> Texture2D:
	return load(ICONS % ICON_NAMES.get(type, type)) as Texture2D


## O menu dos tipos, agrupados pela cor, com o ícone de cada um.
static func fill_type_menu(popup: PopupMenu, picked: Callable) -> void:
	popup.clear()
	var types: Array[String] = []
	for group: String in GROUPS:
		if popup.item_count > 0:
			popup.add_separator()
		for type: String in GROUPS[group]:
			popup.add_icon_item(type_icon(type), TYPE_NAMES[type], types.size())
			popup.set_item_icon_modulate(popup.item_count - 1, type_color(type).lightened(0.25))
			popup.set_item_icon_max_width(popup.item_count - 1, 18)
			types.append(type)
	popup.id_pressed.connect(func(id: int) -> void: picked.call(types[id]))


## O resumo do passo para o cartão, sem o nome do tipo.
static func summary(step: Dictionary) -> String:
	var type := DictFields.get_string(step, "type")
	match type:
		"say":
			var speaker: Variant = step.get("speaker")
			var who := "Narração" if speaker == null else _actor_name(speaker)
			return "%s: %s" % [who, DictFields.get_string(step, "text")]
		"choice":
			var texts: Array[String] = []
			for option: Variant in DictFields.get_array(step, "options"):
				if option is Dictionary:
					texts.append("“%s”" % DictFields.get_string(option, "text"))
			return "%d opções: %s" % [texts.size(), " / ".join(texts)]
		"if_mark":
			return "Se tiver %s" % DictFields.get_string(step, "mark")
		"set_mark":
			return "Liga %s" % DictFields.get_string(step, "mark")
		"wait", "camera_back":
			return "%s s" % EditorNumberField.format(DictFields.get_float(step, "seconds"), false)
		"fade":
			return "%s em %s s" % ["Escurece" if step.get("to") == "black" else "Clareia", EditorNumberField.format(DictFields.get_float(step, "seconds"), false)]
		"move":
			return "%s → (%d, %d)%s" % [_actor_name(step.get("actor")), DictFields.get_int(step, "q"), DictFields.get_int(step, "r"), "" if DictFields.get_bool(step, "wait", true) else "\nsem esperar"]
		"camera":
			return "→ (%d, %d) em %s s" % [DictFields.get_int(step, "q"), DictFields.get_int(step, "r"), EditorNumberField.format(DictFields.get_float(step, "seconds"), false)]
		"face":
			var toward: Variant = step.get("toward")
			var coord: Variant = StoryValidator.coord_of(toward)
			var target := "(%d, %d)" % [coord.x, coord.y] if coord != null else _actor_name(toward)
			return "%s → %s" % [_actor_name(step.get("actor")), target]
		"show", "hide", "follow", "unfollow":
			return _actor_name(step.get("actor"))
		"open_screen":
			return SCREEN_NAMES.get(str(step.get("screen")), str(step.get("screen")))
	return ""


static func _actor_name(actor: Variant) -> String:
	return "Domador" if actor == TAMER else str(actor)


# Os campos do passo escolhido.

func _show_fields() -> void:
	for child: Node in _fields.get_children():
		child.queue_free()
	_actions.visible = chosen.has("index")
	if chosen.has("option"):
		var option: Dictionary = chosen["option"]
		_title.text = "Opção da escolha"
		_text_field("Texto da opção", option, "text", false)
		var delete := _button("Apagar opção", delete_option)
		delete.theme_type_variation = &"DangerButton"
		delete.disabled = (chosen["options"] as Array).size() <= StoryValidator.MIN_OPTIONS
		_fields.add_child(delete)
		return
	var step := chosen_step()
	if step.is_empty():
		_title.text = NOTHING_CHOSEN
		return
	var type := DictFields.get_string(step, "type")
	_title.text = "Passo %d · %s" % [int(chosen["index"]) + 1, TYPE_NAMES.get(type, type)]
	match type:
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
			var current: Variant = "__hex" if StoryValidator.coord_of(toward) != null else toward
			var holder := {"toward": current}
			_choice_field("Para", holder, "toward", options, func(value: Variant) -> void:
				step["toward"] = {"q": _start.x, "r": _start.y} if value == "__hex" else value
				_show_fields())
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
		"choice", "if_mark":
			pass
	if type == "choice" or type == "if_mark":
		var hint := Label.new()
		hint.text = "Use \"Abrir ramos\" no cartão para ver e editar os passos de cada ramo."
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
		_fields.add_child(hint)


func _field_changed() -> void:
	changed.emit()


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


func _button(text: String, pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(pressed)
	return button


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
		if not on_change.is_valid():
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
