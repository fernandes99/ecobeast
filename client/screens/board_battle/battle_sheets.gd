class_name BattleSheets
extends RefCounted
## As folhas da luta de um Ecobeast (board-battle/07), em
## res://assets/creatures/<slug>/battle/, montadas do PixelLab pela ferramenta da skill
## creature-sprites. Uma linha por vista e uma coluna por quadro, todas olhando para a
## direita: a esquerda é a mesma arte espelhada.
##
## Tudo sai da própria imagem, sem arquivo de dados ao lado: a célula é quadrada e a
## mesma nas duas folhas; o idle tem 2 ou 5 linhas, e o walk 3 ou 5 (board-battle/17),
## o que a proporção entre as alturas diz; uma linha tem os quadros até a primeira
## célula vazia; e os pés ficam na última linha de pixels de todas as células.

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
## As alturas que cada folha pode ter, em linhas: as vistas de sempre, ou com as a mais.
const IDLE_ROWS: PackedInt32Array = [2, 5]
const WALK_ROWS: PackedInt32Array = [3, 5]
## Segundos por quadro. O idle usa o tempo dos GIFs do PixelLab; o walk é mais
## rápido, para um ciclo caber num passo de hexágono. A revisar.
const FRAME_SECONDS: Dictionary[String, float] = {IDLE: 0.2, WALK: 0.15}

## As folhas de cada espécie, lidas uma vez: a luta pode ter vários Ecobeasts iguais.
static var _by_slug: Dictionary[String, BattleSheets] = {}

var textures: Dictionary[String, Texture2D] = {}
## Quantas linhas cada folha tem.
var rows: Dictionary[String, int] = {}
## Quantos quadros cada linha tem, por folha.
var frames: Dictionary[String, PackedInt32Array] = {}
var cell := 0
## A última linha de pixels dos pés, dentro da célula.
var feet := 0
## A primeira linha com pixels, em todas as células: dá a altura do Ecobeast.
var top := 0
## A largura do primeiro quadro de frente, para a sombra.
var rest_width := 0


static func has_sheets(slug: String) -> bool:
	return ResourceLoader.exists(PATH % [slug, IDLE]) and ResourceLoader.exists(PATH % [slug, WALK])


## As folhas da espécie, ou null se ela não tem as duas.
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


## Acha quantas linhas cada folha tem e a célula, que é a mesma nas duas. Cada
## combinação de linhas dá uma proporção diferente entre as alturas, então no máximo
## uma serve.
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


## Se a folha tem a linha: o idle de 2 linhas não tem as vistas de lado.
func has_row(sheet: String, row: int) -> bool:
	return row >= 0 and row < rows[sheet]


## A altura do Ecobeast em pixels da arte, dos pés ao ponto mais alto.
func height() -> int:
	return feet + 1 - top


## Quanto dura um passo de hexágono: um ciclo do walk.
func step_seconds() -> float:
	return frame_count(WALK, WALK_SIDE) * FRAME_SECONDS[WALK]
