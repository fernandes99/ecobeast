class_name EditorTools
extends VBoxContainer
## Os pincéis do editor de ilhas (map-editor/03 e 04): o painel com as
## ferramentas, o bioma, a forma, as construções, as áreas e o tamanho, e o que
## cada pincelada muda no rascunho. Uma pincelada vai do apertar ao soltar do
## botão e vira um passo do desfazer (`EditorHistory.Step`). O botão direito faz a
## ação secundária: escolher uma construção, ou tirar hexágonos de uma área.

## Algo para a barra de cima, como o limite de hexágonos.
signal message(text: String)
## A ferramenta ou o tamanho mudou: o contorno do pincel muda junto.
signal brush_changed
## Os painéis de construção e de área mudaram o rascunho, fora de uma pincelada.
signal edited(step: EditorHistory.Step, merge: bool)

enum Tool { BIOME, SHAPE, ADD, REMOVE, START, BUILDING, AREA }

const TOOL_NAMES: Array[String] = ["Bioma", "Forma", "Pôr hexágono", "Tirar hexágono", "Chegada", "Construção", "Área"]
## O que cada ferramenta faz, embaixo dos botões.
const TOOL_HINTS: Array[String] = [
	"Troca o bioma dos hexágonos que já existem.",
	"Troca a forma dos hexágonos que já existem: plano, colina ou montanha.",
	"Cria hexágonos onde não há, com o bioma e a forma escolhidos abaixo.",
	"Apaga hexágonos. A chegada nunca sai.",
	"Move a chegada (a bandeira) para o hexágono clicado.",
	"Pinta uma construção nova, ou aumenta a escolhida. Botão direito escolhe uma construção.",
	"Pinta a área escolhida. Botão direito tira os hexágonos de qualquer área.",
]
const NO_AREA_MESSAGE := "Crie ou escolha uma área no painel antes de pintar."
## Os biomas de terreno, na ordem do painel; o nome vem do catálogo.
const BIOMES: Array[String] = ["temperate", "boreal", "stone", "wshallow", "wdeep"]
const SHAPES: Array[String] = ["flat", "hill", "mont"]
const SHAPE_NAMES: Dictionary[String, String] = {"flat": "Plano", "hill": "Colina", "mont": "Montanha"}
## A altura de cada forma na amostra, como `HexTile.level()` (o plano fica na
## altura do bioma).
const SHAPE_LEVELS: Dictionary[String, int] = {"hill": 2, "mont": 4}
const MAX_RADIUS := 10
const SWATCH_WIDTH := 64.0
const SWATCH_COLUMNS := 5
const TITLE_SIZE := 13
## Os nomes de reserva, se o catálogo não tiver o bioma.
const BIOME_NAMES: Dictionary[String, String] = {
	"temperate": "Planície",
	"boreal": "Boreal",
	"stone": "Pedra",
	"wshallow": "Água rasa",
	"wdeep": "Água profunda",
}
const FULL_MESSAGE := "A ilha chegou a 20.000 hexágonos."

var tool := Tool.BIOME
var biome := "temperate"
var shape := "flat"
## 0 é um hexágono só.
var radius := 0
## A chance de detalhe do gerador, para sortear a variante como ele.
var detail_chance := 0.0

var _tool_buttons: Array[Button] = []
var _tool_hint: Label
var _biome_buttons: Dictionary[String, TerrainSwatch] = {}
var _shape_buttons: Dictionary[String, TerrainSwatch] = {}
var _radius_value: Label
var _radius_slider: HSlider
var _rng := RandomNumberGenerator.new()
var _terrain_sections: Array[Control] = []
var _brush_section: Control
var _building_section: Control
var _area_section: Control
var building_panel: BuildingPanel
var area_panel: AreaPanel

## A pincelada em andamento.
var _step: EditorHistory.Step = null
var _full_warned := false
var _secondary := false
## A construção que a pincelada pinta ou tira; -2 até o primeiro hexágono.
var _stroke_building := -2


