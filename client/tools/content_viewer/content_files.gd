class_name ContentFiles
extends RefCounted
## Onde o jogo procura cada arquivo de conteúdo, e o que já existe
## (content-viewer/architecture.md, "Os arquivos"). Quando o caminho já é constante
## de uma classe do jogo, usa a constante dela. Os da Técnica moram aqui, e a tela da
## luta os usa daqui.
##
## Um arquivo existe quando o ResourceLoader o encontra, que é como o jogo o carrega:
## uma imagem que o Godot ainda não importou (sem o .import) conta como faltando.

const CREATURES_DIR := "res://assets/creatures"
const SKILL_ICON_PATH := "res://assets/skills/%s.png"
const SKILL_EFFECT_PATH := "res://assets/effects/skills/%s.png"
const SKILL_SOUND_PATH := "res://assets/sounds/skills/%s.wav"
## O som do dano, pela efetividade (board-battle/09); a tela da luta o usa daqui.
const HIT_SOUND_PATH := "res://assets/sounds/hits/%s.wav"
## Os sons de dano, com o nome que aparece na tela.
const HIT_SOUNDS: Dictionary[String, String] = {"normal": "normal", "super": "super efetivo", "weak": "pouco efetivo"}
const TAMER_CREDITS_PATH := "res://assets/tamer/CREDITOS.md"
## As peças que o mapa usa em todos os biomas (content-viewer/03, RF-03).
const COMMON_SURFACES: Array[String] = ["cliff", "side", "contour", "highlight"]
## O nome da superfície no mapa, quando é diferente do slug do bioma no catálogo: a
## Montanha é "mountain" no catálogo e "mont" no gerador do mapa (HexTile.surface()).
const SURFACE_OF_BIOME: Dictionary[String, String] = {"mountain": "mont"}
## O nome de cada decoração (HexDecorations.KIND_ROWS) na tela.
const DECORATION_NAMES: Dictionary[String, String] = {
	"tree": "árvore",
	"pine": "pinheiro",
	"bush": "arbusto",
	"dark_bush": "arbusto escuro",
	"tuft": "tufo de grama",
	"flowers": "flores",
	"fern": "samambaia",
	"dry_shrub": "arbusto seco",
	"dry_tuft": "tufo seco",
	"moss": "musgo",
	"pebbles": "pedrinhas",
	"rock": "pedra",
	"mossy_rock": "pedra com musgo",
	"brown_rock": "pedra marrom",
	"boulder": "rochedo",
	"rock_pile": "monte de pedras",
	"spire": "pináculo",
}

## Como o preview mostra cada arquivo.
enum Kind { IMAGE, EXPLORE_SHEET, BATTLE_SHEET, EFFECT, SOUND }

## As direções de cada folha, na ordem de uma volta: o nome, a linha da folha e se é a
## linha espelhada. Só o lado direito é desenhado; o esquerdo é a mesma arte
## espelhada, como no jogo (SheetSprite e BoardView._face).
const EXPLORE_DIRECTIONS: Array[Dictionary] = [
	{"label": "frente", "row": SheetSprite.FRONT_ROW, "mirrored": false},
	{"label": "desce à direita", "row": SheetSprite.LOWER_ROW, "mirrored": false},
	{"label": "direita", "row": SheetSprite.SIDE_ROW, "mirrored": false},
	{"label": "sobe à direita", "row": SheetSprite.UPPER_ROW, "mirrored": false},
	{"label": "costas", "row": SheetSprite.BACK_ROW, "mirrored": false},
	{"label": "sobe à esquerda", "row": SheetSprite.UPPER_ROW, "mirrored": true},
	{"label": "esquerda", "row": SheetSprite.SIDE_ROW, "mirrored": true},
	{"label": "desce à esquerda", "row": SheetSprite.LOWER_ROW, "mirrored": true},
]
## Uma direção que a folha ainda não tem: aparece tracejada, como um arquivo que falta.
const NO_ROW := -1
## As folhas da luta vão ter as mesmas 8 direções do explorar (pedido do dono em
## 2026-11-06), mas hoje a parada só tem frente e costas, e a andando só os 3 passos
## de lado. As que faltam ficam com NO_ROW; quando a folha ganhar a linha, ela entra
## aqui com a constante do BattleSheets.
const BATTLE_IDLE_DIRECTIONS: Array[Dictionary] = [
	{"label": "frente", "row": BattleSheets.IDLE_SOUTH, "mirrored": false},
	{"label": "desce à direita", "row": NO_ROW, "mirrored": false},
	{"label": "direita", "row": NO_ROW, "mirrored": false},
	{"label": "sobe à direita", "row": NO_ROW, "mirrored": false},
	{"label": "costas", "row": BattleSheets.IDLE_NORTH, "mirrored": false},
	{"label": "sobe à esquerda", "row": NO_ROW, "mirrored": true},
	{"label": "esquerda", "row": NO_ROW, "mirrored": true},
	{"label": "desce à esquerda", "row": NO_ROW, "mirrored": true},
]
const BATTLE_WALK_DIRECTIONS: Array[Dictionary] = [
	{"label": "frente", "row": NO_ROW, "mirrored": false},
	{"label": "desce à direita", "row": BattleSheets.WALK_DOWN, "mirrored": false},
	{"label": "direita", "row": BattleSheets.WALK_SIDE, "mirrored": false},
	{"label": "sobe à direita", "row": BattleSheets.WALK_UP, "mirrored": false},
	{"label": "costas", "row": NO_ROW, "mirrored": false},
	{"label": "sobe à esquerda", "row": BattleSheets.WALK_UP, "mirrored": true},
	{"label": "esquerda", "row": BattleSheets.WALK_SIDE, "mirrored": true},
	{"label": "desce à esquerda", "row": BattleSheets.WALK_DOWN, "mirrored": true},
]


