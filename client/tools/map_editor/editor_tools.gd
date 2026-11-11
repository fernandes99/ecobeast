class_name EditorTools
extends VBoxContainer
## Os pincéis de terreno do editor de ilhas (map-editor/03): o painel com as
## ferramentas, o bioma, a forma e o tamanho, e o que cada pincelada muda no
## rascunho. Uma pincelada vai do apertar ao soltar do botão e vira um passo do
## desfazer (`EditorHistory.Step`).

## Algo para a barra de cima, como o limite de hexágonos.
signal message(text: String)
## A ferramenta ou o tamanho mudou: o contorno do pincel muda junto.
signal brush_changed

enum Tool { BIOME, SHAPE, ADD, REMOVE, START }

const TOOL_NAMES: Array[String] = ["Bioma", "Forma", "Pôr hexágono", "Tirar hexágono", "Chegada"]
## Os biomas de terreno, na ordem do painel; o nome vem do catálogo.
const BIOMES: Array[String] = ["temperate", "boreal", "stone", "wshallow", "wdeep"]
const SHAPES: Array[String] = ["flat", "hill", "mont"]
const SHAPE_NAMES: Dictionary[String, String] = {"flat": "Plano", "hill": "Colina", "mont": "Montanha"}
const MAX_RADIUS := 10
const SWATCH_SIZE := Vector2(44.0, 44.0)
const FULL_MESSAGE := "A ilha chegou a 20.000 hexágonos."

var tool := Tool.BIOME
var biome := "temperate"
var shape := "flat"
## 0 é um hexágono só.
var radius := 0
## A chance de detalhe do gerador, para sortear a variante como ele.
var detail_chance := 0.0

var _tool_buttons: Array[Button] = []
var _biome_buttons: Dictionary[String, Button] = {}
var _shape_buttons: Dictionary[String, Button] = {}
var _radius_label: Label
var _radius_slider: HSlider
var _rng := RandomNumberGenerator.new()

## A pincelada em andamento.
var _step: EditorHistory.Step = null
var _full_warned := false


func _init() -> void:
	add_theme_constant_override(&"separation", 6)
	_add_title("Ferramentas (1 a 5)")
	var tools_group := ButtonGroup.new()
	var grid := GridContainer.new()
	grid.columns = 2
	add_child(grid)
	for index: int in TOOL_NAMES.size():
		var button := _toggle("%d  %s" % [index + 1, TOOL_NAMES[index]], tools_group)
		button.pressed.connect(set_tool.bind(index))
		grid.add_child(button)
		_tool_buttons.append(button)

	_add_title("Bioma")
	var biomes_row := HBoxContainer.new()
	add_child(biomes_row)
	var biome_group := ButtonGroup.new()
	for slug: String in BIOMES:
		var swatch := _toggle("", biome_group)
		swatch.custom_minimum_size = SWATCH_SIZE
		swatch.icon = load(HexMapView.SURFACE_PATH % slug) as Texture2D
		swatch.expand_icon = true
		swatch.tooltip_text = _biome_name(slug)
		swatch.pressed.connect(_pick_biome.bind(slug))
		biomes_row.add_child(swatch)
		_biome_buttons[slug] = swatch

	_add_title("Forma")
	var shapes_row := HBoxContainer.new()
	add_child(shapes_row)
	var shape_group := ButtonGroup.new()
	for slug: String in SHAPES:
		var button := _toggle(SHAPE_NAMES[slug], shape_group)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_pick_shape.bind(slug))
		shapes_row.add_child(button)
		_shape_buttons[slug] = button

	_radius_label = Label.new()
	_radius_label.theme_type_variation = &"SecondaryLabel"
	add_child(_radius_label)
	_radius_slider = HSlider.new()
	_radius_slider.min_value = 0
	_radius_slider.max_value = MAX_RADIUS
	_radius_slider.step = 1
	_radius_slider.value_changed.connect(func(value: float) -> void: set_radius(int(value)))
	add_child(_radius_slider)
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


func begin_stroke(draft: IslandDraft) -> void:
	_step = EditorHistory.Step.new()
	_step.label = TOOL_NAMES[tool]
	_full_warned = false
	if draft.buildings.size() > 0:
		_step.buildings_before = draft.buildings.duplicate(true)


## Pinta em volta de `center` e devolve os hexágonos que mudaram.
func paint(draft: IslandDraft, center: Vector2i) -> Array[Vector2i]:
	if _step == null:
		begin_stroke(draft)
	var changed: Array[Vector2i] = []
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
	return false


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
	for slug: String in _biome_buttons:
		_biome_buttons[slug].set_pressed_no_signal(slug == biome)
	for slug: String in _shape_buttons:
		_shape_buttons[slug].set_pressed_no_signal(slug == shape)
	_radius_slider.set_value_no_signal(radius)
	_radius_label.text = "Tamanho do pincel ([ e ]): %s" % ("1 hexágono" if radius == 0 else "raio %d" % radius)


func _biome_name(slug: String) -> String:
	for row: Dictionary in GameData.get_rows("biomes"):
		if row.get("slug") == slug:
			return str(row.get("name", slug))
	return slug


func _add_title(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"BoldLabel"
	add_child(label)


func _toggle(text: String, group: ButtonGroup) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_group = group
	button.focus_mode = Control.FOCUS_NONE
	return button
