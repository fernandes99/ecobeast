class_name EditorTools
extends VBoxContainer

signal message(text: String)
signal brush_changed
signal edited(step: EditorHistory.Step, merge: bool)

enum Tool { BIOME, HEIGHT, GROUND, ADD, REMOVE, START, OBJECT, ACTION, AREA, STAMP, ERASER, PATH }

const TOOL_NAMES: Array[String] = ["Bioma", "Altura", "Chão", "Pôr hexágono", "Tirar hexágono", "Chegada", "Peças", "Ação", "Área", "Carimbo", "Borracha", "Caminho"]
const TOOL_ICONS: Array[String] = ["biome", "height", "ground", "hex_add", "hex_remove", "flag", "object", "action", "area", "stamp", "eraser", "path"]
const TOOL_HINTS: Array[String] = [
	"Troca o bioma dos hexágonos que já existem. A altura só muda se você escolher uma abaixo.",
	"Troca só a altura dos hexágonos que já existem.",
	"Pinta trilhas e pisos sobre o terreno. Sem chão apaga.",
	"Cria hexágonos onde não há, com o bioma e a altura escolhidos abaixo.",
	"Apaga hexágonos. A chegada nunca sai.",
	"Move a chegada (a bandeira) para o hexágono clicado.",
	"Põe peças: as de grade num hexágono, as soltas no ponto do clique. Botão direito escolhe uma posta; arrastar a escolhida a move.",
	"Pinta uma ação nova, ou aumenta a escolhida. Botão direito escolhe uma ação.",
	"Pinta a área escolhida. Botão direito tira os hexágonos de qualquer área.",
	"Põe um carimbo, com o apoio no hexágono clicado, ou escolhe uma área e a guarda como carimbo.",
	"Apaga as decorações naturais e as peças soltas dos hexágonos. Botão direito devolve as decorações naturais.",
	"Arraste para desenhar um caminho. Clique num caminho para escolher, trocar ou apagar.",
]
## Os grupos da coluna (map-editor/06): as ferramentas parecidas viram abas do grupo.
const GROUPS: Array[Dictionary] = [
	{"name": "Terreno", "icon": "biome", "tools": [Tool.BIOME, Tool.HEIGHT, Tool.ADD, Tool.REMOVE]},
	{"name": "Chão", "icon": "ground", "tools": [Tool.GROUND, Tool.PATH]},
	{"name": "Peças", "icon": "object", "tools": [Tool.OBJECT, Tool.STAMP, Tool.ERASER]},
	{"name": "Jogo", "icon": "flag", "tools": [Tool.START, Tool.ACTION, Tool.AREA]},
]
const TAB_ICON_WIDTH := 18
const NO_AREA_MESSAGE := "Crie ou escolha uma área no painel antes de pintar."
const BIOMES: Array[String] = ["temperate", "boreal", "stone", "hill", "mountain", "wshallow", "wdeep"]
const BIOME_SWATCH_HEIGHT := 1
const TOOL_BUTTON_SIZE := Vector2(76.0, 58.0)
const TOOL_ICON_WIDTH := 26
const HEIGHT_BUTTON_SIZE := Vector2(52.0, 44.0)
const HEIGHT_COLUMNS := 6
const KEEP_HEIGHT := -1
const MAX_RADIUS := 10
const SWATCH_WIDTH := 64.0
const SWATCH_COLUMNS := 5
const TITLE_SIZE := 13
const BIOME_NAMES: Dictionary[String, String] = {
	"temperate": "Planície",
	"boreal": "Boreal",
	"stone": "Pedra",
	"hill": "Colina",
	"mountain": "Montanha",
	"wshallow": "Água rasa",
	"wdeep": "Água profunda",
}
const FULL_MESSAGE := "A ilha chegou a 20.000 hexágonos."
## O traço ganha um ponto a cada `PATH_SPACING` pixels da arte; um arraste menor que
## `PATH_CLICK` é um clique, e os pontos a menos de `PATH_TOLERANCE` da reta entre os
## vizinhos saem ao soltar (free-trails/04).
const PATH_SPACING := 12.0
const PATH_CLICK := 4.0
const PATH_TOLERANCE := 2.0
const MAX_PATH_POINTS := 256

var tool := Tool.BIOME
var group := 0
var biome := "temperate"
var height := IslandDraft.BLANK_HEIGHT
## A altura que o Bioma também põe; KEEP_HEIGHT deixa a de cada hexágono.
var biome_height := KEEP_HEIGHT
## A coluna de botões das ferramentas, que o MapEditor põe ao lado do painel.
var tool_column := VBoxContainer.new()
var ground := ""
var radius := 0
var detail_chance := 0.0

