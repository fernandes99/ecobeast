extends SceneTree
## A arte da cidade das ilhas, no estilo de .specs/town-art/style-guide.md, desenhada só
## por código: um PNG por variante, em res://assets/map_objects/<slug>/<variante>.png
## (as peças soltas de PROP_TYPES, em res://assets/props/, free-props/02).
## Da pasta client/: godot --headless -s res://assets/map_objects/make_town.gd [-- <slug>...]
##
## A célula tem a largura do formato, simétrica em volta do ponto de apoio, e o pé dela é
## o canto de baixo da linha da frente.

const OUT := "res://assets/map_objects/%s/%d.png"
## Peças soltas: a imagem acaba no pé, sem as bordas vazias, com o pé no meio.
const PROP_TYPES: Array[String] = ["lamp_post", "sign", "flower_bed", "bench"]
const PROP_OUT := "res://assets/props/%s/%d.png"
const HEX_HALF_WIDTH := 32.0
const CENTER_TO_BOTTOM := 29.0
const CANVAS_HEIGHT := 320
const SHAPES := {
	"one": [Vector2i(0, 0)],
	"pair": [Vector2i(0, 0), Vector2i(1, 0)],
	"triangle": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1)],
}
## slug: formato, quantas variantes e, nos animados, quantos quadros.
const TYPES := {
	"refuge_building": ["triangle", 1],
	"shop_building": ["triangle", 1],
	"town_house": ["one", 9],
	"town_house_medium": ["pair", 12],
	"town_house_large": ["triangle", 10],
	"town_fence": ["one", 2],
	"lamp_post": ["one", 2],
	"sign": ["one", 2],
	"flower_bed": ["one", 3],
	"bench": ["one", 2],
}
## O pé das construções fica acima do canto de baixo da célula, na borda de baixo da linha da frente.
const BASE_LIFT := 6
## O pé dos objetos pequenos fica mais perto do centro do hexágono.
const SMALL_LIFT := 17

## As paletas do guia: claro, base, escuro e contorno.
const ROOF_RED: Array[Color] = [Color("#f8806c"), Color("#e8504c"), Color("#b83438"), Color("#7c2030")]
const ROOF_BLUE: Array[Color] = [Color("#7cb4f8"), Color("#4a8ee8"), Color("#2e66c0"), Color("#1e3f8a")]
const ROOF_ORANGE: Array[Color] = [Color("#f8a058"), Color("#e07838"), Color("#b85428"), Color("#7a3418")]
const ROOF_BROWN: Array[Color] = [Color("#c89870"), Color("#a0704c"), Color("#785034"), Color("#4c3020")]
const ROOF_GREEN: Array[Color] = [Color("#8cd07c"), Color("#58a858"), Color("#3c7c44"), Color("#24502c")]
const ROOF_PURPLE: Array[Color] = [Color("#b490e0"), Color("#8a64c0"), Color("#644496"), Color("#402a64")]
const ROOF_TEAL: Array[Color] = [Color("#78d0c8"), Color("#40a8a0"), Color("#2c7c78"), Color("#1c504e")]
const ROOF_MUSTARD: Array[Color] = [Color("#f0d070"), Color("#d0a840"), Color("#a07c28"), Color("#64481a")]
const BRICK: Array[Color] = [Color("#e08868"), Color("#b05838"), Color("#803c24"), Color("#4c2014")]
const SOIL: Array[Color] = [Color("#c08858"), Color("#9a6838"), Color("#74482a"), Color("#4a2c18")]
const PLASTER: Array[Color] =[Color("#fffaf0"), Color("#f4ecd8"), Color("#d8ccb0"), Color("#5a4a3a")]
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
			var path := OUT % [slug, variant]
			if PROP_TYPES.has(slug):
				var used := art.get_used_rect()
				var middle := floori(art.get_width() / 2.0)
				var half := maxi(middle - used.position.x, used.end.x - middle)
				art = art.get_region(Rect2i(middle - half, 0, half * 2, used.end.y))
				path = PROP_OUT % [slug, variant]
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
			var error := art.save_png(path)
			print("%s/%d: %dx%d %s" % [slug, variant, art.get_width(), art.get_height(), "ok" if error == OK else error_string(error)])
			if slug == "town_fence":
				var parts := _strip_cells(_town_fence_parts(variant))
				error = parts.save_png(HexFences.PARTS_PATH % variant)
				print("town_fence/parts_%d: %dx%d %s" % [variant, parts.get_width(), parts.get_height(), "ok" if error == OK else error_string(error)])
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
func _place_building(building: Image, lift := BASE_LIFT) -> void:
	var foot := Vector2(_image.get_width() / 2.0, CANVAS_HEIGHT - lift)
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


