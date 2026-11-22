class_name CreatureFace
extends Control
## O rosto de um Ecobeast num círculo (.specs/creature-faces/02-face-component.md): o fundo
## na cor do Elemento, o `face.png` recortado no círculo, o anel de HP e o anel de
## selecionado. Sem `face.png`, e na sombra do Bestiário, o `front.png` inteiro faz o papel
## do rosto.

const FACE_PATH := "res://assets/creatures/%s/face.png"
const SilhouetteShader := preload("res://ui/components/silhouette.gdshader")

const FILL_DARKEN := 0.45
const HP_WIDTH := 0.05
const SELECTED_WIDTH := 0.04
## O anel de HP vai do verde ao laranja e ao vermelho conforme a vida cai: a cor de cada
## parte da vida, lida em degradê entre elas.
const HP_STOPS: Array[float] = [0.15, 0.5, 1.0]
const HP_SECONDS := 0.3
const ARC_POINTS := 64
const FAINTED_TINT := Color(0.42, 0.42, 0.42)
const EMPTY_ALPHA := 0.45
const FRONT_MARGIN := 0.08

@export var face_size: int = 88

var _species_id := -1
var _show_hp := false
var _hp := 0
var _max_hp := 0
var _shown_ratio := 0.0:
	set(value):
		_shown_ratio = value
		if _rings != null:
			_rings.queue_redraw()
var _selected := false
var _silhouette := false
var _hp_tween: Tween = null
var _colors: Array[Color] = []
var _backdrop := Control.new()
var _face := TextureRect.new()
var _rings := Control.new()


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_backdrop.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_backdrop.mouse_filter = MOUSE_FILTER_IGNORE
	_backdrop.draw.connect(_draw_backdrop)
	add_child(_backdrop)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_face.mouse_filter = MOUSE_FILTER_IGNORE
	_backdrop.add_child(_face)
	_rings.mouse_filter = MOUSE_FILTER_IGNORE
	_rings.draw.connect(_draw_rings)
	add_child(_rings)


func _ready() -> void:
	custom_minimum_size = Vector2(face_size, face_size)
	resized.connect(_layout)
	_refresh()


func set_creature(creature: CreatureInstance) -> void:
	if creature == null:
		set_species(-1)
		return
	_species_id = creature.species_id
	_show_hp = true
	_hp = creature.current_hp
	_max_hp = creature.stats.hp
	_shown_ratio = _ratio()
	if is_node_ready():
		_refresh()


## Só a espécie, sem o anel de HP (o Bestiário, a fila de vez); -1 é o espaço vazio.
func set_species(species_id: int) -> void:
	_species_id = species_id
	_show_hp = false
	if is_node_ready():
		_refresh()


func set_hp(current: int, maximum: int) -> void:
	var ring_appears := not _show_hp
	_show_hp = true
	_hp = current
	_max_hp = maximum
	if not is_node_ready():
		_shown_ratio = _ratio()
		return
	if _hp_tween != null:
		_hp_tween.kill()
	_hp_tween = create_tween()
	_hp_tween.tween_property(self, "_shown_ratio", _ratio(), HP_SECONDS)
	_refresh_tint()
	if ring_appears:
		_layout()


func set_selected(on: bool) -> void:
	_selected = on
	if is_node_ready():
		_rings.queue_redraw()


func set_silhouette(on: bool) -> void:
	_silhouette = on
	if is_node_ready():
		_refresh()


func _ratio() -> float:
	return clampf(float(_hp) / _max_hp, 0.0, 1.0) if _max_hp > 0 else 0.0


func _fainted() -> bool:
	return _show_hp and _hp <= 0