var _tool_buttons: Array[Button] = []
var _group_buttons: Array[Button] = []
var _tabs: HFlowContainer
var _last_in_group: Array[int] = []
var _tool_title: Label
var _tool_hint: Label
var _biome_buttons: Dictionary[String, TerrainSwatch] = {}
var _height_buttons: Array[Button] = []
var _biome_height_buttons: Array[Button] = []
var _biome_section: Control
var _biome_height_section: Control
var _height_section: Control
var _ground_buttons: Dictionary[String, TerrainSwatch] = {}
var _ground_section: Control
var _radius_value: Label
var _radius_slider: HSlider
var _rng := RandomNumberGenerator.new()
var _brush_section: Control
var _action_section: Control
var _area_section: Control
var action_panel: ActionPanel
var object_panel: ObjectPanel
var _object_section: Control
var _object_done := false
var area_panel: AreaPanel
var stamp_panel: StampPanel
var _stamp_section: Control
var path_panel: PathPanel
var _path_section: Control
var _path: MapTrail = null
var _path_start := Vector2.ZERO

var _step: EditorHistory.Step = null
## O ponto do ponteiro no chão plano, sem a altura, em pixels da arte: as peças soltas
## ficam com o pé nele.
var pointer := Vector2.ZERO
var _moving := -1
var _grab := Vector2.ZERO
var _full_warned := false
var _secondary := false
var _stroke_action := -2
## A altura máxima editável, ou -1 sem corte (terrain-height/03).
var height_cut := -1


