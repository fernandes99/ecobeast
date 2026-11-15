class_name SkillForm
extends VBoxContainer

signal saved(id: int)
signal cancelled

const NEW_SKILL := -1
const NUMBER_WIDTH := 96
const CHOICE_WIDTH := 170
const DESCRIPTION_HEIGHT := 72
const DEFAULT_GROUND_TURNS := 3
const DEFAULT_PERCENT := 50
const DEFAULT_CHANCE := 100
const LEVEL_UP := "level_up"
const EVOLUTION := "evolution"
const TEACHABLE := "teachable"
const ENEMY := "enemy"
const SINGLE := "single"
const HIDDEN_EFFECTS: Array[String] = ["set_weather"]
const BATTLE_EFFECTS: Array[String] = ["apply_status", "modify_stat", "heal", "drain", "recoil", "flinch"]
const NOT_IN_BATTLE := "A luta ainda não usa este efeito."
const SAVING := "Salvando…"

## Valores de uma Técnica nova (.specs/skill-editor/02-skill-form.md, a revisar).
const NEW_VALUES := {
	"slug": "", "name": "", "description": "",
	"power": 40, "accuracy": 100, "max_pp": 20, "priority": 0, "crit_stage": 0,
	"makes_contact": false, "min_hits": 1, "max_hits": 1, "range": 1, "pierces": false,
	"ground_effect_id": null, "ground_turns": null, "cooldown": 0,
}
const NUMBERS: Array[Array] = [
	["Poder", "power", 0, 250],
	["Precisão", "accuracy", 0, 100],
	["PP", "max_pp", 5, 40],
	["Countdown", "cooldown", 0, 5],
	["Prioridade", "priority", -7, 5],
	["Estágio de crítico", "crit_stage", 0, 3],
	["Golpes mín.", "min_hits", 1, 10],
	["Golpes máx.", "max_hits", 1, 10],
	["Alcance", "range", 1, 6],
]
const CHOICES: Array[Array] = [
	["Elemento", "element_id", "elements"],
	["Categoria", "skill_category_id", "skill_categories"],
	["Alvo", "skill_target_id", "skill_targets"],
	["Área", "area_shape_id", "area_shapes"],
]
const EFFECT_FIELDS := {
	"skill_target_id": ["Alvo", "skill_targets"],
	"status_condition_id": ["Estado", "status_conditions"],
	"stat_id": ["Atributo", "stats"],
}
const COPIED_COLUMNS: Array[String] = [
	"name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp",
	"priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits",
	"area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown",
]

var _viewer: ContentViewer
var _skill_id: int
var _draft: Dictionary = {}
var _effects: Array[Dictionary] = []
var _learners: Array[Dictionary] = []
var _effects_box: VBoxContainer
var _learners_box: VBoxContainer
var _ground_turns: SpinBox
var _error: Label
var _save_button: Button
var _cancel_button: Button


func _init(content_viewer: ContentViewer, skill_id: int) -> void:
	_viewer = content_viewer
	_skill_id = skill_id
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override(&"separation", 10)
	if skill_id == NEW_SKILL:
		_start_new()
	else:
		_start_from(skill_id)
	_build()


func is_new() -> bool:
	return _skill_id == NEW_SKILL


func body() -> Dictionary:
	var result := _draft.duplicate()
	result["effects"] = _effects.duplicate(true)
	result["learners"] = _learners.duplicate(true)
	return result


func _start_new() -> void:
	_draft = NEW_VALUES.duplicate()
	for choice: Array in CHOICES:
		_draft[choice[1]] = _first_id(choice[2])
	_draft["skill_target_id"] = _id_by_slug("skill_targets", ENEMY, _draft["skill_target_id"])
	_draft["area_shape_id"] = _id_by_slug("area_shapes", SINGLE, _draft["area_shape_id"])


func _start_from(skill_id: int) -> void:
	var row: Dictionary = GameData.get_row("skills", skill_id)
	_draft["slug"] = str(row.get("slug", ""))
	for column: String in COPIED_COLUMNS:
		_draft[column] = row.get(column)
	var effects: Array[Dictionary] = []
	for effect: Dictionary in GameData.get_rows("skill_effects"):
		if int(effect["skill_id"]) == skill_id:
			effects.append(effect)
	effects.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["sort_order"]) < int(b["sort_order"]))
	for effect: Dictionary in effects:
		var entry := {"effect_type_id": int(effect["effect_type_id"]), "chance": int(effect["chance"])}
		for column: String in _effect_columns():
			entry[column] = effect.get(column)
		_effects.append(entry)
	for learner: Dictionary in GameData.get_rows("species_skills"):
		if int(learner["skill_id"]) == skill_id:
			_learners.append({
				"species_id": int(learner["species_id"]),
				"skill_learn_method_id": int(learner["skill_learn_method_id"]),
				"level": learner.get("level"),
			})


