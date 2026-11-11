extends SceneTree
## Arte provisória dos objetos das ilhas (.specs/island-villages/03-map-objects.md):
## um PNG por variante, em res://assets/map_objects/<slug>/<variante>.png. Da pasta
## client/: godot --headless -s res://assets/map_objects/make_placeholders.gd
##
## A célula tem a largura do formato, simétrica em volta do ponto de apoio (a média
## dos centros dos hexágonos), e o pé dela é o canto de baixo da linha da frente.

const OUT := "res://assets/map_objects/%s/%d.png"
const HEX_HALF_WIDTH := 32.0
const CENTER_TO_BOTTOM := 29.0
const OUTLINE := Color8(40, 30, 28)
const SHAPES := {
	"one": [Vector2i(0, 0)],
	"pair": [Vector2i(0, 0), Vector2i(1, 0)],
	"triangle": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1)],
	"diamond": [Vector2i(0, 0), Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, -2)],
}
const ROOFS: Array[Color] = [Color8(178, 64, 52), Color8(62, 92, 168), Color8(70, 140, 82), Color8(122, 74, 150)]
const WALL := Color8(232, 220, 196)
const WALL_SHADE := Color8(196, 180, 154)
const WOOD := Color8(132, 92, 58)
const WOOD_DARK := Color8(92, 62, 40)
const STONE := Color8(150, 148, 142)
const STONE_DARK := Color8(112, 110, 106)
const LEAF := Color8(78, 150, 64)
const LEAF_LIGHT := Color8(112, 184, 82)
const AUTUMN := Color8(214, 120, 48)
const AUTUMN_LIGHT := Color8(236, 168, 72)
const WINDOW := Color8(150, 196, 226)
const DOOR := Color8(84, 54, 36)
const SOIL := Color8(112, 80, 52)

## slug: formato, altura da célula e as variantes.
const TYPES := {
	"house": ["one", 84, 4],
	"farmhouse": ["pair", 84, 4],
	"windmill": ["pair", 124, 3],
	"castle": ["diamond", 176, 1],
	"big_tree": ["triangle", 136, 2],
	"big_rock": ["pair", 64, 1],
	"garden": ["one", 48, 2],
	"fence": ["one", 44, 2],
	"well": ["one", 68, 1],
	"market_stall": ["one", 70, 3],
	"cart": ["one", 54, 1],
	"bridge": ["one", 46, 1],
	"beast_stable": ["pair", 84, 2],
	"treehouse": ["pair", 136, 1],
	"nest": ["one", 50, 1],
	"trough": ["one", 42, 1],
	"rune_shrine": ["one", 80, 1],
}

var _image: Image
var _centers: Array[Vector2] = []


func _init() -> void:
	for slug: String in TYPES:
		var entry: Array = TYPES[slug]
		for variant: int in range(1, int(entry[2]) + 1):
			var size := _begin(SHAPES[entry[0]], int(entry[1]))
			call("_draw_" + slug, variant)
			_outline()
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/map_objects/%s" % slug))
			var error := _image.save_png(OUT % [slug, variant])
			print("%s/%d: %dx%d %s" % [slug, variant, size.x, size.y, "ok" if error == OK else error_string(error)])
	quit()


func _begin(shape: Array, height: int) -> Vector2i:
	var flat: Array[Vector2] = []
	for offset: Vector2i in shape:
		flat.append(Vector2(64 * offset.x + 32 * offset.y + 32, 42 * offset.y + 29))
	var pivot_x := 0.0
	var bottom := -INF
	var left := INF
	var right := -INF
	for center: Vector2 in flat:
		pivot_x += center.x
		bottom = maxf(bottom, center.y + CENTER_TO_BOTTOM)
		left = minf(left, center.x - HEX_HALF_WIDTH)
		right = maxf(right, center.x + HEX_HALF_WIDTH)
	pivot_x /= flat.size()
	var width := ceili(maxf(pivot_x - left, right - pivot_x) * 2.0)
	_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	_centers.clear()
	for center: Vector2 in flat:
		_centers.append(Vector2(center.x - pivot_x + width / 2.0, center.y - bottom + height))
	return Vector2i(width, height)


## O centro de um hexágono do formato, na célula, na ordem de SHAPES.
func _c(index: int) -> Vector2:
	return _centers[index]


func _mid() -> Vector2:
	var sum := Vector2.ZERO
	for center: Vector2 in _centers:
		sum += center
	return sum / _centers.size()


