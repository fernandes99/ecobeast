extends SceneTree
## O guarda-roupa provisório do Domador (tamer-appearance/04), desenhado só por código
## sobre o template da Eris Esra (res://assets/tamer/template/): os 2 corpos, com a pele
## nas cores-chave, e cada peça em res://assets/tamer/parts/<slug>/. O dono redesenha
## por cima no mesmo formato.
## Da pasta client/: godot --headless -s res://assets/tamer/make_wardrobe.gd
##
## Toda folha tem quadros de 32×32 e 5 linhas (frente, diagonal de baixo, lado, diagonal
## de cima e costas); nas três do meio o Domador olha para a direita. As alturas abaixo
## contam a partir do alto da cabeça de cada quadro: a cabeça vai até 10, o pescoço é 11,
## o tronco vai de 12 a 18, o quadril é 19 e as pernas começam no 20.
##
## A criança (village-crowd/03) sai do template 16x16 (res://assets/tamer/template/child/),
## de quadros de 24×24 postos no meio de baixo do quadro de 32×32: os corpos boy e girl e
## cada peça em res://assets/tamer/parts/<slug>/child/. As alturas dela vêm do Frame.

const TEMPLATE := "res://assets/tamer/template/%s.png"
const CHILD_TEMPLATE := "res://assets/tamer/template/child/%s.png"
const BODY_OUT := "res://assets/tamer/bodies/%s/%s.png"
const PART_OUT := "res://assets/tamer/parts/%s/%s%s.png"
const CHILD_PART_OUT := "res://assets/tamer/parts/%s/child/%s%s.png"
const CELL := 32
const CHILD_CELL := 24
const CHILD_OFFSET := Vector2i(4, 8)
const ROWS := 5
const SHEETS: Array[String] = ["idle", "run"]
const FRONT := 0
const LOWER := 1
const SIDE := 2
const UPPER := 3
const BACK := 4
const HEAD_END := 10
const NECK := 11
const SHOULDERS := 12
const HIPS := 19
const LEGS := 20
const SLEEVE := SHOULDERS + 4
const HAIR_END := 15
const OUTLINE := Color8(0x2f, 0x25, 0x22)
const LIGHT := Color8(0xfa, 0xf3, 0xe8)
const SHADE := Color8(0xb9, 0xb3, 0xa1)
const EAR := Color8(0xe7, 0xd5, 0xc6)
const BLUSH := Color8(0xd1, 0x9d, 0xa7)
const UNDERWEAR := Color8(0x3f, 0x4a, 0x6b)
const KEYS: Array[Color] = [Color8(230, 230, 230), Color8(180, 180, 180), Color8(130, 130, 130), Color8(80, 80, 80)]
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

## slug da peça: os sufixos que ela tem ("" é a folha da frente).
const PARTS := {
	"face_1": [""],
	"face_2": [""],
	"hair_short": [""],
	"hair_spiky": ["", "_short"],
	"hair_ponytail": ["", "_back"],
	"hair_long": ["", "_back", "_short"],
	"cap": [""],
	"straw_hat": [""],
	"helmet": [""],
	"tshirt": [""],
	"jacket": [""],
	"tank_top": [""],
	"pants": [""],
	"shorts": [""],
	"skirt": [""],
	"sneakers": [""],
	"boots": [""],
}


## Um quadro do template: os pixels e as medidas de onde fica cada parte do corpo.
class Frame:
	var pixels: Dictionary = {}
	var row := 0
	var top := 0
	var head_min := 0
	var head_max := 0
	var hip_min := 0
	var hip_max := 0
	var top_min := 0
	var top_max := 0
	var head_end := HEAD_END
	var neck := NECK
	var shoulders := SHOULDERS
	var hips := HIPS
	var legs := LEGS
	var sleeve := SLEEVE
	var hair_end := HAIR_END
	var hip_row := LEGS + 1
	var child := false

	## Uma altura contada no adulto, encolhida na proporção da cabeça da criança.
	func h(rows: int) -> int:
		return roundi(rows * (head_end + 1.0) / (HEAD_END + 1.0))

	func as_child() -> void:
		child = true
		head_end = 8
		neck = 9
		shoulders = 10
		sleeve = 11
		hips = 14
		legs = 14
		hair_end = 12
		hip_row = neck