## Um arquivo esperado: o nome curto que aparece no preview, o caminho e o tipo.
class Entry:
	extends RefCounted
	var label: String
	var path: String
	var kind: Kind
	## Para as folhas: o slug do Ecobeast e qual folha (idle ou walk).
	var slug: String
	var sheet: String
	## Um ciclo da folha, em segundos; 0 usa o ritmo dos Ecobeasts no explorar.
	var cycle := 0.0

	func _init(entry_label: String, entry_path: String, entry_kind: Kind, entry_slug := "", entry_sheet := "") -> void:
		label = entry_label
		path = entry_path
		kind = entry_kind
		slug = entry_slug
		sheet = entry_sheet

	func exists() -> bool:
		return ContentFiles.exists(path)

	## As direções da folha; uma imagem ou um som não tem nenhuma.
	func directions() -> Array[Dictionary]:
		var empty: Array[Dictionary] = []
		match kind:
			Kind.EXPLORE_SHEET:
				return ContentFiles.EXPLORE_DIRECTIONS
			Kind.BATTLE_SHEET:
				return ContentFiles.BATTLE_IDLE_DIRECTIONS if sheet == BattleSheets.IDLE else ContentFiles.BATTLE_WALK_DIRECTIONS
		return empty

	## As direções desenhadas (não espelhadas) que a folha ainda não tem.
	func missing_directions() -> Array[String]:
		var labels: Array[String] = []
		for direction: Dictionary in directions():
			if not direction["mirrored"] and direction["row"] == NO_ROW:
				labels.append(direction["label"])
		return labels

	## Pronto: o arquivo existe e, se for uma folha, tem todas as direções.
	func complete() -> bool:
		return exists() and missing_directions().is_empty()

	## O que falta, numa frase curta: "battle idle" ou "battle idle (3 direções)".
	func missing_text() -> String:
		if not exists():
			return label
		var count := missing_directions().size()
		return "%s (%d %s)" % [label, count, "direção" if count == 1 else "direções"]


static func exists(path: String) -> bool:
	return ResourceLoader.exists(path)


## Os 6 arquivos de um Ecobeast, na ordem em que aparecem.
static func creature_files(slug: String) -> Array[Entry]:
	var idle := CreatureSprite.IDLE
	var walk := CreatureSprite.WALK
	var files: Array[Entry] = [
		Entry.new("front", CreaturePortrait.SPRITE_PATH % slug, Kind.IMAGE),
		Entry.new("board", BoardView.BOARD_SPRITE_PATH % slug, Kind.IMAGE),
		Entry.new("explore idle", CreatureSprite.SHEET_PATH % [slug, idle], Kind.EXPLORE_SHEET, slug, idle),
		Entry.new("explore walk", CreatureSprite.SHEET_PATH % [slug, walk], Kind.EXPLORE_SHEET, slug, walk),
		Entry.new("battle idle", BattleSheets.PATH % [slug, BattleSheets.IDLE], Kind.BATTLE_SHEET, slug, BattleSheets.IDLE),
		Entry.new("battle walk", BattleSheets.PATH % [slug, BattleSheets.WALK], Kind.BATTLE_SHEET, slug, BattleSheets.WALK),
	]
	return files