# --- Os objetos de vila da cidade ----------------------------------------------------


func _draw_town_fence(variant: int, _frame: int) -> void:
	var cell := HexFences.compose(_town_fence_parts(variant), 0)
	var at := Vector2i((_centers[0] - HexFences.CELL_CENTER).round())
	_image.blend_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), at)


## As 7 células da Cerca da cidade, no formato da island-villages/05: o poste do centro e
## os braços dos lados 0 a 5. A madeira tem dois trilhos e um poste na ponta; a pedra,
## um muro baixo com um pilar na ponta.
func _town_fence_parts(variant: int) -> Array[Image]:
	var cells: Array[Image] = []
	var center := HexFences.CELL_CENTER
	for index: int in 7:
		var cell := Image.create(HexFences.CELL_SIZE.x, HexFences.CELL_SIZE.y, false, Image.FORMAT_RGBA8)
		if index == 0:
			if variant == 1:
				_fence_post(cell, center)
			else:
				_fence_pillar(cell, center)
		else:
			var end := center + HexFences.EDGE_MIDPOINTS[index - 1]
			if variant == 1:
				_fence_rails(cell, center, end)
				_fence_post(cell, end)
			else:
				_fence_wall(cell, center, end)
				_fence_pillar(cell, end)
		cells.append(cell)
	return cells


static func _fence_post(cell: Image, foot: Vector2) -> void:
	var x := roundi(foot.x) - 2
	var y := roundi(foot.y) + 2
	_fill(cell, Rect2i(x - 1, y - 14, 6, 15), WOOD[3])
	_fill(cell, Rect2i(x, y - 13, 4, 13), WOOD[1])
	_fill(cell, Rect2i(x, y - 13, 1, 13), WOOD[0])
	_fill(cell, Rect2i(x + 3, y - 13, 1, 13), WOOD[2])
	_fill(cell, Rect2i(x, y - 13, 4, 1), WOOD[0])


static func _fence_rails(cell: Image, from: Vector2, to: Vector2) -> void:
	var steps := ceili(from.distance_to(to) * 2.0)
	for rail: int in [-10, -5]:
		for step: int in steps + 1:
			var p := from.lerp(to, step / float(steps)) + Vector2(0, rail)
			var x := roundi(p.x)
			var y := roundi(p.y)
			_dot(cell, x, y - 1, WOOD[3])
			_dot(cell, x, y, WOOD[0])
			_dot(cell, x, y + 1, WOOD[1])
			_dot(cell, x, y + 2, WOOD[3])


static func _fence_pillar(cell: Image, foot: Vector2) -> void:
	var x := roundi(foot.x) - 4
	var y := roundi(foot.y) + 3
	_fill(cell, Rect2i(x - 1, y - 16, 10, 17), STONE[3])
	_fill(cell, Rect2i(x, y - 15, 8, 15), STONE[1])
	_fill(cell, Rect2i(x, y - 15, 1, 15), STONE[0])
	_fill(cell, Rect2i(x + 6, y - 15, 2, 15), STONE[2])
	_fill(cell, Rect2i(x - 1, y - 16, 10, 2), STONE[0])
	_fill(cell, Rect2i(x - 1, y - 14, 10, 1), STONE[2])
	_fill(cell, Rect2i(x, y - 8, 8, 1), STONE[2])


static func _fence_wall(cell: Image, from: Vector2, to: Vector2) -> void:
	var steps := ceili(from.distance_to(to) * 2.0)
	var length := from.distance_to(to)
	for step: int in steps + 1:
		var t := step / float(steps)
		var p := from.lerp(to, t)
		var x := roundi(p.x)
		var base := roundi(p.y) + 2
		var seam := int(t * length) % 7 == 0
		_dot(cell, x, base - 11, STONE[3])
		_dot(cell, x, base - 10, STONE[0])
		for y: int in range(base - 9, base):
			var color := STONE[1]
			if y == base - 5 or seam or y == base - 1:
				color = STONE[2]
			_dot(cell, x, y, color)
		_dot(cell, x, base, STONE[3])


