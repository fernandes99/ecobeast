class_name SpeciesTab
extends ListDetail
## A aba Ecobeasts (content-viewer/01, RF-04 e RF-05): a lista pelo número do
## Bestiário, com quantos dos 6 arquivos existem, e o detalhe com os dados, a linha de
## Evolução, as Técnicas por nível, os stats, os Traços, os biomas e os arquivos.

const FRONT_BOX := Vector2(128, 128)
const STAT_MAX := 255.0
const BAR_WIDTH := 260.0
const BAR_HEIGHT := 10.0
const LEVEL_UP := "level_up"
## Técnicas que não são por nível vão para o fim da lista.
const NO_LEVEL := 999


func _init(content_viewer: ContentViewer) -> void:
	super(content_viewer)
	var rows: Array[ListDetail.Row] = []
	for species: CreatureSpecies in GameData.get_all_species():
		var files := ContentFiles.creature_files(species.slug)
		var done := ContentFiles.count_complete(files)
		var row := ListDetail.Row.new(species.id, "#%d %s" % [species.id, species.name])
		row.tail = "%d/%d" % [done, files.size()]
		row.tail_color = ContentViewer.status_color(done, files.size())
		rows.append(row)
	set_rows(rows)


func tab_title() -> String:
	return "Ecobeasts (%d)" % GameData.get_all_species().size()


func _build_detail(id: int, box: VBoxContainer) -> void:
	var species := GameData.get_species(id)
	if species == null:
		return
	_header(species, box)
	_evolution(species, ContentViewer.block(box, "Evolução"))
	_skills(species, ContentViewer.block(box, "Técnicas por nível"))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override(&"separation", 10)
	box.add_child(columns)
	_stats(species, ContentViewer.block(columns, "Stats base"))
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override(&"separation", 10)
	columns.add_child(side)
	_progress(species, ContentViewer.block(side, "Progressão e captura"))
	_traits(species, ContentViewer.block(side, "Traços"))
	_biomes(species, ContentViewer.block(side, "Biomas"))
	_files(species, ContentViewer.block(box, "Arquivos"))


func _header(species: CreatureSpecies, box: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 14)
	box.add_child(header)
	header.add_child(FilePreview.create(ContentFiles.creature_files(species.slug)[0], FRONT_BOX))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override(&"separation", 6)
	header.add_child(info)
	var title := ContentViewer.flow(10)
	title.add_child(ContentViewer.text(species.name, ContentViewer.TITLE_SIZE))
	title.add_child(ContentViewer.text("#%d" % species.id, ContentViewer.TITLE_SIZE, UiPalette.TEXT_MUTED))
	info.add_child(title)
	var facts := ContentViewer.flow(8)
	for element_id: int in species.element_ids:
		facts.add_child(viewer.element_link(element_id))
	var rarity: Dictionary = GameData.get_row("rarities", species.rarity_id)
	facts.add_child(ContentViewer.text("%s · %s m · %s kg" % [rarity.get("name", "?"), ContentViewer.decimal(species.height_m), ContentViewer.decimal(species.weight_kg)], 0, UiPalette.TEXT_SECONDARY))
	var starter := _starter_text(species.id)
	if not starter.is_empty():
		facts.add_child(ContentViewer.text(starter, 0, UiPalette.ACCENT))
	info.add_child(facts)
	info.add_child(ContentViewer.paragraph(species.description))


## A linha inteira, do primeiro ao último estágio, uma por ramo.
func _evolution(species: CreatureSpecies, box: VBoxContainer) -> void:
	var first := _first_stage(species)
	var paths: Array = []
	_collect_paths(first.id, [], paths)
	if paths.size() == 1 and (paths[0] as Array).size() == 1:
		box.add_child(ContentViewer.text("Não evolui.", 0, UiPalette.TEXT_SECONDARY))
		return
	for path: Array in paths:
		var line := ContentViewer.flow(6)
		for step: Dictionary in path:
			var stage := GameData.get_species(step["species_id"])
			if step.has("rule"):
				line.add_child(ContentViewer.text("→ %s →" % _trigger_text(step["rule"]), 0, UiPalette.TEXT_SECONDARY))
			if stage.id == species.id:
				var current := ContentViewer.text(stage.name)
				current.theme_type_variation = &"BoldLabel"
				current.add_theme_font_size_override(&"font_size", ContentViewer.FONT_SIZE)
				line.add_child(current)
			else:
				line.add_child(viewer.link(stage.name, ContentViewer.TAB_SPECIES, stage.id))
		box.add_child(line)


func _first_stage(species: CreatureSpecies) -> CreatureSpecies:
	var stage := species
	var guard := 0
	while stage.evolves_from_species_id > 0 and guard < 16:
		var previous := GameData.get_species(stage.evolves_from_species_id)
		if previous == null:
			break
		stage = previous
		guard += 1
	return stage


