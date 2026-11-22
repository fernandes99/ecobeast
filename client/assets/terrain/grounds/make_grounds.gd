extends SceneTree
## Texturas provisórias de chão das ilhas (.specs/island-villages/02-grounds.md e
## .specs/free-trails/01-ground-types.md), em
## pixel art: poucos tons por textura, sem degradê, 512x512 e emendando nas quatro
## bordas. Da pasta client/:
## godot --headless -s res://assets/terrain/grounds/make_grounds.gd

const SIZE := 512
const OUT := "res://assets/terrain/grounds/%s.png"
const BAYER: Array[float] = [0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0]

const DIRT_TRAIL: Array[Color] = [
	Color8(104, 74, 48), Color8(132, 98, 64), Color8(152, 116, 76), Color8(170, 134, 90), Color8(190, 156, 108),
]
const DIRT_FLOOR: Array[Color] = [
	Color8(122, 92, 62), Color8(152, 120, 82), Color8(170, 138, 96), Color8(186, 154, 110), Color8(204, 174, 128),
]
const PEBBLES: Array[Color] = [Color8(86, 78, 70), Color8(132, 124, 112), Color8(166, 158, 144), Color8(198, 190, 176)]
const STONE_TRAIL: Array[Color] = [
	Color8(74, 64, 56), Color8(118, 110, 100), Color8(144, 136, 122), Color8(166, 158, 142), Color8(188, 180, 164), Color8(212, 206, 190),
]
const COBBLE_FLOOR: Array[Color] = [
	Color8(70, 64, 60), Color8(110, 106, 102), Color8(132, 128, 122), Color8(152, 148, 140), Color8(172, 168, 160), Color8(198, 194, 186),
]
const GRAVEL_BED: Array[Color] = [
	Color8(84, 78, 72), Color8(112, 104, 94), Color8(128, 120, 108), Color8(142, 134, 120), Color8(164, 156, 142),
]
const GRAVEL: Array[Color] = [Color8(78, 74, 70), Color8(118, 114, 108), Color8(150, 146, 138), Color8(184, 180, 170), Color8(210, 204, 192)]
const STEPPING_STONES: Array[Color] = [
	Color8(66, 62, 58), Color8(112, 108, 100), Color8(134, 130, 120), Color8(152, 148, 136), Color8(170, 166, 152), Color8(200, 196, 182),
]
const SAND: Array[Color] = [
	Color8(170, 146, 102), Color8(204, 182, 132), Color8(216, 196, 146), Color8(226, 208, 160), Color8(238, 224, 182),
]
const GRASS: Array[Color] = [Color8(58, 104, 46), Color8(86, 140, 58), Color8(124, 172, 72)]
const WOOD: Array[Color] = [
	Color8(66, 42, 28), Color8(108, 72, 44), Color8(134, 92, 56), Color8(158, 112, 68), Color8(184, 138, 88),
]
const NAIL := Color8(54, 50, 52)
const BRICK: Array[Color] = [
	Color8(168, 156, 136), Color8(124, 52, 38), Color8(148, 66, 46), Color8(170, 82, 56), Color8(196, 108, 76),
]
const FLAGSTONE: Array[Color] = [
	Color8(92, 84, 74), Color8(146, 136, 118), Color8(164, 154, 134), Color8(182, 172, 150), Color8(206, 198, 176),
]
const MARBLE: Array[Color] = [
	Color8(168, 166, 170), Color8(206, 204, 208), Color8(222, 220, 224), Color8(234, 232, 236), Color8(248, 247, 250),
]
const VEIN := Color8(150, 148, 156)
const MOSSY_STONE: Array[Color] = [
	Color8(58, 60, 50), Color8(104, 106, 94), Color8(126, 128, 114), Color8(146, 148, 132), Color8(166, 168, 150), Color8(190, 192, 174),
]
const MOSS: Array[Color] = [Color8(50, 76, 36), Color8(72, 104, 44), Color8(100, 132, 56)]
const BASALT: Array[Color] = [
	Color8(82, 32, 26), Color8(40, 38, 42), Color8(52, 50, 54), Color8(62, 60, 64), Color8(74, 72, 76), Color8(98, 96, 100),
]
const CRACK := Color8(26, 24, 28)
const SHELLS: Array[Array] = [
	[Color8(196, 184, 164), Color8(226, 218, 204), Color8(246, 242, 232)],
	[Color8(196, 138, 128), Color8(226, 170, 160), Color8(244, 202, 192)],
	[Color8(170, 140, 104), Color8(204, 178, 142), Color8(228, 206, 172)],
]
const SOIL: Array[Color] = [
	Color8(58, 38, 26), Color8(84, 56, 36), Color8(108, 74, 46), Color8(132, 94, 60), Color8(156, 116, 76),
]
const STRAW: Array[Color] = [
	Color8(140, 102, 40), Color8(178, 138, 58), Color8(204, 166, 78), Color8(226, 194, 104), Color8(244, 222, 144),
]
const MUD: Array[Color] = [
	Color8(52, 38, 28), Color8(72, 54, 38), Color8(86, 66, 46), Color8(100, 78, 54), Color8(120, 96, 68),
]
const PUDDLE: Array[Color] = [Color8(66, 74, 80), Color8(92, 102, 110), Color8(136, 150, 158)]
const LEAVES: Array[Array] = [
	[Color8(140, 56, 24), Color8(196, 92, 34), Color8(232, 138, 52)],
	[Color8(92, 56, 32), Color8(128, 82, 46), Color8(162, 112, 62)],
	[Color8(160, 118, 28), Color8(210, 166, 46), Color8(238, 204, 90)],
	[Color8(124, 40, 30), Color8(168, 60, 40), Color8(204, 92, 60)],
]
const SNOW: Array[Color] = [
	Color8(150, 170, 198), Color8(196, 212, 232), Color8(216, 228, 242), Color8(232, 240, 250), Color8(250, 252, 255),
]
## Nos seixos: o contorno, a sombra, o corpo, o claro e o brilho.
const BLUE_COBBLE: Array[Color] = [
	Color8(92, 92, 128), Color8(118, 132, 176), Color8(138, 156, 200), Color8(160, 178, 218), Color8(186, 202, 232),
]
const COBBLE_JOINT := Color8(112, 96, 104)
const PALE_COBBLE: Array[Color] = [
	Color8(176, 136, 122), Color8(222, 206, 190), Color8(236, 224, 208), Color8(246, 238, 226), Color8(254, 250, 242),
]
const PALE_JOINT := Color8(190, 150, 136)
const RIVER_STONES: Array = [
	[Color8(70, 70, 76), Color8(110, 112, 118), Color8(136, 138, 142), Color8(162, 164, 166), Color8(192, 194, 194)],
	[Color8(80, 68, 58), Color8(124, 108, 92), Color8(150, 134, 114), Color8(174, 158, 136), Color8(200, 186, 164)],
	[Color8(66, 74, 84), Color8(104, 116, 130), Color8(128, 140, 154), Color8(152, 164, 176), Color8(182, 192, 202)],
]
const SLABS: Array[Color] = [
	Color8(82, 78, 72), Color8(130, 126, 116), Color8(152, 148, 136), Color8(172, 168, 154), Color8(196, 192, 178),
]
const STONE_SHADOW := Color8(46, 56, 40)
const CRACKED: Array[Color] = [
	Color8(104, 58, 34), Color8(148, 86, 48), Color8(166, 100, 56), Color8(182, 116, 66), Color8(198, 134, 82),
]
## Nas fiadas: a junta, a sombra, o corpo (1 a 3) e o brilho.
const SANDSTONE: Array[Color] = [
	Color8(184, 124, 84), Color8(210, 168, 112), Color8(224, 186, 128), Color8(234, 200, 144), Color8(246, 220, 168),
]
const SLATE: Array[Color] = [
	Color8(70, 64, 60), Color8(108, 104, 98), Color8(124, 120, 112), Color8(140, 136, 126), Color8(166, 162, 150),
]