static func _strip_cells(cells: Array[Image]) -> Image:
	var size := cells[0].get_size()
	var strip := Image.create(size.x * cells.size(), size.y, false, Image.FORMAT_RGBA8)
	for index: int in cells.size():
		strip.blit_rect(cells[index], Rect2i(Vector2i.ZERO, size), Vector2i(size.x * index, 0))
	return strip


# --- As decorações de rua ------------------------------------------------------------

## O canteiro fica na metade da frente do hexágono, abaixo do pé do Domador: o objeto é
## desenhado depois dos atores da linha dele e cobriria o Domador.
const BED_LIFT := 12
const BED_FLOWERS: Array = [
	[Color("#f05050"), Color("#f8d040")],
	[Color("#f890c0"), Color("#ffffff")],
	[Color("#f05050"), Color("#f8d040"), Color("#ffffff"), Color("#f890c0")],
]


func _draw_lamp_post(variant: int, _frame: int) -> void:
	var s := Image.create(16, 42, false, Image.FORMAT_RGBA8)
	if variant == 1:
		_fill(s, Rect2i(5, 39, 6, 3), IRON[2])
		_fill(s, Rect2i(5, 39, 6, 1), IRON[0])
		_fill(s, Rect2i(6, 36, 4, 3), IRON[1])
		_fill(s, Rect2i(7, 12, 2, 24), IRON[1])
		_fill(s, Rect2i(7, 12, 1, 24), IRON[0])
		_fill(s, Rect2i(6, 20, 4, 1), IRON[2])
		_fill(s, Rect2i(5, 10, 6, 2), IRON[2])
		_lantern(s, Vector2i(4, 1))
	else:
		_fill(s, Rect2i(2, 38, 8, 4), STONE[1])
		_fill(s, Rect2i(2, 38, 8, 1), STONE[0])
		_fill(s, Rect2i(4, 6, 3, 32), WOOD[1])
		_fill(s, Rect2i(4, 6, 1, 32), WOOD[0])
		_fill(s, Rect2i(6, 6, 1, 32), WOOD[2])
		_fill(s, Rect2i(4, 6, 10, 2), WOOD[1])
		_fill(s, Rect2i(4, 7, 10, 1), WOOD[2])
		_fill(s, Rect2i(11, 8, 1, 2), IRON[2])
		_lantern(s, Vector2i(8, 10))
	_place_building(_outline(s, IRON[3] if variant == 1 else WOOD[3]), SMALL_LIFT)


## A lanterna de 8×10: o chapéu de ferro, o vidro aceso e a base.
static func _lantern(s: Image, at: Vector2i) -> void:
	_fill(s, Rect2i(at.x + 3, at.y, 2, 1), IRON[2])
	_fill(s, Rect2i(at.x + 1, at.y + 1, 6, 2), IRON[2])
	_fill(s, Rect2i(at.x + 1, at.y + 1, 6, 1), IRON[1])
	_fill(s, Rect2i(at.x, at.y + 3, 8, 6), IRON[2])
	_fill(s, Rect2i(at.x + 1, at.y + 3, 6, 5), LAMP)
	_fill(s, Rect2i(at.x + 4, at.y + 3, 1, 5), IRON[2])
	_dot(s, at.x + 2, at.y + 4, LAMP_SHINE)
	_dot(s, at.x + 2, at.y + 5, LAMP_SHINE)
	_fill(s, Rect2i(at.x + 1, at.y + 9, 6, 1), IRON[2])


