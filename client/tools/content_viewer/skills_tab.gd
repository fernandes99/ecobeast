class_name SkillsTab
extends ListDetail

const ICON_BOX := Vector2(104, 104)
const LEVEL_UP := "level_up"
const MINUS := "−"
const TEST_LEVEL := 50
const MAX_TEST_LEVEL := 100
const FALLBACK_SPECIES := 1
const NO_PLAYER_TEXT := "Entre na sua conta primeiro."
const BATTLE_OPEN_TEXT := "Termine a luta aberta primeiro."

## O oponente do último teste, enquanto o jogo está aberto.
static var _last_enemy_id := FALLBACK_SPECIES

var _return_id := -1


func _init(content_viewer: ContentViewer) -> void:
	super(content_viewer)
	var rows: Array[ListDetail.Row] = []
	for skill_row: Dictionary in GameData.get_rows("skills"):
		var files := ContentFiles.skill_files(skill_row["slug"])
		var done := ContentFiles.count_complete(files)
		var row := ListDetail.Row.new(skill_row["id"], skill_row["name"])
		var element := GameData.get_element(skill_row["element_id"])
		if element != null:
			row.dot = element.color
		row.tail = "%d/%d" % [done, files.size()]
		row.tail_color = ContentViewer.status_color(done, files.size())
		rows.append(row)
	set_rows(rows)
	var new_button := Button.new()
	new_button.text = "Nova Técnica"
	new_button.pressed.connect(_edit.bind(SkillForm.NEW_SKILL))
	add_list_header(new_button)
	visibility_changed.connect(_on_visibility_changed)


func tab_title() -> String:
	return "Técnicas (%d)" % GameData.get_rows("skills").size()


func _build_detail(id: int, box: VBoxContainer) -> void:
	var skill: Dictionary = GameData.get_row("skills", id)
	if skill.is_empty():
		return
	var files := ContentFiles.skill_files(skill["slug"])
	_header(skill, files[0], box)
	_data(skill, ContentViewer.block(box, "Dados"))
	if skill.get("ground_effect_id") != null:
		_ground(skill, ContentViewer.block(box, "Marca no chão"))
	var effects := _effects_of(id)
	if not effects.is_empty():
		_effects(effects, ContentViewer.block(box, "Efeitos"))
	_learners(id, ContentViewer.block(box, "Quem aprende"))
	var row := ContentViewer.flow(14)
	for entry: ContentFiles.Entry in files + ContentFiles.skill_optional_files(skill["slug"]):
		row.add_child(FilePreview.create(entry))
	ContentViewer.block(box, "Arquivos").add_child(row)


func _header(skill: Dictionary, icon: ContentFiles.Entry, box: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 14)
	box.add_child(header)
	header.add_child(FilePreview.create(icon, ICON_BOX))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override(&"separation", 6)
	header.add_child(info)
	info.add_child(ContentViewer.text(skill["name"], ContentViewer.TITLE_SIZE))
	var facts := ContentViewer.flow(8)
	facts.add_child(viewer.element_link(skill["element_id"]))
	facts.add_child(ContentViewer.text(ContentViewer.row_name("skill_categories", skill.get("skill_category_id")), 0, UiPalette.TEXT_SECONDARY))
	info.add_child(facts)
	info.add_child(ContentViewer.paragraph(str(skill.get("description", ""))))
	var buttons := VBoxContainer.new()
	buttons.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	header.add_child(buttons)
	var edit_button := Button.new()
	edit_button.text = "Editar"
	edit_button.pressed.connect(_edit.bind(int(skill["id"])))
	buttons.add_child(edit_button)
	var test_panel := _test_panel(int(skill["id"]), box)
	var test_button := Button.new()
	test_button.text = "Testar técnica"
	test_button.toggle_mode = true
	test_button.toggled.connect(func(on: bool) -> void: test_panel.visible = on)
	buttons.add_child(test_button)


## O painel do Testar técnica (skill-test/02): quem usa, o oponente, o nível e o
## oponente parado, e o Começar, que abre a luta na janela principal.
func _test_panel(skill_id: int, box: VBoxContainer) -> Control:
	var panel := ContentViewer.block(box, "Testar técnica")
	var holder := panel.get_parent() as Control
	holder.visible = false
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 14)
	grid.add_theme_constant_override(&"v_separation", 6)
	panel.add_child(grid)
	var learners := _learner_ids(skill_id)
	var user := _species_choice(learners)
	var first_user := learners[0] if not learners.is_empty() else FALLBACK_SPECIES
	user.select(user.get_item_index(first_user))
	grid.add_child(ContentViewer.text("Quem usa", 0, UiPalette.TEXT_SECONDARY))
	grid.add_child(user)
	var enemy := _species_choice([])
	var enemy_index := enemy.get_item_index(_last_enemy_id)
	enemy.select(enemy_index if enemy_index >= 0 else enemy.get_item_index(FALLBACK_SPECIES))
	grid.add_child(ContentViewer.text("Oponente", 0, UiPalette.TEXT_SECONDARY))
	grid.add_child(enemy)
	var level := SpinBox.new()
	level.min_value = 1
	level.max_value = MAX_TEST_LEVEL
	level.value = TEST_LEVEL
	grid.add_child(ContentViewer.text("Nível", 0, UiPalette.TEXT_SECONDARY))
	grid.add_child(level)
	var idle := CheckBox.new()
	idle.text = "Oponente parado"
	idle.button_pressed = true
	panel.add_child(idle)
	var message := ContentViewer.text("", 0, UiPalette.TEXT_SECONDARY)
	message.visible = false
	var start := Button.new()
	start.text = "Começar"
	start.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	start.pressed.connect(func() -> void:
		var test := {
			"skill_id": skill_id,
			"species_id": user.get_selected_id(),
			"enemy_species_id": enemy.get_selected_id(),
			"level": int(level.value),
			"enemy_idle": idle.button_pressed,
		}
		_start_test(test, message))
	panel.add_child(start)
	panel.add_child(message)
	return holder