func _init() -> void:
	_save("dirt_trail", _dirt(11, DIRT_TRAIL, 0.006, 420, 300))
	_save("dirt_floor", _dirt(23, DIRT_FLOOR, 0.008, 160, 120))
	_save("stone_trail", _stones(31, 46, 0.95, STONE_TRAIL))
	_save("cobble_floor", _stones(47, 40, 0.35, COBBLE_FLOOR))
	_save("gravel_trail", _gravel(53))
	_save("stepping_stones", _stones(61, 26, 0.8, STEPPING_STONES, 2.2))
	_save("sand_trail", _dirt(67, SAND, 0.005, 40, 520))
	_save("worn_trail", _worn(71))
	_save("wood_planks", _planks(101))
	_save("brick_floor", _masonry(103, 16, 8, 8, BRICK, 1, 3))
	_save("flagstone_floor", _masonry(107, 16, 16, 8, FLAGSTONE, 1, 3))
	_save("marble_floor", _marble(109))
	_save("mossy_trail", _mossy(113))
	_save("basalt_floor", _basalt(127))
	_save("shell_trail", _shells(131))
	_save("tilled_soil", _tilled(137))
	_save("straw_floor", _straw(139))
	_save("mud_trail", _mud(149))
	_save("leaf_trail", _leaves(151))
	_save("snow_trail", _snow(157))
	_save("blue_cobble_trail", _cobbles(163, 36, [BLUE_COBBLE], COBBLE_JOINT, 1.25, 1.45, 1.0))
	_save("cracked_earth_trail", _cracked(167))
	_save("sandstone_trail", _courses(173, 8, 10, 22, SANDSTONE))
	_save("slate_trail", _courses(179, 8, 14, 32, SLATE))
	_save("pale_cobble_trail", _cobbles(181, 50, [PALE_COBBLE], PALE_JOINT, 1.25, 1.45, 1.0))
	_save("river_stones", _cobbles(191, 30, RIVER_STONES, Color.TRANSPARENT, 0.55, 1.0, 0.75))
	_save("loose_slabs", _cobbles(193, 22, [SLABS], Color.TRANSPARENT, 0.85, 1.15, 0.9, true))
	_save("pebble_scatter", _cobbles(197, 52, RIVER_STONES, Color.TRANSPARENT, 0.45, 0.8, 0.75))
	quit()


