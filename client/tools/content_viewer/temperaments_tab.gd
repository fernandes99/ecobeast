class_name TemperamentsTab
extends ScrollContainer
## A aba Temperamentos (content-viewer/03, RF-06): uma tabela só, sem detalhe. Cada
## Temperamento aumenta um stat em 10% e diminui outro em 10%; os neutros aumentam e
## diminuem o mesmo, e não mudam nada.

const NEUTRAL := "neutro"

var viewer: ContentViewer


func _init(content_viewer: ContentViewer) -> void:
	viewer = content_viewer
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	add_child(margin)
	var box := ContentViewer.block(margin, "Temperamentos: +10% em um stat e −10% em outro")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"h_separation", 40)
	grid.add_theme_constant_override(&"v_separation", 4)
	box.add_child(grid)
	for header: String in ["Temperamento", "Aumenta (+10%)", "Diminui (−10%)"]:
		grid.add_child(ContentViewer.text(header, ContentViewer.SMALL_SIZE, UiPalette.ACCENT))
	for row: Dictionary in GameData.get_rows("temperaments"):
		var neutral: bool = row["increased_stat_id"] == row["decreased_stat_id"]
		grid.add_child(ContentViewer.text(row["name"]))
		if neutral:
			grid.add_child(ContentViewer.text(NEUTRAL, 0, UiPalette.TEXT_MUTED))
			grid.add_child(ContentViewer.text(NEUTRAL, 0, UiPalette.TEXT_MUTED))
		else:
			grid.add_child(ContentViewer.text(ContentViewer.row_name("stats", row["increased_stat_id"]), 0, UiPalette.HP_HIGH))
			grid.add_child(ContentViewer.text(ContentViewer.row_name("stats", row["decreased_stat_id"]), 0, UiPalette.DANGER))


func tab_title() -> String:
	return "Temperamentos (%d)" % GameData.get_rows("temperaments").size()