func _init() -> void:
	add_theme_constant_override(&"separation", 10)

	tool_column.add_theme_constant_override(&"separation", 4)
	var groups_group := ButtonGroup.new()
	for index: int in GROUPS.size():
		var button := tool_button(str(GROUPS[index]["name"]), groups_group)
		button.icon = load(MapEditor.ICONS % str(GROUPS[index]["icon"])) as Texture2D
		button.add_theme_constant_override(&"icon_max_width", TOOL_ICON_WIDTH)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.custom_minimum_size = TOOL_BUTTON_SIZE
		button.size_flags_horizontal = Control.SIZE_FILL
		button.add_theme_font_size_override(&"font_size", TITLE_SIZE)
		var names: Array = (GROUPS[index]["tools"] as Array).map(func(member: int) -> String: return TOOL_NAMES[member])
		button.tooltip_text = "%d · %s\n%s" % [index + 1, GROUPS[index]["name"], ", ".join(names)]
		button.pressed.connect(set_group.bind(index))
		tool_column.add_child(button)
		_group_buttons.append(button)
		_last_in_group.append(int((GROUPS[index]["tools"] as Array)[0]))

	var tools_box := _section("")
	_tabs = HFlowContainer.new()
	_tabs.add_theme_constant_override(&"h_separation", 4)
	_tabs.add_theme_constant_override(&"v_separation", 4)
	tools_box.add_child(_tabs)
	tools_box.move_child(_tabs, 0)
	var tabs_group := ButtonGroup.new()
	for index: int in TOOL_NAMES.size():
		var tab := tool_button(TOOL_NAMES[index], tabs_group)
		tab.icon = load(MapEditor.ICONS % TOOL_ICONS[index]) as Texture2D
		tab.add_theme_constant_override(&"icon_max_width", TAB_ICON_WIDTH)
		tab.size_flags_horizontal = Control.SIZE_FILL
		tab.tooltip_text = TOOL_HINTS[index]
		tab.pressed.connect(set_tool.bind(index))
		_tabs.add_child(tab)
		_tool_buttons.append(tab)
	for group_index: int in GROUPS.size():
		for member: int in GROUPS[group_index]["tools"]:
			_tabs.move_child(_tool_buttons[member], -1)
	_tool_title = tools_box.get_child(1) as Label
	_tool_title.theme_type_variation = &"BoldLabel"
	_tool_title.remove_theme_font_size_override(&"font_size")
	_tool_title.remove_theme_color_override(&"font_color")
	_tool_hint = Label.new()
	_tool_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tool_hint.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
	_tool_hint.add_theme_font_size_override(&"font_size", 14)
	tools_box.add_child(_tool_hint)

	var biomes_box := _section("Bioma")
	_biome_section = biomes_box.get_parent()
	var biomes_grid := _swatch_grid(biomes_box)
	var biome_group := ButtonGroup.new()
	for slug: String in BIOMES:
		var swatch := _swatch(biome_group)
		swatch.set_terrain(slug, _biome_name(slug), BIOME_SWATCH_HEIGHT)
		swatch.pressed.connect(_pick_biome.bind(slug))
		biomes_grid.add_child(swatch)
		_biome_buttons[slug] = swatch

	var biome_height_box := _section("Também pôr altura  ·  Shift+0 a 9")
	_biome_height_section = biome_height_box.get_parent()
	var keep_grid := _height_grid()
	var biome_height_group := ButtonGroup.new()
	for value: int in range(KEEP_HEIGHT, HexTile.MAX_HEIGHT + 1):
		var button := _height_button("Manter" if value == KEEP_HEIGHT else str(value), biome_height_group)
		if value == KEEP_HEIGHT:
			button.custom_minimum_size.x = 0.0
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.tooltip_text = "Pintar o bioma sem mudar a altura."
			biome_height_box.add_child(button)
			biome_height_box.add_child(keep_grid)
		else:
			keep_grid.add_child(button)
		button.pressed.connect(_pick_biome_height.bind(value))
		_biome_height_buttons.append(button)

	var heights_box := _section("Altura  ·  Shift+0 a 9")
	_height_section = heights_box.get_parent()
	var heights_row := _height_grid()
	heights_box.add_child(heights_row)
	var height_group := ButtonGroup.new()
	for value: int in HexTile.MAX_HEIGHT + 1:
		var button := _height_button(str(value), height_group)
		button.pressed.connect(_pick_height.bind(value))
		heights_row.add_child(button)
		_height_buttons.append(button)

	var grounds_box := _section("Chão")
	_ground_section = grounds_box.get_parent()
	var grounds_grid := _swatch_grid(grounds_box)
	var ground_group := ButtonGroup.new()
	var ground_slugs: Array[String] = [""]
	for row: Dictionary in GameData.get_rows("ground_types"):
		ground_slugs.append(str(row.get("slug", "")))
	for slug: String in ground_slugs:
		var swatch := _swatch(ground_group)
		swatch.pressed.connect(_pick_ground.bind(slug))
		grounds_grid.add_child(swatch)
		_ground_buttons[slug] = swatch
	if ground_slugs.size() > 1:
		ground = ground_slugs[1]

	var objects_box := _section("Peças")
	_object_section = objects_box.get_parent()
	object_panel = ObjectPanel.new()
	object_panel.edited.connect(func(step: EditorHistory.Step) -> void: edited.emit(step, false))
	object_panel.blocks_editing_changed.connect(func(_on: bool) -> void: brush_changed.emit())
	objects_box.add_child(object_panel)

	var actions_box := _section("Ação")
	_action_section = actions_box.get_parent()
	action_panel = ActionPanel.new()
	action_panel.edited.connect(func(step: EditorHistory.Step) -> void: edited.emit(step, false))
	actions_box.add_child(action_panel)
	var areas_box := _section("Área de Ecobeasts")
	_area_section = areas_box.get_parent()
	area_panel = AreaPanel.new()
	area_panel.edited.connect(func(step: EditorHistory.Step, merge: bool) -> void: edited.emit(step, merge))
	areas_box.add_child(area_panel)

	var stamps_box := _section("Carimbo")
	_stamp_section = stamps_box.get_parent()
	stamp_panel = StampPanel.new()
	stamp_panel.changed.connect(brush_changed.emit)
	stamp_panel.mode_changed.connect(_refresh)
	stamps_box.add_child(stamp_panel)

	var paths_box := _section("Caminho")
	_path_section = paths_box.get_parent()
	path_panel = PathPanel.new()
	path_panel.edited.connect(func(step: EditorHistory.Step) -> void: edited.emit(step, false))
	paths_box.add_child(path_panel)

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
	group = group_of(tool)
	_last_in_group[group] = tool
	if tool != Tool.AREA:
		area_panel.set_focus(false)
	_refresh()
	brush_changed.emit()


static func group_of(value: int) -> int:
	for index: int in GROUPS.size():
		if (GROUPS[index]["tools"] as Array).has(value):
			return index
	return 0


func set_group(index: int) -> void:
	set_tool(_last_in_group[clampi(index, 0, GROUPS.size() - 1)])


## A tecla de um grupo: abre o grupo ou, se ele já está aberto, passa à próxima aba.
func press_group_key(index: int) -> void:
	if index < 0 or index >= GROUPS.size():
		return
	if index != group:
		set_group(index)
		return
	var members: Array = GROUPS[index]["tools"]
	set_tool(int(members[(members.find(tool) + 1) % members.size()]))