## Cada caminho é uma lista de passos {species_id, rule?}: `rule` é a Evolução que
## leva até aquele estágio.
func _collect_paths(species_id: int, path: Array, paths: Array, rule: EvolutionRule = null) -> void:
	var step := {"species_id": species_id}
	if rule != null:
		step["rule"] = rule
	var here := path.duplicate()
	here.append(step)
	var next := GameData.get_evolutions(species_id)
	if next.is_empty() or here.size() > 16:
		paths.append(here)
		return
	for evolution: EvolutionRule in next:
		_collect_paths(evolution.evolved_species_id, here, paths, evolution)


func _trigger_text(rule: EvolutionRule) -> String:
	var trigger: Dictionary = GameData.get_row("evolution_triggers", rule.evolution_trigger_id)
	var trigger_name: String = trigger.get("name", rule.trigger_slug)
	match rule.trigger_slug:
		"level":
			return "nível %d" % rule.min_level
		"item":
			var item := GameData.get_item(rule.item_id)
			return "%s %s" % [trigger_name, item.name if item != null else str(rule.item_id)]
		"bond":
			return "%s %d" % [trigger_name, rule.min_bond]
		"time_of_day":
			return "%s %s" % [trigger_name, rule.time_of_day]
		"zone":
			return "%s %d" % [trigger_name, rule.zone_id]
	return trigger_name


func _skills(species: CreatureSpecies, box: VBoxContainer) -> void:
	var rows: Array[Dictionary] = []
	for row: Dictionary in GameData.get_rows("species_skills"):
		if row["species_id"] == species.id:
			rows.append(row)
	if rows.is_empty():
		box.add_child(ContentViewer.text("Não aprende nenhuma Técnica.", 0, UiPalette.TEXT_SECONDARY))
		return
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var level_a := _level_of(a)
		var level_b := _level_of(b)
		if level_a != level_b:
			return level_a < level_b
		return int(a["skill_id"]) < int(b["skill_id"]))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", 18)
	grid.add_theme_constant_override(&"v_separation", 2)
	box.add_child(grid)
	for row: Dictionary in rows:
		var method: Dictionary = GameData.get_row("skill_learn_methods", row["skill_learn_method_id"])
		var when := "Nv %d" % _level_of(row) if method.get("slug", "") == LEVEL_UP else str(method.get("name", "?"))
		grid.add_child(ContentViewer.text(when, 0, UiPalette.TEXT_SECONDARY))
		var skill := GameData.get_skill(row["skill_id"])
		if skill != null:
			# O link não estica: o espaço sobrando fica à direita dele, e não clicável.
			var cell := HBoxContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.add_child(viewer.link(skill.name, ContentViewer.TAB_SKILLS, skill.id))
			grid.add_child(cell)
		else:
			grid.add_child(ContentViewer.text("Técnica %d" % row["skill_id"]))
		grid.add_child(_skill_files_label(skill.slug if skill != null else ""))


func _level_of(row: Dictionary) -> int:
	var level: Variant = row.get("level")
	return int(level) if level != null else NO_LEVEL


## "ícone ✓ · efeito ✗ · som ✗", na cor de quanto está pronto.
func _skill_files_label(slug: String) -> Label:
	var files := ContentFiles.skill_files(slug)
	var parts: Array[String] = []
	for entry: ContentFiles.Entry in files:
		parts.append("%s %s" % [entry.label, "✓" if entry.exists() else "✗"])
	var done := ContentFiles.count_complete(files)
	return ContentViewer.text(" · ".join(parts), ContentViewer.SMALL_SIZE, ContentViewer.status_color(done, files.size()))


func _stats(species: CreatureSpecies, box: VBoxContainer) -> void:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", 10)
	grid.add_theme_constant_override(&"v_separation", 2)
	box.add_child(grid)
	for slug: String in StatBlock.SLUGS:
		var value := species.base_stats.get_value(slug)
		grid.add_child(ContentViewer.text(GameData.get_stat_name(slug), 0, UiPalette.TEXT_SECONDARY))
		var number := ContentViewer.text(str(value))
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(number)
		var bar := ColorRect.new()
		bar.color = UiPalette.ACCENT
		bar.custom_minimum_size = Vector2(maxf(2.0, value / STAT_MAX * BAR_WIDTH), BAR_HEIGHT)
		bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		grid.add_child(bar)
	grid.add_child(ContentViewer.text("Total"))
	var total := ContentViewer.text(str(species.base_stats.total()))
	total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(total)