func _save(name_of_file: String, image: Image) -> void:
	var error := image.save_png(OUT % name_of_file)
	print("%s: %s" % [name_of_file, "ok" if error == OK else error_string(error)])


func _noise(seed_value: int, frequency: float, octaves: int) -> Image:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	return noise.get_seamless_image(SIZE, SIZE)


func _dither(x: int, y: int) -> float:
	return (BAYER[(y % 4) * 4 + x % 4] + 0.5) / 16.0 - 0.5


## Tons 1 a 3 pelas manchas grandes, com a passagem pontilhada; o 0 e o 4 são o grão
## solto e os montinhos claros.
func _dirt(seed_value: int, tones: Array[Color], frequency: float, pebble_count: int, speck_count: int) -> Image:
	var broad := _noise(seed_value, frequency, 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		for x: int in SIZE:
			var value := broad.get_pixel(x, y).r * 1.4 - 0.2 + _dither(x, y) * 0.12
			var tone := 1 if value < 0.36 else (2 if value < 0.62 else 3)
			var roll := rng.randf()
			if roll < 0.035:
				tone -= 1
			elif roll < 0.055:
				tone += 1
			image.set_pixel(x, y, tones[clampi(tone, 0, 4)])
	for _index: int in speck_count:
		var at := Vector2i(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1))
		if rng.randf() < 0.5:
			for offset: Vector2i in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				_put(image, at + offset, tones[4])
		else:
			_put(image, at, tones[0])
			_put(image, at + Vector2i(1, 0), tones[0])
			_put(image, at + Vector2i(1, 1), tones[1])
	for _index: int in pebble_count:
		var at := Vector2i(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1))
		_pebble(image, at, rng.randi_range(1, 3), rng.randi_range(1, 2), tones[0])
	return image


## Uma pedrinha de `width` x `height` + 1 pixels: clara em cima à esquerda, escura
## embaixo, com a sombra de um pixel no chão, à direita e embaixo.
func _pebble(image: Image, at: Vector2i, width: int, height: int, shadow: Color) -> void:
	for dy: int in height + 1:
		for dx: int in width + 1:
			if (dx == 0 or dx == width) and (dy == 0 or dy == height) and width > 1 and height > 1:
				continue
			var tone := 2
			if dy == 0 or dx == 0:
				tone = 3
			if dy == height:
				tone = 1
			_put(image, at + Vector2i(dx, dy), PEBBLES[tone])
		_put(image, at + Vector2i(width + 1, dy), shadow)
	for dx: int in range(1, width + 1):
		_put(image, at + Vector2i(dx, height + 1), shadow)


func _put(image: Image, at: Vector2i, color: Color) -> void:
	image.set_pixel(posmod(at.x, SIZE), posmod(at.y, SIZE), color)


