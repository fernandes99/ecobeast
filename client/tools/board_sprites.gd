extends SceneTree
## Gera o `board.png` de cada Ecobeast a partir do `front.png` (board-battle/06):
## uma pixel art pequena, com o contorno escuro de 1 pixel, que o tabuleiro
## mostra 2× maior, sem filtro. A altura sai da altura do catálogo.
##
## Uso, na raiz do repositório:
##   godot --headless --path client -s res://tools/board_sprites.gd
## Depois, `godot --headless --path client --import` cria os `.import`.

const CREATURES_DIR := "res://assets/creatures"
## As alturas vêm do seed do servidor; sem ele, todos ficam com 1 m.
const SPECIES_SEED := "res://../server/prisma/seed-data/species.json"
## Altura em pixels do menor e do maior Ecobeast, sem o contorno. A revisar.
const MIN_HEIGHT := 30
const MAX_HEIGHT := 46
const MIN_METERS := 0.3
const MAX_METERS := 1.6
## Quanto da transparência vira pixel cheio.
const ALPHA_CUT := 0.5
## O contorno é a cor do pixel vizinho, escurecida.
const OUTLINE_DARKEN := 0.7
## A folga em volta: 1 pixel para o contorno escuro e 1 para o branco de quem joga.
const PADDING := 2


func _initialize() -> void:
	var heights := _heights()
	var made := 0
	for slug: String in DirAccess.get_directories_at(CREATURES_DIR):
		var front := "%s/%s/front.png" % [CREATURES_DIR, slug]
		if not FileAccess.file_exists(front):
			continue
		var meters: float = heights.get(slug, 1.0)
		var image := _pixelate(Image.load_from_file(ProjectSettings.globalize_path(front)), _target_height(meters))
		image.save_png(ProjectSettings.globalize_path("%s/%s/board.png" % [CREATURES_DIR, slug]))
		print("%s: %d × %d" % [slug, image.get_width(), image.get_height()])
		made += 1
	print("feitos: %d" % made)
	quit()


func _heights() -> Dictionary:
	var heights := {}
	var path := ProjectSettings.globalize_path(SPECIES_SEED)
	if not FileAccess.file_exists(path):
		return heights
	var rows: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if rows is Array:
		for row: Variant in rows:
			if row is Dictionary:
				heights[String(row["slug"])] = float(row["height_m"])
	return heights


func _target_height(meters: float) -> int:
	var t := clampf((meters - MIN_METERS) / (MAX_METERS - MIN_METERS), 0.0, 1.0)
	return roundi(lerpf(MIN_HEIGHT, MAX_HEIGHT, t))


## Recorta o desenho, reduz até a altura, deixa a transparência só cheia ou
## vazia e põe o contorno, com a folga em volta.
func _pixelate(source: Image, height: int) -> Image:
	source.convert(Image.FORMAT_RGBA8)
	var used := source.get_used_rect()
	var art := source.get_region(used)
	var width := maxi(roundi(art.get_width() * float(height) / art.get_height()), 1)
	art.resize(width, height, Image.INTERPOLATE_LANCZOS)
	var out := Image.create_empty(width + PADDING * 2, height + PADDING * 2, false, Image.FORMAT_RGBA8)
	for y: int in height:
		for x: int in width:
			var color := art.get_pixel(x, y)
			if color.a >= ALPHA_CUT:
				color.a = 1.0
				out.set_pixel(x + PADDING, y + PADDING, color)
	var solid := out.duplicate() as Image
	for y: int in out.get_height():
		for x: int in out.get_width():
			if solid.get_pixel(x, y).a > 0.0:
				continue
			var neighbor := _solid_neighbor(solid, x, y)
			if neighbor.a > 0.0:
				out.set_pixel(x, y, neighbor.darkened(OUTLINE_DARKEN))
	return out


func _solid_neighbor(image: Image, x: int, y: int) -> Color:
	for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx := x + offset.x
		var ny := y + offset.y
		if nx < 0 or ny < 0 or nx >= image.get_width() or ny >= image.get_height():
			continue
		var color := image.get_pixel(nx, ny)
		if color.a > 0.0:
			return color
	return Color(0, 0, 0, 0)