func _rect(from: Vector2, to: Vector2, color: Color) -> void:
	var a := Vector2i(from.round())
	var b := Vector2i(to.round())
	for y: int in range(mini(a.y, b.y), maxi(a.y, b.y)):
		for x: int in range(mini(a.x, b.x), maxi(a.x, b.x)):
			_put(x, y, color)


func _poly(points: PackedVector2Array, color: Color) -> void:
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for point: Vector2 in points:
		low = low.min(point)
		high = high.max(point)
	for y: int in range(floori(low.y), ceili(high.y) + 1):
		for x: int in range(floori(low.x), ceili(high.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				_put(x, y, color)


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	for y: int in range(floori(center.y - radius.y), ceili(center.y + radius.y) + 1):
		for x: int in range(floori(center.x - radius.x), ceili(center.x + radius.x) + 1):
			var d := Vector2((x + 0.5 - center.x) / radius.x, (y + 0.5 - center.y) / radius.y)
			if d.length_squared() <= 1.0:
				_put(x, y, color)


func _line(from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var along := (to - from).normalized() * 0.5
	var across := Vector2(-along.y, along.x) * width
	_poly(PackedVector2Array([from + across, to + across, to - across, from - across]), color)


func _put(x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < _image.get_width() and y < _image.get_height():
		_image.set_pixel(x, y, color)


## Contorno de 1 px em volta de tudo o que foi desenhado, como a arte do mapa.
func _outline() -> void:
	var copy := _image.duplicate() as Image
	for y: int in _image.get_height():
		for x: int in _image.get_width():
			if copy.get_pixel(x, y).a > 0.0:
				continue
			for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var at := Vector2i(x, y) + offset
				if at.x >= 0 and at.y >= 0 and at.x < copy.get_width() and at.y < copy.get_height() and copy.get_pixelv(at).a > 0.0:
					_image.set_pixel(x, y, OUTLINE)
					break


func _house(base: Vector2, half: float, wall: float, roof_height: float, roof: Color, wall_color: Color = WALL) -> void:
	_rect(base + Vector2(-half, -wall), base + Vector2(half, 0.0), wall_color)
	_rect(base + Vector2(half - 6.0, -wall), base + Vector2(half, 0.0), WALL_SHADE)
	_poly(PackedVector2Array([base + Vector2(-half - 5.0, -wall), base + Vector2(half + 5.0, -wall), base + Vector2(half - 4.0, -wall - roof_height), base + Vector2(-half + 4.0, -wall - roof_height)]), roof)
	_rect(base + Vector2(-half - 5.0, -wall - 3.0), base + Vector2(half + 5.0, -wall), roof.darkened(0.25))
	_rect(base + Vector2(-4.0, -15.0), base + Vector2(4.0, 0.0), DOOR)
	_rect(base + Vector2(-half + 4.0, -wall + 6.0), base + Vector2(-half + 11.0, -wall + 13.0), WINDOW)
	_rect(base + Vector2(half - 13.0, -wall + 6.0), base + Vector2(half - 6.0, -wall + 13.0), WINDOW)


func _tree(base: Vector2, size: float, leaf: Color, light: Color) -> void:
	_rect(base + Vector2(-size * 0.12, -size * 0.9), base + Vector2(size * 0.12, 0.0), WOOD)
	_ellipse(base + Vector2(0.0, -size * 1.15), Vector2(size * 0.75, size * 0.6), leaf)
	_ellipse(base + Vector2(-size * 0.42, -size * 0.85), Vector2(size * 0.42, size * 0.36), leaf)
	_ellipse(base + Vector2(size * 0.42, -size * 0.85), Vector2(size * 0.42, size * 0.36), leaf)
	_ellipse(base + Vector2(-size * 0.2, -size * 1.35), Vector2(size * 0.32, size * 0.24), light)


func _fence_row(from: Vector2, to: Vector2, color: Color) -> void:
	var posts := maxi(2, int(from.distance_to(to) / 9.0))
	for index: int in posts + 1:
		var at := from.lerp(to, float(index) / posts)
		_rect(at + Vector2(-1.5, -12.0), at + Vector2(1.5, 0.0), color)
	_line(from + Vector2(0.0, -9.0), to + Vector2(0.0, -9.0), 2.0, color)
	_line(from + Vector2(0.0, -4.0), to + Vector2(0.0, -4.0), 2.0, color)


func _draw_house(variant: int) -> void:
	_house(_c(0) + Vector2(0.0, 12.0), 20.0, 26.0, 22.0, ROOFS[variant - 1])


func _draw_farmhouse(variant: int) -> void:
	_house(_c(0) + Vector2(4.0, 10.0), 20.0, 26.0, 22.0, ROOFS[variant - 1])
	var garden := _c(1) + Vector2(0.0, 6.0)
	_ellipse(garden, Vector2(22.0, 12.0), SOIL)
	for row: int in 3:
		for column: int in 4:
			_ellipse(garden + Vector2(-13.0 + column * 9.0, -6.0 + row * 6.0), Vector2(2.5, 2.0), LEAF_LIGHT)
	_fence_row(garden + Vector2(-24.0, 12.0), garden + Vector2(24.0, 12.0), WOOD)


func _draw_windmill(variant: int) -> void:
	var tower := _c(0) + Vector2(6.0, 12.0)
	_poly(PackedVector2Array([tower + Vector2(-16.0, 0.0), tower + Vector2(16.0, 0.0), tower + Vector2(11.0, -58.0), tower + Vector2(-11.0, -58.0)]), WALL)
	_poly(PackedVector2Array([tower + Vector2(-15.0, -58.0), tower + Vector2(15.0, -58.0), tower + Vector2(0.0, -80.0)]), [ROOFS[0], Color8(214, 132, 52), ROOFS[2]][variant - 1])
	_rect(tower + Vector2(-4.0, -14.0), tower + Vector2(4.0, 0.0), DOOR)
	var hub := tower + Vector2(0.0, -56.0)
	for angle: float in [PI / 4.0, 3.0 * PI / 4.0, 5.0 * PI / 4.0, 7.0 * PI / 4.0]:
		var tip := hub + Vector2.from_angle(angle) * 36.0
		_line(hub, tip, 3.0, WOOD_DARK)
		_line(hub.lerp(tip, 0.35) + Vector2.from_angle(angle + PI / 2.0) * 4.0, tip + Vector2.from_angle(angle + PI / 2.0) * 4.0, 7.0, WALL_SHADE)
	_ellipse(hub, Vector2(3.0, 3.0), WOOD_DARK)
	_house(_c(1) + Vector2(2.0, 10.0), 14.0, 18.0, 12.0, WOOD)


func _draw_castle(_variant: int) -> void:
	var gate := _c(0) + Vector2(0.0, 14.0)
	var middle := _mid()
	_rect(Vector2(middle.x - 46.0, gate.y - 64.0), Vector2(middle.x + 46.0, gate.y), STONE)
	_rect(Vector2(middle.x + 34.0, gate.y - 64.0), Vector2(middle.x + 46.0, gate.y), STONE_DARK)
	for x: int in range(-46, 46, 12):
		_rect(Vector2(middle.x + x, gate.y - 70.0), Vector2(middle.x + x + 7, gate.y - 64.0), STONE)
	_rect(Vector2(middle.x - 22.0, gate.y - 112.0), Vector2(middle.x + 22.0, gate.y - 60.0), STONE)
	_poly(PackedVector2Array([Vector2(middle.x - 26.0, gate.y - 112.0), Vector2(middle.x + 26.0, gate.y - 112.0), Vector2(middle.x, gate.y - 146.0)]), ROOFS[1])
	for side: float in [-1.0, 1.0]:
		var tower_x := middle.x + side * 46.0
		_rect(Vector2(tower_x - 12.0, gate.y - 92.0), Vector2(tower_x + 12.0, gate.y), STONE)
		_poly(PackedVector2Array([Vector2(tower_x - 15.0, gate.y - 92.0), Vector2(tower_x + 15.0, gate.y - 92.0), Vector2(tower_x, gate.y - 124.0)]), ROOFS[1])
		_rect(Vector2(tower_x - 3.0, gate.y - 76.0), Vector2(tower_x + 3.0, gate.y - 66.0), WINDOW.darkened(0.4))
	_ellipse(gate + Vector2(0.0, -22.0), Vector2(12.0, 12.0), DOOR.darkened(0.3))
	_rect(gate + Vector2(-12.0, -22.0), gate + Vector2(12.0, 0.0), DOOR.darkened(0.3))
	_rect(Vector2(middle.x - 4.0, gate.y - 100.0), Vector2(middle.x + 4.0, gate.y - 90.0), WINDOW)


func _draw_big_tree(variant: int) -> void:
	var leaf := LEAF if variant == 1 else AUTUMN
	var light := LEAF_LIGHT if variant == 1 else AUTUMN_LIGHT
	_tree(_mid() + Vector2(0.0, 22.0), 64.0, leaf, light)


func _draw_big_rock(_variant: int) -> void:
	var middle := _mid() + Vector2(0.0, 12.0)
	_poly(PackedVector2Array([middle + Vector2(-46.0, 0.0), middle + Vector2(-38.0, -26.0), middle + Vector2(-10.0, -40.0), middle + Vector2(22.0, -34.0), middle + Vector2(44.0, -14.0), middle + Vector2(40.0, 0.0)]), STONE)
	_poly(PackedVector2Array([middle + Vector2(8.0, 0.0), middle + Vector2(22.0, -34.0), middle + Vector2(44.0, -14.0), middle + Vector2(40.0, 0.0)]), STONE_DARK)
	_line(middle + Vector2(-20.0, -30.0), middle + Vector2(-8.0, -12.0), 2.0, STONE_DARK)


func _draw_garden(variant: int) -> void:
	var middle := _c(0) + Vector2(0.0, 4.0)
	_ellipse(middle, Vector2(24.0, 13.0), SOIL)
	var plant := LEAF_LIGHT if variant == 1 else Color8(226, 92, 128)
	for row: int in 3:
		for column: int in 4:
			_ellipse(middle + Vector2(-13.0 + column * 9.0, -7.0 + row * 7.0), Vector2(3.0, 2.5), plant)
	_fence_row(middle + Vector2(-26.0, 14.0), middle + Vector2(26.0, 14.0), WOOD)


func _draw_fence(variant: int) -> void:
	var color := WOOD if variant == 1 else STONE
	var middle := _c(0) + Vector2(0.0, 6.0)
	_fence_row(middle + Vector2(-26.0, 4.0), middle + Vector2(26.0, -4.0), color)


func _draw_well(_variant: int) -> void:
	var base := _c(0) + Vector2(0.0, 12.0)
	_rect(base + Vector2(-14.0, -18.0), base + Vector2(14.0, 0.0), STONE)
	_ellipse(base + Vector2(0.0, -18.0), Vector2(14.0, 5.0), STONE_DARK)
	_ellipse(base + Vector2(0.0, -18.0), Vector2(10.0, 3.0), Color8(60, 90, 130))
	_rect(base + Vector2(-13.0, -46.0), base + Vector2(-10.0, -18.0), WOOD)
	_rect(base + Vector2(10.0, -46.0), base + Vector2(13.0, -18.0), WOOD)
	_poly(PackedVector2Array([base + Vector2(-18.0, -44.0), base + Vector2(18.0, -44.0), base + Vector2(0.0, -56.0)]), ROOFS[0])


func _draw_market_stall(variant: int) -> void:
	var base := _c(0) + Vector2(0.0, 12.0)
	var awning: Color = [ROOFS[0], ROOFS[2], ROOFS[1]][variant - 1]
	_rect(base + Vector2(-22.0, -14.0), base + Vector2(22.0, 0.0), WOOD)
	_rect(base + Vector2(-20.0, -40.0), base + Vector2(-17.0, -14.0), WOOD_DARK)
	_rect(base + Vector2(17.0, -40.0), base + Vector2(20.0, -14.0), WOOD_DARK)
	for stripe: int in 6:
		var color := awning if stripe % 2 == 0 else WALL
		_poly(PackedVector2Array([base + Vector2(-26.0 + stripe * 9.0, -40.0), base + Vector2(-17.0 + stripe * 9.0, -40.0), base + Vector2(-14.0 + stripe * 8.0, -54.0), base + Vector2(-20.0 + stripe * 8.0, -54.0)]), color)
	for item: int in 4:
		_ellipse(base + Vector2(-14.0 + item * 9.0, -17.0), Vector2(3.5, 3.0), [AUTUMN_LIGHT, LEAF_LIGHT, ROOFS[0], AUTUMN][item])


func _draw_cart(_variant: int) -> void:
	var base := _c(0) + Vector2(0.0, 10.0)
	_rect(base + Vector2(-20.0, -26.0), base + Vector2(16.0, -10.0), WOOD)
	_rect(base + Vector2(-20.0, -26.0), base + Vector2(16.0, -23.0), WOOD_DARK)
	_line(base + Vector2(16.0, -14.0), base + Vector2(28.0, -6.0), 2.0, WOOD_DARK)
	for x: float in [-12.0, 8.0]:
		_ellipse(base + Vector2(x, -8.0), Vector2(7.0, 7.0), WOOD_DARK)
		_ellipse(base + Vector2(x, -8.0), Vector2(2.0, 2.0), WOOD)
	_ellipse(base + Vector2(-2.0, -28.0), Vector2(14.0, 5.0), AUTUMN_LIGHT)


func _draw_bridge(_variant: int) -> void:
	var middle := _c(0) + Vector2(0.0, 2.0)
	_poly(PackedVector2Array([middle + Vector2(-32.0, 4.0), middle + Vector2(32.0, 4.0), middle + Vector2(28.0, -6.0), middle + Vector2(0.0, -12.0), middle + Vector2(-28.0, -6.0)]), WOOD)
	for x: int in range(-28, 30, 7):
		_line(middle + Vector2(x, -10.0), middle + Vector2(x, 4.0), 1.0, WOOD_DARK)
	_line(middle + Vector2(-30.0, -14.0), middle + Vector2(0.0, -22.0), 2.0, WOOD_DARK)
	_line(middle + Vector2(0.0, -22.0), middle + Vector2(30.0, -14.0), 2.0, WOOD_DARK)


func _draw_beast_stable(variant: int) -> void:
	var middle := _mid() + Vector2(0.0, 12.0)
	var wall := WOOD if variant == 1 else STONE
	_rect(middle + Vector2(-46.0, -30.0), middle + Vector2(46.0, 0.0), wall)
	_rect(middle + Vector2(-34.0, -24.0), middle + Vector2(-6.0, 0.0), WOOD_DARK)
	_rect(middle + Vector2(6.0, -24.0), middle + Vector2(34.0, 0.0), WOOD_DARK)
	_ellipse(middle + Vector2(-20.0, -4.0), Vector2(10.0, 4.0), AUTUMN_LIGHT)
	_ellipse(middle + Vector2(20.0, -4.0), Vector2(10.0, 4.0), AUTUMN_LIGHT)
	_poly(PackedVector2Array([middle + Vector2(-52.0, -30.0), middle + Vector2(52.0, -30.0), middle + Vector2(40.0, -54.0), middle + Vector2(-40.0, -54.0)]), Color8(150, 72, 52))


func _draw_treehouse(_variant: int) -> void:
	var middle := _mid() + Vector2(0.0, 18.0)
	_tree(middle, 58.0, LEAF, LEAF_LIGHT)
	_house(middle + Vector2(0.0, -50.0), 16.0, 16.0, 12.0, ROOFS[2], Color8(196, 160, 112))
	_line(middle + Vector2(10.0, 0.0), middle + Vector2(10.0, -50.0), 2.0, WOOD_DARK)


func _draw_nest(_variant: int) -> void:
	var base := _c(0) + Vector2(0.0, 10.0)
	_ellipse(base + Vector2(0.0, -10.0), Vector2(24.0, 12.0), WOOD)
	_ellipse(base + Vector2(0.0, -14.0), Vector2(17.0, 6.0), WOOD_DARK)
	for x: float in [-8.0, 0.0, 8.0]:
		_ellipse(base + Vector2(x, -18.0), Vector2(5.0, 6.0), Color8(238, 230, 206))
	for index: int in 6:
		var angle := TAU * index / 6.0
		_line(base + Vector2(0.0, -10.0) + Vector2.from_angle(angle) * Vector2(20.0, 9.0), base + Vector2(0.0, -10.0) + Vector2.from_angle(angle + 0.5) * Vector2(27.0, 13.0), 1.0, WOOD_DARK)


func _draw_trough(_variant: int) -> void:
	var base := _c(0) + Vector2(0.0, 10.0)
	_poly(PackedVector2Array([base + Vector2(-24.0, -16.0), base + Vector2(24.0, -16.0), base + Vector2(20.0, 0.0), base + Vector2(-20.0, 0.0)]), WOOD)
	_rect(base + Vector2(-21.0, -16.0), base + Vector2(21.0, -11.0), Color8(80, 140, 196))


func _draw_rune_shrine(_variant: int) -> void:
	var base := _c(0) + Vector2(0.0, 12.0)
	_rect(base + Vector2(-18.0, -8.0), base + Vector2(18.0, 0.0), STONE_DARK)
	_poly(PackedVector2Array([base + Vector2(-11.0, -8.0), base + Vector2(11.0, -8.0), base + Vector2(8.0, -56.0), base + Vector2(0.0, -64.0), base + Vector2(-8.0, -56.0)]), STONE)
	for y: float in [-46.0, -34.0, -22.0]:
		_rect(base + Vector2(-4.0, y), base + Vector2(4.0, y + 3.0), Color8(110, 230, 220))
	_rect(base + Vector2(-1.0, -50.0), base + Vector2(1.0, -16.0), Color8(110, 230, 220))
