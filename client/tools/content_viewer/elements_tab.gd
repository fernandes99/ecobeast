class_name ElementsTab
extends ListDetail
## A aba Elementos (content-viewer/02, RF-04 a RF-06): a lista pelo `id`, com quantos
## Ecobeasts têm o Elemento, o detalhe com as forças e as fraquezas, e a tabela de
## efetividade de todos contra todos, aberta pelo botão acima da lista.
##
## Os multiplicadores vêm só de `element_efficacy`: o par que não está lá vale 1.

const STRONG := 2.0
const WEAK := 0.5
const IMMUNE := 0.0
const CELL_SIZE := Vector2(44, 28)
## Quatro letras separam Instinto (Inst) de Inseto (Inse).
const HEADER_CHARS := 4
const STRONG_FILL := Color("#2E7D32")
const WEAK_FILL := Color("#8E2A2A")
const IMMUNE_FILL := Color("#3B4656")
## Acima desta luminância, a cor do Elemento é clara demais para texto branco.
const LIGHT_LUMINANCE := 0.6

var _efficacy: Array[Dictionary] = []


func _init(content_viewer: ContentViewer) -> void:
	super(content_viewer)
	_efficacy = GameData.get_rows("element_efficacy")
	var table_button := Button.new()
	table_button.text = "Tabela de efetividade"
	table_button.pressed.connect(show_custom.bind(_build_table))
	add_list_header(table_button)
	var rows: Array[ListDetail.Row] = []
	for element: Element in GameData.get_elements():
		var count := _species_with(element.id).size()
		var row := ListDetail.Row.new(element.id, element.name + (" · raro" if element.is_rare else ""))
		row.dot = element.color
		row.tail = str(count)
		row.tail_color = UiPalette.TEXT_SECONDARY if count > 0 else UiPalette.DANGER
		rows.append(row)
	set_rows(rows)


func tab_title() -> String:
	return "Elementos (%d)" % GameData.get_elements().size()


func _build_detail(id: int, box: VBoxContainer) -> void:
	var element := GameData.get_element(id)
	if element == null:
		return
	var header := ContentViewer.flow(12)
	header.add_child(_color_chip(element, element.name, ContentViewer.TITLE_SIZE))
	header.add_child(ContentViewer.text("#%s%s" % [element.color.to_html(false).to_upper(), " · raro" if element.is_rare else ""], 0, UiPalette.TEXT_SECONDARY))
	box.add_child(header)

	var attack := ContentViewer.block(box, "Atacando")
	_relation(attack, "Forte contra", _against(id, STRONG, true))
	_relation(attack, "Fraco contra", _against(id, WEAK, true))
	_relation(attack, "Não afeta", _against(id, IMMUNE, true))
	var defense := ContentViewer.block(box, "Defendendo")
	_relation(defense, "Sofre mais de", _against(id, STRONG, false))
	_relation(defense, "Resiste a", _against(id, WEAK, false))
	_relation(defense, "Imune a", _against(id, IMMUNE, false))

	var statuses: Array[String] = []
	for row: Dictionary in GameData.get_rows("status_condition_immunities"):
		if row["element_id"] == id:
			statuses.append(ContentViewer.row_name("status_conditions", row["status_condition_id"]))
	ContentViewer.block(box, "Imunidades a Estados").add_child(ContentViewer.text(ContentViewer.EMPTY if statuses.is_empty() else ", ".join(statuses)))

	var species_box := ContentViewer.block(box, "Ecobeasts")
	var species := _species_with(id)
	if species.is_empty():
		species_box.add_child(ContentViewer.text("Nenhum Ecobeast deste Elemento.", 0, UiPalette.TEXT_SECONDARY))
	else:
		var line := ContentViewer.flow(12)
		for one: CreatureSpecies in species:
			line.add_child(viewer.link(one.name, ContentViewer.TAB_SPECIES, one.id))
		species_box.add_child(line)

	var skills_box := ContentViewer.block(box, "Técnicas")
	var skills: Array[Dictionary] = []
	for row: Dictionary in GameData.get_rows("skills"):
		if row["element_id"] == id:
			skills.append(row)
	if skills.is_empty():
		skills_box.add_child(ContentViewer.text("Nenhuma Técnica deste Elemento.", 0, UiPalette.TEXT_SECONDARY))
	else:
		var line := ContentViewer.flow(12)
		for row: Dictionary in skills:
			line.add_child(viewer.link(row["name"], ContentViewer.TAB_SKILLS, row["id"]))
		skills_box.add_child(line)