## Pedras de um Voronoi que se repete nas bordas (`count` x `count` pontos). Tons:
## 0 é a junta; 1 a 4 o corpo da pedra (sorteado por pedra, com grão); 5 o brilho da
## borda de cima e da esquerda. A borda de baixo e da direita escurece um tom.
## Com `gap`, a junta mais larga que ele fica transparente: a grama aparece entre as
## pedras (os Pisantes, free-trails/01).
func _stones(seed_value: int, count: int, jitter: float, tones: Array[Color], gap := 0.0) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var points := PackedVector2Array()
	var bodies := PackedInt32Array()
	for gy: int in count:
		for gx: int in count:
			points.append(Vector2(gx + 0.5 + (rng.randf() - 0.5) * jitter, gy + 0.5 + (rng.randf() - 0.5) * jitter))
			bodies.append(rng.randi_range(2, 4) if rng.randf() < 0.85 else 1)
	var stain := _noise(seed_value + 2, 0.02, 2)
	var cell := float(SIZE) / count
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		for x: int in SIZE:
			var at := Vector2(x + 0.5, y + 0.5) / cell
			var cell_x := floori(at.x)
			var cell_y := floori(at.y)
			var near: Array[Vector2] = []
			var near_index: Array[int] = []
			for dy: int in range(-2, 3):
				for dx: int in range(-2, 3):
					var gx := cell_x + dx
					var gy := cell_y + dy
					var index := posmod(gy, count) * count + posmod(gx, count)
					near.append((points[index] + Vector2(gx - posmod(gx, count), gy - posmod(gy, count))) * cell)
					near_index.append(index)
			var pixel := Vector2(x + 0.5, y + 0.5)
			var best := 0
			for index: int in near.size():
				if pixel.distance_squared_to(near[index]) < pixel.distance_squared_to(near[best]):
					best = index
			var edge := INF
			var toward := Vector2.ZERO
			for index: int in near.size():
				if index == best:
					continue
				var span := near[index] - near[best]
				var distance := (pixel.distance_squared_to(near[index]) - pixel.distance_squared_to(near[best])) / (2.0 * span.length())
				if distance < edge:
					edge = distance
					toward = span.normalized()
			var tone := bodies[near_index[best]]
			if stain.get_pixel(x, y).r + _dither(x, y) * 0.1 > 0.62:
				tone = mini(tone + 1, 4)
			if rng.randf() < 0.05:
				tone = clampi(tone + (1 if rng.randf() < 0.5 else -1), 1, 4)
			if edge < gap:
				image.set_pixel(x, y, Color.TRANSPARENT)
				continue
			if edge < gap + 0.75:
				tone = 0
			elif edge < gap + 1.75:
				var light := toward.x + toward.y * 1.4
				if light < -0.4:
					tone = 5
				elif light > 0.4:
					tone = maxi(tone - 1, 1)
			image.set_pixel(x, y, tones[tone])
	return image


## Terra cinza coberta de pedrinhas soltas, claras e escuras.
func _gravel(seed_value: int) -> Image:
	var image := _dirt(seed_value, GRAVEL_BED, 0.012, 0, 200)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 1
	for _index: int in 15000:
		var at := Vector2i(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1))
		var body := rng.randi_range(1, 3)
		var width := rng.randi_range(1, 3)
		var height := rng.randi_range(1, 2)
		for dy: int in height + 1:
			for dx: int in width + 1:
				var tone := body
				if dy == 0 and dx < width:
					tone = body + 1
				elif dy == height and dx > 0:
					tone = body - 1
				_put(image, at + Vector2i(dx, dy), GRAVEL[clampi(tone, 0, 4)])
		_put(image, at + Vector2i(width + 1, height), GRAVEL_BED[0])
	return image


## A terra da trilha com tufos de grama no meio: cada tufo é um leque de 3 a 5 folhas.
func _worn(seed_value: int) -> Image:
	var image := _dirt(seed_value, DIRT_TRAIL, 0.007, 260, 260)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 1
	var patches := _noise(seed_value + 3, 0.018, 2)
	for _index: int in 2600:
		var at := Vector2i(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1))
		if patches.get_pixel(at.x, at.y).r < 0.48:
			continue
		for blade: int in rng.randi_range(3, 5):
			var lean := blade - 2
			var length := rng.randi_range(3, 6)
			for step: int in length:
				var tone := 2 if step >= length - 2 else (1 if step > 0 else 0)
				var tip := at + Vector2i(lean * step / 2, -step)
				_put(image, tip, GRASS[tone])
				if step == 0:
					_put(image, tip + Vector2i(1, 0), GRASS[0])
		for dx: int in range(-2, 3):
			_put(image, at + Vector2i(dx, 1), DIRT_TRAIL[0])
	return image


