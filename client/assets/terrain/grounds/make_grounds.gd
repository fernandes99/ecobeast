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


func _init() -> void:
	_save("dirt_trail", _dirt(11, DIRT_TRAIL, 0.006, 420, 300))
	_save("dirt_floor", _dirt(23, DIRT_FLOOR, 0.008, 160, 120))
	_save("stone_trail", _stones(31, 46, 0.95, STONE_TRAIL))
	_save("cobble_floor", _stones(47, 40, 0.35, COBBLE_FLOOR))
	_save("gravel_trail", _gravel(53))
	_save("stepping_stones", _stones(61, 26, 0.8, STEPPING_STONES, 2.2))
	_save("sand_trail", _dirt(67, SAND, 0.005, 40, 520))
	_save("worn_trail", _worn(71))
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
