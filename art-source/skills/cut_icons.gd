extends SceneTree
## Recorta ícones de Técnica de uma imagem com vários quadros, como a que o dono
## gerou em 2026-11-06 (instinto_icons.jpg: 3 colunas e 2 linhas, separadas por faixas
## pretas). Cada ícone sai em res://assets/skills/<slug>.png, com 256 × 256 e sem
## transparência, como os outros ícones de Técnica.
##
## Os quadros são achados pelas faixas pretas: uma coluna (ou linha) quase toda preta
## separa um quadro do outro. Do quadro sai o quadrado do meio, um pouco para dentro,
## para não pegar a borda.
##
## Uso, na raiz do repositório:
##   godot --headless --path client -s ../art-source/skills/cut_icons.gd
## Para outra imagem, passe o nome dela (em art-source/skills/) e os slugs na ordem de
## leitura, da esquerda para a direita e de cima para baixo ("-" pula um quadro):
##   godot --headless --path client -s ../art-source/skills/cut_icons.gd -- instinto_vento_icons.jpg uivo patada ...
## Depois, `godot --headless --path client --import` cria os `.import`.

const SOURCE := "../art-source/skills/instinto_icons.jpg"
const OUT := "res://assets/skills/%s.png"
const SIZE := 256
## Quanto entra de cada lado do quadro, em pixels da imagem original.
const INSET := 6
## Um pixel mais escuro que isto conta como preto.
const BLACK := 0.06
## Uma coluna (ou linha) com esta parte dos pixels pretos é separação.
const SEPARATOR := 0.97
## Qual quadro vira qual Técnica: (coluna, linha), a partir de 0.
const ICONS: Dictionary[String, Vector2i] = {
	"rugido_feroz": Vector2i(0, 0),
	"investida_veloz": Vector2i(2, 0),
	"arranhao": Vector2i(0, 1),
}


func _initialize() -> void:
	var source := SOURCE
	var icons := ICONS
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		source = "../art-source/skills/" + args[0]
		icons = {}
		for index: int in range(1, args.size()):
			if args[index] != "-":
				icons[args[index]] = Vector2i((index - 1) % 3, (index - 1) / 3)
	var path := ProjectSettings.globalize_path("res://").path_join(source)
	var image := Image.load_from_file(path)
	if image == null:
		push_error("Não abriu %s" % path)
		quit(1)
		return
	image.convert(Image.FORMAT_RGB8)
	var columns := _spans(image, true)
	var rows := _spans(image, false)
	print("quadros: %d colunas %s, %d linhas %s" % [columns.size(), columns, rows.size(), rows])
	for slug: String in icons:
		var cell: Vector2i = icons[slug]
		if cell.x >= columns.size() or cell.y >= rows.size():
			push_error("A imagem não tem o quadro %s para %s." % [cell, slug])
			quit(1)
			return
		var x: Vector2i = columns[cell.x]
		var y: Vector2i = rows[cell.y]
		var side := mini(x.y - x.x, y.y - y.x) - INSET * 2
		var left := x.x + floori((x.y - x.x - side) / 2.0)
		var top := y.x + floori((y.y - y.x - side) / 2.0)
		var icon := image.get_region(Rect2i(left, top, side, side))
		icon.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
		var out := OUT % slug
		icon.save_png(out)
		print("ok: %s  (%d, %d, lado %d)" % [out, left, top, side])
	quit(0)


## Os trechos [início, fim) entre as separações pretas, nas colunas ou nas linhas.
func _spans(image: Image, along_x: bool) -> Array[Vector2i]:
	var length := image.get_width() if along_x else image.get_height()
	var across := image.get_height() if along_x else image.get_width()
	var spans: Array[Vector2i] = []
	var start := -1
	for i: int in length:
		var dark := 0
		for j: int in across:
			var color := image.get_pixel(i, j) if along_x else image.get_pixel(j, i)
			if color.get_luminance() < BLACK:
				dark += 1
		var separator := float(dark) / across >= SEPARATOR
		if not separator and start < 0:
			start = i
		elif separator and start >= 0:
			spans.append(Vector2i(start, i))
			start = -1
	if start >= 0:
		spans.append(Vector2i(start, length))
	# Uma faixa estreita demais não é um quadro (sobra da borda).
	var frames: Array[Vector2i] = []
	for span: Vector2i in spans:
		if span.y - span.x > length / 10.0:
			frames.append(span)
	return frames