## Tábuas horizontais de 8 px (7 de tábua e a fresta), de comprimentos sorteados, com o
## brilho em cima, a sombra embaixo, o veio e um par de pregos na ponta de cada tábua.
func _planks(seed_value: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for row: int in SIZE / 8:
		var top := row * 8
		var start := rng.randi_range(0, SIZE - 1)
		var done := 0
		while done < SIZE:
			var length := rng.randi_range(28, 72)
			if SIZE - done - length < 20:
				length = SIZE - done
			var body := rng.randi_range(1, 3)
			for dx: int in length:
				for dy: int in 8:
					var tone := body
					if dy == 7 or dx == 0:
						tone = 0
					elif dy == 0:
						tone = mini(body + 1, 4)
					elif dy == 6:
						tone = maxi(body - 1, 1)
					_put(image, Vector2i(start + done + dx, top + dy), WOOD[tone])
			for _grain: int in rng.randi_range(1, 3):
				var grain_y := top + rng.randi_range(2, 5)
				var grain_x := rng.randi_range(4, maxi(4, length - 14))
				for dx: int in rng.randi_range(5, 14):
					_put(image, Vector2i(start + done + grain_x + dx, grain_y), WOOD[maxi(body - 1, 1)])
			for end_x: int in [2, length - 3]:
				_put(image, Vector2i(start + done + end_x, top + 2), NAIL)
				_put(image, Vector2i(start + done + end_x, top + 5), NAIL)
			done += length
	return image


## Blocos em fiadas desencontradas (`width` x `height`, com a junta de 1 px). Tons: 0 a
## junta; `low` a `high` o corpo, sorteado por bloco; o de cima o brilho da borda de cima
## e da esquerda; a borda de baixo e da direita escurece um tom.
func _masonry(seed_value: int, width: int, height: int, shift: int, tones: Array[Color], low: int, high: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var stain := _noise(seed_value + 2, 0.02, 2)
	var columns := SIZE / width
	var bodies := PackedInt32Array()
	for _index: int in columns * (SIZE / height):
		bodies.append(rng.randi_range(low, high))
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		var row := y / height
		var local_y := y % height
		for x: int in SIZE:
			var shifted := posmod(x + (row % 2) * shift, SIZE)
			var local_x := shifted % width
			var body := bodies[row * columns + shifted / width]
			if stain.get_pixel(x, y).r + _dither(x, y) * 0.1 > 0.64:
				body = mini(body + 1, high)
			if rng.randf() < 0.04:
				body = clampi(body + (1 if rng.randf() < 0.5 else -1), low, high)
			var tone := body
			var corner := (local_x == 1 or local_x == width - 1) and (local_y == 1 or local_y == height - 1)
			if local_x == 0 or local_y == 0 or corner:
				tone = 0
			elif local_y == 1 or local_x == 1:
				tone = high + 1
			elif local_y == height - 1 or local_x == width - 1:
				tone = maxi(body - 1, low)
			image.set_pixel(x, y, tones[tone])
	return image


## Placas de 32x32 com os veios finos de dois ruídos.
func _marble(seed_value: int) -> Image:
	var image := _masonry(seed_value, 32, 32, 0, MARBLE, 1, 3)
	var veins := _noise(seed_value + 5, 0.012, 3)
	var thin := _noise(seed_value + 7, 0.03, 2)
	for y: int in SIZE:
		for x: int in SIZE:
			if image.get_pixel(x, y) == MARBLE[0]:
				continue
			if absf(veins.get_pixel(x, y).r - 0.5) < 0.012:
				image.set_pixel(x, y, VEIN)
			elif absf(thin.get_pixel(x, y).r - 0.5) < 0.008:
				image.set_pixel(x, y, MARBLE[1])
	return image


## As pedras da trilha de pedra, esverdeadas, com o musgo em manchas: por cima delas no
## miolo da mancha e só nas juntas na borda dela.
func _mossy(seed_value: int) -> Image:
	var image := _stones(seed_value, 42, 0.95, MOSSY_STONE)
	var patches := _noise(seed_value + 3, 0.016, 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 1
	for y: int in SIZE:
		for x: int in SIZE:
			var value := patches.get_pixel(x, y).r + _dither(x, y) * 0.16
			var joint := image.get_pixel(x, y) == MOSSY_STONE[0]
			if value > 0.64:
				image.set_pixel(x, y, MOSS[2] if rng.randf() < 0.3 else MOSS[1])
			elif value > 0.6:
				image.set_pixel(x, y, MOSS[1])
			elif value > 0.5 and joint:
				image.set_pixel(x, y, MOSS[0])
	return image


## Placas grandes de basalto, com a junta vermelho-escura e rachaduras finas dentro.
func _basalt(seed_value: int) -> Image:
	var image := _stones(seed_value, 18, 0.9, BASALT)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 1
	for _index: int in 520:
		var at := Vector2(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1))
		var heading := rng.randf() * TAU
		for _step: int in rng.randi_range(6, 16):
			_put(image, Vector2i(at.round()), CRACK)
			heading += (rng.randf() - 0.5) * 1.2
			at += Vector2.from_angle(heading)
	return image


## A areia batida coberta de conchinhas: um leque de 3 a 5 px com as costelas mais
## escuras, ou uma concha redonda, com a sombra na areia embaixo.
func _shells(seed_value: int) -> Image:
	var image := _dirt(seed_value, SAND, 0.005, 0, 300)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 1
	for _index: int in 1700:
		var at := Vector2i(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1))
		var tones: Array = SHELLS[rng.randi_range(0, SHELLS.size() - 1)]
		var width := rng.randi_range(3, 5)
		var fan := rng.randf() < 0.6
		for dy: int in 3:
			for dx: int in width:
				if dy == 0 and (dx == 0 or dx == width - 1):
					continue
				if not fan and dy == 2 and (dx == 0 or dx == width - 1):
					continue
				var tone := 2 if dy == 0 else 1
				if fan and dx % 2 == 1 and dy > 0:
					tone = 0
				_put(image, at + Vector2i(dx, dy), tones[tone])
		for dx: int in range(1, width):
			_put(image, at + Vector2i(dx, 3), SAND[0])
	return image


## Fileiras de 16 px: o sulco escuro, a subida, a leira clara com o brilho em cima e a
## descida, com a linha da leira ondulando 1 px e torrões soltos.
func _tilled(seed_value: int) -> Image:
	var wobble := _noise(seed_value, 0.01, 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var bands: Array[int] = [0, 0, 1, 1, 2, 4, 3, 3, 3, 3, 2, 2, 2, 2, 1, 1]
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		for x: int in SIZE:
			var bend := 1 if wobble.get_pixel(x, y).r + _dither(x, y) * 0.06 > 0.55 else 0
			var tone := bands[posmod(y + bend, bands.size())]
			if tone > 0 and rng.randf() < 0.02:
				tone = clampi(tone + (1 if rng.randf() < 0.5 else -1), 1, 4)
			image.set_pixel(x, y, SOIL[tone])
	for _index: int in 500:
		var at := Vector2i(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1))
		_put(image, at, SOIL[4])
		_put(image, at + Vector2i(1, 0), SOIL[3])
		_put(image, at + Vector2i(0, 1), SOIL[1])
		_put(image, at + Vector2i(1, 1), SOIL[0])
	return image


## Fios de palha de 4 a 9 px em várias direções, os claros por cima dos escuros, sobre a
## palha amassada do fundo.
func _straw(seed_value: int) -> Image:
	var image := _dirt(seed_value, STRAW, 0.02, 0, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 1
	for layer: int in 3:
		for _index: int in 6000:
			var at := Vector2(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1))
			var turn := PI / 2.0 if rng.randf() < 0.35 else 0.0
			var heading := Vector2.from_angle(rng.randf_range(-0.9, 0.9) + turn)
			var length := rng.randi_range(4, 9)
			var tone := mini(layer + 1 + (1 if rng.randf() < 0.3 else 0), 4)
			for step: int in length:
				var pixel := Vector2i((at + heading * step).round())
				_put(image, pixel, STRAW[tone])
				if step == length - 1:
					_put(image, pixel + Vector2i(0, 1), STRAW[0])
	return image


## Terra úmida escura, com poças cinza-azuladas de borda escura e brilho, e pegadas.
func _mud(seed_value: int) -> Image:
	var image := _dirt(seed_value, MUD, 0.01, 60, 160)
	var puddles := _noise(seed_value + 3, 0.014, 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 1
	for y: int in SIZE:
		for x: int in SIZE:
			var value := puddles.get_pixel(x, y).r + _dither(x, y) * 0.04
			if value > 0.7:
				image.set_pixel(x, y, PUDDLE[1] if value > 0.73 else PUDDLE[0])
			elif value > 0.68:
				image.set_pixel(x, y, MUD[0])
	for _index: int in 700:
		var at := Vector2i(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1))
		if puddles.get_pixel(at.x, at.y).r > 0.74:
			for dx: int in rng.randi_range(2, 4):
				_put(image, at + Vector2i(dx, 0), PUDDLE[2])
	_walks(image, rng, 10, 24, MUD[0], MUD[3])
	return image


## Trilhas de pegadas de 3x4, alternando o pé, com a parede de cima na sombra e a de
## baixo no claro.
func _walks(image: Image, rng: RandomNumberGenerator, count: int, steps: int, dark: Color, light: Color) -> void:
	for _walker: int in count:
		var at := Vector2(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1))
		var heading := Vector2.from_angle(rng.randf() * TAU)
		for step: int in steps:
			var side := heading.orthogonal() * (3.0 if step % 2 == 0 else -3.0)
			var foot := Vector2i((at + side).round())
			for dy: int in 4:
				for dx: int in 3:
					if (dy == 0 or dy == 3) and dx != 1:
						continue
					_put(image, foot + Vector2i(dx, dy), dark if dy < 2 else light)
			at += heading * 9.0
			heading = heading.rotated((rng.randf() - 0.5) * 0.3)


