class_name QuestDialogueEditor
extends VBoxContainer

## A parte Conversas do formulário da ferramenta Missões (auralis/10): as abas Início,
## Durante e Fim, cada uma com as falas e as escolhas, e a cena do início. Os passos
## ficam no formato das rotas (`say` e `choice`) e vão inteiros no Salvar da missão.

signal edited

const STAGES: Array[String] = ["offer", "ongoing", "done"]
const STAGE_NAMES: Array[String] = ["Início", "Durante", "Fim"]
const STAGE_HINTS: Array[String] = [
	"Antes de aceitar. Sem escolha que recuse, a missão é aceita no fim.",
	"Enquanto a missão não está cumprida; o progresso vem depois.",
	"Na entrega (opcional); a recompensa vem depois.",
]
const SPEAKERS: Array[String] = ["npc", "tamer", "narration"]
const SPEAKER_NAMES: Array[String] = ["NPC", "Domador", "Narração"]
## O que a opção faz na conversa de início: nada (segue), aceita ou recusa.
const OUTCOMES: Array[Variant] = [null, "accept", "decline"]
const OUTCOME_NAMES: Array[String] = ["Segue", "Aceita", "Recusa"]
const MAX_DEPTH := 3
const MIN_OPTIONS := 2
const MAX_OPTIONS := 4
const MAX_OPTION_TEXT := 40
const INDENT := 18
const MAX_TEXT := 300
const MAX_STEPS := 40
const SPEAKER_WIDTH := 130.0
const OUTCOME_WIDTH := 118.0
const TEXT_MIN_HEIGHT := 76.0
const OUTCOME_COLORS: Array[Variant] = [null, UiPalette.HP_HIGH, UiPalette.DANGER]
const EMPTY_HINTS: Array[String] = [
	"Sem conversa nem cena: o NPC diz a fala padrão, e a missão é aceita no fim.",
	"Sem conversa: o NPC diz a fala padrão.",
	"Sem conversa: o NPC diz a fala padrão.",
]
const NO_SCENE := "Nenhuma (a conversa abaixo)"
const SCENE_HINT := "A cena toca em Explorar e aceita a missão no fim; numa sala, vale a conversa abaixo."
const ROOM_WARNING := "Este NPC não está no mapa, só numa sala: lá a cena não toca."
const NO_SCENES_HINT := "Para usar uma cena, crie uma de gatilho \"Pela missão\" na ferramenta Cenas."

var _dialogues: Dictionary = {}
var _stage := 0
var _scene_slugs: Array[String] = []
var _giver_on_map := true

var _tabs: Array[Button] = []
var _stage_hint: Label
var _scene_box: VBoxContainer
var _scene: OptionButton
var _scene_hint: Label
var _steps: VBoxContainer
var _empty: Label
var _count_label: Label


func _init() -> void:
	add_theme_constant_override(&"separation", 6)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override(&"separation", 4)
	add_child(tabs)
	var group := ButtonGroup.new()
	for index: int in STAGES.size():
		var tab := Button.new()
		tab.text = STAGE_NAMES[index]
		tab.toggle_mode = true
		tab.button_group = group
		tab.focus_mode = Control.FOCUS_NONE
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.clip_text = true
		tab.add_theme_font_size_override(&"font_size", QuestEditorStyle.FIELD_FONT)
		tab.pressed.connect(_show_stage.bind(index))
		tabs.add_child(tab)
		_tabs.append(tab)
	_stage_hint = QuestEditorStyle.secondary("")
	add_child(_stage_hint)

	_scene_box = VBoxContainer.new()
	_scene_box.add_theme_constant_override(&"separation", 4)
	add_child(_scene_box)
	_scene = OptionButton.new()
	_scene.item_selected.connect(func(_index: int) -> void:
		_refresh_scene_hint()
		_refresh_empty()
		edited.emit())
	_scene_box.add_child(QuestPanel._row("Cena", _scene))
	_scene_hint = QuestEditorStyle.secondary("")
	_scene_box.add_child(_scene_hint)

	_empty = QuestEditorStyle.secondary("")
	add_child(_empty)
	_steps = VBoxContainer.new()
	_steps.add_theme_constant_override(&"separation", 8)
	add_child(_steps)
	_count_label = QuestEditorStyle.secondary("")
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_count_label)
	set_dialogues({}, "", 0)


## As conversas de uma missão (vazias na nova) e as cenas "Pela missão" da ilha.
func set_dialogues(data: Variant, scene_slug: String, island_id: int) -> void:
	_dialogues = {}
	for stage: String in STAGES:
		var steps: Array = []
		if data is Dictionary:
			steps = DictFields.get_array(data, stage).duplicate(true)
		_dialogues[stage] = steps
	_scene_slugs.clear()
	_scene.clear()
	_scene.add_item(NO_SCENE)
	for scene: StoryScene in Story.library.for_island(island_id):
		if DictFields.get_string(scene.trigger, "type") == "quest":
			_scene_slugs.append(scene.slug)
			_scene.add_item("%s (%s)" % [scene.name, scene.slug])
	if not scene_slug.is_empty() and not _scene_slugs.has(scene_slug):
		_scene_slugs.append(scene_slug)
		_scene.add_item("%s (não encontrada)" % scene_slug)
	_scene.select(_scene_slugs.find(scene_slug) + 1 if not scene_slug.is_empty() else 0)
	_show_stage(0)