## As abas do grupo aberto, na ordem.
func group_tabs() -> Array[Button]:
	var tabs: Array[Button] = []
	for member: int in GROUPS[group]["tools"]:
		tabs.append(_tool_buttons[member])
	return tabs


func set_radius(value: int) -> void:
	radius = clampi(value, 0, MAX_RADIUS)
	_refresh()
	brush_changed.emit()


## O raio do contorno: a chegada pega um hexágono só, qualquer que seja o tamanho.
func brush_radius() -> int:
	return 0 if tool == Tool.START or tool == Tool.PATH else radius


func brush_coords(center: Vector2i) -> Array[Vector2i]:
	if tool == Tool.STAMP and stamp_panel.mode == StampPanel.Mode.PLACE:
		return Stamp.targets(stamp_panel.stamp, center, stamp_panel.flip) if not stamp_panel.stamp.is_empty() else [center]
	if tool == Tool.OBJECT and object_panel.placing_prop and object_panel.selected < 0:
		return [center]
	if tool == Tool.OBJECT and not object_panel.editing_blocks:
		return ObjectPanel.coords_of(ObjectPanel.footprint(object_panel.type_id, center, object_panel.mirrored))
	var reach := brush_radius()
	var coords: Array[Vector2i] = []
	for q: int in range(-reach, reach + 1):
		for r: int in range(maxi(-reach, -q - reach), mini(reach, -q + reach) + 1):
			coords.append(center + Vector2i(q, r))
	return coords


## Com o corte, nenhuma ferramenta muda um hexágono acima dele nem o que está nele.
func editable(draft: IslandDraft, coord: Vector2i) -> bool:
	if height_cut < 0:
		return true
	var tile: HexTile = draft.tiles.get(coord)
	return tile == null or tile.height <= height_cut


func _object_editable(draft: IslandDraft, index: int) -> bool:
	return draft.object_tiles(index).all(func(coord: Vector2i) -> bool: return editable(draft, coord))


func set_draft(draft: IslandDraft) -> void:
	action_panel.set_draft(draft)
	object_panel.set_draft(draft)
	area_panel.set_draft(draft)
	stamp_panel.set_draft(draft)
	path_panel.set_draft(draft)


func refresh_panels() -> void:
	action_panel.refresh()
	object_panel.refresh()
	area_panel.refresh()


func paints_marks() -> bool:
	return tool == Tool.ACTION or tool == Tool.AREA


func begin_stroke(draft: IslandDraft, secondary: bool = false) -> void:
	_step = EditorHistory.Step.new()
	_step.label = TOOL_NAMES[tool]
	_full_warned = false
	_secondary = secondary
	_stroke_action = -2
	_object_done = false
	_moving = -1
	if draft.props.size() > 0 or tool == Tool.OBJECT or tool == Tool.STAMP or tool == Tool.ERASER:
		_step.props_before = draft.props.duplicate(true)
	if draft.actions.size() > 0 or tool == Tool.ACTION:
		_step.actions_before = draft.actions.duplicate(true)
	if draft.objects.size() > 0 or tool == Tool.OBJECT or tool == Tool.STAMP:
		_step.objects_before = draft.objects.duplicate(true)
	if tool == Tool.PATH:
		_step.trails_before = IslandDraft.copy_trails(draft.trails)
		_path = null
		_path_start = pointer


func paint(draft: IslandDraft, center: Vector2i) -> Array[Vector2i]:
	if _step == null:
		begin_stroke(draft)
	var changed: Array[Vector2i] = []
	if tool == Tool.ACTION:
		return _paint_action(draft, center)
	if tool == Tool.OBJECT:
		return _paint_object(draft, center)
	if tool == Tool.STAMP:
		return _paint_stamp(draft, center)
	if tool == Tool.PATH:
		return changed
	if _secondary and tool != Tool.AREA and tool != Tool.ERASER:
		return changed
	if tool == Tool.START:
		if draft.tiles.has(center) and draft.start != center and editable(draft, center):
			if _step.start_before == null:
				_step.start_before = draft.start
			changed.append(draft.start)
			draft.start = center
			_step.start_after = center
			changed.append(center)
		return changed
	for coord: Vector2i in brush_coords(center):
		if not editable(draft, coord):
			continue
		var before := draft.snapshot(coord)
		if not _change(draft, coord):
			continue
		if not _step.before.has(coord):
			_step.before[coord] = before
		_step.after[coord] = draft.snapshot(coord)
		changed.append(coord)
	return changed