## Folhas caídas, elipses de 5 a 8 px num ângulo sorteado, com o lado de cima claro, o de
## baixo escuro e a nervura no meio, mais juntas em manchas, sobre o fundo transparente
## (ali aparece o bioma, como entre os Pisantes).
func _leaves(seed_value: int) -> Image:
	var patches := _noise(seed_value + 3, 0.02, 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for _index: int in 11000:
		var at := Vector2(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1))
		if patches.get_pixel(int(at.x), int(at.y)).r + rng.randf() * 0.5 < 0.52:
			continue
		var tones: Array = LEAVES[rng.randi_range(0, LEAVES.size() - 1)]
		var along := Vector2.from_angle(rng.randf() * PI)
		var across := along.orthogonal()
		if across.y > 0.0:
			across = -across
		var half_length := rng.randf_range(2.6, 4.0)
		var half_width := rng.randf_range(1.3, 1.8)
		var reach := ceili(half_length) + 1
		for dy: int in range(-reach, reach + 1):
			for dx: int in range(-reach, reach + 1):
				var offset := Vector2(dx, dy)
				var u := offset.dot(along) / half_length
				var v := offset.dot(across) / half_width
				if u * u + v * v > 1.0:
					continue
				var tone := 1
				if v > 0.45:
					tone = 2
				elif v < -0.35:
					tone = 0
				_put(image, Vector2i(at) + Vector2i(dx, dy), tones[tone])
		_put(image, Vector2i((at - along * (half_length + 1.0)).round()), tones[0])
	return image


