extends SceneTree
## Arte dos objetos das ilhas (.specs/island-villages/03-map-objects.md), montada a partir
## do pacote Sunnyside World, que o dono tem e não fica no repositório: um PNG por
## variante, em res://assets/map_objects/<slug>/<variante>.png. Da pasta client/:
## godot --headless -s res://assets/map_objects/make_objects.gd -- <pasta do pacote>
## (a pasta que tem Sunnyside_World_Assets e Sunnyside_World_Gamemaker).
##
## As casas, o moinho e as barracas vêm do mapa de exemplo do pacote (Room1), já
## montadas peça por peça; a cor do telhado troca de bloco no tileset, que repete as
## mesmas peças em cada cor. A célula tem a largura do formato, simétrica em volta do
## ponto de apoio, e o pé dela é o canto de baixo da linha da frente.

const OUT := "res://assets/map_objects/%s/%d.png"
const HEX_HALF_WIDTH := 32.0
const CENTER_TO_BOTTOM := 29.0
const CANVAS_HEIGHT := 320
const EMPTY_TILE := -2147483648
const SHAPES := {
	"one": [Vector2i(0, 0)],
	"pair": [Vector2i(0, 0), Vector2i(1, 0)],
	"triangle": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1)],
	"diamond": [Vector2i(0, 0), Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, -2)],
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
## slug: formato e quantas variantes.
const TYPES := {
	"house": ["one", 4],
	"farmhouse": ["pair", 4],
	"windmill": ["pair", 3],
	"castle": ["diamond", 1],
	"big_tree": ["triangle", 2],
	"big_rock": ["pair", 1],
	"garden": ["one", 2],
	"fence": ["one", 2],
	"well": ["one", 1],
	"market_stall": ["one", 3],
	"cart": ["one", 1],
	"bridge": ["one", 1],
	"beast_stable": ["pair", 2],
	"treehouse": ["pair", 1],
	"nest": ["one", 1],
	"trough": ["one", 1],
	"rune_shrine": ["one", 1],
}
const OUTLINE := Color8(61, 41, 46)
const WOOD := Color8(196, 120, 76)
const WOOD_LIGHT := Color8(232, 168, 112)
const WOOD_DARK := Color8(140, 80, 56)
const STRAW := Color8(214, 170, 92)
const STRAW_LIGHT := Color8(240, 206, 126)
const STRAW_DARK := Color8(160, 116, 60)
const SHADOW := Color(0.0, 0.0, 0.0, 0.18)

var _pack := ""
var _tileset: Image
var _forest: Image
var _layers: Dictionary = {}
var _assets: Array[Dictionary] = []
var _sprites: Dictionary = {}
var _image: Image
var _centers: Array[Vector2] = []


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
		for variant: int in range(1, int(entry[1]) + 1):
			_begin(SHAPES[entry[0]])
			call("_draw_" + slug, variant)
			var art := _trimmed()
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


## O primeiro quadro de um sprite do GameMaker, com o ponto de origem dele.
func _sprite(name: String) -> Array:
	if not _sprites.has(name):
		var folder := _pack + "/Sunnyside_World_Gamemaker/sprites/" + name
		var data := _yy(folder + "/" + name + ".yy")
		var frame := str(data["frames"][0]["name"])
		var origin := Vector2(data["sequence"]["xorigin"], data["sequence"]["yorigin"])
		_sprites[name] = [_load(folder + "/" + frame + ".png"), origin]
	return _sprites[name]


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
		if color >= 0 and not layer["forest"] and row >= 9 and row < 49 and column >= 15 and column < 36:
			row += (color - (row - 9) / 8) * 8
		var piece := source.get_region(Rect2i((tile % columns) * size, row * size, size, size))
		if value & (1 << 28):
			piece.flip_x()
		if value & (1 << 29):
			piece.flip_y()
		if value & (1 << 30):
			piece.rotate_90(CLOCKWISE)
		image.blend_rect(piece, Rect2i(0, 0, size, size), at)


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