func _init() -> void:
	add_theme_constant_override(&"separation", 10)

	var tools_box := _section("Ferramenta  ·  teclas 1 a 7")
	var tools_group := ButtonGroup.new()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 6)
	grid.add_theme_constant_override(&"v_separation", 6)
	tools_box.add_child(grid)
	for index: int in TOOL_NAMES.size():
		var button := tool_button("%d   %s" % [index + 1, TOOL_NAMES[index]], tools_group)
		button.tooltip_text = TOOL_HINTS[index]
		button.pressed.connect(set_tool.bind(index))
		grid.add_child(button)
		_tool_buttons.append(button)
	_tool_hint = Label.new()
	_tool_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tool_hint.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	_tool_hint.add_theme_font_size_override(&"font_size", 14)
	tools_box.add_child(_tool_hint)

	var biomes_box := _section("Bioma")
	_terrain_sections.append(biomes_box.get_parent())
	var biomes_grid := _swatch_grid(biomes_box)
	var biome_group := ButtonGroup.new()
	for slug: String in BIOMES:
		var swatch := _swatch(biome_group)
		swatch.set_terrain(slug, _biome_name(slug), _flat_level(slug))
		swatch.pressed.connect(_pick_biome.bind(slug))
		biomes_grid.add_child(swatch)
		_biome_buttons[slug] = swatch

	var shapes_box := _section("Forma")
	_terrain_sections.append(shapes_box.get_parent())
	var shapes_grid := _swatch_grid(shapes_box)
	var shape_group := ButtonGroup.new()
	for slug: String in SHAPES:
		var swatch := _swatch(shape_group)
		swatch.pressed.connect(_pick_shape.bind(slug))
		shapes_grid.add_child(swatch)
		_shape_buttons[slug] = swatch

	var buildings_box := _section("Construção")
	_building_section = buildings_box.get_parent()
	building_panel = BuildingPanel.new()
	building_panel.edited.connect(func(step: EditorHistory.Step) -> void: edited.emit(step, false))
	buildings_box.add_child(building_panel)
	var areas_box := _section("Área de Ecobeasts")
	_area_section = areas_box.get_parent()
	area_panel = AreaPanel.new()
	area_panel.edited.connect(func(step: EditorHistory.Step, merge: bool) -> void: edited.emit(step, merge))
	areas_box.add_child(area_panel)

	var brush_box := _section("Pincel  ·  teclas [ e ]")
	_brush_section = brush_box.get_parent()
	var brush_row := HBoxContainer.new()
	brush_box.add_child(brush_row)
	var brush_label := Label.new()
	brush_label.text = "Tamanho"
	brush_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brush_row.add_child(brush_label)
	_radius_value = Label.new()
	_radius_value.theme_type_variation = &"BoldLabel"
	brush_row.add_child(_radius_value)
	_radius_slider = HSlider.new()
	_radius_slider.min_value = 0
	_radius_slider.max_value = MAX_RADIUS
	_radius_slider.step = 1
	_radius_slider.tick_count = MAX_RADIUS + 1
	_radius_slider.ticks_on_borders = true
	_radius_slider.focus_mode = Control.FOCUS_NONE
	_radius_slider.value_changed.connect(func(value: float) -> void: set_radius(int(value)))
	brush_box.add_child(_radius_slider)
	_refresh()


func set_tool(value: int) -> void:
	tool = value as Tool
	_refresh()
	brush_changed.emit()


func set_radius(value: int) -> void:
	radius = clampi(value, 0, MAX_RADIUS)
	_refresh()
	brush_changed.emit()


## O raio do contorno: a chegada pega um hexágono só, qualquer que seja o tamanho.
func brush_radius() -> int:
	return 0 if tool == Tool.START else radius


## Os hexágonos que o pincel pega em volta de `center`, existam ou não.
func brush_coords(center: Vector2i) -> Array[Vector2i]:
	var reach := brush_radius()
	var coords: Array[Vector2i] = []
	for q: int in range(-reach, reach + 1):
		for r: int in range(maxi(-reach, -q - reach), mini(reach, -q + reach) + 1):
			coords.append(center + Vector2i(q, r))
	return coords


## A ilha aberta, para os painéis de construção e de área.
func set_draft(draft: IslandDraft) -> void:
	building_panel.set_draft(draft)
	area_panel.set_draft(draft)


## As construções e as áreas mudaram por fora (desfazer, refazer): os painéis
## mostram o rascunho de novo.
func refresh_panels() -> void:
	building_panel.refresh()
	area_panel.refresh()


## A construção e a área mudam a camada de cor, e não o terreno.
func paints_marks() -> bool:
	return tool == Tool.BUILDING or tool == Tool.AREA


func begin_stroke(draft: IslandDraft, secondary: bool = false) -> void:
	_step = EditorHistory.Step.new()
	_step.label = TOOL_NAMES[tool]
	_full_warned = false
	_secondary = secondary
	_stroke_building = -2
	if draft.buildings.size() > 0 or tool == Tool.BUILDING:
		_step.buildings_before = draft.buildings.duplicate(true)