## Neve azulada com brilhos e trilhas de pegadas.
func _snow(seed_value: int) -> Image:
	var image := _dirt(seed_value, SNOW, 0.006, 0, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 1
	for _index: int in 1400:
		_put(image, Vector2i(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1)), SNOW[4])
	_walks(image, rng, 16, 30, SNOW[0], SNOW[3])
	return image


## Seixos arredondados num Voronoi que se repete nas bordas (`count` x `count`): cada
## pedra é o pedaço da célula a até `fill` do raio dela (sorteado entre `min_fill` e
## `max_fill`), com o contorno, o claro em cima à esquerda, a sombra embaixo à direita e
## um brilho. Fora das pedras fica a `joint`; transparente, aparece o bioma, e a pedra
## ganha a sombra de 1 px no chão. `keep` é a chance de cada célula ter pedra. Com
## `flat`, a pedra é uma laje chata: o claro e a sombra só na beirada.
func _cobbles(seed_value: int, count: int, palettes: Array, joint: Color, min_fill: float, max_fill: float, keep: float, flat := false) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var points := PackedVector2Array()
	var fills := PackedFloat32Array()
	var tones_of: Array = []
	for _index: int in count * count:
		points.append(Vector2(rng.randf_range(0.15, 0.85), rng.randf_range(0.15, 0.85)))
		fills.append(rng.randf_range(min_fill, max_fill) if rng.randf() < keep else 0.0)
		tones_of.append(palettes[rng.randi_range(0, palettes.size() - 1)])
	var cell := float(SIZE) / count
	var radius := cell * 0.5
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		for x: int in SIZE:
			var pixel := Vector2(x + 0.5, y + 0.5)
			var cell_x := floori(pixel.x / cell)
			var cell_y := floori(pixel.y / cell)
			var best := -1
			var best_center := Vector2.ZERO
			var best_distance := INF
			var centers: Array[Vector2] = []
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					var gx := cell_x + dx
					var gy := cell_y + dy
					var index := posmod(gy, count) * count + posmod(gx, count)
					var center := (Vector2(gx, gy) + points[index]) * cell
					centers.append(center)
					var distance := pixel.distance_squared_to(center)
					if distance < best_distance:
						best_distance = distance
						best = index
						best_center = center
			var edge := INF
			for center: Vector2 in centers:
				if center == best_center:
					continue
				var span := center - best_center
				edge = minf(edge, (pixel.distance_squared_to(center) - best_distance) / (2.0 * span.length()))
			var fill := fills[best]
			var reach := fill * radius
			var distance := sqrt(best_distance)
			if fill <= 0.0 or edge < 1.0 or distance > reach:
				image.set_pixel(x, y, joint)
				continue
			var tones: Array = tones_of[best]
			var normal := (pixel - best_center) / reach
			var light := -(normal.x * 0.8 + normal.y)
			var tone := 2
			if edge < 2.0 or distance > reach - 1.0:
				tone = 0
			elif flat:
				var rim := edge < 4.0 or distance > reach - 3.0
				if rim and light > 0.0:
					tone = 3
				elif rim:
					tone = 1
				elif _dither(x, y) + rng.randf() * 0.3 > 0.62:
					tone = 3
			elif (normal + Vector2(0.35, 0.45)).length() < 0.2:
				tone = 4
			elif light + _dither(x, y) * 0.2 > 0.35:
				tone = 3
			elif light + _dither(x, y) * 0.2 < -0.45:
				tone = 1
			image.set_pixel(x, y, tones[tone])
	if joint.a == 0.0:
		var stones := image.duplicate() as Image
		for y: int in SIZE:
			for x: int in SIZE:
				if stones.get_pixel(x, y).a == 0.0 and stones.get_pixel(x, posmod(y - 1, SIZE)).a > 0.0:
					image.set_pixel(x, y, STONE_SHADOW)
	return image


