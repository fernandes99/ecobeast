extends SceneTree
## A textura da cachoeira (.specs/water-motion/02-waterfalls.md): faixas verticais
## nos tons da água rasa, com riscos claros que o shader faz descer. 512x64,
## emendando nas quatro bordas. Da pasta client/:
## godot --headless -s res://assets/terrain/surfaces/make_waterfall.gd

const WIDTH := 512
const HEIGHT := 64
const OUT := "res://assets/terrain/surfaces/waterfall.png"
const BASES: Array[Color] = [Color("#2f8fcf"), Color("#379bd6"), Color("#43a8de"), Color("#52b5e5")]
const BASE_WEIGHTS: Array[float] = [1.0, 3.0, 3.0, 2.0]
const STREAK := Color("#63c1ea")
const BRIGHT := Color("#8fdcf3")
const HEAD := Color("#c2eefa")
const SEED := 4721


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGB8)
	var x := 0
	var previous := -1
	while x < WIDTH:
		var width := rng.randi_range(2, 4)
		var tone := previous
		while tone == previous:
			tone = rng.rand_weighted(PackedFloat32Array(BASE_WEIGHTS))
		previous = tone
		for column: int in range(x, mini(x + width, WIDTH)):
			for y: int in HEIGHT:
				image.set_pixel(column, y, BASES[tone])
		_add_streaks(image, rng, x, mini(x + width, WIDTH))
		x += width
	image.save_png(ProjectSettings.globalize_path(OUT))
	print("ok ", OUT)
	quit()


## Os riscos claros de uma faixa, com a ponta de baixo mais clara: é a frente da água
## que desce. Um risco que passa da borda continua no alto, para emendar.
func _add_streaks(image: Image, rng: RandomNumberGenerator, from: int, to: int) -> void:
	for _streak: int in rng.randi_range(1, 2):
		var column := rng.randi_range(from, to - 1)
		var top := rng.randi_range(0, HEIGHT - 1)
		var length := rng.randi_range(5, 14)
		var bright := rng.randf() < 0.4
		for step: int in length:
			var y := (top + step) % HEIGHT
			var color := STREAK
			if step == length - 1:
				color = HEAD
			elif bright and step >= length - 4:
				color = BRIGHT
			image.set_pixel(column, y, color)
			if to - from > 2 and step * 2 >= length and column + 1 < to:
				image.set_pixel(column + 1, y, STREAK)