func end_stroke(draft: IslandDraft) -> EditorHistory.Step:
	var step := _step
	_step = null
	if step == null:
		return null
	if tool == Tool.ACTION:
		for index: int in range(draft.actions.size() - 1, -1, -1):
			if (draft.actions[index]["tiles"] as Array).is_empty():
				draft.actions.remove_at(index)
		action_panel.refresh()
	elif tool == Tool.AREA:
		area_panel.refresh()
	if step.actions_before != null and step.actions_before != draft.actions:
		step.actions_after = draft.actions.duplicate(true)
	else:
		step.actions_before = null
	if step.objects_before != null and step.objects_before != draft.objects:
		step.objects_after = draft.objects.duplicate(true)
	else:
		step.objects_before = null
	if tool == Tool.PATH:
		_finish_path(draft)
	if step.trails_before != null and IslandDraft.trails_state(step.trails_before) != IslandDraft.trails_state(draft.trails):
		step.trails_after = IslandDraft.copy_trails(draft.trails)
	else:
		step.trails_before = null
	if step.props_before != null and step.props_before != draft.props:
		step.props_after = draft.props.duplicate(true)
	else:
		step.props_before = null
	_moving = -1
	if tool == Tool.OBJECT or tool == Tool.REMOVE:
		object_panel.refresh()
	if step.start_after == step.start_before:
		step.start_before = null
		step.start_after = null
	# Um hexágono que voltou ao que era na mesma pincelada não conta.
	for coord: Vector2i in step.after.keys():
		if step.after[coord] == step.before[coord]:
			step.after.erase(coord)
			step.before.erase(coord)
	return null if step.is_empty() else step


func _change(draft: IslandDraft, coord: Vector2i) -> bool:
	var tile: HexTile = draft.tiles.get(coord)
	match tool:
		Tool.BIOME:
			if tile == null:
				return false
			var changed := false
			if tile.biome != biome:
				tile.biome = biome
				if tile.variant > IslandDraft.max_variant(biome):
					tile.variant = IslandDraft.roll_variant(biome, detail_chance, _rng)
				changed = true
			if biome_height != KEEP_HEIGHT and tile.height != biome_height:
				tile.height = biome_height
				changed = true
			if tile.bare:
				tile.bare = false
				changed = true
			return changed
		Tool.HEIGHT:
			if tile == null or tile.height == height:
				return false
			tile.height = height
			return true
		Tool.GROUND:
			if tile == null or tile.ground == ground:
				return false
			tile.ground = ground
			return true
		Tool.ADD:
			if tile != null:
				return false
			if draft.tiles.size() >= IslandDraft.MAX_TILES:
				if not _full_warned:
					_full_warned = true
					message.emit(FULL_MESSAGE)
				return false
			return draft.add_tile(coord, biome, height, IslandDraft.roll_variant(biome, detail_chance, _rng))
		Tool.REMOVE:
			if tile == null or coord == draft.start:
				return false
			draft.remove_tile(coord)
			return true
		Tool.ERASER:
			if tile == null:
				return false
			var erased := false
			if not _secondary:
				for index: int in range(draft.props.size() - 1, -1, -1):
					if draft.prop_coord(index) == coord:
						draft.props.remove_at(index)
						erased = true
			if tile.bare == not _secondary:
				return erased
			tile.bare = not _secondary
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


func _paint_action(draft: IslandDraft, center: Vector2i) -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	if _secondary:
		if _stroke_action == -2:
			_stroke_action = -1
			action_panel.select(draft.action_at(center))
		return changed
	if _stroke_action == -2:
		_stroke_action = _stroke_target(draft, center)
	var target := _stroke_action
	if target < 0 or target >= draft.actions.size():
		return changed
	var occupied: Array = draft.actions[target]["tiles"]
	for coord: Vector2i in brush_coords(center):
		if not draft.tiles.has(coord) or not editable(draft, coord):
			continue
		var holder := draft.action_at(coord)
		if action_panel.removing:
			if holder != target:
				continue
			for spot: int in range(occupied.size() - 1, -1, -1):
				if int(occupied[spot]["q"]) == coord.x and int(occupied[spot]["r"]) == coord.y:
					occupied.remove_at(spot)
			changed.append(coord)
		elif holder == -1:
			occupied.append({"q": coord.x, "r": coord.y})
			changed.append(coord)
	if action_panel.removing and occupied.is_empty():
		draft.actions.remove_at(target)
		_stroke_action = -1
		action_panel.select(-1)
	return changed


