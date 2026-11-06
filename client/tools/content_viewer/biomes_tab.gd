class_name BiomesTab
extends ListDetail
## A aba Biomas (content-viewer/03, RF-01 a RF-03): a lista pelo `id`, com quantos
## Ecobeasts nascem em cada bioma, e o detalhe com os Ecobeasts, a superfície que o
## mapa desenha e as decorações que nascem nela, com todas as variantes. A última
## linha, Peças comuns, não é um bioma: são as peças que o mapa usa em todos.
##
## Colina e Montanha são biomas no catálogo, mas o gerador do mapa as trata como
## formas do terreno: a aba mostra o que encontra e não corrige isso.

## A linha de Peças comuns: nenhum bioma tem id 0.
const COMMON_ID := 0
const SURFACE_BOX := Vector2(160, 160)
const COMMON_BOX := Vector2(200, 200)
## A célula da decoração (48 × 64) ampliada 2×.
const DECORATION_BOX := Vector2(104, 136)


func _init(content_viewer: ContentViewer) -> void:
	super(content_viewer)
	var rows: Array[ListDetail.Row] = []
	for biome: Dictionary in GameData.get_rows("biomes"):
		var count := _spawns(biome["id"]).size()
		var row := ListDetail.Row.new(biome["id"], biome["name"])
		row.tail = str(count)
		row.tail_color = UiPalette.TEXT_SECONDARY if count > 0 else UiPalette.DANGER
		rows.append(row)
	var common := ListDetail.Row.new(COMMON_ID, "Peças comuns")
	common.tail = "todos"
	rows.append(common)
	set_rows(rows)


func tab_title() -> String:
	return "Biomas (%d)" % GameData.get_rows("biomes").size()


func _build_detail(id: int, box: VBoxContainer) -> void:
	if id == COMMON_ID:
		_common(box)
		return
	var biome: Dictionary = GameData.get_row("biomes", id)
	if biome.is_empty():
		return
	box.add_child(ContentViewer.text(biome["name"], ContentViewer.TITLE_SIZE))
	box.add_child(ContentViewer.paragraph(str(biome.get("description", ""))))
	box.add_child(ContentViewer.text("slug: %s" % biome["slug"], ContentViewer.SMALL_SIZE, UiPalette.TEXT_MUTED))

	var spawns_box := ContentViewer.block(box, "Ecobeasts que nascem aqui")
	var spawns := _spawns(id)
	if spawns.is_empty():
		spawns_box.add_child(ContentViewer.text("Nenhum Ecobeast nasce aqui.", 0, UiPalette.TEXT_SECONDARY))
	else:
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override(&"h_separation", 18)
		grid.add_theme_constant_override(&"v_separation", 2)
		for row: Dictionary in spawns:
			var species := GameData.get_species(row["species_id"])
			if species == null:
				continue
			var cell := HBoxContainer.new()
			cell.add_child(viewer.link(species.name, ContentViewer.TAB_SPECIES, species.id))
			grid.add_child(cell)
			grid.add_child(ContentViewer.text(str(row["rate"]), 0, UiPalette.TEXT_SECONDARY))
		spawns_box.add_child(grid)

	ContentViewer.block(box, "Superfície").add_child(FilePreview.create(ContentFiles.biome_surface(biome["slug"]), SURFACE_BOX))
	_decorations(ContentFiles.surface_name(biome["slug"]), ContentViewer.block(box, "Decorações"))


## As decorações que o mapa sorteia na superfície (HexDecorations.RECIPES), da maior
## para a menor: a chance de aparecer num hexágono, quantas, e as variantes.
func _decorations(surface: String, box: VBoxContainer) -> void:
	var recipe: Array = HexDecorations.RECIPES.get(surface, [])
	if recipe.is_empty():
		box.add_child(ContentViewer.text("Nenhuma decoração.", 0, UiPalette.TEXT_SECONDARY))
		return
	var sheet := ContentFiles.decorations_sheet()
	if not sheet.exists():
		box.add_child(FilePreview.create(sheet))
		return
	for entry: Array in recipe:
		var kind: String = entry[0]
		var amount := "%d" % entry[2] if entry[2] == entry[3] else "%d a %d" % [entry[2], entry[3]]
		var facts := "%d%% dos hexágonos · %s por hexágono" % [roundi(float(entry[1]) * 100.0), amount]
		if HexDecorations.KIND_SWAY.has(kind):
			facts += " · balança com o vento"
		var title := ContentViewer.flow(10)
		title.add_child(ContentViewer.text(ContentFiles.DECORATION_NAMES.get(kind, kind)))
		title.add_child(ContentViewer.text(facts, ContentViewer.SMALL_SIZE, UiPalette.TEXT_SECONDARY))
		box.add_child(title)
		var variants := ContentViewer.flow(10)
		for column: int in HexDecorations.VARIANTS:
			variants.add_child(FilePreview.create_cell(sheet, HexDecorations.CELL_SIZE, HexDecorations.KIND_ROWS[kind], column, "variante %d" % (column + 1), DECORATION_BOX))
		box.add_child(variants)


## As linhas de `species_biomes` do bioma, da maior taxa para a menor.
func _spawns(biome_id: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for row: Dictionary in GameData.get_rows("species_biomes"):
		if row["biome_id"] == biome_id:
			rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["rate"]) > int(b["rate"]))
	return rows


func _common(box: VBoxContainer) -> void:
	box.add_child(ContentViewer.text("Peças comuns", ContentViewer.TITLE_SIZE))
	box.add_child(ContentViewer.paragraph("As peças que o mapa usa em todos os biomas: as bordas, o contorno, o destaque e as transições entre biomas. As superfícies e as decorações ficam em cada bioma."))
	var row := ContentViewer.flow(14)
	for entry: ContentFiles.Entry in ContentFiles.common_pieces():
		row.add_child(FilePreview.create(entry, COMMON_BOX))
	ContentViewer.block(box, "Arquivos").add_child(row)