## Terra batida marrom com rachaduras escuras que se ramificam, com a beirada de baixo
## de cada rachadura clara.
func _cracked(seed_value: int) -> Image:
	var image := _dirt(seed_value, CRACKED, 0.012, 60, 140)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 1
	for _index: int in 900:
		var at := Vector2(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1))
		var heading := rng.randf() * TAU
		for _step: int in rng.randi_range(4, 12):
			var pixel := Vector2i(at.round())
			_put(image, pixel, CRACKED[0])
			_put(image, pixel + Vector2i(0, 1), CRACKED[4])
			heading += (rng.randf() - 0.5) * 1.4
			at += Vector2.from_angle(heading)
	return image


## Pedras chatas em fiadas de `height` px, de comprimentos sorteados entre `min_length` e
## `max_length`, com os cantos arredondados, o brilho em cima e à esquerda e a sombra
## embaixo e à direita. Tons: 0 a junta, 1 a sombra, 2 e 3 o corpo, 4 o brilho.
func _courses(seed_value: int, height: int, min_length: int, max_length: int, tones: Array[Color]) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for row: int in SIZE / height:
		var top := row * height
		var start := rng.randi_range(0, SIZE - 1)
		var done := 0
		while done < SIZE:
			var length := rng.randi_range(min_length, max_length)
			if SIZE - done - length < min_length:
				length = SIZE - done
			var body := rng.randi_range(2, 3)
			for dx: int in length:
				for dy: int in height:
					var tone := body
					var corner := (dx == 1 or dx == length - 1) and (dy == 0 or dy == height - 2)
					if dy == height - 1 or dx == 0 or corner:
						tone = 0
					elif dy == 0 or dx == 1:
						tone = 4
					elif dy == height - 2 or dx == length - 1:
						tone = 1
					elif rng.randf() < 0.05:
						tone = 1 if body == 2 else 4
					_put(image, Vector2i(start + done + dx, top + dy), tones[tone])
			done += length
	return image
