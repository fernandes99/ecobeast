class_name GeneralTab
extends ScrollContainer


var viewer: ContentViewer


func _init(content_viewer: ContentViewer) -> void:
	viewer = content_viewer
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	add_child(margin)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override(&"separation", 10)
	margin.add_child(box)

	var tamer := ContentViewer.block(box, "Domador")
	for entry: ContentFiles.Entry in ContentFiles.tamer_files():
		if entry.exists():
			tamer.add_child(FilePreview.create_sheet(entry))
		else:
			tamer.add_child(FilePreview.create(entry))
	var credits := _credits()
	if not credits.is_empty():
		tamer.add_child(ContentViewer.text("Créditos da arte", ContentViewer.SMALL_SIZE, UiPalette.ACCENT))
		tamer.add_child(ContentViewer.paragraph(credits))

	var sounds := ContentViewer.flow(14)
	for entry: ContentFiles.Entry in ContentFiles.hit_sounds():
		sounds.add_child(FilePreview.create(entry))
	ContentViewer.block(box, "Sons de dano").add_child(sounds)


func tab_title() -> String:
	return "Geral"


func _credits() -> String:
	if not FileAccess.file_exists(ContentFiles.TAMER_CREDITS_PATH):
		return ""
	var lines: Array[String] = []
	for line: String in FileAccess.get_file_as_string(ContentFiles.TAMER_CREDITS_PATH).split("\n"):
		var clean := line.strip_edges()
		if clean.is_empty() or clean.begins_with("#"):
			continue
		lines.append(clean.replace("`", ""))
	return "\n".join(lines)
