extends SceneTree
## A arte da cidade das ilhas, no estilo de .specs/town-art/style-guide.md, desenhada só
## por código: um PNG por variante, em res://assets/map_objects/<slug>/<variante>.png.
## Da pasta client/: godot --headless -s res://assets/map_objects/make_town.gd [-- <slug>...]
##
## A célula tem a largura do formato, simétrica em volta do ponto de apoio, e o pé dela é
## o canto de baixo da linha da frente, como no make_objects.gd.

const OUT := "res://assets/map_objects/%s/%d.png"
const HEX_HALF_WIDTH := 32.0
const CENTER_TO_BOTTOM := 29.0
const CANVAS_HEIGHT := 320
const SHAPES := {
	"one": [Vector2i(0, 0)],
	"pair": [Vector2i(0, 0), Vector2i(1, 0)],
	"triangle": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1)],
	"block": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, -1), Vector2i(2, -1)],
}
## slug: formato, quantas variantes e, nos animados, quantos quadros.
const TYPES := {
	"refuge_building": ["triangle", 1],
	"shop_building": ["triangle", 1],
	"arena_building": ["block", 1],
	"town_house": ["one", 9],
	"town_house_medium": ["pair", 12],
	"town_house_large": ["triangle", 10],
}
## O pé das construções fica acima do canto de baixo da célula, na borda de baixo da linha da frente.
const BASE_LIFT := 6

## As paletas do guia: claro, base, escuro e contorno.
const ROOF_RED: Array[Color] = [Color("#f8806c"), Color("#e8504c"), Color("#b83438"), Color("#7c2030")]
const ROOF_BLUE: Array[Color] = [Color("#7cb4f8"), Color("#4a8ee8"), Color("#2e66c0"), Color("#1e3f8a")]
const ROOF_SLATE: Array[Color] = [Color("#8a96ac"), Color("#5e687e"), Color("#434b5e"), Color("#2a3040")]
const ROOF_ORANGE: Array[Color] = [Color("#f8a058"), Color("#e07838"), Color("#b85428"), Color("#7a3418")]
const ROOF_BROWN: Array[Color] = [Color("#c89870"), Color("#a0704c"), Color("#785034"), Color("#4c3020")]
const ROOF_GREEN: Array[Color] = [Color("#8cd07c"), Color("#58a858"), Color("#3c7c44"), Color("#24502c")]
const ROOF_PURPLE: Array[Color] = [Color("#b490e0"), Color("#8a64c0"), Color("#644496"), Color("#402a64")]
const ROOF_TEAL: Array[Color] = [Color("#78d0c8"), Color("#40a8a0"), Color("#2c7c78"), Color("#1c504e")]
const ROOF_MUSTARD: Array[Color] = [Color("#f0d070"), Color("#d0a840"), Color("#a07c28"), Color("#64481a")]
const BRICK: Array[Color] = [Color("#e08868"), Color("#b05838"), Color("#803c24"), Color("#4c2014")]
const PLASTER: Array[Color] = [Color("#fffaf0"), Color("#f4ecd8"), Color("#d8ccb0"), Color("#5a4a3a")]
const ARENA_STONE: Array[Color] = [Color("#f2eee2"), Color("#dcd6c6"), Color("#b4ac9a"), Color("#2a2e3c")]
const STONE: Array[Color] = [Color("#eceaf2"), Color("#bcbccc"), Color("#84849c"), Color("#56566c")]
const WOOD: Array[Color] = [Color("#e0a868"), Color("#b07840"), Color("#7a4a26"), Color("#3a2414")]
const IRON: Array[Color] = [Color("#7880a0"), Color("#50587a"), Color("#3a4058"), Color("#22263a")]
const BANNER: Array[Color] = [Color("#f8a868"), Color("#f08030"), Color("#c05420")]
const GOLD: Array[Color] = [Color("#fff090"), Color("#f8c838"), Color("#c8901c"), Color("#7a5410")]
const LEAF: Array[Color] = [Color("#86d266"), Color("#3f9c48"), Color("#2a7038")]
const FLOWERS: Array[Color] = [Color("#f05050"), Color("#f8d040"), Color("#ffffff"), Color("#f890c0")]
const FLOWER_HEART := Color("#f8a028")
const GLASS := Color("#6cb8f0")
const GLASS_DARK := Color("#4890d8")
const GLASS_SHINE := Color("#e4f6ff")
const DOOR_GLASS := Color("#a8dcf8")
const DOOR_GLASS_DARK := Color("#78b8e8")
const FRAME := Color("#4a3c34")
const SILL := Color("#fffaf0")
const FOUNDATION := Color("#a8a8b4")
const FOUNDATION_DARK := Color("#80808c")
const WHITE := Color("#ffffff")
const HEART := Color("#e84858")
const HEART_SHINE := Color("#ffc0c8")
const SPROUT := Color("#58c050")
const SPROUT_DARK := Color("#3a9a40")
const CLAW := Color("#b02828")
const LAMP := Color("#ffe070")
const LAMP_SHINE := Color("#fff8c8")
const SHADOW := Color(0.0, 0.0, 0.0, 0.18)

