extends SceneTree
## A arte da cidade das ilhas, no estilo de .specs/town-art/style-guide.md, desenhada só
## por código: um PNG por variante, em res://assets/props/<slug>/<variante>.png
## (free-props/02, free-objects/04). As casas da cidade, o prédio da Loja, o poste e a
## placa saíram do jogo (prop-cleanup/01); sobram o canteiro e o banco. A arte das
## paredes sai do assets/walls/make_walls.py, e a do prédio do Refúgio, do
## assets/props/make_refuge_building.py (refuge-art/01).
## Da pasta client/: godot --headless -s res://assets/map_objects/make_town.gd [-- <slug>...]
##
## A célula tem a largura do formato, simétrica em volta do ponto de apoio, e o pé dela é
## o canto de baixo da linha da frente.

const OUT := "res://assets/props/%s/%d.png"
## As decorações de rua: a imagem acaba no pé, sem as bordas vazias, com o pé no meio.
const PROP_TYPES: Array[String] = ["flower_bed", "bench"]
const HEX_HALF_WIDTH := 32.0
const CENTER_TO_BOTTOM := 29.0
const CANVAS_HEIGHT := 320
const SHAPES := {
	"one": [Vector2i(0, 0)],
}
## slug: formato, quantas variantes e, nos animados, quantos quadros.
const TYPES := {
	"flower_bed": ["one", 3],
	"bench": ["one", 2],
}
## O pé das construções fica acima do canto de baixo da célula, na borda de baixo da linha da frente.
const BASE_LIFT := 6
## O pé dos objetos pequenos fica mais perto do centro do hexágono.
const SMALL_LIFT := 17

const BRICK: Array[Color] = [Color("#e08868"), Color("#b05838"), Color("#803c24"), Color("#4c2014")]
const SOIL: Array[Color] = [Color("#c08858"), Color("#9a6838"), Color("#74482a"), Color("#4a2c18")]
const STONE: Array[Color] = [Color("#eceaf2"), Color("#bcbccc"), Color("#84849c"), Color("#56566c")]
const WOOD: Array[Color] = [Color("#e0a868"), Color("#b07840"), Color("#7a4a26"), Color("#3a2414")]
const IRON: Array[Color] = [Color("#7880a0"), Color("#50587a"), Color("#3a4058"), Color("#22263a")]
const LEAF: Array[Color] = [Color("#86d266"), Color("#3f9c48"), Color("#2a7038")]
const FLOWER_HEART := Color("#f8a028")
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
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
			var error := art.save_png(path)
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


# --- As decorações de rua ------------------------------------------------------------

## O canteiro fica na metade da frente do hexágono, abaixo do pé do Domador: o objeto é
## desenhado depois dos atores da linha dele e cobriria o Domador.
const BED_LIFT := 12
const BED_FLOWERS: Array = [
	[Color("#f05050"), Color("#f8d040")],
	[Color("#f890c0"), Color("#ffffff")],
	[Color("#f05050"), Color("#f8d040"), Color("#ffffff"), Color("#f890c0")],
]


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