func _build() -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 10)
	header.add_child(ContentViewer.text("Nova Técnica" if is_new() else "Editar %s" % _draft["name"], ContentViewer.TITLE_SIZE))
	add_child(header)

	var main := ContentViewer.block(self, "Técnica")
	var top := GridContainer.new()
	top.columns = 2
	top.add_theme_constant_override(&"h_separation", 14)
	main.add_child(top)
	top.add_child(_label("Slug"))
	if is_new():
		var slug := _line(_draft, "slug")
		slug.placeholder_text = "so_letras_minusculas"
		top.add_child(slug)
	else:
		top.add_child(ContentViewer.text(_draft["slug"], 0, UiPalette.TEXT_SECONDARY))
	top.add_child(_label("Nome"))
	top.add_child(_line(_draft, "name"))
	main.add_child(_label("Descrição"))
	var description := TextEdit.new()
	description.text = str(_draft["description"])
	description.custom_minimum_size.y = DESCRIPTION_HEIGHT
	description.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	description.text_changed.connect(func() -> void: _draft["description"] = description.text)
	main.add_child(description)

	var data := ContentViewer.block(self, "Dados")
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override(&"h_separation", 12)
	grid.add_theme_constant_override(&"v_separation", 6)
	data.add_child(grid)
	for choice: Array in CHOICES:
		grid.add_child(_label(choice[0]))
		grid.add_child(_choice(_draft, choice[1], choice[2]))
	for number: Array in NUMBERS:
		grid.add_child(_label(number[0]))
		grid.add_child(_number(_draft, number[1], number[2], number[3]))
	grid.add_child(_label("Faz contato"))
	grid.add_child(_check(_draft, "makes_contact"))
	grid.add_child(_label("Atravessa"))
	grid.add_child(_check(_draft, "pierces"))
	grid.add_child(_label("Marca no chão"))
	var ground := _choice(_draft, "ground_effect_id", "ground_effects", "Nenhuma")
	ground.item_selected.connect(func(_index: int) -> void: _on_ground_changed())
	grid.add_child(ground)
	grid.add_child(_label("Turnos da marca"))
	_ground_turns = _number(_draft, "ground_turns", 1, 20)
	_ground_turns.visible = _draft["ground_effect_id"] != null
	grid.add_child(_ground_turns)

	var effects := ContentViewer.block(self, "Efeitos")
	_effects_box = VBoxContainer.new()
	effects.add_child(_effects_box)
	effects.add_child(_add_button("+ Efeito", _add_effect))
	_refresh_effects()

	var learners := ContentViewer.block(self, "Quem aprende")
	_learners_box = VBoxContainer.new()
	learners.add_child(_learners_box)
	learners.add_child(_add_button("+ Ecobeast", _add_learner))
	_refresh_learners()

	_error = ContentViewer.paragraph("", UiPalette.DANGER)
	_error.visible = false
	add_child(_error)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override(&"separation", 10)
	_cancel_button = Button.new()
	_cancel_button.text = "Cancelar"
	_cancel_button.pressed.connect(cancelled.emit)
	buttons.add_child(_cancel_button)
	_save_button = Button.new()
	_save_button.text = "Salvar"
	_save_button.pressed.connect(_save)
	buttons.add_child(_save_button)
	add_child(buttons)


func _on_ground_changed() -> void:
	var has_ground: bool = _draft["ground_effect_id"] != null
	if has_ground and _draft["ground_turns"] == null:
		_draft["ground_turns"] = DEFAULT_GROUND_TURNS
		_ground_turns.set_value_no_signal(DEFAULT_GROUND_TURNS)
	elif not has_ground:
		_draft["ground_turns"] = null
	_ground_turns.visible = has_ground


func _refresh_effects() -> void:
	_clear(_effects_box)
	for index: int in _effects.size():
		_effects_box.add_child(_effect_row(index))


