extends SceneTree

const SIZE := 512
## base, mancha clara, mancha escura, folha clara, folha, sombra
const PALETTES := {
	"temperate": ["62ab45", "6ab24a", "5ba341", "a9d86a", "84c257", "478f3a"],
	"boreal": ["3a8a50", "41924f", "348249", "7fbf6e", "5ea865", "29683f"],
	"hill": ["b1ad58", "b8b45e", "a9a552", "dcd384", "c4bb69", "8b8644"],
}
const BLADES := [
	["L.L", "LML", ".S."],
	[".L.", "LML", "MSM"],
	["L..L", "ML.L", ".MMS"],
	[".L", "LM", "S."],
	["L.", "M.", "S."],
	["..L", "L.M", "MMS"],
]
const LEAVES := [
	["..L..", ".LML.", "LMMMS", ".SMS.", "..S.."],
	[".L.L.", "LMLMS", ".MMS.", "..S.."],
	["..LL.", ".LMMS", "LMMS.", ".SS.."],
]
const CELL := Vector2i(64, 58)
const VARIANTS := 3
const CORNERS: Array[Vector2] = [Vector2(32, 0), Vector2(64, 16), Vector2(64, 42), Vector2(32, 58), Vector2(0, 42), Vector2(0, 16)]
const MATERIALS: Array[String] = ["foam", "temperate", "boreal", "hill", "stone", "mountain"]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var project: String = args[1]
	var surfaces: Dictionary = {}
	for biome: String in PALETTES:
		surfaces[biome] = _grass(biome, PALETTES[biome])
		surfaces[biome].save_png(out.path_join("flat_%s.png" % biome))
	for biome: String in ["stone", "mountain"]:
		surfaces[biome] = Image.load_from_file(project.path_join("assets/terrain/surfaces/%s.png" % biome))
		surfaces[biome].convert(Image.FORMAT_RGBA8)
	var old := Image.load_from_file(project.path_join("assets/terrain/transitions/transitions.png"))
	old.convert(Image.FORMAT_RGBA8)
	var sheet := Image.create(CELL.x * 6, CELL.y * VARIANTS * MATERIALS.size(), false, Image.FORMAT_RGBA8)
	sheet.blit_rect(old, Rect2i(0, 0, CELL.x * 6, CELL.y * VARIANTS), Vector2i.ZERO)
	var noise := FastNoiseLite.new()
	noise.frequency = 0.09
	noise.fractal_octaves = 2
	for m: int in range(1, MATERIALS.size()):
		var surface: Image = surfaces[MATERIALS[m]]
		for variant: int in VARIANTS:
			for edge: int in 6:
				var origin := Vector2i(edge * CELL.x, (m * VARIANTS + variant) * CELL.y)
				var a := CORNERS[edge]
				var b := CORNERS[(edge + 1) % 6]
				for y: int in CELL.y:
					for x: int in CELL.x:
						var p := Vector2(x + 0.5, y + 0.5)
						if not _inside(p):
							continue
						var d := _segment_distance(p, a, b)
						var reach := 6.0 + noise.get_noise_3d(x * 1.0, y * 1.0, (variant * 6 + edge) * 40.0) * 7.0
						if d > reach:
							continue
						var sample := Vector2i(posmod(x + variant * 97 + edge * 31, SIZE), posmod(y + variant * 53, SIZE))
						sheet.set_pixel(origin.x + x, origin.y + y, surface.get_pixelv(sample))
	sheet.save_png(out.path_join("transitions_soft.png"))
	print("salvo")
	quit()


func _inside(p: Vector2) -> bool:
	for i: int in 6:
		var a := CORNERS[i]
		var b := CORNERS[(i + 1) % 6]
		if (b - a).cross(p - a) < 0.0:
			return false
	return true


func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


func _grass(biome: String, hexes: Array) -> Image:
	var colors: Array[Color] = []
	for value: String in hexes:
		colors.append(Color.html(value))
	var noise := FastNoiseLite.new()
	noise.seed = biome.hash()
	noise.frequency = 0.008
	noise.fractal_octaves = 3
	var patches := noise.get_seamless_image(SIZE, SIZE, false, false, 0.2)
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		for x: int in SIZE:
			var n := patches.get_pixel(x, y).r
			var checker := 0.03 if (x + y) % 2 == 0 else -0.03
			var color := colors[0]
			if n + checker > 0.62:
				color = colors[1]
			elif n + checker < 0.36:
				color = colors[2]
			image.set_pixel(x, y, color)
	var random := RandomNumberGenerator.new()
	random.seed = biome.hash() + 1
	for _cluster: int in 700:
		var center := Vector2i(random.randi_range(0, SIZE - 1), random.randi_range(0, SIZE - 1))
		var light := patches.get_pixelv(center).r > 0.5
		for _blade: int in random.randi_range(2, 5):
			var at := center + Vector2i(random.randi_range(-5, 5), random.randi_range(-3, 3))
			_stamp(image, BLADES[random.randi_range(0, BLADES.size() - 1)], at, colors, light)
	for _cluster: int in 70:
		var center := Vector2i(random.randi_range(0, SIZE - 1), random.randi_range(0, SIZE - 1))
		for _leaf: int in random.randi_range(2, 6):
			var at := center + Vector2i(random.randi_range(-7, 7), random.randi_range(-4, 4))
			_stamp(image, LEAVES[random.randi_range(0, LEAVES.size() - 1)], at, colors, true)
	return image


func _stamp(image: Image, rows: Array, at: Vector2i, colors: Array[Color], light: bool) -> void:
	for dy: int in rows.size():
		var row: String = rows[dy]
		for dx: int in row.length():
			var color: Color
			match row[dx]:
				"L":
					color = colors[3] if light else colors[4]
				"M":
					color = colors[4] if light else colors[5]
				"S":
					color = colors[5]
				_:
					continue
			image.set_pixel(posmod(at.x + dx, SIZE), posmod(at.y + dy, SIZE), color)