func _draw_sign(variant: int, _frame: int) -> void:
	var s: Image
	if variant == 1:
		s = Image.create(22, 24, false, Image.FORMAT_RGBA8)
		for x: int in [4, 16]:
			_fill(s, Rect2i(x, 8, 2, 16), WOOD[2])
			_fill(s, Rect2i(x, 8, 1, 16), WOOD[1])
		_fill(s, Rect2i(0, 2, 22, 13), WOOD[1])
		_fill(s, Rect2i(0, 2, 22, 1), WOOD[0])
		_fill(s, Rect2i(0, 14, 22, 1), WOOD[2])
		_fill(s, Rect2i(0, 8, 22, 1), WOOD[2])
		_stamp(s, Vector2i(5, 4), [
			".......D....",
			"DDDDDDDDD...",
			".......D....",
			"............",
			"....D.......",
			"...DDDDDDDDD",
			"....D.......",
		], {"D": WOOD[3]})
		_place_building(_outline(s, WOOD[3]), SMALL_LIFT)
	else:
		s = Image.create(16, 22, false, Image.FORMAT_RGBA8)
		for y: int in 22:
			var inset: int = 0 if y >= 4 else [5, 3, 2, 1][y]
			_fill(s, Rect2i(inset, y, 16 - inset * 2, 1), STONE[1])
			_dot(s, inset, y, STONE[0])
			_dot(s, 15 - inset, y, STONE[2])
			_dot(s, 14 - inset, y, STONE[2])
		_fill(s, Rect2i(0, 19, 16, 3), STONE[2])
		_fill(s, Rect2i(0, 19, 16, 1), STONE[0])
		_stamp(s, Vector2i(3, 6), [
			"....D.....",
			"....DD....",
			"DDDDDDD...",
			"....DD....",
			"....D.....",
			"..........",
			".D.D.D.D..",
		], {"D": STONE[3]})
		_place_building(_outline(s, STONE[3]), SMALL_LIFT)


func _draw_flower_bed(variant: int, _frame: int) -> void:
	var colors: Array = BED_FLOWERS[variant - 1]
	var s := Image.create(44, 14, false, Image.FORMAT_RGBA8)
	_fill(s, Rect2i(1, 6, 42, 5), SOIL[1])
	_fill(s, Rect2i(1, 6, 42, 1), SOIL[0])
	_fill(s, Rect2i(0, 10, 44, 4), BRICK[1])
	_fill(s, Rect2i(0, 10, 44, 1), BRICK[0])
	_fill(s, Rect2i(0, 13, 44, 1), BRICK[2])
	for x: int in range(5, 44, 6):
		_fill(s, Rect2i(x, 11, 1, 2), BRICK[2])
	var index := 0
	for row: int in 2:
		for x: int in range(3 + row * 3, 42, 6):
			var y := 3 + row * 3
			var color: Color = colors[index % colors.size()]
			index += 1
			_dot(s, x - 1, y + 2, LEAF[1])
			_dot(s, x + 1, y + 2, LEAF[2])
			_dot(s, x, y + 3, LEAF[2])
			for d: Vector2i in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
				_dot(s, x + d.x, y + d.y, color)
			_dot(s, x, y, FLOWER_HEART)
	_place_building(_outline(s, BRICK[3]), BED_LIFT)


func _draw_bench(variant: int, _frame: int) -> void:
	var s := Image.create(34, 18, false, Image.FORMAT_RGBA8)
	if variant == 1:
		for x: int in [3, 28]:
			_fill(s, Rect2i(x, 0, 3, 18), IRON[1])
			_fill(s, Rect2i(x, 0, 1, 18), IRON[0])
		for y: int in [1, 5]:
			_fill(s, Rect2i(1, y, 32, 3), WOOD[1])
			_fill(s, Rect2i(1, y, 32, 1), WOOD[0])
			_fill(s, Rect2i(1, y + 2, 32, 1), WOOD[2])
		_fill(s, Rect2i(0, 10, 34, 4), WOOD[0])
		_fill(s, Rect2i(0, 12, 34, 2), WOOD[1])
		_fill(s, Rect2i(0, 13, 34, 1), WOOD[2])
		_place_building(_outline(s, WOOD[3]), SMALL_LIFT)
	else:
		for x: int in [3, 24]:
			_fill(s, Rect2i(x, 12, 7, 6), STONE[1])
			_fill(s, Rect2i(x, 12, 1, 6), STONE[0])
			_fill(s, Rect2i(x + 5, 12, 2, 6), STONE[2])
		_fill(s, Rect2i(0, 7, 34, 5), STONE[0])
		_fill(s, Rect2i(0, 9, 34, 3), STONE[1])
		_fill(s, Rect2i(0, 11, 34, 1), STONE[2])
		_fill(s, Rect2i(16, 9, 1, 2), STONE[2])
		_place_building(_outline(s, STONE[3]), SMALL_LIFT)