func set_giver_on_map(on_map: bool) -> void:
	_giver_on_map = on_map
	_refresh_scene_hint()


func dialogues() -> Dictionary:
	return _dialogues.duplicate(true)


func offer_scene() -> String:
	var index := _scene.selected - 1
	return _scene_slugs[index] if index >= 0 and index < _scene_slugs.size() else ""


func _show_stage(index: int) -> void:
	_stage = index
	_tabs[index].button_pressed = true
	_stage_hint.text = STAGE_HINTS[index]
	_scene_box.visible = index == 0
	_refresh_scene_hint()
	_render()


func _refresh_scene_hint() -> void:
	var texts: Array[String] = []
	if _scene_slugs.is_empty():
		texts.append(NO_SCENES_HINT)
	elif not offer_scene().is_empty():
		texts.append(SCENE_HINT)
		if not _giver_on_map:
			texts.append(ROOM_WARNING)
	_scene_hint.text = "\n".join(texts)
	_scene_hint.visible = not texts.is_empty()


func _render() -> void:
	for child: Node in _steps.get_children():
		child.queue_free()
	_add_steps(_steps, _dialogues[STAGES[_stage]], 0)
	for index: int in STAGES.size():
		var count := count_steps(_dialogues[STAGES[index]])
		_tabs[index].text = STAGE_NAMES[index] + (" (%d)" % count if count > 0 else "")
	var total := count_steps(_dialogues[STAGES[_stage]])
	_count_label.text = "Passos: %d de %d" % [total, MAX_STEPS]
	_count_label.visible = total > 0
	_count_label.add_theme_color_override(&"font_color", UiPalette.DANGER if total > MAX_STEPS else UiPalette.TEXT_SECONDARY)
	_refresh_empty()


func _refresh_empty() -> void:
	var empty: bool = (_dialogues[STAGES[_stage]] as Array).is_empty()
	_empty.text = EMPTY_HINTS[_stage]
	_empty.visible = empty and (_stage != 0 or offer_scene().is_empty())


## Como o servidor conta (`MAX_DIALOGUE_STEPS`): cada fala, escolha e opção é um passo.
static func count_steps(steps: Array) -> int:
	var total := 0
	for step: Variant in steps:
		if not step is Dictionary:
			continue
		total += 1
		for option: Variant in DictFields.get_array(step, "options"):
			if option is Dictionary:
				total += 1 + count_steps(DictFields.get_array(option, "steps"))
	return total


## Os passos de uma lista (a conversa ou as respostas de uma opção) e os botões de pôr.
func _add_steps(parent: VBoxContainer, steps: Array, depth: int) -> void:
	for index: int in steps.size():
		if not steps[index] is Dictionary:
			continue
		var step: Dictionary = steps[index]
		if step.get("type") == "choice":
			parent.add_child(_choice_block(steps, index, depth))
		else:
			parent.add_child(_say_row(steps, index))
	var adds := HBoxContainer.new()
	adds.add_theme_constant_override(&"separation", 6)
	parent.add_child(adds)
	adds.add_child(QuestEditorStyle.outline("+ Fala", _add_say.bind(steps)))
	if depth < MAX_DEPTH:
		adds.add_child(QuestEditorStyle.outline("+ Escolha", _add_choice.bind(steps)))


func _say_row(steps: Array, index: int) -> VBoxContainer:
	var step: Dictionary = steps[index]
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 2)
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", 2)
	box.add_child(head)
	var speaker := OptionButton.new()
	speaker.focus_mode = Control.FOCUS_NONE
	speaker.fit_to_longest_item = false
	speaker.custom_minimum_size.x = SPEAKER_WIDTH
	speaker.clip_text = true
	speaker.add_theme_font_size_override(&"font_size", QuestEditorStyle.FIELD_FONT)
	for label_text: String in SPEAKER_NAMES:
		speaker.add_item(label_text)
	speaker.select(maxi(0, SPEAKERS.find(DictFields.get_string(step, "speaker", "npc"))))
	speaker.item_selected.connect(func(selected: int) -> void:
		step["speaker"] = SPEAKERS[selected]
		edited.emit())
	head.add_child(speaker)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(gap)
	_add_step_buttons(head, steps, index)
	var text := TextEdit.new()
	text.text = DictFields.get_string(step, "text")
	text.placeholder_text = "O que ele diz… Uma linha em branco começa outra caixa."
	text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text.scroll_fit_content_height = true
	text.custom_minimum_size.y = TEXT_MIN_HEIGHT
	text.add_theme_font_size_override(&"font_size", QuestEditorStyle.FIELD_FONT)
	box.add_child(text)
	var counter := QuestEditorStyle.secondary("")
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(counter)
	_refresh_counter(counter, text.text)
	text.text_changed.connect(func() -> void:
		step["text"] = text.text
		_refresh_counter(counter, text.text)
		edited.emit())
	return box