var _image: Image
var _centers: Array[Vector2] = []


func _init() -> void:
	var only := OS.get_cmdline_user_args()
	for slug: String in TYPES:
		if not only.is_empty() and not only.has(slug):
			continue
		var entry: Array = TYPES[slug]
		var frames := int(entry[2]) if entry.size() > 2 else 1
		for variant: int in range(1, int(entry[1]) + 1):
			var images: Array[Image] = []
			for frame: int in frames:
				_begin(SHAPES[entry[0]])
				call("_draw_" + slug, variant, frame)
				images.append(_image)
			var art := _strip(images)
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/map_objects/%s" % slug))
			var error := art.save_png(OUT % [slug, variant])
			print("%s/%d: %dx%d %s" % [slug, variant, art.get_width(), art.get_height(), "ok" if error == OK else error_string(error)])
	quit()


# --- A célula ---------------------------------------------------------------------

func _begin(shape: Array) -> void:
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
	_image = Image.create(width, CANVAS_HEIGHT, false, Image.FORMAT_RGBA8)
	_centers.clear()
	for center: Vector2 in flat:
		_centers.append(Vector2(center.x - pivot_x + width / 2.0, center.y - bottom + CANVAS_HEIGHT))


static func _strip(images: Array[Image]) -> Image:
	var width := images[0].get_width()
	var top := CANVAS_HEIGHT - 1
	for image: Image in images:
		top = mini(top, _top(image))
	var strip := Image.create(width * images.size(), CANVAS_HEIGHT - top, false, Image.FORMAT_RGBA8)
	for index: int in images.size():
		strip.blit_rect(images[index], Rect2i(0, top, width, CANVAS_HEIGHT - top), Vector2i(width * index, 0))
	return strip


static func _top(image: Image) -> int:
	for y: int in image.get_height():
		for x: int in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				return y
	return image.get_height() - 1


## Põe a construção (já com o contorno) no meio da célula, com o pé acima do canto de
## baixo, e a sombra oval no chão por baixo dela.
func _place_building(building: Image) -> void:
	var foot := Vector2(_image.get_width() / 2.0, CANVAS_HEIGHT - BASE_LIFT)
	_shadow(foot + Vector2(2.0, -1.0), Vector2(building.get_width() / 2.0 + 2.0, 4.0))
	var at := Vector2i(roundi(foot.x - building.get_width() / 2.0), roundi(foot.y) - building.get_height())
	_image.blend_rect(building, Rect2i(Vector2i.ZERO, building.get_size()), at)


func _shadow(center: Vector2, radius: Vector2) -> void:
	for y: int in range(floori(center.y - radius.y), ceili(center.y + radius.y)):
		for x: int in range(floori(center.x - radius.x), ceili(center.x + radius.x)):
			var d := Vector2((x + 0.5 - center.x) / radius.x, (y + 0.5 - center.y) / radius.y)
			if d.length_squared() <= 1.0 and x >= 0 and y >= 0 and x < _image.get_width() and y < _image.get_height():
				_image.set_pixel(x, y, _image.get_pixel(x, y).blend(SHADOW))


# --- As peças do guia ----------------------------------------------------------------

