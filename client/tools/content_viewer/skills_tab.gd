class_name SkillsTab
extends ListDetail
## A aba Técnicas (content-viewer/02, RF-01 e RF-02): a lista pelo `id`, com quantos
## dos 3 arquivos (ícone, efeito e som) existem, e o detalhe com os dados, a marca no
## chão, os efeitos, quem aprende e os arquivos tocando.
##
## Os dados saem das linhas do catálogo, e não do modelo `Skill`: a linha diz o que
## está vazio (o poder de uma Técnica de suporte), e a tela mostra "—".

const ICON_BOX := Vector2(104, 104)
const LEVEL_UP := "level_up"
const MINUS := "−"


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
	for entry: ContentFiles.Entry in files:
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


func _data(skill: Dictionary, box: VBoxContainer) -> void:
	var lines: Array = [
		["Poder", _power_text(skill.get("power"))],
		["Precisão", ContentViewer.value_or_dash(skill.get("accuracy"))],
		["PP", ContentViewer.value_or_dash(skill.get("max_pp"))],
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


## "Alterar atributo · 100% · Inimigo · Ataque −1": o tipo, a chance, o alvo e os
## campos preenchidos da linha.
## O Estado de um efeito vira link para a aba Estados (content-viewer/03, RF-08).
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


## Pares de nome e valor em colunas.
func _grid(lines: Array, columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns * 2
	grid.add_theme_constant_override(&"h_separation", 14)
	grid.add_theme_constant_override(&"v_separation", 2)
	for line: Array in lines:
		grid.add_child(ContentViewer.text(line[0], 0, UiPalette.TEXT_SECONDARY))
		grid.add_child(ContentViewer.text(line[1]))
	return grid


## Poder 0 é uma Técnica sem dano (de suporte): aparece "—", como um valor vazio.
func _power_text(power: Variant) -> String:
	if power == null or int(power) <= 0:
		return ContentViewer.EMPTY
	return str(power)


func _yes_no(value: Variant) -> String:
	if value == null:
		return ContentViewer.EMPTY
	return "sim" if bool(value) else "não"
