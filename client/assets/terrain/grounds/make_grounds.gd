extends SceneTree
## Texturas provisórias de chão das ilhas (.specs/island-villages/02-grounds.md),
## 512x512 e emendando nas quatro bordas. Da pasta client/:
## godot --headless -s res://assets/terrain/grounds/make_grounds.gd

const SIZE := 512
const OUT := "res://assets/terrain/grounds/%s.png"


func _init() -> void:
	_save("dirt_trail", _dirt(11, Color8(176, 140, 92), Color8(124, 94, 62), 420))
	_save("dirt_floor", _dirt(23, Color8(192, 160, 114), Color8(150, 120, 84), 90))
	_save("stone_trail", _flagstones(31, 9, 0.9, Color8(146, 136, 118), Color8(198, 188, 168), Color8(92, 82, 70), 2.2))
	_save("cobble_floor", _flagstones(47, 20, 0.55, Color8(128, 124, 118), Color8(178, 172, 162), Color8(80, 74, 68), 1.8))
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


## Voronoi que se repete nas bordas: uma grade de `count` x `count` pontos sorteados,
## e cada pixel olha as 9 células em volta, dando a volta no fim da imagem.
## Devolve, por pixel, a diferença entre o segundo e o primeiro ponto mais perto (a
## borda) e o tom sorteado da pedra.
func _cells(seed_value: int, count: int, jitter: float) -> Array[PackedFloat32Array]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var points := PackedVector2Array()
	var shades := PackedFloat32Array()
	for gy: int in count:
		for gx: int in count:
			points.append(Vector2(gx + 0.5 + (rng.randf() - 0.5) * jitter, gy + 0.5 + (rng.randf() - 0.5) * jitter))
			shades.append(rng.randf())
	var edges := PackedFloat32Array()
	var tones := PackedFloat32Array()
	edges.resize(SIZE * SIZE)
	tones.resize(SIZE * SIZE)
	var scale := float(count) / SIZE
	for y: int in SIZE:
		for x: int in SIZE:
			var at := Vector2(x + 0.5, y + 0.5) * scale
			var cell_x := int(at.x)
			var cell_y := int(at.y)
			var best := 99.0
			var second := 99.0
			var tone := 0.0
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					var gx := cell_x + dx
					var gy := cell_y + dy
					var index := posmod(gy, count) * count + posmod(gx, count)
					var point := points[index] + Vector2(gx - posmod(gx, count), gy - posmod(gy, count))
					var distance := at.distance_to(point)
					if distance < best:
						second = best
						best = distance
						tone = shades[index]
					elif distance < second:
						second = distance
			edges[y * SIZE + x] = (second - best) / scale
			tones[y * SIZE + x] = tone
	return [edges, tones]


func _dirt(seed_value: int, light: Color, dark: Color, pebble_count: int) -> Image:
	var broad := _noise(seed_value, 0.006, 4)
	var grain := _noise(seed_value + 1, 0.12, 2)
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		for x: int in SIZE:
			var tone := clampf(broad.get_pixel(x, y).r * 1.3 - 0.15, 0.0, 1.0)
			var color := dark.lerp(light, tone)
			color = color * (0.9 + grain.get_pixel(x, y).r * 0.18)
			color.a = 1.0
			image.set_pixel(x, y, color)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for _index: int in pebble_count:
		var center := Vector2(rng.randf() * SIZE, rng.randf() * SIZE)
		var radius := rng.randf_range(1.5, 3.8)
		var stone := Color8(118, 104, 88).lerp(Color8(180, 168, 150), rng.randf())
		_pebble(image, center, radius, stone)
	return image


func _pebble(image: Image, center: Vector2, radius: float, stone: Color) -> void:
	var reach := ceili(radius) + 1
	for dy: int in range(-reach, reach + 1):
		for dx: int in range(-reach, reach + 1):
			var offset := Vector2(dx, dy)
			var distance := offset.length()
			if distance > radius:
				continue
			var x := posmod(int(center.x) + dx, SIZE)
			var y := posmod(int(center.y) + dy, SIZE)
			var light := 1.1 - (offset.x + offset.y) / (radius * 4.0)
			var color := stone * light
			if distance > radius - 1.0:
				color = stone * 0.7
			color.a = 1.0
			image.set_pixel(x, y, color)


## `gap_width` em pixels: a junta entre as pedras.
func _flagstones(seed_value: int, count: int, jitter: float, dark: Color, light: Color, gap: Color, gap_width: float) -> Image:
	var cells := _cells(seed_value, count, jitter)
	var edges: PackedFloat32Array = cells[0]
	var tones: PackedFloat32Array = cells[1]
	var stain := _noise(seed_value + 2, 0.02, 3)
	var grain := _noise(seed_value + 3, 0.15, 2)
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		for x: int in SIZE:
			var edge := edges[y * SIZE + x]
			var tone := clampf(tones[y * SIZE + x] * 0.7 + stain.get_pixel(x, y).r * 0.45 - 0.1, 0.0, 1.0)
			var color := dark.lerp(light, tone) * (0.94 + grain.get_pixel(x, y).r * 0.12)
			if edge < gap_width:
				color = gap
			elif edge < gap_width * 2.5:
				color = color * 0.84
			elif edge > gap_width * 6.0:
				color = color * 1.05
			color.a = 1.0
			image.set_pixel(x, y, color)
	return image