## Uma coisa por clique: escolher (botão direito), começar a mover a peça solta
## escolhida, trocar o bloqueio de um hexágono do objeto escolhido ou pôr a peça nova.
func _paint_object(draft: IslandDraft, center: Vector2i) -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	if _object_done:
		return changed
	_object_done = true
	var art := pointer - Vector2(0.0, draft.rise_at(HexMapView.grid_coord(pointer)))
	if _secondary:
		var hit := draft.prop_at(art)
		if hit >= 0 and editable(draft, draft.prop_coord(hit)):
			object_panel.select_prop(hit)
		else:
			var index := draft.object_at(center)
			object_panel.select(index if index < 0 or _object_editable(draft, index) else -1)
		return changed
	var chosen := object_panel.selected_prop
	if chosen >= 0 and draft.prop_rect(chosen).has_point(art) and editable(draft, draft.prop_coord(chosen)):
		_moving = chosen
		_grab = draft.prop_foot(chosen) - pointer
		return changed
	if object_panel.placing_prop and not object_panel.editing_blocks:
		var foot := pointer.round()
		var coord := HexMapView.grid_coord(foot)
		if not draft.tiles.has(coord) or not editable(draft, coord):
			return changed
		draft.props.append(object_panel.new_prop(coord, Vector2i(foot - HexMapView.flat_center(coord))))
		object_panel.select_prop(draft.props.size() - 1)
		changed.append(coord)
		return changed
	if not object_panel.editing_blocks and draft.object_at(center) >= 0:
		if _object_editable(draft, draft.object_at(center)):
			object_panel.select(draft.object_at(center))
		return changed
	if object_panel.editing_blocks:
		var selected := object_panel.selected
		if selected < 0 or draft.object_at(center) != selected or not _object_editable(draft, selected):
			return changed
		for at: Variant in (draft.objects[selected] as Dictionary).get("tiles", []):
			if int(at.get("q", 0)) == center.x and int(at.get("r", 0)) == center.y:
				at["blocks"] = not bool(at.get("blocks", true))
				changed.append(center)
		return changed
	var object := object_panel.new_object(center)
	var coords := ObjectPanel.coords_of(object["tiles"])
	if coords.is_empty() or not draft.object_fits(coords) or not coords.all(func(coord: Vector2i) -> bool: return editable(draft, coord)):
		return changed
	draft.objects.append(object)
	object_panel.select(draft.objects.size() - 1)
	return coords


## Escolhendo a área, marca (ou, com o botão direito, desmarca) os hexágonos do pincel.
## Pondo, um carimbo por clique, com o apoio em `center`.
func _paint_stamp(draft: IslandDraft, center: Vector2i) -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	if stamp_panel.mode == StampPanel.Mode.SELECT:
		for coord: Vector2i in brush_coords(center):
			if draft.tiles.has(coord) and editable(draft, coord) and stamp_panel.mark(coord, not _secondary):
				changed.append(coord)
		stamp_panel.refresh_count()
		return changed
	if _secondary or _object_done or stamp_panel.stamp.is_empty():
		return changed
	_object_done = true
	var allowed := func(coord: Vector2i) -> bool: return editable(draft, coord)
	for coord: Vector2i in Stamp.targets(stamp_panel.stamp, center, stamp_panel.flip):
		if draft.tiles.has(coord) and allowed.call(coord) and not _step.before.has(coord):
			_step.before[coord] = draft.snapshot(coord)
	changed = Stamp.place(draft, stamp_panel.stamp, center, stamp_panel.flip, allowed)
	for coord: Vector2i in changed:
		_step.after[coord] = draft.snapshot(coord)
	object_panel.select(-1)
	return changed


## Arrastando com o Caminho: o traço nasce depois de `PATH_CLICK` pixels e ganha um
## ponto a cada `PATH_SPACING`, só sobre hexágonos da ilha que se podem editar; fora
## deles, ele pausa. Devolve o pedaço novo, para redesenhar, ou `null`.
func extend_path(draft: IslandDraft, flat: Vector2) -> MapTrail:
	if tool != Tool.PATH or _step == null or _secondary:
		return null
	if _path == null:
		if flat.distance_to(_path_start) < PATH_CLICK or not _path_point_ok(draft, _path_start):
			return null
		_path = MapTrail.new()
		_path.ground = path_panel.ground
		_path.width = path_panel.width
		_path.points.append(_path_start.round())
		draft.trails.append(_path)
		path_panel.select(-1)
	var last := _path.points[_path.points.size() - 1]
	if _path.points.size() >= MAX_PATH_POINTS or flat.distance_to(last) < PATH_SPACING or not _path_point_ok(draft, flat):
		return null
	_path.points.append(flat.round())
	_path.smoothed = PackedVector2Array()
	var piece := MapTrail.new()
	piece.ground = _path.ground
	piece.width = _path.width
	piece.points = _path.points.slice(maxi(0, _path.points.size() - 3))
	return piece