func _refresh() -> void:
	_colors.clear()
	_face.texture = null
	_face.material = null
	var species: CreatureSpecies = GameData.get_species(_species_id) if _species_id > 0 else null
	if species != null:
		for element_id: int in species.element_ids:
			_colors.append(GameData.get_element(element_id).color.darkened(FILL_DARKEN))
		# Na sombra, o rosto recortado viraria um disco: o corpo inteiro tem a silhueta.
		var path := FACE_PATH % species.slug
		var whole := _silhouette or not ResourceLoader.exists(path)
		_face.set_meta(&"whole", whole)
		if whole:
			path = CreaturePortrait.SPRITE_PATH % species.slug
		if ResourceLoader.exists(path):
			_face.texture = load(path) as Texture2D
		if _silhouette:
			var shadow := ShaderMaterial.new()
			shadow.shader = SilhouetteShader
			shadow.set_shader_parameter(&"color", UiPalette.SILHOUETTE)
			_face.material = shadow
	_refresh_tint()
	_layout()


func _refresh_tint() -> void:
	_backdrop.modulate = FAINTED_TINT if _fainted() else Color.WHITE
	_backdrop.queue_redraw()
	_rings.queue_redraw()


func _layout() -> void:
	var side := minf(size.x, size.y)
	var inner := _inner_radius(side) * 2.0
	_backdrop.size = Vector2(inner, inner)
	_backdrop.position = (size - _backdrop.size) / 2.0
	var margin := inner * FRONT_MARGIN if _face.get_meta(&"whole", false) else 0.0
	_face.position = Vector2(margin, margin)
	_face.size = _backdrop.size - Vector2(margin, margin) * 2.0
	_backdrop.queue_redraw()
	_rings.size = size
	_rings.queue_redraw()


func _inner_radius(side: float) -> float:
	var radius := side / 2.0 - side * SELECTED_WIDTH
	if _show_hp:
		radius -= side * HP_WIDTH
	return radius


## O fundo redondo: a cor do Elemento ou, com dois, as duas separadas na diagonal.
func _draw_backdrop() -> void:
	var radius := _backdrop.size.x / 2.0
	var center := _backdrop.size / 2.0
	if _colors.is_empty():
		var empty := UiPalette.SURFACE_RAISED
		empty.a = EMPTY_ALPHA
		if _silhouette:
			empty = UiPalette.SURFACE_RAISED
		_backdrop.draw_circle(center, radius, empty, true, -1.0, true)
		return
	var first := _colors[0] if not _silhouette else UiPalette.SURFACE_RAISED
	_backdrop.draw_circle(center, radius, first, true, -1.0, true)
	if _colors.size() > 1 and not _silhouette:
		var half := PackedVector2Array()
		for step: int in ARC_POINTS / 2 + 1:
			var angle := PI / 4.0 + PI * step / (ARC_POINTS / 2.0)
			half.append(center + Vector2(cos(angle), sin(angle)) * radius)
		_backdrop.draw_colored_polygon(half, _colors[1])


## O anel de HP esvazia no sentido horário a partir do topo, sobre o trilho; o de
## selecionado fica por fora dele.
func _draw_rings() -> void:
	var side := minf(_rings.size.x, _rings.size.y)
	var center := _rings.size / 2.0
	var selected_width := side * SELECTED_WIDTH
	if _show_hp and _species_id > 0:
		var width := side * HP_WIDTH
		var radius := side / 2.0 - selected_width - width / 2.0
		_rings.draw_arc(center, radius, 0.0, TAU, ARC_POINTS, UiPalette.TRACK, width, true)
		if _shown_ratio > 0.0 and not _fainted():
			var start := -PI / 2.0
			_rings.draw_arc(center, radius, start, start + TAU * _shown_ratio, ARC_POINTS, _hp_color(), width, true)
	if _selected:
		_rings.draw_arc(center, side / 2.0 - selected_width / 2.0, 0.0, TAU, ARC_POINTS, UiPalette.TEXT, selected_width, true)


func _hp_color() -> Color:
	var colors: Array[Color] = [UiPalette.HP_LOW, UiPalette.HP_ORANGE, UiPalette.HP_HIGH]
	var ratio := _shown_ratio
	if ratio <= HP_STOPS[0]:
		return colors[0]
	for index: int in range(1, HP_STOPS.size()):
		if ratio <= HP_STOPS[index]:
			var weight := (ratio - HP_STOPS[index - 1]) / (HP_STOPS[index] - HP_STOPS[index - 1])
			return colors[index - 1].lerp(colors[index], weight)
	return colors[-1]