func _effect_row(index: int) -> Control:
	var effect := _effects[index]
	var slug := _slug_of("effect_types", effect["effect_type_id"])
	var line := HFlowContainer.new()
	line.add_theme_constant_override(&"h_separation", 8)
	line.add_child(_small_button("↑", _move_effect.bind(index, -1), index == 0))
	line.add_child(_small_button("↓", _move_effect.bind(index, 1), index == _effects.size() - 1))
	line.add_child(ContentViewer.text("%d." % (index + 1)))
	var type := _choice(effect, "effect_type_id", "effect_types", "", HIDDEN_EFFECTS)
	type.item_selected.connect(func(_index: int) -> void: _on_effect_type_changed(effect))
	line.add_child(type)
	line.add_child(_number(effect, "chance", 1, 100))
	line.add_child(_label("%"))
	var params: Dictionary = CatalogSchema.EFFECT_PARAMS.get(slug, {"required": [], "optional": []})
	for column: String in params["required"] + params["optional"]:
		match column:
			"skill_target_id", "status_condition_id", "stat_id":
				line.add_child(_label(EFFECT_FIELDS[column][0]))
				line.add_child(_choice(effect, column, EFFECT_FIELDS[column][1]))
			"stages":
				line.add_child(_label("Estágios"))
				line.add_child(_stages(effect))
			"percent":
				line.add_child(_label("%"))
				line.add_child(_number(effect, "percent", 1, 100))
			"value":
				line.add_child(_label("Valor (0 = vazio)"))
				line.add_child(_optional_number(effect, "value", 9999))
			"min_turns":
				line.add_child(_label("Turnos"))
				line.add_child(_number(effect, "min_turns", 1, 99))
	if not BATTLE_EFFECTS.has(slug):
		line.add_child(ContentViewer.text(NOT_IN_BATTLE, 0, UiPalette.WARNING))
	line.add_child(_small_button("×", _remove_effect.bind(index)))
	return line


func _on_effect_type_changed(effect: Dictionary) -> void:
	var slug := _slug_of("effect_types", effect["effect_type_id"])
	var params: Dictionary = CatalogSchema.EFFECT_PARAMS.get(slug, {"required": [], "optional": []})
	for column: String in _effect_columns():
		if params["required"].has(column):
			if effect.get(column) == null:
				effect[column] = _default_param(column)
		elif not params["optional"].has(column):
			effect[column] = null
	_refresh_effects.call_deferred()


func _default_param(column: String) -> Variant:
	match column:
		"skill_target_id":
			return _id_by_slug("skill_targets", ENEMY, _first_id("skill_targets"))
		"status_condition_id":
			return _first_id("status_conditions")
		"stat_id":
			return _first_id("stats")
		"stages":
			return -1
		"percent":
			return DEFAULT_PERCENT
		"min_turns":
			return 1
	return null


func _add_effect() -> void:
	var effect := {"effect_type_id": _id_by_slug("effect_types", "apply_status", _first_id("effect_types")), "chance": DEFAULT_CHANCE}
	for column: String in _effect_columns():
		effect[column] = null
	_effects.append(effect)
	_on_effect_type_changed(effect)


func _move_effect(index: int, step: int) -> void:
	var effect: Dictionary = _effects.pop_at(index)
	_effects.insert(index + step, effect)
	_refresh_effects.call_deferred()


func _remove_effect(index: int) -> void:
	_effects.remove_at(index)
	_refresh_effects.call_deferred()


func _refresh_learners() -> void:
	_clear(_learners_box)
	for index: int in _learners.size():
		_learners_box.add_child(_learner_row(index))


func _learner_row(index: int) -> Control:
	var learner := _learners[index]
	var line := HBoxContainer.new()
	line.add_theme_constant_override(&"separation", 8)
	line.add_child(_choice(learner, "species_id", "species"))
	var method := _choice(learner, "skill_learn_method_id", "skill_learn_methods")
	method.item_selected.connect(func(_index: int) -> void: _on_method_changed(learner))
	line.add_child(method)
	if _slug_of("skill_learn_methods", learner["skill_learn_method_id"]) == LEVEL_UP:
		line.add_child(_label("Nível"))
		line.add_child(_number(learner, "level", 1, 100))
	line.add_child(_small_button("×", _remove_learner.bind(index)))
	return line


func _on_method_changed(learner: Dictionary) -> void:
	match _slug_of("skill_learn_methods", learner["skill_learn_method_id"]):
		LEVEL_UP:
			if learner.get("level") == null or int(learner["level"]) < 1:
				learner["level"] = 1
		EVOLUTION:
			learner["level"] = 0
		TEACHABLE:
			learner["level"] = null
	_refresh_learners.call_deferred()


func _add_learner() -> void:
	_learners.append({
		"species_id": _first_id("species"),
		"skill_learn_method_id": _id_by_slug("skill_learn_methods", LEVEL_UP, _first_id("skill_learn_methods")),
		"level": 1,
	})
	_refresh_learners()


