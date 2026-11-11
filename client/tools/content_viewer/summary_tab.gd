class_name SummaryTab
extends ScrollContainer

const CARD_WIDTH := 220
const NO_LEVEL := 999

var viewer: ContentViewer
var _box: VBoxContainer


func _init(content_viewer: ContentViewer) -> void:
	viewer = content_viewer
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_theme_constant_override(&"separation", 10)
	margin.add_child(_box)
	add_child(margin)
	if ContentViewer.has_catalog():
		_build()
	else:
		_build_offline()


func tab_title() -> String:
	return "Resumo"


func _build() -> void:
	var species := GameData.get_all_species()
	var total := species.size()
	var with_front := 0
	var with_board := 0
	var with_explore := 0
	var with_battle := 0
	var with_call := 0
	var incomplete: Array[Dictionary] = []
	for one: CreatureSpecies in species:
		var files := ContentFiles.creature_files(one.slug)
		var found: Array[bool] = []
		for entry: ContentFiles.Entry in files:
			found.append(entry.complete())
		with_front += int(found[0])
		with_board += int(found[1])
		with_explore += int(found[2] and found[3])
		with_battle += int(found[4] and found[5])
		with_call += int(found[6])
		var missing := ContentFiles.missing_labels(files)
		if not missing.is_empty():
			incomplete.append({"species": one, "missing": missing})

	var cards := ContentViewer.flow(10)
	_box.add_child(cards)
	_card(cards, "Ecobeasts no catálogo", str(total), UiPalette.TEXT)
	_count_card(cards, "Com front", with_front, total)
	_count_card(cards, "Com board", with_board, total)
	_count_card(cards, "Com as folhas de explorar", with_explore, total)
	_count_card(cards, "Com as folhas da luta", with_battle, total)
	_count_card(cards, "Com call", with_call, total)
	_starters_and_growth()

	var slugs: Array[String] = []
	for one: CreatureSpecies in species:
		slugs.append(one.slug)
	var orphans := ContentFiles.orphan_folders(ContentFiles.CREATURES_DIR, slugs)
	if not orphans.is_empty():
		var list := ContentViewer.block(_box, "Pastas de Ecobeast fora do catálogo")
		list.add_child(ContentViewer.paragraph(", ".join(orphans), UiPalette.WARNING))
		list.add_child(ContentViewer.text("Em %s/" % ContentFiles.CREATURES_DIR, ContentViewer.SMALL_SIZE, UiPalette.TEXT_MUTED))

	if not incomplete.is_empty():
		var list := ContentViewer.block(_box, "Ecobeasts aos quais falta algum arquivo")
		for item: Dictionary in incomplete:
			var one: CreatureSpecies = item["species"]
			var missing: Array[String] = item["missing"]
			var line := HBoxContainer.new()
			line.add_theme_constant_override(&"separation", 0)
			line.add_child(viewer.link(one.name, ContentViewer.TAB_SPECIES, one.id))
			line.add_child(ContentViewer.text(": " + ", ".join(missing), 0, UiPalette.TEXT_SECONDARY))
			list.add_child(line)

	_build_skills()
	_build_elements()
	_build_world()


func _build_skills() -> void:
	var skills := GameData.get_rows("skills")
	var total := skills.size()
	var with_file: Array[int] = [0, 0, 0]
	var with_projectile := 0
	var incomplete: Array[Dictionary] = []
	var first_level := _first_levels()
	for skill: Dictionary in skills:
		var files := ContentFiles.skill_files(skill["slug"])
		for i: int in files.size():
			with_file[i] += int(files[i].complete())
		with_projectile += int(ContentFiles.skill_optional_files(skill["slug"])[0].exists())
		var missing := ContentFiles.missing_labels(files)
		if not missing.is_empty():
			incomplete.append({"skill": skill, "missing": missing, "level": first_level.get(skill["id"], NO_LEVEL)})

	_section("Técnicas")
	var cards := ContentViewer.flow(10)
	_box.add_child(cards)
	_card(cards, "Técnicas no catálogo", str(total), UiPalette.TEXT)
	_count_card(cards, "Com ícone", with_file[0], total)
	_count_card(cards, "Com efeito", with_file[1], total)
	_count_card(cards, "Com som", with_file[2], total)
	_card(cards, "Com projétil (opcional)", "%d de %d" % [with_projectile, total], UiPalette.TEXT)

	if incomplete.is_empty():
		return
	incomplete.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["level"] != b["level"]:
			return a["level"] < b["level"]
		return int(a["skill"]["id"]) < int(b["skill"]["id"]))
	var list := ContentViewer.block(_box, "Técnicas que faltam arquivos (pelo nível em que aparecem)")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", 18)
	grid.add_theme_constant_override(&"v_separation", 2)
	list.add_child(grid)
	for item: Dictionary in incomplete:
		var level: int = item["level"]
		grid.add_child(ContentViewer.text("Nv %d" % level if level != NO_LEVEL else "ninguém aprende", 0, UiPalette.TEXT_SECONDARY))
		var skill: Dictionary = item["skill"]
		var cell := HBoxContainer.new()
		cell.add_child(viewer.link(skill["name"], ContentViewer.TAB_SKILLS, skill["id"]))
		grid.add_child(cell)
		var missing: Array[String] = item["missing"]
		grid.add_child(ContentViewer.text("falta " + ", ".join(missing), 0, UiPalette.WARNING))


