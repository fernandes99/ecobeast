class_name BattleSheets
extends RefCounted

const PATH := "res://assets/creatures/%s/battle/%s.png"
const IDLE := "idle"
const WALK := "walk"
## As linhas de cada folha, de cima para baixo. As 3 últimas do idle (de lado, na
## ordem do walk) só existem no idle de 5 linhas, e as 2 últimas do walk (de frente e
## de costas, que o tabuleiro não usa) só no walk de 5 linhas (board-battle/17).
const IDLE_SOUTH := 0
const IDLE_NORTH := 1
const IDLE_DOWN := 2
const IDLE_SIDE := 3
const IDLE_UP := 4
const WALK_DOWN := 0
const WALK_SIDE := 1
const WALK_UP := 2
const WALK_SOUTH := 3
const WALK_NORTH := 4
const IDLE_ROWS: PackedInt32Array = [2, 5]
const WALK_ROWS: PackedInt32Array = [3, 5]
const FRAME_SECONDS: Dictionary[String, float] = {IDLE: 0.2, WALK: 0.15}

static var _by_slug: Dictionary[String, BattleSheets] = {}

var textures: Dictionary[String, Texture2D] = {}
var rows: Dictionary[String, int] = {}
var frames: Dictionary[String, PackedInt32Array] = {}
var cell := 0
var feet := 0
var top := 0
var rest_width := 0


static func has_sheets(slug: String) -> bool:
	return ResourceLoader.exists(PATH % [slug, IDLE]) and ResourceLoader.exists(PATH % [slug, WALK])


static func for_slug(slug: String) -> BattleSheets:
	if not _by_slug.has(slug):
		_by_slug[slug] = _read(slug) if has_sheets(slug) else null
	return _by_slug[slug]


static func _read(slug: String) -> BattleSheets:
	var sheets := BattleSheets.new()
	var bottom := 0
	var highest := INF
	var images: Dictionary[String, Image] = {}
	for sheet: String in [IDLE, WALK]:
		var texture: Texture2D = load(PATH % [slug, sheet])
		sheets.textures[sheet] = texture
		images[sheet] = texture.get_image()
	if not _find_rows(sheets, images[IDLE].get_height(), images[WALK].get_height()):
		push_error("As folhas de %s não têm as linhas que a luta espera." % slug)
		return null
	var size := sheets.cell
	for sheet: String in [IDLE, WALK]:
		var image := images[sheet]
		var count_rows := sheets.rows[sheet]
		var counts := PackedInt32Array()
		for row: int in count_rows:
			var count := 0
			while (count + 1) * size <= image.get_width():
				var used := image.get_region(Rect2i(count * size, row * size, size, size)).get_used_rect()
				if used.size == Vector2i.ZERO:
					break
				bottom = maxi(bottom, used.end.y - 1)
				highest = minf(highest, used.position.y)
				if sheet == IDLE and row == IDLE_SOUTH and count == 0:
					sheets.rest_width = used.size.x
				count += 1
			if count == 0:
				push_error("A folha %s de %s tem uma linha vazia." % [sheet, slug])
				return null
			counts.append(count)
		sheets.frames[sheet] = counts
	sheets.feet = bottom
	sheets.top = int(highest)
	return sheets


static func _find_rows(sheets: BattleSheets, idle_height: int, walk_height: int) -> bool:
	for idle_rows: int in IDLE_ROWS:
		for walk_rows: int in WALK_ROWS:
			# Sem resto e com a mesma célula: idle / idle_rows == walk / walk_rows.
			if idle_height % idle_rows != 0 or idle_height * walk_rows != walk_height * idle_rows:
				continue
			@warning_ignore("integer_division")
			sheets.cell = idle_height / idle_rows
			sheets.rows[IDLE] = idle_rows
			sheets.rows[WALK] = walk_rows
			return true
	return false


func columns(sheet: String) -> int:
	return textures[sheet].get_width() / cell


func frame_count(sheet: String, row: int) -> int:
	return frames[sheet][row]


func has_row(sheet: String, row: int) -> bool:
	return row >= 0 and row < rows[sheet]


func height() -> int:
	return feet + 1 - top


func step_seconds() -> float:
	return frame_count(WALK, WALK_SIDE) * FRAME_SECONDS[WALK]