## Pinta em volta de `center` e devolve os hexágonos que mudaram.
func paint(draft: IslandDraft, center: Vector2i) -> Array[Vector2i]:
	if _step == null:
		begin_stroke(draft)
	var changed: Array[Vector2i] = []
	if tool == Tool.BUILDING:
		return _paint_building(draft, center)
	if _secondary and tool != Tool.AREA:
		return changed
	if tool == Tool.START:
		if draft.tiles.has(center) and draft.start != center:
			if _step.start_before == null:
				_step.start_before = draft.start
			changed.append(draft.start)
			draft.start = center
			_step.start_after = center
			changed.append(center)
		return changed
	for coord: Vector2i in brush_coords(center):
		var before := draft.snapshot(coord)
		if not _change(draft, coord):
			continue
		if not _step.before.has(coord):
			_step.before[coord] = before
		_step.after[coord] = draft.snapshot(coord)
		changed.append(coord)
	return changed


## Fecha a pincelada: o passo do desfazer, ou null se nada mudou.
func end_stroke(draft: IslandDraft) -> EditorHistory.Step:
	var step := _step
	_step = null
	if step == null:
		return null
	if tool == Tool.BUILDING:
		for index: int in range(draft.buildings.size() - 1, -1, -1):
			if (draft.buildings[index]["tiles"] as Array).is_empty():
				draft.buildings.remove_at(index)
		building_panel.refresh()
	elif tool == Tool.AREA:
		area_panel.refresh()
	if step.buildings_before != null and step.buildings_before != draft.buildings:
		step.buildings_after = draft.buildings.duplicate(true)
	else:
		step.buildings_before = null
	if step.start_after == step.start_before:
		step.start_before = null
		step.start_after = null
	# Um hexágono que voltou ao que era na mesma pincelada não conta.
	for coord: Vector2i in step.after.keys():
		if step.after[coord] == step.before[coord]:
			step.after.erase(coord)
			step.before.erase(coord)
	return null if step.is_empty() else step


## Um hexágono sob o pincel; devolve se mudou.
func _change(draft: IslandDraft, coord: Vector2i) -> bool:
	var tile: HexTile = draft.tiles.get(coord)
	match tool:
		Tool.BIOME:
			if tile == null or tile.biome == biome:
				return false
			tile.biome = biome
			return true
		Tool.SHAPE:
			if tile == null or tile.shape == shape:
				return false
			tile.shape = shape
			tile.variant = IslandDraft.roll_variant(shape, detail_chance, _rng)
			return true
		Tool.ADD:
			if tile != null:
				return false
			if draft.tiles.size() >= IslandDraft.MAX_TILES:
				if not _full_warned:
					_full_warned = true
					message.emit(FULL_MESSAGE)
				return false
			return draft.add_tile(coord, biome, shape, IslandDraft.roll_variant(shape, detail_chance, _rng))
		Tool.REMOVE:
			if tile == null or coord == draft.start:
				return false
			draft.remove_tile(coord)
			return true
		Tool.AREA:
			if tile == null:
				return false
			if _secondary:
				return draft.tile_areas.erase(coord)
			var key := area_panel.selected_key
			if key == 0:
				if not _full_warned:
					_full_warned = true
					message.emit(NO_AREA_MESSAGE)
				return false
			if draft.tile_areas.get(coord, 0) == key:
				return false
			draft.tile_areas[coord] = key
			return true
	return false


## A construção: o botão direito escolhe; o esquerdo cria uma nova num hexágono
## livre, ou aumenta a construção de onde a pincelada começou. Com "Tirar
## hexágonos", o pincel tira só da construção escolhida.
func _paint_building(draft: IslandDraft, center: Vector2i) -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	if _secondary:
		if _stroke_building == -2:
			_stroke_building = -1
			building_panel.select(draft.building_at(center))
		return changed
	if _stroke_building == -2:
		_stroke_building = _stroke_target(draft, center)
	var target := _stroke_building
	if target < 0 or target >= draft.buildings.size():
		return changed
	var occupied: Array = draft.buildings[target]["tiles"]
	for coord: Vector2i in brush_coords(center):
		if not draft.tiles.has(coord):
			continue
		var holder := draft.building_at(coord)
		if building_panel.removing:
			if holder != target:
				continue
			for spot: int in range(occupied.size() - 1, -1, -1):
				if int(occupied[spot]["q"]) == coord.x and int(occupied[spot]["r"]) == coord.y:
					occupied.remove_at(spot)
			changed.append(coord)
		elif holder == -1:
			occupied.append({"q": coord.x, "r": coord.y})
			changed.append(coord)
	if building_panel.removing and occupied.is_empty():
		draft.buildings.remove_at(target)
		_stroke_building = -1
		building_panel.select(-1)
	return changed


