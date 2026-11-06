class_name FilePreview
extends VBoxContainer
## Um arquivo de conteúdo no visualizador (content-viewer/architecture.md, "O preview
## de um arquivo"): o quadro com fundo xadrez e o arquivo dentro, parado ou animado
## como no jogo, e o nome embaixo. O que falta aparece tracejado em vermelho, com o
## caminho onde o jogo o procura. Um som vira o botão "▶ Ouvir".

const BOX_SIZE := Vector2(104, 104)
const CHECKER := 8.0
const CHECKER_LIGHT := Color("#24365A")
const CHECKER_DARK := Color("#1A2944")
const MISSING_FILL := Color("#3A1D26")
const MISSING_BORDER := Color("#FF7A7A")
const DASH := 6.0
const LABEL_SIZE := 13
const PATH_SIZE := 11
## Pausa entre uma volta e outra do efeito de Técnica, em segundos. A revisar.
const EFFECT_PAUSE := 0.6
## O quadro de cada direção de uma folha: o explorar (32) ampliado 3×, e a luta (64), 2×.
const EXPLORE_DIRECTION_BOX := Vector2(96, 96)
const BATTLE_DIRECTION_BOX := Vector2(136, 136)

var entry: ContentFiles.Entry
## Para uma folha: a direção mostrada ({label, row, mirrored}); vazia, a primeira linha.
var direction: Dictionary = {}


## Mostra o arquivo; o tamanho do quadro é opcional.
static func create(file: ContentFiles.Entry, box_size := BOX_SIZE) -> FilePreview:
	var preview := FilePreview.new()
	preview.entry = file
	preview._build(box_size)
	return preview


## Uma folha com todas as direções, cada uma andando, sob o nome do arquivo. Sem o
## arquivo, o tracejado de sempre.
static func create_sheet(file: ContentFiles.Entry) -> Control:
	if not file.exists() or file.directions().is_empty():
		return create(file)
	var group := VBoxContainer.new()
	group.add_theme_constant_override(&"separation", 4)
	# Uma folha sem todas as direções diz quantas faltam, em amarelo.
	if file.complete():
		group.add_child(ContentViewer.text(file.label, ContentViewer.SMALL_SIZE, UiPalette.ACCENT))
	else:
		var count: int = file.missing_directions().size()
		var missing := "falta 1 direção" if count == 1 else "faltam %d direções" % count
		group.add_child(ContentViewer.text("%s · %s" % [file.label, missing], ContentViewer.SMALL_SIZE, UiPalette.WARNING))
	var row := ContentViewer.flow(8)
	var box := EXPLORE_DIRECTION_BOX if file.kind == ContentFiles.Kind.EXPLORE_SHEET else BATTLE_DIRECTION_BOX
	for one: Dictionary in file.directions():
		var preview := FilePreview.new()
		preview.entry = file
		preview.direction = one
		preview._build(box)
		row.add_child(preview)
	group.add_child(row)
	return group


func _build(box_size: Vector2) -> void:
	add_theme_constant_override(&"separation", 2)
	var found := entry.exists()
	if not direction.is_empty() and direction["row"] == ContentFiles.NO_ROW:
		# A folha existe, mas ainda não tem esta direção.
		found = false
	if entry.kind == ContentFiles.Kind.SOUND and found:
		_add_sound_button(box_size)
	else:
		var frame := Frame.new()
		frame.custom_minimum_size = box_size
		frame.missing = not found
		if found:
			_setup_frame(frame)
		add_child(frame)
	var caption := Label.new()
	caption.text = entry.label if found else "%s · falta" % entry.label
	if not direction.is_empty():
		caption.text = direction["label"] if found else "%s · falta" % direction["label"]
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override(&"font_size", LABEL_SIZE)
	if not found:
		caption.add_theme_color_override(&"font_color", MISSING_BORDER)
	add_child(caption)
	if direction.get("mirrored", false):
		var mirror := ContentViewer.text("(espelho)", PATH_SIZE, UiPalette.TEXT_SECONDARY)
		mirror.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(mirror)
	if not found and direction.is_empty():
		var path := Label.new()
		path.text = entry.path
		path.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		path.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		path.custom_minimum_size.x = box_size.x
		path.add_theme_font_size_override(&"font_size", PATH_SIZE)
		path.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
		add_child(path)