## O servidor conta as letras sem os espaços das pontas; as caixas seguem os parágrafos.
static func _refresh_counter(counter: Label, text: String) -> void:
	var letters := text.strip_edges().length()
	var boxes := MapNpc.paragraphs(text).size()
	counter.text = "%d/%d  ·  %d caixa%s" % [letters, MAX_TEXT, boxes, "" if boxes == 1 else "s"]
	var bad := letters == 0 or letters > MAX_TEXT
	counter.add_theme_color_override(&"font_color", UiPalette.DANGER if bad else UiPalette.TEXT_SECONDARY)


func _choice_block(steps: Array, index: int, depth: int) -> PanelContainer:
	var step: Dictionary = steps[index]
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", QuestEditorStyle.choice_style(depth))
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 8)
	panel.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", 2)
	box.add_child(head)
	var label := Label.new()
	label.text = "Escolha"
	label.theme_type_variation = &"BoldLabel"
	head.add_child(label)
	var sub := QuestEditorStyle.secondary("  o jogador responde")
	sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sub)
	_add_step_buttons(head, steps, index)
	var options := DictFields.get_array(step, "options")
	step["options"] = options
	for at: int in options.size():
		if options[at] is Dictionary:
			box.add_child(_option_block(options, at, depth))
	if options.size() < MAX_OPTIONS:
		var add := QuestEditorStyle.outline("+ Opção", func() -> void:
			options.append(_new_option())
			_changed())
		add.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		box.add_child(add)
	return panel


func _option_block(options: Array, at: int, depth: int) -> VBoxContainer:
	var option: Dictionary = options[at]
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 6)
	var head := HBoxContainer.new()
	head.add_theme_constant_override(&"separation", 4)
	box.add_child(head)
	var text := LineEdit.new()
	text.text = DictFields.get_string(option, "text")
	text.placeholder_text = "Resposta %d" % (at + 1)
	text.max_length = MAX_OPTION_TEXT
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_font_size_override(&"font_size", QuestEditorStyle.FIELD_FONT)
	text.text_changed.connect(func(value: String) -> void:
		option["text"] = value
		edited.emit())
	head.add_child(text)
	if _stage == 0:
		var outcome := OptionButton.new()
		outcome.focus_mode = Control.FOCUS_NONE
		outcome.fit_to_longest_item = false
		outcome.custom_minimum_size.x = OUTCOME_WIDTH
		outcome.clip_text = true
		outcome.add_theme_font_size_override(&"font_size", QuestEditorStyle.FIELD_FONT)
		for label_text: String in OUTCOME_NAMES:
			outcome.add_item(label_text)
		var chosen := maxi(0, OUTCOMES.find(option.get("outcome")))
		outcome.select(chosen)
		_color_outcome(outcome, chosen)
		outcome.tooltip_text = "Aceita ou Recusa encerram a conversa depois das falas desta resposta; Segue continua do passo seguinte à escolha."
		outcome.item_selected.connect(func(selected: int) -> void:
			option["outcome"] = OUTCOMES[selected]
			_color_outcome(outcome, selected)
			edited.emit())
		head.add_child(outcome)
	if options.size() > MIN_OPTIONS:
		head.add_child(QuestEditorStyle.mini("✕", func() -> void:
			options.remove_at(at)
			_changed(), true))
	var replies := VBoxContainer.new()
	replies.add_theme_constant_override(&"separation", 8)
	var indent := MarginContainer.new()
	indent.add_theme_constant_override(&"margin_left", INDENT)
	indent.add_child(replies)
	box.add_child(indent)
	var steps := DictFields.get_array(option, "steps")
	option["steps"] = steps
	_add_steps(replies, steps, depth + 1)
	return box


static func _color_outcome(outcome: OptionButton, index: int) -> void:
	var color: Variant = OUTCOME_COLORS[index]
	for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		if color is Color:
			outcome.add_theme_color_override(state, color)
		else:
			outcome.remove_theme_color_override(state)


func _add_step_buttons(row: HBoxContainer, steps: Array, index: int) -> void:
	row.add_child(QuestEditorStyle.mini("↑", _move_step.bind(steps, index, -1)))
	row.add_child(QuestEditorStyle.mini("↓", _move_step.bind(steps, index, 1)))
	row.add_child(QuestEditorStyle.mini("✕", func() -> void:
		steps.remove_at(index)
		_changed(), true))


func _move_step(steps: Array, index: int, offset: int) -> void:
	var target := index + offset
	if target < 0 or target >= steps.size():
		return
	var step: Variant = steps[index]
	steps[index] = steps[target]
	steps[target] = step
	_changed()


func _add_say(steps: Array) -> void:
	steps.append({"type": "say", "speaker": "npc", "text": ""})
	_changed()


func _add_choice(steps: Array) -> void:
	steps.append({"type": "choice", "options": [_new_option(), _new_option()]})
	_changed()


func _changed() -> void:
	_render()
	edited.emit()


func _new_option() -> Dictionary:
	return {"text": "", "outcome": null, "steps": []}
