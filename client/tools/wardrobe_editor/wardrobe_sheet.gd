class_name WardrobeSheet
extends RefCounted
## Uma folha do Domador aberta no editor de roupas (tamer-looks/05): a imagem, o pincel
## preso a um quadro de 32×32, o desfazer por pincelada e o salvar por cima do PNG.

signal changed

const CELL := SheetSprite.CELL_SIZE
const ROWS := 5
const MAX_UNDO := 100
const OUTLINE := Color8(0x2f, 0x25, 0x22)
const KEYS: Array[Color] = [Color8(230, 230, 230), Color8(180, 180, 180), Color8(130, 130, 130), Color8(80, 80, 80)]

var path: String
var image: Image
var dirty := false
var _undo: Array[Dictionary] = []
var _redo: Array[Dictionary] = []
## Pixel absoluto da folha -> [antes, depois], da pincelada em andamento.
var _stroke: Dictionary = {}
var _stroking := false


## Lê pelo arquivo, e não pelo load(), para ver o que acabou de ser salvo; null sem o arquivo.
static func open(sheet_path: String) -> WardrobeSheet:
	var global := ProjectSettings.globalize_path(sheet_path)
	if not FileAccess.file_exists(global):
		return null
	var loaded := Image.load_from_file(global)
	if loaded == null:
		return null
	loaded.convert(Image.FORMAT_RGBA8)
	var sheet := WardrobeSheet.new()
	sheet.path = sheet_path
	sheet.image = loaded
	return sheet


func columns() -> int:
	return floori(image.get_width() / float(CELL.x))


func cell_rect(column: int, row: int) -> Rect2i:
	return Rect2i(Vector2i(column, row) * CELL, CELL)


func pixel(column: int, row: int, at: Vector2i) -> Color:
	if not _inside(at):
		return Color.TRANSPARENT
	return image.get_pixelv(cell_rect(column, row).position + at)


func begin_stroke() -> void:
	_stroke = {}
	_stroking = true


## Pinta `at` (dentro do quadro); false fora dele ou se o pixel já tinha a cor.
func paint(column: int, row: int, at: Vector2i, color: Color) -> bool:
	if not _inside(at) or column < 0 or row < 0 or column >= columns() or row >= ROWS:
		return false
	var p := cell_rect(column, row).position + at
	var before := image.get_pixelv(p)
	if before.to_rgba32() == color.to_rgba32():
		return false
	if _stroke.has(p):
		_stroke[p][1] = color
	else:
		_stroke[p] = [before, color]
	image.set_pixelv(p, color)
	if not _stroking:
		end_stroke()
	changed.emit()
	return true


func end_stroke() -> void:
	_stroking = false
	# Mover uma seleção e soltá-la no mesmo lugar não muda nada: não vira passo.
	for p: Vector2i in _stroke.keys():
		if (_stroke[p][0] as Color).to_rgba32() == (_stroke[p][1] as Color).to_rgba32():
			_stroke.erase(p)
	if _stroke.is_empty():
		return
	_undo.append(_stroke)
	if _undo.size() > MAX_UNDO:
		_undo.pop_front()
	_redo.clear()
	_stroke = {}
	dirty = true


func undo() -> bool:
	if _undo.is_empty():
		return false
	var stroke: Dictionary = _undo.pop_back()
	_apply(stroke, 0)
	_redo.append(stroke)
	return true


func redo() -> bool:
	if _redo.is_empty():
		return false
	var stroke: Dictionary = _redo.pop_back()
	_apply(stroke, 1)
	_undo.append(stroke)
	return true


## As 4 chaves, o contorno e depois as outras cores opacas da folha, sem repetir.
func colors() -> Array[Color]:
	var result: Array[Color] = []
	var seen := {}
	for color: Color in KEYS + [OUTLINE]:
		result.append(color)
		seen[color.to_rgba32()] = true
	for y: int in image.get_height():
		for x: int in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a < 1.0:
				continue
			var key := color.to_rgba32()
			if not seen.has(key):
				seen[key] = true
				result.append(color)
	return result


func save() -> Error:
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error == OK:
		dirty = false
	return error


func _apply(stroke: Dictionary, side: int) -> void:
	for p: Vector2i in stroke:
		image.set_pixelv(p, stroke[p][side])
	dirty = true
	changed.emit()


func _inside(at: Vector2i) -> bool:
	return at.x >= 0 and at.y >= 0 and at.x < CELL.x and at.y < CELL.y
