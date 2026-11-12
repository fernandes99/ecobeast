extends SceneTree
## Arte dos objetos das ilhas (.specs/island-villages/03-map-objects.md), montada a partir
## do pacote Sunnyside World, que o dono tem e não fica no repositório: um PNG por
## variante, em res://assets/map_objects/<slug>/<variante>.png. Da pasta client/:
## godot --headless -s res://assets/map_objects/make_objects.gd -- <pasta do pacote>
## (a pasta que tem Sunnyside_World_Assets e Sunnyside_World_Gamemaker).
##
## As casas, o moinho e as barracas vêm do mapa de exemplo do pacote (Room1), já
## montadas peça por peça; a cor do telhado troca de bloco no tileset, que repete as
## mesmas peças em cada cor. As árvores, as pedras e as hortas são compostas com os
## sprites e as peças do pacote. A célula tem a largura do formato, simétrica em volta do
## ponto de apoio, e o pé dela é o canto de baixo da linha da frente. Um objeto animado
## tem os quadros lado a lado no mesmo PNG, cada um com a largura da célula. A
## Vegetação usa as plantas do terreno (HexDecorations): o PNG dela é só a prévia do editor.

const OUT := "res://assets/map_objects/%s/%d.png"
const HEX_HALF_WIDTH := 32.0
const CENTER_TO_BOTTOM := 29.0
const CANVAS_HEIGHT := 320
const EMPTY_TILE := -2147483648
const SHAPES := {
	"one": [Vector2i(0, 0)],
	"pair": [Vector2i(0, 0), Vector2i(1, 0)],
	"triangle": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1)],
}
## Os blocos de cor do tileset, de 8 linhas cada, a partir da linha 9, nas colunas 15 a 35.
const BLUE := 0
const GREEN := 1
const ORANGE := 2
const RED := 3
const PURPLE := 4
const OBJECT_LAYERS: Array[String] = ["building", "walls", "decoration_02", "decoration_03"]
const LAYER_DEPTHS := {"decoration_03": 400.0, "decoration_02": 500.0, "walls": 600.0, "building": 700.0, "forest": 800.0, "decoration_01": 1000.0}
## Sprites do mapa de exemplo que não entram nos recortes: gente, bichos e sombras.
const SKIPPED_SPRITES: Array[String] = [
	"spr_idle", "spr_doing", "spr_carry", "spr_swimming", "spr_attack", "spr_jump", "spr_roll", "spr_mining",
	"spr_watering", "spr_dig", "spr_axe", "spr_run", "spr_reeling", "skeleton_idle", "spr_deco_charactershadow",
	"spr_deco_bird_01", "spr_deco_shadow", "spr_deco_glint_01", "spr_deco_glint_02", "spr_deco_coin",
	"spr_deco_blinking", "chimneysmoke_01", "chimneysmoke_02", "chimneysmoke_04", "spr_deco_chicken_01",
	"spr_deco_sheep_01", "spr_deco_pig_01", "spr_deco_cow", "spr_deco_duck_01", "spr_deco_windmillshadow",
	"spr_deco_windmill_withshadow", "expression_attack", "expression_alerted",
]
## slug: formato, quantas variantes e, nos animados, quantos quadros.
const TYPES := {
	"house": ["one", 9],
	"house_medium": ["pair", 11],
	"house_large": ["triangle", 10],
	"windmill": ["pair", 3, 9],
	"tree": ["one", 8, 4],
	"rock": ["one", 6],
	"garden": ["one", 6],
	"fence": ["one", 2],
	"well": ["one", 1],
	"market_stall": ["one", 3],
	"cart": ["one", 1],
	"beast_stable": ["pair", 2],
	"trough": ["one", 1],
	"rune_shrine": ["one", 4, 4],
	"plants": ["one", 10],
}
const DECORATIONS := "res://assets/terrain/decorations/decorations.png"
const OUTLINE := Color8(61, 41, 46)
const WOOD := Color8(196, 120, 76)
const WOOD_LIGHT := Color8(232, 168, 112)
const WOOD_DARK := Color8(140, 80, 56)
const STRAW := Color8(214, 170, 92)
const STRAW_LIGHT := Color8(240, 206, 126)
const SHADOW := Color(0.0, 0.0, 0.0, 0.18)
const DIRT := Color8(228, 166, 114)
const DIRT_DARK := Color8(190, 124, 82)
const DIRT_SPECK := Color8(206, 140, 94)
const DIRT_LIGHT := Color8(238, 186, 136)
const MOSS := Color8(99, 160, 74)
const MOSS_LIGHT := Color8(140, 196, 92)