## Diz ao quadro qual parte da imagem desenhar e em que ritmo.
func _setup_frame(frame: Frame) -> void:
	var texture: Texture2D = load(entry.path)
	frame.texture = texture
	var row: int = direction.get("row", 0)
	frame.mirrored = direction.get("mirrored", false)
	match entry.kind:
		ContentFiles.Kind.EXPLORE_SHEET:
			# Uma linha (sem direção, a de frente), num ciclo no ritmo do jogo.
			var cell := SheetSprite.CELL_SIZE
			var frames := maxi(1, texture.get_width() / cell.x)
			var cycle := CreatureSprite.IDLE_SECONDS if entry.sheet == CreatureSprite.IDLE else CreatureSprite.WALK_SECONDS
			frame.animate(cell, frames, cycle / frames, 0.0, row)
		ContentFiles.Kind.BATTLE_SHEET:
			# Cada linha tem os quadros até a primeira célula vazia (BattleSheets).
			var sheets := BattleSheets.for_slug(entry.slug)
			if sheets == null:
				frame.animate(Vector2i(texture.get_size()), 1, 1.0, 0.0)
			else:
				frame.animate(Vector2i(sheets.cell, sheets.cell), sheets.frame_count(entry.sheet, row), BattleSheets.FRAME_SECONDS[entry.sheet], 0.0, row)
		ContentFiles.Kind.EFFECT:
			# Os quadros ficam lado a lado, cada um da altura da imagem (BoardView.play_effect).
			var side := texture.get_height()
			var frames := maxi(1, roundi(texture.get_width() / float(side)))
			frame.animate(Vector2i(side, side), frames, BoardView.EFFECT_FRAME_SECONDS, EFFECT_PAUSE)
		_:
			frame.animate(Vector2i(texture.get_size()), 1, 1.0, 0.0)


func _add_sound_button(box_size: Vector2) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = load(entry.path)
	add_child(player)
	var button := Button.new()
	button.text = "▶ Ouvir"
	button.custom_minimum_size = Vector2(box_size.x, 0)
	button.pressed.connect(player.play)
	add_child(button)


## O quadro: o xadrez e um quadro da imagem, ampliado por um número inteiro e sem
## filtro (pixel art); o que não cabe é reduzido com filtro suave. Ou o tracejado.
class Frame:
	extends Control

	var texture: Texture2D = null
	var missing := false
	## Desenha a linha virada para o outro lado, como o flip_h do jogo.
	var mirrored := false
	var _cell := Vector2i.ONE
	var _row := 0
	var _frames := 1
	var _frame_seconds := 1.0
	var _pause := 0.0
	var _time := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(false)

	func animate(cell: Vector2i, frames: int, frame_seconds: float, pause: float, row := 0) -> void:
		_row = row
		_cell = Vector2i(maxi(1, cell.x), maxi(1, cell.y))
		_frames = maxi(1, frames)
		_frame_seconds = maxf(0.01, frame_seconds)
		_pause = pause
		var factor := _scale()
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if factor >= 1.0 else CanvasItem.TEXTURE_FILTER_LINEAR
		set_process(_frames > 1)
		queue_redraw()

	func _process(delta: float) -> void:
		_time = fmod(_time + delta, _frames * _frame_seconds + _pause)
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		if missing:
			draw_rect(rect, FilePreview.MISSING_FILL)
			_dashed_border(rect)
			return
		_checker(rect)
		if texture == null:
			return
		var frame := mini(int(_time / _frame_seconds), _frames - 1)
		var source := Rect2(Vector2(frame * _cell.x, _row * _cell.y), Vector2(_cell))
		var target_size := Vector2(_cell) * _scale()
		var target := Rect2(((size - target_size) / 2.0).floor(), target_size)
		if mirrored:
			# Espelha em volta do meio do quadro.
			draw_set_transform(Vector2(size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
		draw_texture_rect_region(texture, target, source)
		draw_set_transform(Vector2.ZERO)

	## Inteiro quando a imagem cabe ampliada; senão, o quanto ela precisa encolher.
	func _scale() -> float:
		var fit := minf(custom_minimum_size.x / _cell.x, custom_minimum_size.y / _cell.y)
		return floorf(fit) if fit >= 1.0 else fit

	func _checker(rect: Rect2) -> void:
		draw_rect(rect, FilePreview.CHECKER_DARK)
		var step := FilePreview.CHECKER
		var y := 0.0
		var row := 0
		while y < rect.size.y:
			var x := step if row % 2 == 1 else 0.0
			while x < rect.size.x:
				draw_rect(Rect2(x, y, minf(step, rect.size.x - x), minf(step, rect.size.y - y)), FilePreview.CHECKER_LIGHT)
				x += step * 2.0
			y += step
			row += 1

	func _dashed_border(rect: Rect2) -> void:
		var corners: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
		for i: int in corners.size():
			draw_dashed_line(corners[i], corners[(i + 1) % corners.size()], FilePreview.MISSING_BORDER, 2.0, FilePreview.DASH)