func _first_levels() -> Dictionary:
	var levels: Dictionary = {}
	for row: Dictionary in GameData.get_rows("species_skills"):
		var level: int = int(row["level"]) if row.get("level") != null else NO_LEVEL
		levels[row["skill_id"]] = mini(levels.get(row["skill_id"], NO_LEVEL), level)
	return levels


func _build_elements() -> void:
	var used: Dictionary = {}
	for species: CreatureSpecies in GameData.get_all_species():
		for element_id: int in species.element_ids:
			used[element_id] = true
	var elements := GameData.get_elements()
	var without: Array[String] = []
	for element: Element in elements:
		if not used.has(element.id):
			without.append(element.name)
	_section("Elementos")
	var cards := ContentViewer.flow(10)
	_box.add_child(cards)
	var box := _count_card(cards, "Elementos com Ecobeast", elements.size() - without.size(), elements.size())
	if not without.is_empty():
		box.add_child(ContentViewer.paragraph("Sem nenhum: " + ", ".join(without), UiPalette.TEXT_SECONDARY))


func _build_world() -> void:
	var biomes := GameData.get_rows("biomes")
	var with_surface := 0
	var empty_biomes: Array[String] = []
	var spawned: Dictionary = {}
	for row: Dictionary in GameData.get_rows("species_biomes"):
		spawned[row["biome_id"]] = true
	for biome: Dictionary in biomes:
		with_surface += int(ContentFiles.biome_surface(biome["slug"]).exists())
		if not spawned.has(biome["id"]):
			empty_biomes.append(biome["name"])
	var items := GameData.get_rows("items")
	var with_icon := 0
	for item: Dictionary in items:
		with_icon += int(ContentFiles.item_icon(item["slug"]).exists())

	_section("Biomas e itens")
	var cards := ContentViewer.flow(10)
	_box.add_child(cards)
	var biome_card := _count_card(cards, "Biomas com superfície", with_surface, biomes.size())
	if not empty_biomes.is_empty():
		biome_card.add_child(ContentViewer.paragraph("Sem Ecobeast: " + ", ".join(empty_biomes), UiPalette.TEXT_SECONDARY))
	_count_card(cards, "Itens com ícone", with_icon, items.size())


func _starters_and_growth() -> void:
	var row := ContentViewer.flow(10)
	_box.add_child(row)
	var starters_box := ContentViewer.block(row, "Iniciais")
	var starters := GameData.get_rows("starter_options")
	starters.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["sort_order"]) < int(b["sort_order"]))
	var line := ContentViewer.flow(12)
	for starter: Dictionary in starters:
		var species := GameData.get_species(starter["species_id"])
		if species != null:
			line.add_child(viewer.link(species.name, ContentViewer.TAB_SPECIES, species.id))
	if line.get_child_count() == 0:
		line.add_child(ContentViewer.text(ContentViewer.EMPTY))
	starters_box.add_child(line)

	var growth_box := ContentViewer.block(row, "Curvas de XP")
	var users: Dictionary = {}
	for species: CreatureSpecies in GameData.get_all_species():
		users[species.growth_rate_id] = int(users.get(species.growth_rate_id, 0)) + 1
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", 18)
	grid.add_theme_constant_override(&"v_separation", 2)
	for growth: Dictionary in GameData.get_rows("growth_rates"):
		grid.add_child(ContentViewer.text(growth["name"]))
		grid.add_child(ContentViewer.text("×%s" % ContentViewer.decimal(float(growth["xp_multiplier"])), 0, UiPalette.TEXT_SECONDARY))
		var count := int(users.get(growth["id"], 0))
		grid.add_child(ContentViewer.text("%d %s" % [count, "Ecobeast" if count == 1 else "Ecobeasts"], 0, UiPalette.TEXT_SECONDARY))
	growth_box.add_child(grid)


func _section(title: String) -> void:
	var label := ContentViewer.text(title, ContentViewer.TITLE_SIZE)
	_box.add_child(label)


func _build_offline() -> void:
	var list := ContentViewer.block(_box, "Pastas de Ecobeast")
	var folders := ContentFiles.folders(ContentFiles.CREATURES_DIR)
	if folders.is_empty():
		list.add_child(ContentViewer.text("Nenhuma pasta em %s/." % ContentFiles.CREATURES_DIR, 0, UiPalette.TEXT_SECONDARY))
	for folder: String in folders:
		var files := ContentFiles.creature_files(folder)
		var done := ContentFiles.count_complete(files)
		var line := HBoxContainer.new()
		line.add_theme_constant_override(&"separation", 12)
		var name_label := ContentViewer.text(folder)
		name_label.custom_minimum_size.x = 160
		line.add_child(name_label)
		line.add_child(ContentViewer.text("%d/%d" % [done, files.size()], 0, ContentViewer.status_color(done, files.size())))
		list.add_child(line)


func _count_card(parent: Control, caption: String, done: int, total: int) -> VBoxContainer:
	return _card(parent, caption, "%d de %d" % [done, total], ContentViewer.status_color(done, total))


func _card(parent: Control, caption: String, value: String, color: Color) -> VBoxContainer:
	var box := ContentViewer.block(parent, caption)
	box.get_parent().custom_minimum_size.x = CARD_WIDTH
	box.add_child(ContentViewer.text(value, ContentViewer.NUMBER_SIZE, color))
	return box