## Os 3 arquivos de uma Técnica: ícone, efeito e som.
static func skill_files(slug: String) -> Array[Entry]:
	var files: Array[Entry] = [
		Entry.new("ícone", SKILL_ICON_PATH % slug, Kind.IMAGE),
		Entry.new("efeito", SKILL_EFFECT_PATH % slug, Kind.EFFECT),
		Entry.new("som", SKILL_SOUND_PATH % slug, Kind.SOUND),
	]
	return files


## As folhas do Domador, no mesmo formato das do explorar, com o ritmo dele.
static func tamer_files() -> Array[Entry]:
	var files: Array[Entry] = []
	for sheet_name: String in [TamerSprite.IDLE, TamerSprite.RUN]:
		var entry := Entry.new(sheet_name, TamerSprite.SHEET_PATH % sheet_name, Kind.EXPLORE_SHEET, "", sheet_name)
		entry.cycle = TamerSprite.IDLE_SECONDS if sheet_name == TamerSprite.IDLE else TamerSprite.RUN_SECONDS
		files.append(entry)
	return files


## Os sons de dano: normal, super efetivo e pouco efetivo.
static func hit_sounds() -> Array[Entry]:
	var files: Array[Entry] = []
	for kind: String in HIT_SOUNDS:
		files.append(Entry.new(HIT_SOUNDS[kind], HIT_SOUND_PATH % kind, Kind.SOUND))
	return files


## O ícone de um item.
static func item_icon(slug: String) -> Entry:
	return Entry.new("ícone", ItemIcon.SPRITE_PATH % slug, Kind.IMAGE)


## A superfície que o mapa desenha num bioma.
static func biome_surface(slug: String) -> Entry:
	return Entry.new("superfície", HexMapView.SURFACE_PATH % surface_name(slug), Kind.IMAGE)


## O nome que o mapa usa para a superfície e as decorações do bioma.
static func surface_name(biome_slug: String) -> String:
	return SURFACE_OF_BIOME.get(biome_slug, biome_slug)


## A folha das decorações, com uma linha por tipo e uma coluna por variante.
static func decorations_sheet() -> Entry:
	return Entry.new("decorações", HexDecorations.TEXTURE_PATH, Kind.IMAGE)


## As peças que o mapa usa em todos os biomas, com o nome do arquivo.
static func common_pieces() -> Array[Entry]:
	var pieces: Array[Entry] = []
	for surface: String in COMMON_SURFACES:
		var path := HexMapView.SURFACE_PATH % surface
		pieces.append(Entry.new(path.get_file(), path, Kind.IMAGE))
	for path: String in [HexTransitions.TEXTURE_PATH, HexTransitions.DRIP_TEXTURE_PATH]:
		pieces.append(Entry.new(path.get_file(), path, Kind.IMAGE))
	return pieces


## Quantos dos arquivos estão prontos: existem e têm todas as direções.
static func count_complete(files: Array[Entry]) -> int:
	var count := 0
	for entry: Entry in files:
		if entry.complete():
			count += 1
	return count


## O que falta de cada arquivo que não está pronto, na ordem da lista.
static func missing_labels(files: Array[Entry]) -> Array[String]:
	var labels: Array[String] = []
	for entry: Entry in files:
		if not entry.complete():
			labels.append(entry.missing_text())
	return labels


## As subpastas de `dir`, em ordem alfabética.
static func folders(dir: String) -> Array[String]:
	var names: Array[String] = []
	names.assign(DirAccess.get_directories_at(dir))
	names.sort()
	return names


## As subpastas de `dir` que não batem com nenhum slug, em ordem alfabética.
static func orphan_folders(dir: String, slugs: Array[String]) -> Array[String]:
	var orphans: Array[String] = []
	for folder: String in folders(dir):
		if folder not in slugs:
			orphans.append(folder)
	return orphans