var _pack := ""
var _tileset: Image
var _forest: Image
var _layers: Dictionary = {}
var _assets: Array[Dictionary] = []
var _sprites: Dictionary = {}
var _image: Image
var _centers: Array[Vector2] = []
## O quadro que está sendo desenhado: os sprites animados do pacote usam o quadro dele.
var _frame := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or not DirAccess.dir_exists_absolute(args[0] + "/Sunnyside_World_Gamemaker"):
		push_error("Passe a pasta do pacote Sunnyside World depois de --.")
		quit(1)
		return
	_pack = args[0]
	_tileset = _load(_pack + "/Sunnyside_World_Assets/Tileset/spr_tileset_sunnysideworld_16px.png")
	_forest = _load(_pack + "/Sunnyside_World_Assets/Tileset/spr_tileset_sunnysideworld_forest_32px.png")
	_read_room(_pack + "/Sunnyside_World_Gamemaker/rooms/Room1/Room1.yy")
	for slug: String in TYPES:
		var entry: Array = TYPES[slug]
		var frames := int(entry[2]) if entry.size() > 2 else 1
		for variant: int in range(1, int(entry[1]) + 1):
			var images: Array[Image] = []
			for frame: int in frames:
				_frame = frame
				_begin(SHAPES[entry[0]])
				call("_draw_" + slug, variant)
				images.append(_image)
			var art := _strip(images)
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/map_objects/%s" % slug))
			var error := art.save_png(OUT % [slug, variant])
			print("%s/%d: %dx%d %s" % [slug, variant, art.get_width(), art.get_height(), "ok" if error == OK else error_string(error)])
	quit()


# --- O pacote -------------------------------------------------------------------

static func _load(path: String) -> Image:
	var image := Image.load_from_file(path)
	image.convert(Image.FORMAT_RGBA8)
	return image


## Os .yy do GameMaker são JSON com vírgula sobrando antes de } e ].
static func _yy(path: String) -> Dictionary:
	var trailing := RegEx.create_from_string(",(\\s*[}\\]])")
	return JSON.parse_string(trailing.sub(FileAccess.get_file_as_string(path), "$1", true))


func _read_room(path: String) -> void:
	var room := _yy(path)
	for layer: Dictionary in room["layers"]:
		match str(layer["resourceType"]):
			"GMRTileLayer":
				var tiles: Dictionary = layer["tiles"]
				var values: Array = []
				if tiles.has("TileCompressedData"):
					var data: Array = tiles["TileCompressedData"]
					var index := 0
					while index < data.size():
						var count := int(data[index])
						index += 1
						if count < 0:
							for _repeat: int in -count:
								values.append(int(data[index]))
							index += 1
						else:
							for offset: int in count:
								values.append(int(data[index + offset]))
							index += count
				else:
					values = tiles["TileSerialiseData"]
				_layers[str(layer["name"])] = {"forest": str(layer["tilesetId"]["name"]) == "tileset_forest", "w": int(tiles["SerialiseWidth"]), "tiles": values}
			"GMRAssetLayer":
				for asset: Dictionary in layer["assets"]:
					var name := str(asset["spriteId"]["name"])
					if not SKIPPED_SPRITES.has(name):
						asset["depth"] = float(layer["depth"])
						_assets.append(asset)