func _remove_learner(index: int) -> void:
	_learners.remove_at(index)
	_refresh_learners.call_deferred()


func _save() -> void:
	_save_button.disabled = true
	_cancel_button.disabled = true
	_show_error("")
	_save_button.text = SAVING
	var response: ApiResponse
	if is_new():
		response = await EditorApi.create_skill(body())
	else:
		response = await EditorApi.save_skill(_skill_id, body())
	if response.ok and response.data is Dictionary:
		saved.emit(int(response.data["id"]))
		return
	_save_button.text = "Salvar"
	_save_button.disabled = false
	_cancel_button.disabled = false
	_show_error(response.error)


func _show_error(message: String) -> void:
	_error.text = message
	_error.visible = not message.is_empty()


static func _effect_columns() -> Array[String]:
	var columns: Array[String] = []
	for column: String in SkillEffect.PARAM_COLUMNS:
		if column != "weather_id":
			columns.append(column)
	return columns


static func _label(value: String) -> Label:
	return ContentViewer.text(value, 0, UiPalette.TEXT_SECONDARY)


static func _clear(box: Container) -> void:
	for child: Node in box.get_children():
		box.remove_child(child)
		child.queue_free()


static func _first_id(table_name: String) -> Variant:
	var rows := GameData.get_rows(table_name)
	if rows.is_empty():
		return null
	return int(rows[0]["id"])


static func _id_by_slug(table_name: String, slug: String, fallback: Variant) -> Variant:
	for row: Dictionary in GameData.get_rows(table_name):
		if row.get("slug") == slug:
			return int(row["id"])
	return fallback


static func _slug_of(table_name: String, id: Variant) -> String:
	if id == null:
		return ""
	return str(GameData.get_row(table_name, int(id)).get("slug", ""))


static func _line(target: Dictionary, key: String) -> LineEdit:
	var line := LineEdit.new()
	line.text = str(target[key])
	line.custom_minimum_size.x = 320
	line.text_changed.connect(func(value: String) -> void: target[key] = value)
	return line


static func _number(target: Dictionary, key: String, min_value: int, max_value: int) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = 1
	spin.rounded = true
	spin.custom_minimum_size.x = NUMBER_WIDTH
	spin.value = min_value if target.get(key) == null else int(target[key])
	spin.value_changed.connect(func(value: float) -> void: target[key] = int(value))
	return spin


static func _optional_number(target: Dictionary, key: String, max_value: int) -> SpinBox:
	var spin := _number(target, key, 0, max_value)
	spin.value_changed.connect(func(value: float) -> void:
		if value == 0:
			target[key] = null)
	if target.get(key) == null:
		target[key] = null
	return spin


static func _stages(target: Dictionary) -> SpinBox:
	var spin := _number(target, "stages", -6, 6)
	var last := [int(spin.value)]
	spin.value_changed.connect(func(value: float) -> void:
		if int(value) == 0:
			spin.set_value_no_signal(1 if last[0] < 0 else -1)
			target["stages"] = int(spin.value)
		last[0] = int(spin.value))
	return spin


static func _check(target: Dictionary, key: String) -> CheckBox:
	var box := CheckBox.new()
	box.button_pressed = bool(target[key])
	box.toggled.connect(func(on: bool) -> void: target[key] = on)
	return box


static func _choice(target: Dictionary, key: String, table_name: String, none_label := "", skipped: Array[String] = []) -> OptionButton:
	var button := OptionButton.new()
	button.custom_minimum_size.x = CHOICE_WIDTH
	button.fit_to_longest_item = false
	if not none_label.is_empty():
		button.add_item(none_label)
		button.set_item_metadata(0, null)
	var current: Variant = target.get(key)
	for row: Dictionary in GameData.get_rows(table_name):
		var id := int(row["id"])
		if skipped.has(str(row.get("slug", ""))) and (current == null or int(current) != id):
			continue
		button.add_item(str(row.get("name", row.get("slug", id))))
		button.set_item_metadata(button.item_count - 1, id)
	for index: int in button.item_count:
		var meta: Variant = button.get_item_metadata(index)
		if (meta == null and current == null) or (meta != null and current != null and int(meta) == int(current)):
			button.select(index)
	button.item_selected.connect(func(index: int) -> void: target[key] = button.get_item_metadata(index))
	return button


static func _add_button(label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.pressed.connect(action)
	return button


static func _small_button(label: String, action: Callable, disabled := false) -> Button:
	var button := Button.new()
	button.text = label
	button.disabled = disabled
	button.custom_minimum_size.x = 30
	button.pressed.connect(action)
	return button
