class_name TraitsTab
extends ListDetail


func _init(content_viewer: ContentViewer) -> void:
	super(content_viewer)
	var rows: Array[ListDetail.Row] = []
	for creature_trait: Dictionary in GameData.get_rows("traits"):
		var count := _holders(creature_trait["id"]).size()
		var row := ListDetail.Row.new(creature_trait["id"], creature_trait["name"])
		row.tail = str(count)
		row.tail_color = UiPalette.TEXT_SECONDARY if count > 0 else UiPalette.DANGER
		rows.append(row)
	set_rows(rows)


func tab_title() -> String:
	return "Traços (%d)" % GameData.get_rows("traits").size()


func _build_detail(id: int, box: VBoxContainer) -> void:
	var creature_trait: Dictionary = GameData.get_row("traits", id)
	if creature_trait.is_empty():
		return
	box.add_child(ContentViewer.text(creature_trait["name"], ContentViewer.TITLE_SIZE))
	box.add_child(ContentViewer.paragraph(str(creature_trait.get("description", ""))))
	var holders_box := ContentViewer.block(box, "Ecobeasts com este Traço")
	var holders := _holders(id)
	if holders.is_empty():
		holders_box.add_child(ContentViewer.text("Nenhum Ecobeast tem este Traço.", 0, UiPalette.TEXT_SECONDARY))
		return
	for row: Dictionary in holders:
		var species := GameData.get_species(row["species_id"])
		if species == null:
			continue
		var line := ContentViewer.flow(6)
		line.add_child(viewer.link(species.name, ContentViewer.TAB_SPECIES, species.id))
		if row.get("is_hidden", false):
			line.add_child(ContentViewer.text("(oculto)", 0, UiPalette.TEXT_MUTED))
		holders_box.add_child(line)


func _holders(trait_id: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for row: Dictionary in GameData.get_rows("species_traits"):
		if row["trait_id"] == trait_id:
			rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["species_id"]) < int(b["species_id"]))
	return rows