## O quadro `_frame` de um sprite do GameMaker (o primeiro, num sprite parado), com o
## ponto de origem dele.
func _sprite(name: String) -> Array:
	if not _sprites.has(name):
		var folder := _pack + "/Sunnyside_World_Gamemaker/sprites/" + name
		var data := _yy(folder + "/" + name + ".yy")
		var frames: Array[Image] = []
		for frame: Dictionary in data["frames"]:
			frames.append(_load(folder + "/" + str(frame["name"]) + ".png"))
		var origin := Vector2(data["sequence"]["xorigin"], data["sequence"]["yorigin"])
		_sprites[name] = [frames, origin]
	var frames: Array = _sprites[name][0]
	return [frames[_frame % frames.size()], _sprites[name][1]]


func _element(path: String) -> Image:
	return _load(_pack + "/Sunnyside_World_Assets/Elements/" + path)


## Um recorte do tileset de 16 px, em pixels.
func _piece(x: int, y: int, w: int, h: int) -> Image:
	return _tileset.get_region(Rect2i(x, y, w, h))


## Um retângulo do mapa de exemplo, em pixels, com as camadas pedidas e os sprites.
## `color` troca o bloco de cor das peças de construção.
func _room(rect: Rect2i, color := -1, layers: Array = OBJECT_LAYERS, with_sprites := true) -> Image:
	var image := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	var entries: Array = []
	for name: Variant in layers:
		entries.append([LAYER_DEPTHS[name], str(name)])
	if with_sprites:
		for asset: Dictionary in _assets:
			entries.append([asset["depth"], asset])
	entries.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for entry: Array in entries:
		if entry[1] is String:
			_room_tiles(image, rect, _layers[entry[1]], color)
		else:
			_room_sprite(image, rect, entry[1])
	return image


func _room_tiles(image: Image, rect: Rect2i, layer: Dictionary, color: int) -> void:
	var source := _forest if layer["forest"] else _tileset
	var size := 32 if layer["forest"] else 16
	var columns := source.get_width() / size
	var width: int = layer["w"]
	var tiles: Array = layer["tiles"]
	for index: int in tiles.size():
		var value := int(tiles[index])
		if value == EMPTY_TILE or value == 0:
			continue
		var at := Vector2i((index % width) * size, (index / width) * size) - rect.position
		if at.x <= -size or at.y <= -size or at.x >= rect.size.x or at.y >= rect.size.y:
			continue
		var tile := value & 0x7FFFF
		var row := tile / columns
		var column := tile % columns
		var piece: Image
		if color >= 0 and not layer["forest"] and row >= 9 and row < 49 and column >= 15 and column < 36:
			var block := (row - 9) / 8
			var original := source.get_region(Rect2i(column * size, row * size, size, size))
			piece = source.get_region(Rect2i(column * size, (row + (color - block) * 8) * size, size, size))
			if _opaque(piece) < _opaque(original) * 0.8:
				piece = _hue_shifted(original, block, color)
		else:
			piece = source.get_region(Rect2i(column * size, row * size, size, size))
		if value & (1 << 28):
			piece.flip_x()
		if value & (1 << 29):
			piece.flip_y()
		if value & (1 << 30):
			piece.rotate_90(CLOCKWISE)
		image.blend_rect(piece, Rect2i(0, 0, size, size), at)


const BLOCK_HUES: Array[float] = [0.55, 0.27, 0.07, 0.98, 0.83]


## Algumas peças (a cumeeira da casa grande) só existem num bloco de cor: nos outros,
## a peça é a original com o matiz do telhado trocado, menos saturada.
static func _hue_shifted(piece: Image, from: int, to: int) -> Image:
	var shift := BLOCK_HUES[to] - BLOCK_HUES[from]
	for y: int in piece.get_height():
		for x: int in piece.get_width():
			var color := piece.get_pixel(x, y)
			if color.a > 0.0 and color.s > 0.25 and absf(wrapf(color.h - BLOCK_HUES[from], -0.5, 0.5)) < 0.12:
				piece.set_pixel(x, y, Color.from_hsv(wrapf(color.h + shift, 0.0, 1.0), color.s * 0.7, color.v * 0.95, color.a))
	return piece