## "inicial (1º de 3)" para um Ecobeast de `starter_options`; vazio para os outros.
func _starter_text(species_id: int) -> String:
	var starters := GameData.get_rows("starter_options")
	starters.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["sort_order"]) < int(b["sort_order"]))
	for i: int in starters.size():
		if starters[i]["species_id"] == species_id:
			return "inicial (%dº de %d)" % [i + 1, starters.size()]
	return ""


## Os dados que pesam no balanceamento (content-viewer/04, RF-01).
func _progress(species: CreatureSpecies, box: VBoxContainer) -> void:
	var row: Dictionary = GameData.get_row("species", species.id)
	var growth: Dictionary = GameData.get_row("growth_rates", species.growth_rate_id)
	var training: Array[String] = []
	for stat_row: Dictionary in GameData.get_rows("species_stats"):
		if stat_row["species_id"] == species.id and int(stat_row.get("training_yield", 0)) > 0:
			training.append("%s +%d" % [ContentViewer.row_name("stats", stat_row["stat_id"]), int(stat_row["training_yield"])])
	var lines: Array = [
		["Curva de XP", "%s (×%s)" % [growth.get("name", "?"), ContentViewer.decimal(float(growth.get("xp_multiplier", 1.0)))]],
		["XP ao ser derrotado", ContentViewer.value_or_dash(row.get("base_xp_yield"))],
		["Captura", "%s de 100" % ContentViewer.value_or_dash(row.get("capture_rate"))],
		["Gênero", gender_text(row.get("gender_ratio"))],
		["Treino que rende", ContentViewer.EMPTY if training.is_empty() else ", ".join(training)],
	]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 18)
	grid.add_theme_constant_override(&"v_separation", 2)
	for line: Array in lines:
		grid.add_child(ContentViewer.text(line[0], 0, UiPalette.TEXT_SECONDARY))
		grid.add_child(ContentViewer.text(line[1]))
	box.add_child(grid)


## `gender_ratio` é a fração de machos, de 0 a 1; −1 é sem gênero.
static func gender_text(ratio: Variant) -> String:
	if ratio == null:
		return ContentViewer.EMPTY
	var male := float(ratio)
	if male < 0.0:
		return "sem gênero"
	var male_percent := roundi(male * 100.0)
	return "%d%% macho · %d%% fêmea" % [male_percent, 100 - male_percent]


func _traits(species: CreatureSpecies, box: VBoxContainer) -> void:
	var rows := GameData.get_species_traits(species.id)
	if rows.is_empty():
		box.add_child(ContentViewer.text("Nenhum Traço.", 0, UiPalette.TEXT_SECONDARY))
	for row: Dictionary in rows:
		var creature_trait := GameData.get_trait(row["trait_id"])
		var line := ContentViewer.flow(6)
		if creature_trait != null:
			line.add_child(viewer.link(creature_trait.name, ContentViewer.TAB_TRAITS, creature_trait.id))
		else:
			line.add_child(ContentViewer.text("?"))
		if row.get("is_hidden", false):
			line.add_child(ContentViewer.text("(oculto)", 0, UiPalette.TEXT_MUTED))
		box.add_child(line)


func _biomes(species: CreatureSpecies, box: VBoxContainer) -> void:
	var rows: Array[Dictionary] = []
	for row: Dictionary in GameData.get_rows("species_biomes"):
		if row["species_id"] == species.id:
			rows.append(row)
	if rows.is_empty():
		box.add_child(ContentViewer.text("Não nasce no mapa.", 0, UiPalette.TEXT_SECONDARY))
		return
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["rate"]) > int(b["rate"]))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 18)
	grid.add_theme_constant_override(&"v_separation", 2)
	box.add_child(grid)
	for row: Dictionary in rows:
		var biome: Dictionary = GameData.get_row("biomes", row["biome_id"])
		var cell := HBoxContainer.new()
		cell.add_child(viewer.link(str(biome.get("name", "?")), ContentViewer.TAB_BIOMES, row["biome_id"]))
		grid.add_child(cell)
		grid.add_child(ContentViewer.text(str(row["rate"]), 0, UiPalette.TEXT_SECONDARY))


## As imagens paradas e o som numa linha, cada folha na sua, com todas as direções,
## e por último os tracejados das folhas que faltam.
func _files(species: CreatureSpecies, box: VBoxContainer) -> void:
	var images := ContentViewer.flow(14)
	box.add_child(images)
	var missing := ContentViewer.flow(14)
	for entry: ContentFiles.Entry in ContentFiles.creature_files(species.slug):
		if entry.kind == ContentFiles.Kind.IMAGE or entry.kind == ContentFiles.Kind.SOUND:
			images.add_child(FilePreview.create(entry))
		elif entry.exists():
			box.add_child(FilePreview.create_sheet(entry))
		else:
			missing.add_child(FilePreview.create(entry))
	if missing.get_child_count() > 0:
		box.add_child(missing)