func _path_point_ok(draft: IslandDraft, flat: Vector2) -> bool:
	var coord := HexMapView.grid_coord(flat)
	return draft.tiles.has(coord) and editable(draft, coord)


## Ao soltar: o traço desenhado fica com os pontos simplificados, sem escolha, para a
## próxima amostra valer para o próximo; um clique escolhe o traço de cima no ponto, ou
## solta a escolha.
func _finish_path(draft: IslandDraft) -> void:
	if _path == null:
		path_panel.select(draft.trail_at(_path_start))
		return
	_path.points = simplified(_path.points, PATH_TOLERANCE)
	_path.smoothed = PackedVector2Array()
	if _path.points.size() < 2:
		draft.trails.erase(_path)
	path_panel.select(-1)
	_path = null


## Ramer-Douglas-Peucker: tira os pontos a menos de `tolerance` da reta entre os que ficam.
static func simplified(points: PackedVector2Array, tolerance: float) -> PackedVector2Array:
	if points.size() < 3:
		return points
	var first := points[0]
	var last := points[points.size() - 1]
	var farthest := 0
	var distance := 0.0
	for index: int in range(1, points.size() - 1):
		var gap := points[index].distance_to(Geometry2D.get_closest_point_to_segment(points[index], first, last))
		if gap > distance:
			distance = gap
			farthest = index
	if distance <= tolerance:
		return PackedVector2Array([first, last])
	var left := simplified(points.slice(0, farthest + 1), tolerance)
	var right := simplified(points.slice(farthest), tolerance)
	left.remove_at(left.size() - 1)
	left.append_array(right)
	return left


## Os hexágonos da área marcada para o carimbo, enquanto ela está sendo escolhida.
func marked_coords() -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	if tool == Tool.STAMP and stamp_panel.mode == StampPanel.Mode.SELECT:
		coords.assign(stamp_panel.selection.keys())
	return coords


## Arrastando a peça solta escolhida: o pé segue o ponteiro, sem sair da ilha. Devolve
## os hexágonos que mudaram.
func drag(draft: IslandDraft, flat: Vector2) -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	if _moving < 0 or _moving >= draft.props.size():
		return changed
	var foot := (flat + _grab).round()
	var coord := HexMapView.grid_coord(foot)
	if not draft.tiles.has(coord) or not editable(draft, coord):
		return changed
	var prop: Dictionary = draft.props[_moving]
	var offset := Vector2i(foot - HexMapView.flat_center(coord))
	var before := draft.prop_coord(_moving)
	if before == coord and int(prop["dx"]) == offset.x and int(prop["dy"]) == offset.y:
		return changed
	prop["q"] = coord.x
	prop["r"] = coord.y
	prop["dx"] = offset.x
	prop["dy"] = offset.y
	changed.append(before)
	if coord != before:
		changed.append(coord)
	return changed


func is_moving() -> bool:
	return _moving >= 0


## A cor do contorno sob o ponteiro com a ferramenta Peças: verde se o objeto cabe,
## vermelho se não; transparente nas outras ferramentas e com uma peça solta.
func brush_color(draft: IslandDraft, center: Vector2i) -> Color:
	if tool == Tool.STAMP and stamp_panel.mode == StampPanel.Mode.PLACE and draft != null and not stamp_panel.stamp.is_empty():
		var all_in := brush_coords(center).all(func(coord: Vector2i) -> bool: return draft.tiles.has(coord) and editable(draft, coord))
		return UiPalette.HP_HIGH if all_in else UiPalette.WARNING
	if tool != Tool.OBJECT or object_panel.editing_blocks or draft == null or object_panel.placing_prop:
		return Color.TRANSPARENT
	var coords := brush_coords(center)
	var fits := draft.object_fits(coords) and coords.all(func(coord: Vector2i) -> bool: return editable(draft, coord))
	return UiPalette.HP_HIGH if fits else UiPalette.DANGER