static func _opaque(piece: Image) -> int:
	var count := 0
	for y: int in piece.get_height():
		for x: int in piece.get_width():
			if piece.get_pixel(x, y).a > 0.0:
				count += 1
	return count


func _room_sprite(image: Image, rect: Rect2i, asset: Dictionary) -> void:
	var sprite := _sprite(str(asset["spriteId"]["name"]))
	var source: Image = sprite[0]
	var origin: Vector2 = sprite[1]
	var place := Transform2D(deg_to_rad(-float(asset["rotation"])), Vector2(asset["scaleX"], asset["scaleY"]), 0.0, Vector2(asset["x"], asset["y"]) - Vector2(rect.position))
	var inverse := place.affine_inverse()
	var box := Rect2(place * -origin, Vector2.ZERO)
	for corner: Vector2 in [Vector2(source.get_width(), 0.0), Vector2(source.get_size()), Vector2(0.0, source.get_height())]:
		box = box.expand(place * (corner - origin))
	var from := Vector2i(box.position.floor()).max(Vector2i.ZERO)
	var to := Vector2i(box.end.ceil()).min(rect.size)
	for y: int in range(from.y, to.y):
		for x: int in range(from.x, to.x):
			var pixel := Vector2i((inverse * Vector2(x + 0.5, y + 0.5) + origin).floor())
			if pixel.x < 0 or pixel.y < 0 or pixel.x >= source.get_width() or pixel.y >= source.get_height():
				continue
			var color := source.get_pixelv(pixel)
			if color.a > 0.0:
				image.set_pixel(x, y, image.get_pixel(x, y).blend(color))


# --- A célula -------------------------------------------------------------------

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


## Os quadros lado a lado, cortados no mesmo topo (as linhas vazias de cima de todos);
## o pé continua embaixo.
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


## Põe a imagem com o meio dos pixels desenhados em `foot.x` e a borda de baixo em
## `foot.y`: sprites com borda vazia de um lado só ficam centrados.
func _put_centered(image: Image, foot: Vector2) -> void:
	var used := image.get_used_rect()
	var at := Vector2i(roundi(foot.x - used.position.x - used.size.x / 2.0), roundi(foot.y) - image.get_height())
	_image.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), at)


## O centro de um hexágono do formato, na célula, na ordem de SHAPES.
func _c(index: int) -> Vector2:
	return _centers[index]


func _mid() -> Vector2:
	var sum := Vector2.ZERO
	for center: Vector2 in _centers:
		sum += center
	return sum / _centers.size()


## Põe a imagem com o meio da borda de baixo em `foot`.
func _put(image: Image, foot: Vector2) -> void:
	var at := Vector2i(roundi(foot.x - image.get_width() / 2.0), roundi(foot.y) - image.get_height())
	_image.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), at)


## Uma sombra oval no chão, por baixo do que vier depois.
func _shadow(center: Vector2, radius: Vector2) -> void:
	for y: int in range(floori(center.y - radius.y), ceili(center.y + radius.y)):
		for x: int in range(floori(center.x - radius.x), ceili(center.x + radius.x)):
			var d := Vector2((x + 0.5 - center.x) / radius.x, (y + 0.5 - center.y) / radius.y)
			if d.length_squared() <= 1.0 and x >= 0 and y >= 0 and x < _image.get_width() and y < _image.get_height():
				_image.set_pixel(x, y, _image.get_pixel(x, y).blend(SHADOW))