## Primeiro quem aprende a Técnica, na ordem do id, e depois as outras espécies.
func _species_choice(first: Array[int]) -> OptionButton:
	var choice := OptionButton.new()
	for species_id: int in first:
		var species := GameData.get_species(species_id)
		if species != null:
			choice.add_item("%s (aprende)" % species.name, species.id)
	if not first.is_empty():
		choice.add_separator()
	for species: CreatureSpecies in GameData.get_all_species():
		if not first.has(species.id):
			choice.add_item(species.name, species.id)
	return choice


func _learner_ids(skill_id: int) -> Array[int]:
	var ids: Array[int] = []
	for row: Dictionary in GameData.get_rows("species_skills"):
		var species_id := int(row["species_id"])
		if int(row["skill_id"]) == skill_id and not ids.has(species_id):
			ids.append(species_id)
	ids.sort()
	return ids


func _start_test(test: Dictionary, message: Label) -> void:
	var refusal := ""
	if Session.player == null:
		refusal = NO_PLAYER_TEXT
	elif Router.current_id() == &"board_battle" and not _skill_test_open():
		refusal = BATTLE_OPEN_TEXT
	message.text = refusal
	message.visible = not refusal.is_empty()
	if not refusal.is_empty():
		return
	_last_enemy_id = test["enemy_species_id"]
	var center := BattleIntro.get_viewport().get_visible_rect().size / 2.0
	if not await BattleIntro.cover(center, &"wild"):
		return
	# Um teste aberto, terminado ou não, dá lugar ao novo; o servidor descarta o anterior.
	if _skill_test_open():
		Router.replace(&"board_battle", {"skill_test": test})
	else:
		Router.push(&"board_battle", {"skill_test": test})


func _skill_test_open() -> bool:
	var screen := Router.current_screen()
	return screen != null and Router.current_id() == &"board_battle" and screen.has_method(&"is_skill_test") and bool(screen.call(&"is_skill_test"))


func _edit(id: int) -> void:
	if selected_id != -1:
		_return_id = selected_id
	if id != SkillForm.NEW_SKILL:
		_return_id = id
	show_custom(func(box: VBoxContainer) -> void:
		var form := SkillForm.new(viewer, id)
		form.saved.connect(_on_saved)
		form.cancelled.connect(_close_form)
		box.add_child(form))


func _close_form() -> void:
	select(_return_id)
	if selected_id == -1 and not _buttons.is_empty():
		select(_buttons.keys()[0])


func _on_saved(id: int) -> void:
	await GameData.load_catalog()
	viewer.rebuild()
	viewer.show_item(ContentViewer.TAB_SKILLS, id)


func _on_visibility_changed() -> void:
	if not is_visible_in_tree() and selected_id == -1:
		_close_form()


func _data(skill: Dictionary, box: VBoxContainer) -> void:
	var lines: Array = [
		["Poder", _power_text(skill.get("power"))],
		["Precisão", ContentViewer.value_or_dash(skill.get("accuracy"))],
		["PP", ContentViewer.value_or_dash(skill.get("max_pp"))],
		["Countdown", _countdown_text(skill.get("cooldown"))],
		["Prioridade", ContentViewer.value_or_dash(skill.get("priority"))],
		["Estágio de crítico", ContentViewer.value_or_dash(skill.get("crit_stage"))],
		["Alvo", ContentViewer.row_name("skill_targets", skill.get("skill_target_id"))],
		["Área", ContentViewer.row_name("area_shapes", skill.get("area_shape_id"))],
		["Alcance", ContentViewer.value_or_dash(skill.get("range"))],
		["Atravessa", _yes_no(skill.get("pierces"))],
		["Faz contato", _yes_no(skill.get("makes_contact"))],
	]
	var max_hits: Variant = skill.get("max_hits")
	if max_hits != null and int(max_hits) > 1:
		lines.append(["Golpes", "%s a %s" % [ContentViewer.value_or_dash(skill.get("min_hits")), max_hits]])
	box.add_child(_grid(lines, 4))


