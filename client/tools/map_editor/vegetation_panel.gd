class_name VegetationPanel
extends VBoxContainer
## O bloco da ferramenta Vegetação (vegetation-brush/02): o grupo, os tipos ligados de
## cada grupo e a densidade, e a pincelada, que espalha peças soltas pelos hexágonos.

const GROUPS: Array[Dictionary] = [
	{"name": "Árvores", "kinds": ["tree", "pine"], "per_tile": 1.0},
	{"name": "Arbustos", "kinds": ["bush", "dark_bush", "dry_shrub", "fern"], "per_tile": 2.0},
	{"name": "Gramas", "kinds": ["tuft", "dry_tuft", "moss"], "per_tile": 4.0},
	{"name": "Flores", "kinds": ["flowers"], "per_tile": 3.0},
	{"name": "Pedras pequenas", "kinds": ["pebbles"], "per_tile": 2.0},
	{"name": "Pedras médias", "kinds": ["rock", "mossy_rock", "brown_rock"], "per_tile": 1.0},
	{"name": "Pedras grandes", "kinds": ["boulder", "rock_pile", "spire"], "per_tile": 1.0},
]
const DENSITIES: Array[float] = [0.5, 1.0, 2.0]
const DENSITY_NAMES: Array[String] = ["Pouca", "Média", "Muita"]
const MAX_PROPS := 20000
const FULL_MESSAGE := "A ilha chegou ao limite de 20.000 peças."
## O espaço das peças de arte própria (poste, placa, canteiro e banco), que não estão em KIND_RADIUS.
const OTHER_RADIUS := 8.0
const ICON_WIDTH := 28

var group := 0
var density := 1
## A pincelada parou no limite de peças.
var full := false

var _enabled: Array[Array] = []
var _group_buttons: Array[Button] = []
var _kinds_box: HFlowContainer
var _density_buttons: Array[Button] = []
## Na pincelada: os hexágonos que já receberam peças e os pontos ocupados de cada um.
var _painted: Dictionary[Vector2i, bool] = {}
var _taken: Dictionary[Vector2i, Array] = {}
var _type_ids: Dictionary[String, int] = {}
var _variants: Dictionary[String, int] = {}
static var _icons: Dictionary[String, Texture2D] = {}


func _init() -> void:
	add_theme_constant_override(&"separation", 8)
	for entry: Dictionary in GROUPS:
		_enabled.append((entry["kinds"] as Array).duplicate())
	var groups := HFlowContainer.new()
	groups.add_theme_constant_override(&"h_separation", 4)
	groups.add_theme_constant_override(&"v_separation", 4)
	add_child(groups)
	var group_group := ButtonGroup.new()
	for index: int in GROUPS.size():
		var button := EditorTools.tool_button(str(GROUPS[index]["name"]), group_group)
		button.icon = kind_icon(str((GROUPS[index]["kinds"] as Array)[0]))
		button.add_theme_constant_override(&"icon_max_width", ICON_WIDTH)
		button.size_flags_horizontal = Control.SIZE_FILL
		button.pressed.connect(pick_group.bind(index))
		groups.add_child(button)
		_group_buttons.append(button)
	var kinds_title := Label.new()
	kinds_title.text = "Tipos que entram"
	EditorTools.section_title(kinds_title)
	add_child(kinds_title)
	_kinds_box = HFlowContainer.new()
	_kinds_box.add_theme_constant_override(&"h_separation", 4)
	_kinds_box.add_theme_constant_override(&"v_separation", 4)
	add_child(_kinds_box)
	var density_title := Label.new()
	density_title.text = "Densidade"
	EditorTools.section_title(density_title)
	add_child(density_title)
	var densities := HBoxContainer.new()
	densities.add_theme_constant_override(&"separation", 4)
	add_child(densities)
	var density_group := ButtonGroup.new()
	for index: int in DENSITIES.size():
		var button := EditorTools.tool_button(DENSITY_NAMES[index], density_group)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(pick_density.bind(index))
		densities.add_child(button)
		_density_buttons.append(button)
	refresh()


func pick_group(index: int) -> void:
	group = clampi(index, 0, GROUPS.size() - 1)
	refresh()


func pick_density(index: int) -> void:
	density = clampi(index, 0, DENSITIES.size() - 1)
	refresh()


## Liga ou desliga um tipo do grupo escolhido; o último ligado não desliga.
func toggle_kind(slug: String) -> void:
	var kinds: Array = _enabled[group]
	if kinds.has(slug):
		if kinds.size() > 1:
			kinds.erase(slug)
	elif (GROUPS[group]["kinds"] as Array).has(slug):
		kinds.append(slug)
		var order: Array = GROUPS[group]["kinds"]
		kinds.sort_custom(func(a: String, b: String) -> bool: return order.find(a) < order.find(b))
	refresh()


func enabled_kinds() -> Array[String]:
	var kinds: Array[String] = []
	kinds.assign(_enabled[group])
	return kinds


func refresh() -> void:
	for index: int in _group_buttons.size():
		_group_buttons[index].set_pressed_no_signal(index == group)
	for index: int in _density_buttons.size():
		_density_buttons[index].set_pressed_no_signal(index == density)
	for child: Node in _kinds_box.get_children():
		child.queue_free()
	for slug: String in GROUPS[group]["kinds"]:
		var button := EditorTools.tool_button(_kind_name(slug), null)
		button.icon = kind_icon(slug)
		button.add_theme_constant_override(&"icon_max_width", ICON_WIDTH)
		button.size_flags_horizontal = Control.SIZE_FILL
		button.set_pressed_no_signal((_enabled[group] as Array).has(slug))
		button.pressed.connect(toggle_kind.bind(slug))
		_kinds_box.add_child(button)