## Corta as linhas vazias de cima; o pé continua embaixo.
func _trimmed() -> Image:
	var top := CANVAS_HEIGHT - 1
	for y: int in CANVAS_HEIGHT:
		for x: int in _image.get_width():
			if _image.get_pixel(x, y).a > 0.0:
				top = y
				break
		if top == y:
			break
	return _image.get_region(Rect2i(0, top, _image.get_width(), CANVAS_HEIGHT - top))


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


# --- Os objetos -------------------------------------------------------------------

const HOUSE_COLORS: Array[int] = [RED, BLUE, GREEN, PURPLE]


func _draw_house(variant: int) -> void:
	_put(_room(Rect2i(809, 410, 47, 54), HOUSE_COLORS[variant - 1], OBJECT_LAYERS, false), _c(0) + Vector2(0, 14))


func _draw_farmhouse(variant: int) -> void:
	_put(_garden_patch(variant % 2 + 1), _c(1) + Vector2(6, 14))
	_put(_room(Rect2i(520, 304, 64, 80), HOUSE_COLORS[variant - 1], OBJECT_LAYERS, false), _c(0) + Vector2(4, 14))


func _draw_windmill(variant: int) -> void:
	_put(_room(Rect2i(1112, 630, 112, 100), [RED, BLUE, ORANGE][variant - 1]), _mid() + Vector2(0, 14))


## O pacote não tem castelo: as torres são o corpo de pedra da torre do moinho grande,
## com o pico do telhado em cima, e na frente o muro com o portão.
func _draw_castle(_variant: int) -> void:
	var source := _room(Rect2i(1160, 16, 48, 192), BLUE, OBJECT_LAYERS, false)
	var peak := source.get_region(Rect2i(0, 0, 48, 18))
	var stone := source.get_region(Rect2i(0, 86, 48, 62))
	var keep := Image.create(48, 18 + 62 * 2, false, Image.FORMAT_RGBA8)
	keep.blend_rect(stone, Rect2i(0, 0, 48, 62), Vector2i(0, 80))
	keep.blend_rect(stone, Rect2i(0, 0, 48, 62), Vector2i(0, 18))
	keep.blend_rect(peak, Rect2i(0, 0, 48, 18), Vector2i.ZERO)
	var tower := Image.create(48, 18 + 62, false, Image.FORMAT_RGBA8)
	tower.blend_rect(stone, Rect2i(0, 0, 48, 62), Vector2i(0, 18))
	tower.blend_rect(peak, Rect2i(0, 0, 48, 18), Vector2i.ZERO)
	_put(keep, _c(3) + Vector2(0, 8))
	_put(tower, _c(1) + Vector2(-4, 12))
	_put(tower, _c(2) + Vector2(4, 12))
	var wall := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	wall.blend_rect(_piece(704, 16, 64, 16), Rect2i(0, 0, 64, 16), Vector2i.ZERO)
	wall.blend_rect(_piece(704, 32, 16, 16), Rect2i(0, 0, 16, 16), Vector2i(0, 16))
	wall.blend_rect(_piece(720, 32, 48, 16), Rect2i(0, 0, 48, 16), Vector2i(16, 16))
	_put(wall, _c(0) + Vector2(0, 8))


func _draw_big_tree(variant: int) -> void:
	var grove := _room(Rect2i(392, 270, 102, 100), -1, ["forest"], false)
	_put(grove if variant == 1 else _autumn(grove), _mid() + Vector2(0, 22))


func _draw_big_rock(_variant: int) -> void:
	_put(_piece(816, 464, 32, 32), _c(1) + Vector2(-2, 8))
	_put(_piece(784, 464, 32, 32), _c(0) + Vector2(10, 12))
	_put(_piece(848, 464, 32, 32), _c(1) + Vector2(16, 16))
	_put(_piece(880, 464, 16, 32), _c(0) + Vector2(-14, 14))