func _ground(skill: Dictionary, box: VBoxContainer) -> void:
	var ground := GameData.get_ground_effect(int(skill["ground_effect_id"]))
	if ground == null:
		box.add_child(ContentViewer.text(ContentViewer.EMPTY))
		return
	var line := ContentViewer.flow(10)
	var swatch := ColorRect.new()
	swatch.color = ground.color
	swatch.custom_minimum_size = Vector2(14, 14)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(swatch)
	line.add_child(viewer.link(ground.name, ContentViewer.TAB_STATUSES, StatusesTab.ground_row_id(ground.id)))
	line.add_child(ContentViewer.text("%d%% de dano por turno · %s turnos" % [ground.damage_percent, ContentViewer.value_or_dash(skill.get("ground_turns"))], 0, UiPalette.TEXT_SECONDARY))
	box.add_child(line)


func _effects_of(skill_id: int) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	for row: Dictionary in GameData.get_rows("skill_effects"):
		if row["skill_id"] == skill_id:
			effects.append(row)
	effects.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0)))
	return effects


func _effects(effects: Array[Dictionary], box: VBoxContainer) -> void:
	for effect: Dictionary in effects:
		if effect.get("status_condition_id") == null:
			box.add_child(ContentViewer.text(effect_text(effect)))
			continue
		var status_id := int(effect["status_condition_id"])
		var status_name := ContentViewer.row_name("status_conditions", status_id)
		var parts := effect_text(effect).split(" · ")
		var line := HBoxContainer.new()
		line.add_theme_constant_override(&"separation", 0)
		for i: int in parts.size():
			if i > 0:
				line.add_child(ContentViewer.text(" · "))
			if parts[i] == status_name:
				line.add_child(viewer.link(status_name, ContentViewer.TAB_STATUSES, status_id))
			else:
				line.add_child(ContentViewer.text(parts[i]))
		box.add_child(line)


static func effect_text(effect: Dictionary) -> String:
	var parts: Array[String] = [ContentViewer.row_name("effect_types", effect.get("effect_type_id"))]
	if effect.get("chance") != null:
		parts.append("%d%%" % int(effect["chance"]))
	if effect.get("skill_target_id") != null:
		parts.append(ContentViewer.row_name("skill_targets", effect["skill_target_id"]))
	if effect.get("status_condition_id") != null:
		parts.append(ContentViewer.row_name("status_conditions", effect["status_condition_id"]))
	if effect.get("stat_id") != null:
		var stat := ContentViewer.row_name("stats", effect["stat_id"])
		var stages: Variant = effect.get("stages")
		if stages != null:
			var amount := int(stages)
			stat += " %s%d" % ["+" if amount > 0 else MINUS if amount < 0 else "", absi(amount)]
		parts.append(stat)
	if effect.get("percent") != null:
		parts.append("%d%%" % int(effect["percent"]))
	if effect.get("value") != null:
		parts.append("valor %d" % int(effect["value"]))
	if effect.get("weather_id") != null:
		parts.append("clima %d" % int(effect["weather_id"]))
	if effect.get("min_turns") != null:
		parts.append("%d turnos" % int(effect["min_turns"]))
	return " · ".join(parts)


func _learners(skill_id: int, box: VBoxContainer) -> void:
	var rows: Array[Dictionary] = []
	for row: Dictionary in GameData.get_rows("species_skills"):
		if row["skill_id"] == skill_id:
			rows.append(row)
	if rows.is_empty():
		box.add_child(ContentViewer.text("Nenhum Ecobeast aprende.", 0, UiPalette.TEXT_SECONDARY))
		return
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["species_id"]) < int(b["species_id"]))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 18)
	grid.add_theme_constant_override(&"v_separation", 2)
	box.add_child(grid)
	for row: Dictionary in rows:
		var species := GameData.get_species(row["species_id"])
		if species == null:
			continue
		grid.add_child(viewer.link(species.name, ContentViewer.TAB_SPECIES, species.id))
		var method: Dictionary = GameData.get_row("skill_learn_methods", row["skill_learn_method_id"])
		var when := "Nv %s" % ContentViewer.value_or_dash(row.get("level")) if method.get("slug", "") == LEVEL_UP else str(method.get("name", ContentViewer.EMPTY))
		grid.add_child(ContentViewer.text(when, 0, UiPalette.TEXT_SECONDARY))


func _grid(lines: Array, columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns * 2
	grid.add_theme_constant_override(&"h_separation", 14)
	grid.add_theme_constant_override(&"v_separation", 2)
	for line: Array in lines:
		grid.add_child(ContentViewer.text(line[0], 0, UiPalette.TEXT_SECONDARY))
		grid.add_child(ContentViewer.text(line[1]))
	return grid


func _power_text(power: Variant) -> String:
	if power == null or int(power) <= 0:
		return ContentViewer.EMPTY
	return str(power)


func _countdown_text(cooldown: Variant) -> String:
	if cooldown == null:
		return ContentViewer.EMPTY
	match int(cooldown):
		0:
			return "Nenhum"
		1:
			return "1 rodada"
		_:
			return "%d rodadas" % int(cooldown)


func _yes_no(value: Variant) -> String:
	if value == null:
		return ContentViewer.EMPTY
	return "sim" if bool(value) else "não"