func _dot(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
		image.set_pixel(x, y, color)


func _box(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect.intersection(Rect2i(Vector2i.ZERO, image.get_size())), color)


## Folhas verdes viram outono: o tom vai para o laranja, sem mexer no contorno.
static func _autumn(image: Image) -> Image:
	var result := image.duplicate() as Image
	for y: int in result.get_height():
		for x: int in result.get_width():
			var color := result.get_pixel(x, y)
			if color.a > 0.0 and color.g > color.r * 1.15 and color.g > color.b:
				result.set_pixel(x, y, Color.from_hsv(0.07 + (color.h - 0.33) * 0.3, minf(color.s * 1.1, 1.0), color.v * 1.05, color.a))
	return result


## As folhas verdes ganham a florada: rosa no lugar do verde, sem mexer no contorno.
static func _blossom(image: Image) -> Image:
	var result := image.duplicate() as Image
	for y: int in result.get_height():
		for x: int in result.get_width():
			var color := result.get_pixel(x, y)
			if color.a > 0.0 and color.g > color.r * 1.15 and color.g > color.b:
				result.set_pixel(x, y, Color.from_hsv(0.93, minf(color.s * 0.55, 1.0), minf(color.v * 1.25, 1.0), color.a))
	return result


## Musgo no alto da pedra: os pixels claros de cima ficam verdes.
static func _mossy(image: Image) -> Image:
	var result := image.duplicate() as Image
	var top := result.get_height()
	for y: int in result.get_height():
		for x: int in result.get_width():
			if result.get_pixel(x, y).a > 0.0:
				top = mini(top, y)
	for y: int in result.get_height():
		for x: int in result.get_width():
			var color := result.get_pixel(x, y)
			if color.a < 1.0 or y > top + 10 or color.v < 0.55 or (x * 5 + y * 3) % 7 == 0:
				continue
			result.set_pixel(x, y, MOSS_LIGHT if color.v > 0.75 else MOSS)
	return result


# --- Os objetos -------------------------------------------------------------------

## As casas do mapa de exemplo: o retângulo e a cor do telhado de cada variante.
const HOUSES := [
	[Rect2i(808, 410, 46, 52), RED],
	[Rect2i(488, 426, 48, 60), BLUE],
	[Rect2i(848, 202, 54, 60), GREEN],
	[Rect2i(1128, 422, 46, 40), ORANGE],
	[Rect2i(360, 278, 30, 40), RED],
	[Rect2i(1224, 634, 46, 78), PURPLE],
	[Rect2i(696, 26, 52, 72), ORANGE],
	[Rect2i(648, 230, 30, 88), BLUE],
	[Rect2i(1000, 310, 46, 88), GREEN],
]
const MEDIUM_HOUSES := [
	[Rect2i(872, 0, 62, 62), BLUE],
	[Rect2i(824, 106, 64, 60), GREEN],
	[Rect2i(872, 394, 78, 68), ORANGE],
	[Rect2i(520, 304, 62, 78), RED],
	[Rect2i(216, 424, 78, 86), PURPLE],
	[Rect2i(872, 0, 62, 62), RED],
	[Rect2i(886, 492, 84, 72), ORANGE],
	[Rect2i(278, 534, 80, 60), RED],
	[Rect2i(216, 424, 78, 86), GREEN],
	[Rect2i(36, 400, 64, 112), PURPLE],
	[Rect2i(648, 514, 66, 96), GREEN],
]
const LARGE_HOUSES := [
	[Rect2i(632, 392, 102, 94), BLUE],
	[Rect2i(632, 392, 102, 94), RED],
	[Rect2i(632, 392, 102, 94), GREEN],
	[Rect2i(632, 392, 102, 94), PURPLE],
	[Rect2i(454, 20, 116, 214), ORANGE],
	[Rect2i(632, 392, 102, 94), ORANGE],
	[Rect2i(454, 20, 116, 214), RED],
	[Rect2i(454, 20, 116, 214), BLUE],
	[Rect2i(454, 20, 116, 214), GREEN],
	[Rect2i(454, 20, 116, 214), PURPLE],
]


func _draw_house(variant: int) -> void:
	var house: Array = HOUSES[variant - 1]
	_put(_room(house[0], house[1], OBJECT_LAYERS, false), _c(0) + Vector2(0, 14))


func _draw_house_medium(variant: int) -> void:
	var house: Array = MEDIUM_HOUSES[variant - 1]
	_put(_room(house[0], house[1], OBJECT_LAYERS, false), _mid() + Vector2(0, 14))


func _draw_house_large(variant: int) -> void:
	var house: Array = LARGE_HOUSES[variant - 1]
	_put(_room(house[0], house[1], OBJECT_LAYERS, false), _mid() + Vector2(0, 24))


## O corpo do moinho do mapa de exemplo, sem as pás, e as pás do pacote no quadro da
## vez, com o eixo no mesmo lugar: a de baixo cabe inteira.
func _draw_windmill(variant: int) -> void:
	var body := _room(Rect2i(1112, 630, 112, 122), [RED, BLUE, ORANGE][variant - 1], OBJECT_LAYERS, false)
	var sails: Image = _sprite("spr_deco_windmill")[0]
	body.blend_rect(sails, Rect2i(Vector2i.ZERO, sails.get_size()), Vector2i(1, 8))
	_put(body, _mid() + Vector2(0, 36))


## O primeiro quadro de um sprite, numa cópia que pode ser recolorida.
func _copy(name: String) -> Image:
	return (_sprite(name)[0] as Image).duplicate() as Image


## Uma árvore ou um grupo delas, com a redonda e o pinheiro dos sprites do pacote. O
## outono e a florada recolorem a árvore verde.
func _draw_tree(variant: int) -> void:
	var round_tree := _copy("spr_deco_tree_01")
	var pine := _copy("spr_deco_tree_02")
	var mushrooms := _copy("spr_deco_mushroom_red_01")
	var blue_mushrooms := _copy("spr_deco_mushroom_blue_02")
	var foot := _c(0) + Vector2(0, 14)
	match variant:
		1:
			_put(round_tree, foot)
		2:
			_put(pine, foot)
		3:
			_put(round_tree, foot + Vector2(-9, -7))
			_put(round_tree, foot + Vector2(9, 0))
		4:
			_put(pine, foot + Vector2(-10, -6))
			_put(round_tree, foot + Vector2(8, 0))
		5:
			_put(pine, foot + Vector2(0, -9))
			_put(pine, foot + Vector2(-12, 0))
			_put(pine, foot + Vector2(12, 1))
		6:
			_put(_autumn(round_tree), foot + Vector2(-8, -6))
			_put(_autumn(round_tree), foot + Vector2(9, 0))
		7:
			_put(round_tree, foot + Vector2(-4, -3))
			_put(mushrooms, foot + Vector2(14, 3))
		8:
			_put(_blossom(round_tree), foot + Vector2(-4, -3))
			_put(blue_mushrooms, foot + Vector2(14, 3))


## As pedras do tileset (grande, média, achatada e pequena), sozinhas ou juntas.
func _draw_rock(variant: int) -> void:
	var big := _piece(784, 464, 32, 32)
	var medium := _piece(816, 464, 32, 32)
	var flat := _piece(848, 464, 32, 32)
	var small := _piece(880, 464, 16, 32)
	var foot := _c(0) + Vector2(0, 14)
	match variant:
		1:
			_put(big, foot + Vector2(-2, 0))
			_put(small, foot + Vector2(14, 2))
		2:
			_put(medium, foot + Vector2(-6, 0))
			_put(flat, foot + Vector2(10, 4))
		3:
			_put(medium, foot + Vector2(10, -4))
			_put(big, foot + Vector2(-6, 2))
		4:
			_put(flat, foot)
			_put(small, foot + Vector2(-16, 3))
			_put(small, foot + Vector2(15, 4))
		5:
			_put(_mossy(big), foot + Vector2(-4, 0))
			_put(_mossy(small), foot + Vector2(13, 3))
		6:
			_put(_mossy(medium), foot + Vector2(-8, -2))
			_put(_mossy(flat), foot + Vector2(9, 3))


## As plantas de cada horta, por fileira de trás para a frente, crescidas (04) ou
## crescendo (02 e 03); "" é a cova vazia.
const GARDENS := [
	[["pumpkin_04", "cabbage_04", "pumpkin_04"], ["cabbage_04", "pumpkin_04", "cabbage_04", "pumpkin_04"], ["pumpkin_04", "cabbage_04", "pumpkin_04"]],
	[["carrot_04", "carrot_04", "carrot_04"], ["beetroot_04", "beetroot_04", "beetroot_04", "beetroot_04"], ["radish_04", "radish_04", "radish_04"]],
	[["wheat_04", "wheat_04", "wheat_04"], ["wheat_04", "wheat_04", "wheat_04", "wheat_04"], ["wheat_04", "wheat_04", "wheat_04"]],
	[["sunflower_04", "sunflower_04", "sunflower_04"], ["cauliflower_04", "kale_04", "cauliflower_04", "kale_04"], ["kale_04", "cauliflower_04", "kale_04"]],
	[["parsnip_04", "potato_04", "parsnip_04"], ["potato_04", "parsnip_04", "potato_04", "parsnip_04"], ["parsnip_04", "potato_04", "parsnip_04"]],
	[["cabbage_02", "carrot_03", "beetroot_02"], ["", "radish_02", "kale_03", ""], ["carrot_02", "", "cabbage_03"]],
]


## Um canteiro oval de terra arada, com as covas em fileiras desencontradas e as plantas
## em cima delas.
func _draw_garden(variant: int) -> void:
	var bed := Image.create(60, 40, false, Image.FORMAT_RGBA8)
	var center := Vector2(30, 20)
	var noise := RandomNumberGenerator.new()
	noise.seed = variant * 31
	for y: int in bed.get_height():
		for x: int in bed.get_width():
			var d := Vector2((x + 0.5 - center.x) / 29.5, (y + 0.5 - center.y) / 19.5).length()
			if d > 1.0:
				continue
			var color := DIRT
			if d > 0.93:
				color = DIRT_DARK
			elif y > center.y + 13 and d > 0.82:
				color = DIRT_SPECK
			elif noise.randf() < 0.06:
				color = DIRT_SPECK if noise.randf() < 0.7 else DIRT_LIGHT
			bed.set_pixel(x, y, color)
	var soil := _element("Crops/soil_00.png")
	var rows: Array = GARDENS[variant - 1]
	var holes: Array[Vector2i] = []
	for row: int in rows.size():
		var plants: Array = rows[row]
		for column: int in plants.size():
			var hole := Vector2i(30 - plants.size() * 7 + column * 14 - 1, 6 + row * 10)
			bed.blend_rect(soil, Rect2i(Vector2i.ZERO, soil.get_size()), hole)
			holes.append(hole)
	var bottom := _c(0) + Vector2(0, 16)
	_put(bed, bottom)
	var origin := bottom - Vector2(30, 40)
	var index := 0
	for plants: Array in rows:
		for slug: String in plants:
			var hole := holes[index]
			index += 1
			if not slug.is_empty():
				_put(_element("Crops/%s.png" % slug), origin + Vector2(hole.x + 8, hole.y + 9))


func _draw_fence(variant: int) -> void:
	if variant == 1:
		_put(_piece(612, 32, 57, 16), _c(0) + Vector2(0, 8))
	else:
		_put(_piece(704, 16, 64, 17), _c(0) + Vector2(0, 8))


func _draw_well(_variant: int) -> void:
	_put(_sprite("spr_deco_well_covered")[0], _c(0) + Vector2(0, 10))
	_put(_sprite("spr_deco_bucket")[0], _c(0) + Vector2(16, 12))


func _draw_market_stall(variant: int) -> void:
	var rects: Array[Rect2i] = [Rect2i(536, 456, 48, 44), Rect2i(776, 444, 32, 40), Rect2i(1036, 444, 41, 40)]
	_put(_room(rects[variant - 1]), _c(0) + Vector2(0, 12))


## A carroça não existe no pacote: desenhada no estilo dele, com o contorno escuro.
func _draw_cart(_variant: int) -> void:
	var cart := Image.create(44, 30, false, Image.FORMAT_RGBA8)
	_box(cart, Rect2i(2, 6, 34, 14), OUTLINE)
	_box(cart, Rect2i(3, 7, 32, 12), WOOD)
	_box(cart, Rect2i(3, 7, 32, 2), WOOD_LIGHT)
	for x: int in [11, 19, 27]:
		_box(cart, Rect2i(x, 9, 1, 10), WOOD_DARK)
	_box(cart, Rect2i(36, 14, 8, 2), OUTLINE)
	for wheel: Vector2i in [Vector2i(10, 22), Vector2i(28, 22)]:
		for y: int in range(-7, 8):
			for x: int in range(-7, 8):
				var d := Vector2(x, y).length()
				if d <= 6.5:
					_dot(cart, wheel.x + x, wheel.y + y, OUTLINE if d > 5.0 or d < 1.5 else (WOOD_DARK if (x == 0 or y == 0) else Color(0, 0, 0, 0)))
	var crate := _sprite("spr_deco_crate_02")[0] as Image
	cart.blend_rect(crate, Rect2i(Vector2i.ZERO, crate.get_size()), Vector2i(6, 6 - crate.get_height() + 4))
	var hay := Image.create(16, 8, false, Image.FORMAT_RGBA8)
	_box(hay, Rect2i(1, 1, 14, 7), OUTLINE)
	_box(hay, Rect2i(2, 2, 12, 5), STRAW)
	_box(hay, Rect2i(2, 2, 12, 1), STRAW_LIGHT)
	cart.blend_rect(hay, Rect2i(0, 0, 16, 8), Vector2i(19, 0))
	_shadow(_c(0) + Vector2(0, 12), Vector2(20, 4))
	_put(cart, _c(0) + Vector2(0, 14))


func _draw_beast_stable(variant: int) -> void:
	_put(_room(Rect2i(888, 496, 80, 64), [ORANGE, RED][variant - 1], OBJECT_LAYERS, false), _mid() + Vector2(-8, 14))
	_put(_sprite("spr_deco_trough")[0], _c(1) + Vector2(14, 16))


func _draw_trough(_variant: int) -> void:
	_put(_sprite("spr_deco_trough")[0], _c(0) + Vector2(-4, 12))
	_put(_sprite("spr_deco_barrel_water")[0], _c(0) + Vector2(18, 10))


const SHRINE_ORES: Array[String] = ["spr_deco_ore_bluestone", "spr_deco_ore_gold", "spr_deco_ore_silver", "spr_deco_ore_coal"]


## O pilar do tileset com um minério em cima, os dois centrados, e um brilho que pisca.
func _draw_rune_shrine(variant: int) -> void:
	var foot := _c(0) + Vector2(0, 12)
	_put_centered(_piece(736, 304, 30, 44), foot)
	var ore: Image = _sprite(SHRINE_ORES[variant - 1])[0]
	var ore_foot := foot + Vector2(0, -36)
	_put_centered(ore, ore_foot)
	var used := ore.get_used_rect()
	var glint: Image = _sprite("spr_deco_glint_02")[0]
	_put_centered(glint, ore_foot + Vector2(used.size.x / 2.0 - 2.0, -used.size.y + 4.0))


## A prévia da Vegetação no editor: as plantas do terreno que o objeto põe no hexágono
## (0, 0). No mapa, elas saem do HexMapView, com o vento.
func _draw_plants(variant: int) -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(DECORATIONS))
	sheet.convert(Image.FORMAT_RGBA8)
	var decorations := HexDecorations.decorations_of_object(Vector2i.ZERO, variant, false)
	decorations.sort_custom(func(a: HexDecorations.Decoration, b: HexDecorations.Decoration) -> bool: return a.offset.y < b.offset.y)
	for decoration: HexDecorations.Decoration in decorations:
		var cell := Vector2i(decoration.column, HexDecorations.KIND_ROWS[decoration.kind]) * HexDecorations.CELL_SIZE
		var piece := sheet.get_region(Rect2i(cell, HexDecorations.CELL_SIZE))
		if decoration.flipped:
			piece.flip_x()
		var at := Vector2i(_c(0)) + decoration.offset - HexDecorations.CELL_BASE
		_image.blend_rect(piece, Rect2i(Vector2i.ZERO, piece.get_size()), at)