func _init() -> void:
	for sheet: String in SHEETS:
		var template := _load(TEMPLATE % sheet)
		var small := _load(CHILD_TEMPLATE % sheet)
		var columns := template.get_width() / CELL
		var frames: Array[Frame] = []
		var children: Array[Frame] = []
		for row: int in ROWS:
			for column: int in columns:
				frames.append(_read(template, column, row, CELL, Vector2i.ZERO, false))
				children.append(_read(small, column, row, CHILD_CELL, CHILD_OFFSET, true))
		_save(BODY_OUT % ["male", sheet], columns, frames, _body.bind(false))
		_save(BODY_OUT % ["female", sheet], columns, frames, _body.bind(true))
		_save(BODY_OUT % ["boy", sheet], columns, children, _body.bind(false))
		_save(BODY_OUT % ["girl", sheet], columns, children, _body.bind(true))
		for slug: String in PARTS:
			for suffix: String in PARTS[slug]:
				var draw := Callable(self, "_" + slug + suffix)
				_save(PART_OUT % [slug, sheet, suffix], columns, frames, draw)
				_save(CHILD_PART_OUT % [slug, sheet, suffix], columns, children, draw)
	print("guarda-roupa gerado")
	quit()


func _load(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	image.convert(Image.FORMAT_RGBA8)
	return image


func _read(template: Image, column: int, row: int, cell: int, offset: Vector2i, child: bool) -> Frame:
	var frame := Frame.new()
	frame.row = row
	frame.top = CELL
	if child:
		frame.as_child()
	for y: int in cell:
		for x: int in cell:
			var color := template.get_pixel(column * cell + x, row * cell + y)
			if color.a > 0.0:
				var p := Vector2i(x, y) + offset
				frame.pixels[p] = color
				frame.top = mini(frame.top, p.y)
	_measure(frame)
	return frame


func _measure(frame: Frame) -> void:
	frame.head_min = CELL
	frame.head_max = -1
	frame.hip_min = CELL
	frame.hip_max = -1
	frame.top_min = CELL
	frame.top_max = -1
	for p: Vector2i in frame.pixels:
		var rel := p.y - frame.top
		if rel <= frame.head_end:
			frame.head_min = mini(frame.head_min, p.x)
			frame.head_max = maxi(frame.head_max, p.x)
		if rel == frame.hip_row:
			frame.hip_min = mini(frame.hip_min, p.x)
			frame.hip_max = maxi(frame.hip_max, p.x)
		if rel == 0:
			frame.top_min = mini(frame.top_min, p.x)
			frame.top_max = maxi(frame.top_max, p.x)


func _save(path: String, columns: int, frames: Array[Frame], draw: Callable) -> void:
	var image := Image.create(columns * CELL, ROWS * CELL, false, Image.FORMAT_RGBA8)
	for index: int in frames.size():
		var origin := Vector2i(index % columns, index / columns) * CELL
		var layer: Dictionary = draw.call(frames[index])
		for p: Vector2i in layer:
			if p.x >= 0 and p.y >= 0 and p.x < CELL and p.y < CELL:
				image.set_pixelv(origin + p, layer[p])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	image.save_png(ProjectSettings.globalize_path(path))


# --- medidas -----------------------------------------------------------------

static func _same(a: Color, b: Color) -> bool:
	return a.to_rgba32() == b.to_rgba32()


static func _rel(f: Frame, p: Vector2i) -> int:
	return p.y - f.top


static func _boundary(f: Frame, p: Vector2i) -> bool:
	for side: Vector2i in SIDES:
		if not f.pixels.has(p + side):
			return true
	return false


static func _hips(f: Frame, x: int) -> bool:
	return x >= f.hip_min and x <= f.hip_max


static func _foot(f: Frame, p: Vector2i) -> bool:
	return f.pixels.has(p) and _rel(f, p) >= f.legs and _same(f.pixels[p], LIGHT)


## Os olhos e a bochecha: o contorno e o rosado de dentro da cabeça.
static func _face_pixel(f: Frame, p: Vector2i) -> bool:
	if _rel(f, p) > f.head_end or _boundary(f, p):
		return false
	var color: Color = f.pixels[p]
	return _same(color, OUTLINE) or _same(color, BLUSH)


static func _faces_right(f: Frame) -> bool:
	return f.row == LOWER or f.row == SIDE or f.row == UPPER


# --- pintura -----------------------------------------------------------------

## Uma peça feita dos pixels do corpo: o contorno fica, a luz e a sombra viram as chaves.
static func _dress(f: Frame, keep: Callable, light: int, shade: int, hem_row: int = -1) -> Dictionary:
	var layer := {}
	for p: Vector2i in f.pixels:
		if not keep.call(p):
			continue
		var color: Color = f.pixels[p]
		if _same(color, OUTLINE):
			layer[p] = OUTLINE
		elif _rel(f, p) == hem_row:
			layer[p] = KEYS[mini(shade + 1, 3)]
		elif _same(color, SHADE):
			layer[p] = KEYS[shade]
		else:
			layer[p] = KEYS[light]
	return layer


## Uma peça com forma própria: contorno onde encosta no vazio (sem corpo nem peça).
static func _paint(f: Frame, mask: Dictionary, shade: Callable, solid: bool = true) -> Dictionary:
	var layer := {}
	for p: Vector2i in mask:
		var edge := false
		for side: Vector2i in SIDES:
			var q := p + side
			if not mask.has(q) and not (solid and f.pixels.has(q)):
				edge = true
		layer[p] = OUTLINE if edge else shade.call(p)
	return layer


static func _hair_shade(p: Vector2i, f: Frame, mask: Dictionary) -> Color:
	var below := p + Vector2i.DOWN
	if f.pixels.has(below) and not mask.has(below):
		return KEYS[3]
	if _rel(f, p) <= 1:
		return KEYS[0]
	if p.x <= f.head_min + 1:
		return KEYS[2]
	return KEYS[1]


## A cabeça coberta pelo cabelo, com 1 linha de volume em cima.
static func _hair_mask(f: Frame, volume: bool = true) -> Dictionary:
	var mask := {}
	for p: Vector2i in f.pixels:
		var rel := _rel(f, p)
		if rel > f.head_end:
			continue
		var covered := rel <= f.h(3)
		match f.row:
			FRONT:
				covered = covered or (rel <= f.h(6) and (p.x <= f.head_min + 1 or p.x >= f.head_max - 1))
			LOWER:
				covered = covered or (rel <= f.head_end - 2 and p.x <= f.head_min + 2) or (rel <= f.h(5) and p.x >= f.head_max - 1)
			SIDE:
				covered = covered or (rel <= f.head_end - 1 and p.x <= f.head_min + 3)
			UPPER:
				covered = covered or (rel <= f.head_end - 1 and p.x <= f.head_max - 2) or rel <= f.h(4)
			BACK:
				covered = true
		if covered:
			mask[p] = true
	if volume:
		for x: int in range(f.top_min, f.top_max + 1):
			mask[Vector2i(x, f.top - 1)] = true
	return mask


static func _rect(mask: Dictionary, x0: int, x1: int, y0: int, y1: int) -> void:
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			mask[Vector2i(x, y)] = true


# --- corpos e rostos ---------------------------------------------------------

func _body(f: Frame, female: bool) -> Dictionary:
	var layer := {}
	for p: Vector2i in f.pixels:
		var color: Color = f.pixels[p]
		var rel := _rel(f, p)
		if _face_pixel(f, p):
			layer[p] = KEYS[0]
		elif _same(color, OUTLINE):
			layer[p] = OUTLINE
		elif (rel == f.hips or rel == f.legs) and _hips(f, p.x):
			layer[p] = UNDERWEAR
		elif _same(color, SHADE) or _same(color, EAR):
			layer[p] = KEYS[1]
		else:
			layer[p] = KEYS[0]
	if female and not f.child and (f.row == FRONT or f.row == BACK):
		var waist := f.top + f.shoulders + 4
		for x: int in [f.hip_min + 1, f.hip_max - 1]:
			var p := Vector2i(x, waist)
			if layer.has(p) and layer[p] == KEYS[0]:
				layer[p] = KEYS[1]
	return layer


func _face_1(f: Frame) -> Dictionary:
	var layer := {}
	for p: Vector2i in f.pixels:
		if _face_pixel(f, p):
			layer[p] = f.pixels[p]
	return layer


## Olhos mais baixos, com sobrancelha, e sem bochecha.
func _face_2(f: Frame) -> Dictionary:
	var layer := {}
	for p: Vector2i in f.pixels:
		if not _face_pixel(f, p) or not _same(f.pixels[p], OUTLINE):
			continue
		var above := p + Vector2i.UP
		if _face_pixel(f, above) and _same(f.pixels[above], OUTLINE):
			layer[p] = OUTLINE
		else:
			layer[p + Vector2i.UP * 2] = OUTLINE
	return layer


# --- cabelos -----------------------------------------------------------------

func _hair_short(f: Frame) -> Dictionary:
	var mask := _hair_mask(f)
	return _paint(f, mask, _hair_shade.bind(f, mask))


func _hair_spiky(f: Frame) -> Dictionary:
	var mask := _hair_mask(f)
	var span := f.top_max - f.top_min
	for x: int in [f.top_min + 1, f.top_min + span / 2, f.top_max - 1]:
		_rect(mask, x - 1, x + 1, f.top - 2, f.top - 2)
		mask[Vector2i(x, f.top - 3)] = true
	return _paint(f, mask, _hair_shade.bind(f, mask))


func _hair_spiky_short(f: Frame) -> Dictionary:
	var mask := _hair_mask(f, false)
	return _paint(f, mask, _hair_shade.bind(f, mask))


func _hair_ponytail(f: Frame) -> Dictionary:
	var mask := _hair_mask(f)
	var center := (f.head_min + f.head_max) / 2
	if f.row == BACK:
		_rect(mask, center - 1, center + 1, f.top + f.h(8), f.top + f.h(14))
	elif f.row == UPPER:
		_rect(mask, f.head_min + 2, f.head_min + 4, f.top + f.h(8), f.top + f.h(13))
	return _paint(f, mask, _hair_shade.bind(f, mask))


func _hair_ponytail_back(f: Frame) -> Dictionary:
	var mask := {}
	match f.row:
		FRONT:
			_rect(mask, f.head_max - 1, f.head_max + 1, f.top + f.h(8), f.top + f.h(13))
		LOWER:
			_rect(mask, f.head_min - 2, f.head_min, f.top + f.h(4), f.top + f.h(12))
		SIDE:
			_rect(mask, f.head_min - 3, f.head_min - 1, f.top + f.h(3), f.top + f.h(11))
	return _paint(f, mask, _flat.bind(2), false)


func _long_mask(f: Frame, volume: bool) -> Dictionary:
	var mask := _hair_mask(f, volume)
	match f.row:
		FRONT:
			_rect(mask, f.head_min, f.head_min + 1, f.top + f.h(7), f.top + f.hair_end - 1)
			_rect(mask, f.head_max - 1, f.head_max, f.top + f.h(7), f.top + f.hair_end - 1)
		LOWER:
			_rect(mask, f.head_min, f.head_min + 2, f.top + f.h(9), f.top + f.hair_end - 1)
		SIDE:
			_rect(mask, f.head_min, f.head_min + 3, f.top + f.h(10), f.top + f.hair_end - 1)
		UPPER, BACK:
			var nape := f.head_end if f.child else f.neck
			_rect(mask, f.head_min + 1, f.head_max - 1, f.top + nape, f.top + f.hair_end)
	return mask


func _hair_long(f: Frame) -> Dictionary:
	var mask := _long_mask(f, true)
	return _paint(f, mask, _hair_shade.bind(f, mask))


func _hair_long_short(f: Frame) -> Dictionary:
	var mask := _long_mask(f, false)
	return _paint(f, mask, _hair_shade.bind(f, mask))


func _hair_long_back(f: Frame) -> Dictionary:
	var mask := {}
	if f.row != UPPER and f.row != BACK:
		_rect(mask, f.head_min, f.head_max, f.top + f.h(4), f.top + f.hair_end)
	return _paint(f, mask, _flat.bind(2), false)


static func _flat(_p: Vector2i, key: int) -> Color:
	return KEYS[key]


# --- chapéus -----------------------------------------------------------------

func _cap(f: Frame) -> Dictionary:
	var mask := {}
	for p: Vector2i in f.pixels:
		if _rel(f, p) <= f.h(3) or (f.row >= UPPER and _rel(f, p) <= f.h(4)):
			mask[p] = true
	for x: int in range(f.top_min, f.top_max + 1):
		mask[Vector2i(x, f.top - 1)] = true
	var brim := {}
	match f.row:
		FRONT:
			_rect(brim, f.head_min + 1, f.head_max - 1, f.top + f.h(4), f.top + f.h(4))
		LOWER, SIDE:
			_rect(brim, f.head_max - 2, f.head_max + 3, f.top + f.h(4), f.top + f.h(4))
	mask.merge(brim)
	return _paint(f, mask, _cap_shade.bind(f, brim))


static func _cap_shade(p: Vector2i, f: Frame, brim: Dictionary) -> Color:
	if brim.has(p):
		return KEYS[2]
	return KEYS[0] if _rel(f, p) <= 0 else KEYS[1]


func _straw_hat(f: Frame) -> Dictionary:
	var mask := {}
	_rect(mask, f.top_min, f.top_max, f.top - 2, f.top + f.h(3) - 1)
	var brim := {}
	_rect(brim, f.head_min - 3, f.head_max + 3, f.top + f.h(3), f.top + f.h(3))
	_rect(brim, f.head_min - 1, f.head_max + 1, f.top + f.h(4), f.top + f.h(4))
	mask.merge(brim)
	return _paint(f, mask, _straw_shade.bind(f, brim), false)


static func _straw_shade(p: Vector2i, f: Frame, brim: Dictionary) -> Color:
	var rel := _rel(f, p)
	if rel == f.h(3) - 1:
		return KEYS[3]
	if brim.has(p):
		return KEYS[1]
	return KEYS[0] if rel <= 0 else KEYS[1]


func _helmet(f: Frame) -> Dictionary:
	var mask := {}
	for p: Vector2i in f.pixels:
		var rel := _rel(f, p)
		if rel > f.head_end:
			continue
		var window := false
		if rel >= f.h(5):
			match f.row:
				FRONT:
					window = p.x >= f.head_min + 2 and p.x <= f.head_max - 2
				LOWER:
					window = p.x >= f.head_min + 4
				SIDE:
					window = p.x >= f.head_min + 5
		if not window:
			mask[p] = true
	for x: int in range(f.top_min, f.top_max + 1):
		mask[Vector2i(x, f.top - 1)] = true
	return _paint(f, mask, _helmet_shade.bind(f))


static func _helmet_shade(p: Vector2i, f: Frame) -> Color:
	var rel := _rel(f, p)
	if rel == f.h(4):
		return KEYS[3]
	if rel <= 0:
		return KEYS[0]
	return KEYS[2] if p.x <= f.head_min + 1 else KEYS[1]


# --- roupas ------------------------------------------------------------------

static func _tshirt_keeps(p: Vector2i, f: Frame) -> bool:
	var rel := _rel(f, p)
	return (rel >= f.shoulders and rel <= f.sleeve) or (rel > f.sleeve and rel < f.hips and _hips(f, p.x))


func _tshirt(f: Frame) -> Dictionary:
	return _dress(f, _tshirt_keeps.bind(f), 0, 1, f.hips - 1)


static func _jacket_keeps(p: Vector2i, f: Frame) -> bool:
	var rel := _rel(f, p)
	return rel >= f.shoulders and rel < f.hips


func _jacket(f: Frame) -> Dictionary:
	var layer := _dress(f, _jacket_keeps.bind(f), 1, 2, f.hips - 1)
	var center := (f.hip_min + f.hip_max) / 2
	if f.row == FRONT or f.row == LOWER:
		var zipper := center if f.row == FRONT else center + 1
		for y: int in range(f.top + f.shoulders + 1, f.top + f.hips):
			var p := Vector2i(zipper, y)
			if layer.has(p) and layer[p] != OUTLINE:
				layer[p] = KEYS[3]
	return layer


static func _tank_top_keeps(p: Vector2i, f: Frame) -> bool:
	var rel := _rel(f, p)
	return rel > f.shoulders and rel < f.hips and _hips(f, p.x)


func _tank_top(f: Frame) -> Dictionary:
	return _dress(f, _tank_top_keeps.bind(f), 0, 1, f.hips - 1)


static func _pants_keeps(p: Vector2i, f: Frame) -> bool:
	if _foot(f, p):
		return false
	var rel := _rel(f, p)
	return ((rel == f.hips or rel == f.legs) and _hips(f, p.x)) or rel > f.legs


func _pants(f: Frame) -> Dictionary:
	return _dress(f, _pants_keeps.bind(f), 1, 2)


static func _shorts_keeps(p: Vector2i, f: Frame) -> bool:
	if f.child and _foot(f, p):
		return false
	var rel := _rel(f, p)
	return ((rel == f.hips or rel == f.legs) and _hips(f, p.x)) or rel == f.legs + 1


func _shorts(f: Frame) -> Dictionary:
	return _dress(f, _shorts_keeps.bind(f), 1, 1, f.legs + 1)


func _skirt(f: Frame) -> Dictionary:
	var mask := {}
	var waist := _skirt_waist(f)
	for step: int in _skirt_rows(f):
		var grow := (step + 1) / 2
		_rect(mask, f.hip_min - grow, f.hip_max + grow, f.top + waist + step, f.top + waist + step)
	return _paint(f, mask, _skirt_shade.bind(f), f.child)


## Na criança, a saia sobe 1 linha e tem 2, para não cobrir os pés.
static func _skirt_waist(f: Frame) -> int:
	return f.hips - 1 if f.child else f.hips


static func _skirt_rows(f: Frame) -> int:
	return 2 if f.child else 4


static func _skirt_shade(p: Vector2i, f: Frame) -> Color:
	var rel := _rel(f, p)
	var waist := _skirt_waist(f)
	if rel == waist + _skirt_rows(f) - 1:
		return KEYS[2]
	return KEYS[1] if rel > waist else KEYS[0]


func _sneakers(f: Frame) -> Dictionary:
	var layer := {}
	for p: Vector2i in f.pixels:
		if _foot(f, p):
			layer[p] = KEYS[0] if _foot(f, p + Vector2i.DOWN) else KEYS[2]
	return layer


func _boots(f: Frame) -> Dictionary:
	var layer := {}
	for p: Vector2i in f.pixels:
		if _foot(f, p):
			layer[p] = KEYS[2] if _foot(f, p + Vector2i.DOWN) else KEYS[3]
		elif _rel(f, p) >= f.legs and _same(f.pixels[p], SHADE):
			if _foot(f, p + Vector2i.DOWN) or _foot(f, p + Vector2i.DOWN * 2):
				layer[p] = KEYS[1]
	return layer