## Os Elementos com aquele multiplicador: atacando (`id` ataca) ou defendendo.
func _against(id: int, multiplier: float, attacking: bool) -> Array[int]:
	var ids: Array[int] = []
	for row: Dictionary in _efficacy:
		var mine: int = row["attacker_element_id"] if attacking else row["defender_element_id"]
		var other: int = row["defender_element_id"] if attacking else row["attacker_element_id"]
		if mine == id and is_equal_approx(float(row["multiplier"]), multiplier):
			ids.append(other)
	ids.sort()
	return ids


func _relation(box: VBoxContainer, caption: String, ids: Array[int]) -> void:
	var line := ContentViewer.flow(6)
	var label := ContentViewer.text(caption, 0, UiPalette.TEXT_SECONDARY)
	label.custom_minimum_size.x = 130
	line.add_child(label)
	if ids.is_empty():
		line.add_child(ContentViewer.text(ContentViewer.EMPTY))
	for other: int in ids:
		line.add_child(viewer.element_link(other))
	box.add_child(line)


func _species_with(element_id: int) -> Array[CreatureSpecies]:
	var found: Array[CreatureSpecies] = []
	for species: CreatureSpecies in GameData.get_all_species():
		if element_id in species.element_ids:
			found.append(species)
	return found


# --- A tabela de efetividade -----------------------------------------------------

## O ataque nas linhas e a defesa nas colunas; só os multiplicadores diferentes de 1.
func _build_table(box: VBoxContainer) -> void:
	box.add_child(ContentViewer.text("Tabela de efetividade", ContentViewer.TITLE_SIZE))
	box.add_child(ContentViewer.text("Linha: quem ataca. Coluna: quem defende. Vazio vale 1. Clique num Elemento para abri-lo.", 0, UiPalette.TEXT_SECONDARY))
	var elements := GameData.get_elements()
	var multipliers: Dictionary = {}
	for row: Dictionary in _efficacy:
		multipliers[Vector2i(row["attacker_element_id"], row["defender_element_id"])] = float(row["multiplier"])
	var grid := GridContainer.new()
	grid.columns = elements.size() + 1
	grid.add_theme_constant_override(&"h_separation", 2)
	grid.add_theme_constant_override(&"v_separation", 2)
	grid.add_child(Control.new())
	for defender: Element in elements:
		grid.add_child(_header_button(defender, defender.name.left(HEADER_CHARS), CELL_SIZE.x))
	for attacker: Element in elements:
		grid.add_child(_header_button(attacker, attacker.name, 0.0))
		for defender: Element in elements:
			var key := Vector2i(attacker.id, defender.id)
			grid.add_child(_cell(multipliers.get(key, 1.0)))
	box.add_child(grid)


func _header_button(element: Element, label: String, width: float) -> Button:
	var button := Button.new()
	button.text = label
	button.tooltip_text = element.name
	button.custom_minimum_size = Vector2(width, CELL_SIZE.y)
	button.add_theme_font_size_override(&"font_size", ContentViewer.SMALL_SIZE)
	var style := StyleBoxFlat.new()
	style.bg_color = element.color
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"focus"]:
		button.add_theme_stylebox_override(state, style)
	var text_color := UiPalette.BACKGROUND if element.color.get_luminance() > LIGHT_LUMINANCE else UiPalette.TEXT
	for color_name: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
		button.add_theme_color_override(color_name, text_color)
	button.pressed.connect(select.bind(element.id))
	return button


func _cell(multiplier: float) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = CELL_SIZE
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(3)
	var label := ""
	if is_equal_approx(multiplier, STRONG):
		style.bg_color = STRONG_FILL
		label = "2"
	elif is_equal_approx(multiplier, WEAK):
		style.bg_color = WEAK_FILL
		label = "½"
	elif is_equal_approx(multiplier, IMMUNE):
		style.bg_color = IMMUNE_FILL
		label = "0"
	else:
		style.bg_color = Color(1, 1, 1, 0.04)
		if not is_equal_approx(multiplier, 1.0):
			style.bg_color = IMMUNE_FILL
			label = ContentViewer.decimal(multiplier)
	cell.add_theme_stylebox_override(&"panel", style)
	var text := ContentViewer.text(label, ContentViewer.SMALL_SIZE)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(text)
	return cell


func _color_chip(element: Element, label: String, font_size: int) -> PanelContainer:
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = element.color
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	chip.add_theme_stylebox_override(&"panel", style)
	var text_color := UiPalette.BACKGROUND if element.color.get_luminance() > LIGHT_LUMINANCE else UiPalette.TEXT
	chip.add_child(ContentViewer.text(label, font_size, text_color))
	return chip