## Começa uma pincelada: os pontos já ocupados são lidos uma vez, por hexágono.
func begin(draft: IslandDraft) -> void:
	_painted.clear()
	_taken.clear()
	full = false
	for index: int in draft.props.size():
		var prop: Dictionary = draft.props[index]
		var coord := draft.prop_coord(index)
		if not _taken.has(coord):
			_taken[coord] = []
		_taken[coord].append([Vector2i(int(prop.get("dx", 0)), int(prop.get("dy", 0))), _radius_of(PropArt.slug_of(int(prop.get("prop_type_id", 0))))])


## Põe as peças de um hexágono, uma vez só por pincelada, e devolve quantas pôs.
func paint_tile(draft: IslandDraft, coord: Vector2i, random: RandomNumberGenerator) -> int:
	var tile: HexTile = draft.tiles.get(coord)
	if tile == null or _painted.has(coord):
		return 0
	_painted[coord] = true
	var taken: Array = _taken.get(coord, [])
	if not tile.bare:
		for decoration: HexDecorations.Decoration in HexDecorations.decorations_of(tile, draft.id):
			taken.append([decoration.offset, HexDecorations.KIND_RADIUS[decoration.kind]])
	var wanted := float(GROUPS[group]["per_tile"]) * DENSITIES[density]
	var count := floori(wanted) + (1 if random.randf() < wanted - floorf(wanted) else 0)
	var kinds := enabled_kinds()
	var trails := _trails_at(draft, coord)
	var center := HexMapView.flat_center(coord)
	var placed := 0
	for _piece: int in count:
		if draft.props.size() >= MAX_PROPS:
			full = true
			break
		var slug: String = kinds[random.randi_range(0, kinds.size() - 1)]
		var radius := _radius_of(slug)
		for _try: int in HexDecorations.PLACE_TRIES:
			var spot := HexDecorations.random_spot(random)
			if not HexDecorations.is_free_spot(spot, radius, taken):
				continue
			if not HexGrounds.allows_on(HexGrounds.ground_at(tile, center + Vector2(spot), trails), slug):
				continue
			taken.append([spot, radius])
			draft.props.append({
				"prop_type_id": _type_id(slug),
				"q": coord.x,
				"r": coord.y,
				"dx": spot.x,
				"dy": spot.y,
				"variant": random.randi_range(1, _variant_count(slug)),
				"mirrored": random.randf() < 0.5,
			})
			placed += 1
			break
	_taken[coord] = taken
	return placed


## Apaga as peças soltas com o pé em `coords` e devolve os hexágonos que perderam alguma.
func erase(draft: IslandDraft, coords: Array[Vector2i]) -> Array[Vector2i]:
	var wanted: Dictionary[Vector2i, bool] = {}
	for coord: Vector2i in coords:
		wanted[coord] = true
	var changed: Dictionary[Vector2i, bool] = {}
	var kept: Array = []
	for index: int in draft.props.size():
		var coord := draft.prop_coord(index)
		if wanted.has(coord):
			changed[coord] = true
		else:
			kept.append(draft.props[index])
	if not changed.is_empty():
		draft.props = kept
		for coord: Vector2i in changed:
			_taken.erase(coord)
			_painted.erase(coord)
	return changed.keys()


func _trails_at(draft: IslandDraft, coord: Vector2i) -> Array[MapTrail]:
	var near: Array[MapTrail] = []
	var area := Rect2(HexMapView.flat_center(coord) - Vector2(32.0, 32.0), Vector2(64.0, 64.0))
	for trail: MapTrail in draft.trails:
		if GroundMask.trail_bounds(trail).intersects(area):
			near.append(trail)
	return near


## O ícone da primeira variante, recortado no desenho: a célula das plantas pequenas é quase toda vazia.
static func kind_icon(slug: String) -> Texture2D:
	if _icons.has(slug):
		return _icons[slug]
	var art := PropArt.icon(slug, 1)
	var icon := art
	if art != null:
		var used := art.get_image().get_used_rect()
		if used.has_area():
			var cropped := AtlasTexture.new()
			cropped.atlas = art
			cropped.region = Rect2(used)
			icon = cropped
	_icons[slug] = icon
	return icon


static func _radius_of(slug: String) -> float:
	return HexDecorations.KIND_RADIUS.get(slug, OTHER_RADIUS)


func _type_id(slug: String) -> int:
	_read_types()
	return _type_ids.get(slug, 0)


func _variant_count(slug: String) -> int:
	_read_types()
	return maxi(1, _variants.get(slug, 1))


func _read_types() -> void:
	if not _type_ids.is_empty():
		return
	for row: Dictionary in GameData.get_rows("prop_types"):
		var slug := str(row.get("slug", ""))
		_type_ids[slug] = int(row.get("id", 0))
		_variants[slug] = mini(int(row.get("variants", 1)), HexDecorations.VARIANTS) if HexDecorations.KIND_ROWS.has(slug) else int(row.get("variants", 1))


func _kind_name(slug: String) -> String:
	_read_types()
	return str(GameData.get_row("prop_types", _type_ids.get(slug, 0)).get("name", slug))