## Onde a pincelada de construção começa: na escolhida, tirando; numa construção,
## aumentando-a; num hexágono livre, uma construção nova.
func _stroke_target(draft: IslandDraft, center: Vector2i) -> int:
	if building_panel.removing:
		return building_panel.selected
	if not draft.tiles.has(center):
		return -1
	var holder := draft.building_at(center)
	if holder >= 0:
		building_panel.select(holder)
		return holder
	draft.buildings.append({"building_type_id": building_panel.type_id, "tiles": []})
	building_panel.select(draft.buildings.size() - 1)
	return draft.buildings.size() - 1


func _pick_biome(slug: String) -> void:
	biome = slug
	if tool != Tool.ADD:
		set_tool(Tool.BIOME)


func _pick_shape(slug: String) -> void:
	shape = slug
	if tool != Tool.ADD:
		set_tool(Tool.SHAPE)


func _refresh() -> void:
	for index: int in _tool_buttons.size():
		_tool_buttons[index].set_pressed_no_signal(index == tool)
	_tool_hint.text = TOOL_HINTS[tool]
	var terrain := tool == Tool.BIOME or tool == Tool.SHAPE or tool == Tool.ADD
	for section: Control in _terrain_sections:
		section.visible = terrain
	_building_section.visible = tool == Tool.BUILDING
	_area_section.visible = tool == Tool.AREA
	_brush_section.visible = tool != Tool.START
	for slug: String in _biome_buttons:
		_biome_buttons[slug].set_pressed_no_signal(slug == biome)
		_biome_buttons[slug].queue_redraw()
	for slug: String in _shape_buttons:
		var level: int = SHAPE_LEVELS.get(slug, _flat_level(biome))
		var surface := biome if slug == "flat" else slug
		_shape_buttons[slug].set_terrain(surface, SHAPE_NAMES[slug], level)
		_shape_buttons[slug].set_pressed_no_signal(slug == shape)
	_radius_slider.set_value_no_signal(radius)
	_radius_value.text = "1 hexágono" if radius == 0 else "raio %d  ·  %d hexágonos" % [radius, 3 * radius * (radius + 1) + 1]


## O plano de um bioma: a água fica embaixo, a pedra mais alta, como no jogo.
static func _flat_level(slug: String) -> int:
	var tile := HexTile.new()
	tile.biome = slug
	tile.shape = "flat"
	return tile.level()


func _biome_name(slug: String) -> String:
	for row: Dictionary in GameData.get_rows("biomes"):
		if row.get("slug") == slug:
			return str(row.get("name", slug))
	return BIOME_NAMES.get(slug, slug)


## Um bloco do painel, com o título pequeno em cima; devolve onde pôr o conteúdo.
func _section(title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"SectionPanel"
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 8)
	panel.add_child(box)
	var label := Label.new()
	label.text = title
	section_title(label)
	box.add_child(label)
	return box


## O título pequeno de um bloco do painel, também usado pela lista de ilhas.
static func section_title(label: Label) -> void:
	label.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	label.add_theme_font_size_override(&"font_size", TITLE_SIZE)


func _swatch_grid(parent: Control) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = SWATCH_COLUMNS
	grid.add_theme_constant_override(&"h_separation", 4)
	grid.add_theme_constant_override(&"v_separation", 4)
	parent.add_child(grid)
	return grid


func _swatch(group: ButtonGroup) -> TerrainSwatch:
	var swatch := TerrainSwatch.new()
	swatch.button_group = group
	swatch.custom_minimum_size.x = SWATCH_WIDTH
	return swatch


## Um botão de ferramenta: escuro, e azul com borda clara quando escolhido. Sem
## grupo, ele liga e desliga sozinho.
static func tool_button(text: String, group: ButtonGroup) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_group = group
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := _tool_style(UiPalette.SURFACE_RAISED, UiPalette.BORDER, 1)
	var hover := _tool_style(UiPalette.BORDER, UiPalette.BORDER, 1)
	var chosen := _tool_style(UiPalette.PRIMARY, UiPalette.ACCENT, 2)
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"pressed", chosen)
	button.add_theme_stylebox_override(&"hover_pressed", chosen)
	button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	button.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	button.add_theme_color_override(&"font_hover_color", UiPalette.TEXT)
	button.add_theme_color_override(&"font_pressed_color", UiPalette.TEXT)
	button.add_theme_color_override(&"font_hover_pressed_color", UiPalette.TEXT)
	return button


static func _tool_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style