## Um canteiro de terra com 3 x 2 plantas, já crescidas.
func _garden_patch(variant: int) -> Image:
	var crops: Array[String] = ["pumpkin", "cabbage", "cauliflower"]
	if variant != 1:
		crops = ["carrot", "beetroot", "radish"]
	var soil := _element("Crops/soil_00.png")
	var patch := Image.create(48, 40, false, Image.FORMAT_RGBA8)
	for row: int in 2:
		for column: int in 3:
			patch.blend_rect(soil, Rect2i(Vector2i.ZERO, soil.get_size()), Vector2i(column * 16, 8 + row * 16))
	for row: int in 2:
		for column: int in 3:
			var crop := _element("Crops/%s_05.png" % crops[(column + row) % 3])
			patch.blend_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), Vector2i(column * 16, row * 16))
	return patch


func _draw_garden(variant: int) -> void:
	_put(_garden_patch(variant), _c(0) + Vector2(0, 12))


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


func _draw_bridge(_variant: int) -> void:
	var piece := _piece(632, 78, 32, 34)
	piece.rotate_90(CLOCKWISE)
	var bridge := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	bridge.blend_rect(piece, Rect2i(0, 0, 34, 32), Vector2i(0, 0))
	bridge.blend_rect(piece, Rect2i(0, 0, 34, 32), Vector2i(30, 0))
	_put(bridge.get_region(Rect2i(0, 0, 60, 32)), _c(0) + Vector2(0, 14))


func _draw_beast_stable(variant: int) -> void:
	_put(_room(Rect2i(888, 496, 80, 64), [ORANGE, RED][variant - 1], OBJECT_LAYERS, false), _mid() + Vector2(-8, 14))
	_put(_sprite("spr_deco_trough")[0], _c(1) + Vector2(14, 16))


## A casa sobre estacas do mapa de exemplo, com a escada, entre as árvores.
func _draw_treehouse(_variant: int) -> void:
	_put(_room(Rect2i(398, 270, 66, 60), -1, ["forest"], false), _mid() + Vector2(-6, -2))
	_put(_room(Rect2i(36, 400, 64, 112), GREEN, OBJECT_LAYERS, false), _mid() + Vector2(0, 14))
	_put(_sprite("spr_deco_tree_01")[0], _c(1) + Vector2(14, 14))


## O ninho não existe no pacote: palha em anel, desenhada no estilo dele, com ovos.
func _draw_nest(_variant: int) -> void:
	var nest := Image.create(40, 22, false, Image.FORMAT_RGBA8)
	var center := Vector2(20, 13)
	for y: int in nest.get_height():
		for x: int in nest.get_width():
			var d := Vector2((x + 0.5 - center.x) / 19.0, (y + 0.5 - center.y) / 9.0).length()
			if d > 1.0:
				continue
			var color := STRAW
			if d > 0.88:
				color = OUTLINE
			elif d < 0.55 and y < 13:
				color = STRAW_DARK
			elif (x * 7 + y * 3) % 5 == 0:
				color = STRAW_LIGHT
			elif (x * 3 + y * 5) % 7 == 0:
				color = STRAW_DARK
			nest.set_pixel(x, y, color)
	var egg := _element("Crops/egg.png")
	for at: Vector2i in [Vector2i(9, 0), Vector2i(17, -2), Vector2i(23, 1)]:
		nest.blend_rect(egg, Rect2i(Vector2i.ZERO, egg.get_size()), at)
	_shadow(_c(0) + Vector2(0, 12), Vector2(20, 4))
	_put(nest, _c(0) + Vector2(0, 14))


func _draw_trough(_variant: int) -> void:
	_put(_sprite("spr_deco_trough")[0], _c(0) + Vector2(-4, 12))
	_put(_sprite("spr_deco_barrel_water")[0], _c(0) + Vector2(18, 10))


func _draw_rune_shrine(_variant: int) -> void:
	_put(_piece(736, 304, 30, 44), _c(0) + Vector2(0, 12))
	_put(_sprite("spr_deco_ore_bluestone")[0], _c(0) + Vector2(0, -24))