static func _dot(s: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < s.get_width() and y < s.get_height():
		s.set_pixel(x, y, color)


static func _fill(s: Image, rect: Rect2i, color: Color) -> void:
	var clipped := rect.intersection(Rect2i(Vector2i.ZERO, s.get_size()))
	if clipped.has_area():
		s.fill_rect(clipped, color)


static func _disc(s: Image, center: Vector2, radius: float, color: Color) -> void:
	for y: int in range(floori(center.y - radius) - 1, ceili(center.y + radius) + 1):
		for x: int in range(floori(center.x - radius) - 1, ceili(center.x + radius) + 1):
			if Vector2(x + 0.5 - center.x, y + 0.5 - center.y).length() <= radius:
				_dot(s, x, y, color)


## Um desenho em texto, uma letra por cor; as letras fora de `colors` ficam vazias.
static func _stamp(s: Image, at: Vector2i, rows: Array, colors: Dictionary) -> void:
	for j: int in rows.size():
		var line: String = rows[j]
		for i: int in line.length():
			if colors.has(line[i]):
				_dot(s, at.x + i, at.y + j, colors[line[i]])


static func _outline(s: Image, color: Color) -> Image:
	var w := s.get_width()
	var h := s.get_height()
	var o := Image.create(w + 2, h + 2, false, Image.FORMAT_RGBA8)
	o.blit_rect(s, Rect2i(0, 0, w, h), Vector2i(1, 1))
	for y: int in h + 2:
		for x: int in w + 2:
			if o.get_pixel(x, y).a > 0.5:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var p := Vector2i(x - 1, y - 1) + d
				if p.x >= 0 and p.y >= 0 and p.x < w and p.y < h and s.get_pixel(p.x, p.y).a > 0.5:
					o.set_pixel(x, y, color)
					break
	return o


## O telhado visto de frente: o terço de cima claro, as 3 linhas de baixo escuras com o
## beiral no contorno, e uma linha de telha a cada 4 px com emendas desencontradas.
static func _roof(s: Image, rect: Rect2i, palette: Array[Color]) -> void:
	var h := rect.size.y
	for j: int in h:
		var color := palette[1]
		if j < h / 3:
			color = palette[0]
		elif j >= h - 3:
			color = palette[2]
		_fill(s, Rect2i(rect.position.x, rect.position.y + j, rect.size.x, 1), color)
	for j: int in range(4, h - 3, 4):
		var line := palette[1] if j < h / 3 else palette[2]
		var y := rect.position.y + j
		_fill(s, Rect2i(rect.position.x, y, rect.size.x, 1), line)
		var offset := (j / 4) % 2 * 4
		for x: int in range(rect.position.x + offset + 2, rect.end.x - 1, 8):
			_dot(s, x, y - 1, line)
			_dot(s, x, y - 2, line)
	_fill(s, Rect2i(rect.position.x, rect.end.y - 1, rect.size.x, 1), palette[3])


## A parede: a luz na esquerda, a sombra na direita e a do beiral em cima, e a fundação.
static func _wall(s: Image, rect: Rect2i, palette: Array[Color]) -> void:
	var x := rect.position.x
	var y := rect.position.y
	var w := rect.size.x
	var h := rect.size.y
	_fill(s, rect, palette[1])
	_fill(s, Rect2i(x, y, 1, h), palette[0])
	_fill(s, Rect2i(x + w - 2, y, 2, h), palette[2])
	_fill(s, Rect2i(x, y, w, 2), palette[2])
	_fill(s, Rect2i(x, y + h - 3, w, 3), FOUNDATION)
	_fill(s, Rect2i(x, y + h - 1, w, 1), FOUNDATION_DARK)
	for i: int in range(x + 3, x + w - 2, 6):
		_dot(s, i, y + h - 2, FOUNDATION_DARK)


static func _window(s: Image, rect: Rect2i, curtains := false) -> void:
	var x := rect.position.x
	var y := rect.position.y
	var w := rect.size.x
	var h := rect.size.y
	_fill(s, rect.grow(1), FRAME)
	_fill(s, rect, GLASS)
	_fill(s, Rect2i(x, y + h - 2, w, 2), GLASS_DARK)
	_dot(s, x + 1, y + 1, GLASS_SHINE)
	_dot(s, x + 2, y + 1, GLASS_SHINE)
	_dot(s, x + 1, y + 2, GLASS_SHINE)
	_fill(s, Rect2i(x + w / 2, y, 1, h), FRAME)
	if curtains:
		for j: int in mini(4, h - 2):
			_dot(s, x + j / 2, y + j, FLOWERS[3])
			_dot(s, x + w - 1 - j / 2, y + j, FLOWERS[3])
	_fill(s, Rect2i(x - 1, y + h + 1, w + 2, 1), SILL)


## Uma porta de vidro, de uma folha ou duas, com a moldura na cor dada.
static func _glass_door(s: Image, rect: Rect2i, frame: Color, leaves: int) -> void:
	_fill(s, rect, frame)
	var inner := rect.grow(-1)
	_fill(s, inner, DOOR_GLASS)
	_fill(s, Rect2i(inner.position.x, inner.end.y - 3, inner.size.x, 3), DOOR_GLASS_DARK)
	var leaf_width := inner.size.x / leaves
	for leaf: int in leaves:
		var lx := inner.position.x + leaf * leaf_width
		if leaf > 0:
			_fill(s, Rect2i(lx, inner.position.y, 1, inner.size.y), frame)
		_dot(s, lx + 2, inner.position.y + 1, GLASS_SHINE)
		_dot(s, lx + 3, inner.position.y + 1, GLASS_SHINE)
		_dot(s, lx + 2, inner.position.y + 2, GLASS_SHINE)
	if leaves == 2:
		_fill(s, Rect2i(inner.position.x + leaf_width - 2, inner.position.y + inner.size.y / 2 - 1, 1, 3), frame)
		_fill(s, Rect2i(inner.position.x + leaf_width + 2, inner.position.y + inner.size.y / 2 - 1, 1, 3), frame)
	else:
		_fill(s, Rect2i(inner.end.x - 3, inner.position.y + inner.size.y / 2 - 1, 1, 3), frame)


## O emblema das construções-chave: o disco branco com o anel no contorno do telhado.
static func _emblem(s: Image, center: Vector2, radius: float, ring: Color) -> void:
	_disc(s, center, radius, ring)
	_disc(s, center, radius - 1.0, WHITE)


static func _flower_box(s: Image, at: Vector2i, width: int) -> void:
	_fill(s, Rect2i(at.x, at.y + 2, width, 3), WOOD[1])
	_fill(s, Rect2i(at.x, at.y + 4, width, 1), WOOD[2])
	_fill(s, Rect2i(at.x, at.y + 1, width, 1), LEAF[1])
	for i: int in range(1, width - 1, 3):
		_dot(s, at.x + i, at.y, FLOWERS[(i / 3) % FLOWERS.size()])
		_dot(s, at.x + i + 1, at.y + 1, LEAF[2])


# --- As construções-chave ----------------------------------------------------------

func _draw_refuge_building(_variant: int, _frame: int) -> void:
	var s := Image.create(112, 80, false, Image.FORMAT_RGBA8)
	_roof(s, Rect2i(0, 0, 112, 34), ROOF_RED)
	_wall(s, Rect2i(3, 34, 106, 46), PLASTER)
	_fill(s, Rect2i(3, 36, 106, 3), ROOF_RED[1])
	_fill(s, Rect2i(3, 36, 106, 1), ROOF_RED[0])
	_fill(s, Rect2i(3, 39, 106, 1), ROOF_RED[2])
	for x: int in [9, 25, 76, 92]:
		_window(s, Rect2i(x, 48, 11, 11))
		_flower_box(s, Vector2i(x - 1, 61), 13)
	_glass_door(s, Rect2i(45, 54, 22, 23), STONE[2], 2)
	_fill(s, Rect2i(40, 47, 32, 4), ROOF_RED[1])
	_fill(s, Rect2i(40, 47, 32, 1), ROOF_RED[0])
	_fill(s, Rect2i(40, 51, 32, 1), ROOF_RED[3])
	for x: int in range(41, 72, 4):
		_dot(s, x, 52, ROOF_RED[2])
	_emblem(s, Vector2(56.0, 19.0), 10.0, ROOF_RED[3])
	_stamp(s, Vector2i(51, 14), [
		".RRR...RRR.",
		"RSSRR.RRRRR",
		"RSRRRRRRRRR",
		"RRRRRRRRRRR",
		"RRRRRRRRRRR",
		".RRRRRRRRR.",
		"..RRRRRRR..",
		"...RRRRR...",
		"....RRR....",
		".....R.....",
	], {"R": HEART, "S": HEART_SHINE})
	_stamp(s, Vector2i(58, 10), [
		"..LLL",
		".LLLD",
		".LDD.",
		"D....",
	], {"L": SPROUT, "D": SPROUT_DARK})
	_place_building(_outline(s, ROOF_RED[3]))


func _draw_shop_building(_variant: int, _frame: int) -> void:
	var s := Image.create(112, 76, false, Image.FORMAT_RGBA8)
	_roof(s, Rect2i(0, 0, 112, 32), ROOF_BLUE)
	_wall(s, Rect2i(3, 32, 106, 44), PLASTER)
	_fill(s, Rect2i(9, 47, 58, 24), FRAME)
	_fill(s, Rect2i(10, 48, 56, 22), DOOR_GLASS)
	_fill(s, Rect2i(10, 67, 56, 3), DOOR_GLASS_DARK)
	var goods: Array[Color] = [FLOWERS[0], GOLD[1], LEAF[1], FLOWERS[3], BANNER[1], ROOF_BLUE[1], FLOWERS[0], GOLD[1], LEAF[1]]
	for shelf: int in 2:
		var y := 57 + shelf * 9
		_fill(s, Rect2i(10, y, 56, 1), WOOD[1])
		_fill(s, Rect2i(10, y + 1, 56, 1), WOOD[2])
		for i: int in goods.size():
			var x := 12 + i * 6 + shelf * 2
			var color := goods[(i + shelf * 4) % goods.size()]
			_fill(s, Rect2i(x, y - 4, 4, 4), color)
			_dot(s, x, y - 4, WHITE)
	for i: int in 64:
		var stripe := ROOF_BLUE[1] if (i / 5) % 2 == 0 else WHITE
		_fill(s, Rect2i(6 + i, 40, 1, 6), stripe)
		if i % 5 in [1, 2, 3]:
			_dot(s, 6 + i, 46, stripe)
	_fill(s, Rect2i(6, 40, 64, 1), ROOF_BLUE[2])
	_glass_door(s, Rect2i(77, 49, 18, 24), ROOF_BLUE[2], 1)
	_fill(s, Rect2i(78, 42, 16, 5), WOOD[1])
	_fill(s, Rect2i(78, 42, 16, 1), WOOD[0])
	_fill(s, Rect2i(78, 46, 16, 1), WOOD[2])
	_disc(s, Vector2(86.0, 44.5), 2.0, GOLD[1])
	_dot(s, 85, 43, GOLD[0])
	_emblem(s, Vector2(56.0, 18.0), 10.0, ROOF_BLUE[3])
	_stamp(s, Vector2i(51, 12), [
		"...D...D...",
		"..D.D.D.D..",
		".OOOOOOOOO.",
		".OLOOOOOOOD",
		".OLOOOOOOOD",
		".OOOOCCCOOD",
		".OOOCYYYCOD",
		".OOOCYGYCOD",
		".OOOCYYYCOD",
		".OOOOCCCOOD",
		"..DDDDDDDD.",
	], {"O": BANNER[1], "L": BANNER[0], "D": BANNER[2], "C": GOLD[2], "Y": GOLD[1], "G": GOLD[0]})
	_place_building(_outline(s, ROOF_BLUE[3]))


func _draw_arena_building(_variant: int, _frame: int) -> void:
	var s := Image.create(176, 106, false, Image.FORMAT_RGBA8)
	for x: int in [4, 171]:
		_fill(s, Rect2i(x, 0, 1, 26), IRON[2])
		var dir := 1 if x < 88 else -1
		for j: int in 6:
			var length := 8 - absi(j - 2) * 2 if j < 5 else 0
			for i: int in maxi(length, 0):
				_dot(s, x + dir * (1 + i), 1 + j, BANNER[1] if j > 0 else BANNER[0])
	_roof(s, Rect2i(0, 22, 176, 24), ROOF_SLATE)
	_fill(s, Rect2i(0, 42, 176, 1), BANNER[1])
	_wall(s, Rect2i(3, 46, 170, 52), ARENA_STONE)
	for row: int in range(0, 6):
		var y := 54 + row * 7
		_fill(s, Rect2i(4, y, 166, 1), ARENA_STONE[2])
		var offset := (row % 2) * 7
		for x: int in range(6 + offset, 170, 14):
			_fill(s, Rect2i(x, y - 6, 1, 6), ARENA_STONE[2])
	for x: int in [12, 40, 129, 157]:
		_fill(s, Rect2i(x - 1, 46, 9, 3), ARENA_STONE[0])
		_fill(s, Rect2i(x - 1, 48, 9, 1), ARENA_STONE[2])
		_fill(s, Rect2i(x, 49, 7, 46), ARENA_STONE[1])
		_fill(s, Rect2i(x, 49, 1, 46), ARENA_STONE[0])
		_fill(s, Rect2i(x + 6, 49, 1, 46), ARENA_STONE[2])
	for x: int in [24, 145]:
		_window(s, Rect2i(x, 58, 8, 13))
	_roof(s, Rect2i(50, 2, 76, 40), ROOF_SLATE)
	_fill(s, Rect2i(50, 38, 76, 1), BANNER[1])
	_shield(s, Vector2i(77, 7))
	_gate(s, Rect2i(72, 60, 32, 37))
	for x: int in [57, 110]:
		_banner(s, Rect2i(x, 50, 9, 24))
	_fill(s, Rect2i(66, 97, 44, 3), STONE[0])
	_fill(s, Rect2i(66, 99, 44, 1), STONE[2])
	_fill(s, Rect2i(62, 100, 52, 3), STONE[1])
	_fill(s, Rect2i(62, 102, 52, 1), STONE[2])
	_fill(s, Rect2i(58, 103, 60, 3), STONE[1])
	_fill(s, Rect2i(58, 105, 60, 1), STONE[3])
	for x: int in [48, 122]:
		_brazier(s, Vector2i(x, 84))
	_place_building(_outline(s, ROOF_SLATE[3]))


## O escudo de ouro com as três marcas de garra, 22×25.
static func _shield(s: Image, at: Vector2i) -> void:
	for y: int in 25:
		var half := 11 if y < 13 else roundi(11.0 * (1.0 - (y - 12) / 13.0))
		for x: int in range(11 - half, 11 + half):
			var color := GOLD[1]
			if y == 0 or x == 11 - half or x == 10 + half:
				color = GOLD[3]
			elif x == 12 - half or y == 1:
				color = GOLD[0]
			elif x == 9 + half or (y >= 13 and x >= 9 + half - 1):
				color = GOLD[2]
			_dot(s, at.x + x, at.y + y, color)
	for k: int in 3:
		for i: int in 12:
			var x := at.x + 9 + k * 4 - i / 2
			var y := at.y + 4 + i
			_dot(s, x, y, CLAW)
			_dot(s, x + 1, y, GOLD[2])


## O portão de madeira em arco, com tábuas, rebites de ouro e a pedra de fecho.
static func _gate(s: Image, rect: Rect2i) -> void:
	var cx := rect.position.x + rect.size.x / 2.0
	var r := rect.size.x / 2.0
	for y: int in range(rect.position.y - 1, rect.end.y):
		for x: int in range(rect.position.x - 1, rect.end.x + 1):
			var dx := x + 0.5 - cx
			var top := rect.position.y + r - sqrt(maxf(r * r - dx * dx, 0.0)) * 0.6
			if y + 0.5 < top - 1.0:
				continue
			var border := x == rect.position.x - 1 or x == rect.end.x or y + 0.5 < top
			var color := ARENA_STONE[3] if border else WOOD[1]
			if not border and (x - rect.position.x) % 4 == 3:
				color = WOOD[2]
			if not border and absf(dx) < 1.0:
				color = WOOD[3]
			_dot(s, x, y, color)
	for y: int in range(rect.position.y + 8, rect.end.y - 2, 7):
		for x: int in range(rect.position.x + 2, rect.end.x - 1, 6):
			_dot(s, x, y, GOLD[1])
	_fill(s, Rect2i(int(cx) - 3, rect.position.y - 6, 6, 5), ARENA_STONE[0])
	_fill(s, Rect2i(int(cx) - 3, rect.position.y - 2, 6, 1), ARENA_STONE[2])
	_dot(s, int(cx) - 3, rect.position.y - 6, ARENA_STONE[3])
	_dot(s, int(cx) + 2, rect.position.y - 6, ARENA_STONE[3])
	_fill(s, Rect2i(int(cx) - 4, rect.position.y + 12, 2, 4), IRON[2])
	_fill(s, Rect2i(int(cx) + 2, rect.position.y + 12, 2, 4), IRON[2])


## O estandarte laranja pendurado na barra de ferro, com a ponta em V e um losango de ouro.
static func _banner(s: Image, rect: Rect2i) -> void:
	_fill(s, Rect2i(rect.position.x - 1, rect.position.y - 1, rect.size.x + 2, 1), IRON[2])
	_fill(s, rect, BANNER[1])
	_fill(s, Rect2i(rect.position.x, rect.position.y, 1, rect.size.y), BANNER[0])
	_fill(s, Rect2i(rect.end.x - 1, rect.position.y, 1, rect.size.y), BANNER[2])
	var mid := rect.position.x + rect.size.x / 2
	for j: int in 4:
		for x: int in range(rect.position.x + j, rect.end.x - j):
			if absi(x - mid) >= j:
				_dot(s, x, rect.end.y + j, BANNER[1])
	_stamp(s, Vector2i(mid - 2, rect.position.y + 6), [
		"..G..",
		".GYG.",
		"GYGYG",
		".GYG.",
		"..G..",
	], {"G": GOLD[1], "Y": GOLD[0]})


## O braseiro de ferro com fogo, ao lado da escada.
static func _brazier(s: Image, at: Vector2i) -> void:
	_fill(s, Rect2i(at.x + 2, at.y + 6, 2, 10), IRON[1])
	_fill(s, Rect2i(at.x + 2, at.y + 6, 1, 10), IRON[0])
	_fill(s, Rect2i(at.x, at.y + 15, 6, 2), IRON[2])
	_fill(s, Rect2i(at.x - 1, at.y + 3, 8, 3), IRON[1])
	_fill(s, Rect2i(at.x - 1, at.y + 3, 8, 1), IRON[0])
	_stamp(s, Vector2i(at.x - 1, at.y - 5), [
		"...F....",
		"..FF.F..",
		".FFOFF..",
		".FOYOFF.",
		"FOYLYOF.",
		"FOYYYOFF",
		".OOYOOO.",
		"..OOOO..",
	], {"F": BANNER[2], "O": BANNER[1], "Y": GOLD[1], "L": LAMP_SHINE})


# --- As casas da cidade --------------------------------------------------------------

const HOUSE_ROOFS: Array = [ROOF_ORANGE, ROOF_GREEN, ROOF_PURPLE]
const MEDIUM_HOUSE_ROOFS: Array = [ROOF_ORANGE, ROOF_BROWN, ROOF_GREEN, ROOF_TEAL]
const LARGE_HOUSE_ROOFS: Array = [ROOF_ORANGE, ROOF_BROWN, ROOF_MUSTARD, ROOF_PURPLE, ROOF_TEAL]
const CLEAR := Color(0.0, 0.0, 0.0, 0.0)


func _draw_town_house(variant: int, _frame: int) -> void:
	var roof: Array[Color] = []
	roof.assign(HOUSE_ROOFS[(variant - 1) / 3])
	var s: Image
	match (variant - 1) % 3:
		0:
			s = Image.create(44, 42, false, Image.FORMAT_RGBA8)
			_hip_roof(s, Rect2i(0, 0, 44, 22), roof, 12)
			_wall(s, Rect2i(3, 22, 38, 20), PLASTER)
			_window(s, Rect2i(8, 27, 9, 7), true)
			_flower_box(s, Vector2i(7, 35), 11)
			_wood_door(s, Rect2i(25, 25, 10, 14))
		1:
			s = Image.create(46, 48, false, Image.FORMAT_RGBA8)
			_chimney(s, Rect2i(32, 0, 6, 12))
			_roof(s, Rect2i(0, 6, 46, 22), roof)
			_wall(s, Rect2i(3, 28, 40, 20), PLASTER)
			_window(s, Rect2i(7, 32, 9, 7))
			_window(s, Rect2i(31, 32, 9, 7))
			_wood_door(s, Rect2i(18, 31, 10, 14))
		_:
			s = Image.create(50, 46, false, Image.FORMAT_RGBA8)
			_hip_roof(s, Rect2i(0, 0, 50, 24), roof, 20)
			_wall(s, Rect2i(3, 24, 44, 22), PLASTER)
			_window(s, Rect2i(8, 30, 10, 8), true)
			_flower_box(s, Vector2i(7, 39), 12)
			_wood_door(s, Rect2i(30, 29, 10, 14))
			_porch(s, Rect2i(25, 26, 20, 17))
	_place_building(_outline(s, roof[3]))


func _draw_town_house_medium(variant: int, _frame: int) -> void:
	var roof: Array[Color] = []
	roof.assign(MEDIUM_HOUSE_ROOFS[(variant - 1) / 3])
	var s: Image
	match (variant - 1) % 3:
		0:
			s = Image.create(100, 56, false, Image.FORMAT_RGBA8)
			_chimney(s, Rect2i(76, 0, 6, 12))
			_roof(s, Rect2i(0, 6, 100, 24), roof)
			_wall(s, Rect2i(3, 30, 94, 26), PLASTER)
			for x: int in [10, 27, 64, 81]:
				_window(s, Rect2i(x, 36, 10, 8), true)
				_flower_box(s, Vector2i(x - 1, 46), 12)
			_wood_door(s, Rect2i(44, 38, 12, 15))
		1:
			s = Image.create(84, 70, false, Image.FORMAT_RGBA8)
			_hip_roof(s, Rect2i(0, 0, 84, 26), roof, 10)
			_wall(s, Rect2i(3, 26, 78, 44), PLASTER)
			_fill(s, Rect2i(3, 46, 78, 2), WOOD[1])
			_fill(s, Rect2i(3, 47, 78, 1), WOOD[2])
			for x: int in [12, 37, 62]:
				_window(s, Rect2i(x, 31, 10, 9), x != 37)
			_railing(s, Rect2i(33, 41, 18, 4))
			for x: int in [12, 62]:
				_window(s, Rect2i(x, 52, 10, 8))
				_flower_box(s, Vector2i(x - 1, 62), 12)
			_wood_door(s, Rect2i(36, 52, 12, 15))
		_:
			s = Image.create(108, 54, false, Image.FORMAT_RGBA8)
			_roof(s, Rect2i(62, 18, 46, 18), WOOD)
			_wall(s, Rect2i(64, 36, 41, 18), WOOD)
			for x: int in range(67, 104, 4):
				_fill(s, Rect2i(x, 38, 1, 13), WOOD[2])
			_fill(s, Rect2i(72, 40, 28, 11), WOOD[3])
			_fill(s, Rect2i(72, 40, 28, 1), WOOD[2])
			_stamp(s, Vector2i(76, 44), [
				"..IIIII.",
				"IIIIIIII",
				"..IJJI..",
				".IIIIII.",
			], {"I": IRON[1], "J": IRON[0]})
			_barrel(s, Vector2i(90, 42))
			_chimney(s, Rect2i(50, 0, 6, 12))
			_roof(s, Rect2i(0, 6, 66, 24), roof)
			_wall(s, Rect2i(3, 30, 60, 24), PLASTER)
			_window(s, Rect2i(9, 36, 10, 8), true)
			_flower_box(s, Vector2i(8, 46), 12)
			_wood_door(s, Rect2i(33, 37, 12, 15))
	_place_building(_outline(s, roof[3]))


func _draw_town_house_large(variant: int, _frame: int) -> void:
	var roof: Array[Color] = []
	roof.assign(LARGE_HOUSE_ROOFS[(variant - 1) / 2])
	var s: Image
	if (variant - 1) % 2 == 0:
		s = Image.create(112, 92, false, Image.FORMAT_RGBA8)
		_chimney(s, Rect2i(92, 16, 6, 14))
		_hip_roof(s, Rect2i(22, 26, 90, 30), roof, 10)
		_wall(s, Rect2i(25, 56, 84, 36), PLASTER)
		for x: int in [40, 88]:
			_window(s, Rect2i(x, 63, 10, 9), true)
			_flower_box(s, Vector2i(x - 1, 74), 12)
		_double_wood_door(s, Rect2i(62, 70, 16, 19))
		_wall(s, Rect2i(5, 26, 30, 66), PLASTER)
		_hip_roof(s, Rect2i(1, 0, 38, 28), roof, 15)
		for y: int in [34, 58]:
			_window(s, Rect2i(15, y, 10, 9), y == 58)
		_fill(s, Rect2i(6, 50, 27, 1), PLASTER[2])
	else:
		s = Image.create(112, 90, false, Image.FORMAT_RGBA8)
		for x: int in [14, 92]:
			_chimney(s, Rect2i(x, 0, 6, 14))
		_roof(s, Rect2i(0, 8, 112, 30), roof)
		_wall(s, Rect2i(3, 38, 106, 52), PLASTER)
		_fill(s, Rect2i(3, 62, 106, 2), WOOD[1])
		_fill(s, Rect2i(3, 63, 106, 1), WOOD[2])
		for x: int in [12, 30, 72, 90]:
			_window(s, Rect2i(x, 44, 10, 9), true)
			_window(s, Rect2i(x, 69, 10, 8))
			_flower_box(s, Vector2i(x - 1, 79), 12)
		_wood_door(s, Rect2i(51, 43, 10, 18))
		_railing(s, Rect2i(44, 54, 24, 7))
		_double_wood_door(s, Rect2i(48, 69, 16, 18))
	_place_building(_outline(s, roof[3]))


## O telhado de quatro águas visto de frente: o de `_roof`, cortado em trapézio, com a
## aresta da esquerda clara e a da direita escura.
static func _hip_roof(s: Image, rect: Rect2i, palette: Array[Color], top_inset: int) -> void:
	_roof(s, rect, palette)
	var h := rect.size.y
	for j: int in h:
		var inset := roundi(top_inset * (1.0 - j / float(h - 1)))
		var y := rect.position.y + j
		_fill(s, Rect2i(rect.position.x, y, inset, 1), CLEAR)
		_fill(s, Rect2i(rect.end.x - inset, y, inset, 1), CLEAR)
		if j < h - 1:
			_dot(s, rect.position.x + inset, y, palette[0])
			_dot(s, rect.end.x - inset - 1, y, palette[2])


static func _chimney(s: Image, rect: Rect2i) -> void:
	_fill(s, rect, BRICK[1])
	_fill(s, Rect2i(rect.position.x, rect.position.y + 2, 1, rect.size.y - 2), BRICK[0])
	_fill(s, Rect2i(rect.end.x - 2, rect.position.y + 2, 2, rect.size.y - 2), BRICK[2])
	_fill(s, Rect2i(rect.position.x - 1, rect.position.y, rect.size.x + 2, 2), BRICK[0])
	_fill(s, Rect2i(rect.position.x - 1, rect.position.y + 1, rect.size.x + 2, 1), BRICK[2])
	for y: int in range(rect.position.y + 5, rect.end.y, 4):
		_fill(s, Rect2i(rect.position.x + 1, y, rect.size.x - 3, 1), BRICK[2])


static func _wood_door(s: Image, rect: Rect2i) -> void:
	_fill(s, rect, WOOD[3])
	var inner := Rect2i(rect.position.x + 1, rect.position.y + 1, rect.size.x - 2, rect.size.y - 1)
	_fill(s, inner, WOOD[1])
	_fill(s, Rect2i(inner.position.x, inner.position.y, inner.size.x, 1), WOOD[0])
	for x: int in range(inner.position.x + 2, inner.end.x - 1, 3):
		_fill(s, Rect2i(x, inner.position.y + 1, 1, inner.size.y - 1), WOOD[2])
	_dot(s, inner.end.x - 2, inner.position.y + inner.size.y / 2, GOLD[1])


static func _double_wood_door(s: Image, rect: Rect2i) -> void:
	_wood_door(s, rect)
	var mid := rect.position.x + rect.size.x / 2
	_fill(s, Rect2i(mid, rect.position.y + 1, 1, rect.size.y - 1), WOOD[3])
	_dot(s, mid - 2, rect.position.y + rect.size.y / 2, GOLD[1])
	_dot(s, mid + 2, rect.position.y + rect.size.y / 2, GOLD[1])


## A varanda: o telhadinho de madeira sobre a porta, com dois esteios e um vaso em cada.
static func _porch(s: Image, rect: Rect2i) -> void:
	_fill(s, Rect2i(rect.position.x, rect.position.y, rect.size.x, 4), WOOD[1])
	_fill(s, Rect2i(rect.position.x, rect.position.y, rect.size.x, 1), WOOD[0])
	_fill(s, Rect2i(rect.position.x, rect.position.y + 3, rect.size.x, 1), WOOD[3])
	for x: int in [rect.position.x + 1, rect.end.x - 3]:
		_fill(s, Rect2i(x, rect.position.y + 4, 2, rect.size.y - 4), WOOD[1])
		_fill(s, Rect2i(x + 1, rect.position.y + 4, 1, rect.size.y - 4), WOOD[2])
		_fill(s, Rect2i(x - 1, rect.end.y - 4, 4, 3), BRICK[1])
		_fill(s, Rect2i(x - 1, rect.end.y - 4, 4, 1), BRICK[0])
		_dot(s, x, rect.end.y - 5, LEAF[1])
		_dot(s, x + 1, rect.end.y - 6, LEAF[0])
		_dot(s, x + 1, rect.end.y - 5, FLOWERS[0])


## O parapeito de madeira de uma sacada, com os balaústres por cima da parede.
static func _railing(s: Image, rect: Rect2i) -> void:
	_fill(s, Rect2i(rect.position.x, rect.position.y, rect.size.x, 1), WOOD[0])
	for x: int in range(rect.position.x, rect.end.x, 3):
		_fill(s, Rect2i(x, rect.position.y + 1, 1, rect.size.y - 2), WOOD[1])
	_fill(s, Rect2i(rect.position.x, rect.end.y - 1, rect.size.x, 1), WOOD[2])


static func _barrel(s: Image, at: Vector2i) -> void:
	_fill(s, Rect2i(at.x, at.y, 7, 9), WOOD[1])
	_fill(s, Rect2i(at.x, at.y, 1, 9), WOOD[0])
	_fill(s, Rect2i(at.x + 5, at.y, 2, 9), WOOD[2])
	_fill(s, Rect2i(at.x, at.y + 2, 7, 1), IRON[1])
	_fill(s, Rect2i(at.x, at.y + 6, 7, 1), IRON[1])
	_fill(s, Rect2i(at.x + 1, at.y, 5, 1), WOOD[0])