func _stroke_target(draft: IslandDraft, center: Vector2i) -> int:
	if action_panel.removing:
		return action_panel.selected
	if not draft.tiles.has(center) or not editable(draft, center):
		return -1
	var holder := draft.action_at(center)
	if holder >= 0:
		action_panel.select(holder)
		return holder
	draft.actions.append({"action_type_id": action_panel.type_id, "tiles": []})
	action_panel.select(draft.actions.size() - 1)
	return draft.actions.size() - 1


func _pick_biome(slug: String) -> void:
	biome = slug
	if tool != Tool.ADD:
		set_tool(Tool.BIOME)


func _pick_ground(slug: String) -> void:
	ground = slug
	set_tool(Tool.GROUND)


func _pick_height(value: int) -> void:
	height = value
	_refresh()


func _pick_biome_height(value: int) -> void:
	biome_height = value
	_refresh()


## Shift+0 a 9: a altura da ferramenta escolhida, no Bioma a que ele também põe.
func pick_height_key(value: int) -> bool:
	if tool == Tool.BIOME:
		_pick_biome_height(value)
	elif tool == Tool.HEIGHT or tool == Tool.ADD:
		_pick_height(value)
	else:
		return false
	return true


func _refresh() -> void:
	for index: int in _group_buttons.size():
		_group_buttons[index].set_pressed_no_signal(index == group)
	var members: Array = GROUPS[group]["tools"]
	for index: int in _tool_buttons.size():
		_tool_buttons[index].visible = members.has(index)
		_tool_buttons[index].set_pressed_no_signal(index == tool)
	var group_name := str(GROUPS[group]["name"])
	_tool_title.text = "%d · %s" % [group + 1, group_name] if group_name == TOOL_NAMES[tool] else "%d · %s · %s" % [group + 1, group_name, TOOL_NAMES[tool]]
	_tool_hint.text = TOOL_HINTS[tool]
	_biome_section.visible = tool == Tool.BIOME or tool == Tool.ADD
	_biome_height_section.visible = tool == Tool.BIOME
	_height_section.visible = tool == Tool.HEIGHT or tool == Tool.ADD
	_ground_section.visible = tool == Tool.GROUND
	_object_section.visible = tool == Tool.OBJECT
	_action_section.visible = tool == Tool.ACTION
	_area_section.visible = tool == Tool.AREA
	_stamp_section.visible = tool == Tool.STAMP
	_path_section.visible = tool == Tool.PATH
	_brush_section.visible = tool != Tool.START and tool != Tool.OBJECT and tool != Tool.PATH and not (tool == Tool.STAMP and stamp_panel.mode == StampPanel.Mode.PLACE)
	for slug: String in _biome_buttons:
		_biome_buttons[slug].set_pressed_no_signal(slug == biome)
		_biome_buttons[slug].queue_redraw()
	for value: int in _height_buttons.size():
		_height_buttons[value].set_pressed_no_signal(value == height)
	for index: int in _biome_height_buttons.size():
		_biome_height_buttons[index].set_pressed_no_signal(index + KEEP_HEIGHT == biome_height)
	for slug: String in _ground_buttons:
		_ground_buttons[slug].set_ground(slug, _ground_name(slug), biome)
		_ground_buttons[slug].set_pressed_no_signal(slug == ground)
	_radius_slider.set_value_no_signal(radius)
	_radius_value.text = "1 hexágono" if radius == 0 else "raio %d  ·  %d hexágonos" % [radius, 3 * radius * (radius + 1) + 1]


func _ground_name(slug: String) -> String:
	if slug.is_empty():
		return "Sem chão"
	for row: Dictionary in GameData.get_rows("ground_types"):
		if row.get("slug") == slug:
			return str(row.get("name", slug))
	return slug


func _biome_name(slug: String) -> String:
	for row: Dictionary in GameData.get_rows("biomes"):
		if row.get("slug") == slug:
			return str(row.get("name", slug))
	return BIOME_NAMES.get(slug, slug)


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


func _swatch(button_group: ButtonGroup) -> TerrainSwatch:
	var swatch := TerrainSwatch.new()
	swatch.button_group = button_group
	swatch.custom_minimum_size.x = SWATCH_WIDTH
	return swatch


func _height_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = HEIGHT_COLUMNS
	grid.add_theme_constant_override(&"h_separation", 4)
	grid.add_theme_constant_override(&"v_separation", 4)
	return grid


func _height_button(text: String, button_group: ButtonGroup) -> Button:
	var button := tool_button(text, button_group)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.custom_minimum_size = HEIGHT_BUTTON_SIZE
	button.size_flags_horizontal = Control.SIZE_FILL
	return button


static func tool_button(text: String, button_group: ButtonGroup) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_group = button_group
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
