class_name StatRadar
extends Control
## Hexágono dos 6 stats (creature-details/02, RF-11 e RF-12). A escala é o maior
## stat da própria criatura: o gráfico mostra o perfil dela, e os números exatos
## ficam em cada ponta. _draw() é o método em que um Control desenha a si mesmo;
## o Godot o chama de novo depois de queue_redraw().

const SIDES := 6
const RINGS := 3
const FILL_ALPHA := 0.35
const RING_WIDTH := 2.0
const SHAPE_WIDTH := 4.0
## Espaço em volta do hexágono para os textos das pontas.
const SIDE_MARGIN := 120.0
const VERTICAL_MARGIN := 72.0
const TEXT_GAP := 14.0
const NAME_SIZE := 20
const VALUE_SIZE := 28
const MARK_SIZE := 14.0
const MARK_GAP := 6.0
const FONT_TYPE := &"BoldLabel"

var _stats := StatBlock.new()
var _increased_slug := ""
var _decreased_slug := ""


## Com Temperamento neutro, os dois slugs ficam vazios.
func set_stats(stats: StatBlock, increased_slug: String, decreased_slug: String) -> void:
	_stats = stats
	_increased_slug = increased_slug
	_decreased_slug = decreased_slug
	queue_redraw()


func _draw() -> void:
	var biggest := _biggest_stat()
	if biggest == 0:
		return
	var center := size / 2.0
	var radius := minf(size.x / 2.0 - SIDE_MARGIN, size.y / 2.0 - VERTICAL_MARGIN)
	draw_colored_polygon(_ring(center, radius), UiPalette.TRACK)
	for ring: int in RINGS:
		_draw_closed(_ring(center, radius * (ring + 1) / RINGS), UiPalette.BORDER, RING_WIDTH)

	var shape := PackedVector2Array()
	for index: int in SIDES:
		var value := _stats.get_value(StatBlock.SLUGS[index])
		shape.append(center + _direction(index) * radius * value / biggest)
	var fill := UiPalette.ACCENT
	fill.a = FILL_ALPHA
	draw_colored_polygon(shape, fill)
	_draw_closed(shape, UiPalette.ACCENT, SHAPE_WIDTH)

	for index: int in SIDES:
		_draw_label(index, center + _direction(index) * radius)


func _biggest_stat() -> int:
	var biggest := 0
	for slug: String in StatBlock.SLUGS:
		biggest = maxi(biggest, _stats.get_value(slug))
	return biggest


## A ponta de cada stat, em sentido horário a partir do topo.
func _direction(index: int) -> Vector2:
	return Vector2.UP.rotated(TAU * index / SIDES)


func _ring(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in SIDES:
		points.append(center + _direction(index) * radius)
	return points


func _draw_closed(points: PackedVector2Array, color: Color, width: float) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, color, width, true)


## Nome curto e valor do stat, do lado de fora da ponta.
func _draw_label(index: int, tip: Vector2) -> void:
	var font := get_theme_font(&"font", FONT_TYPE)
	var slug: String = StatBlock.SLUGS[index]
	var stat_name: String = GameData.get_row("stats", GameData.get_stat_id(slug))["short_name"]
	var value := str(_stats.get_value(slug))
	var color := _value_color(slug)
	var has_mark := slug == _increased_slug or slug == _decreased_slug

	var name_width := font.get_string_size(stat_name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x
	var value_width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, VALUE_SIZE).x
	var value_full_width := value_width + (MARK_GAP + MARK_SIZE if has_mark else 0.0)
	var height := float(NAME_SIZE + VALUE_SIZE)

	var direction := _direction(index)
	var name_x := _aligned_x(tip.x, direction.x, name_width)
	var value_x := _aligned_x(tip.x, direction.x, value_full_width)
	var top := tip.y - height / 2.0
	if is_zero_approx(direction.x):
		top = tip.y - height - TEXT_GAP if direction.y < 0.0 else tip.y + TEXT_GAP
	var name_y := top + NAME_SIZE
	var value_y := name_y + VALUE_SIZE

	draw_string(font, Vector2(name_x, name_y), stat_name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, UiPalette.TEXT_SECONDARY)
	draw_string(font, Vector2(value_x, value_y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, VALUE_SIZE, color)
	if has_mark:
		_draw_mark(Vector2(value_x + value_width + MARK_GAP, value_y - MARK_SIZE), slug == _increased_slug, color)


## À direita do hexágono, o texto começa depois da ponta; à esquerda, termina
## antes dela; em cima e embaixo, fica centrado.
func _aligned_x(tip_x: float, direction_x: float, width: float) -> float:
	if is_zero_approx(direction_x):
		return tip_x - width / 2.0
	if direction_x > 0.0:
		return tip_x + TEXT_GAP
	return tip_x - TEXT_GAP - width


func _value_color(slug: String) -> Color:
	if slug == _increased_slug:
		return UiPalette.HP_HIGH
	if slug == _decreased_slug:
		return UiPalette.WARNING
	return UiPalette.TEXT


## Triângulo para cima no stat aumentado, para baixo no diminuído.
func _draw_mark(corner: Vector2, is_up: bool, color: Color) -> void:
	var tip_y := corner.y if is_up else corner.y + MARK_SIZE
	var base_y := corner.y + MARK_SIZE if is_up else corner.y
	draw_colored_polygon(PackedVector2Array([
		Vector2(corner.x + MARK_SIZE / 2.0, tip_y),
		Vector2(corner.x + MARK_SIZE, base_y),
		Vector2(corner.x, base_y),
	]), color)
