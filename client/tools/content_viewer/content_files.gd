class_name ContentFiles
extends RefCounted

const CREATURES_DIR := "res://assets/creatures"
const SKILL_ICON_PATH := "res://assets/skills/%s.png"
const SKILL_EFFECT_PATH := "res://assets/effects/skills/%s.png"
const SKILL_PROJECTILE_PATH := "res://assets/effects/skills/%s_projectile.png"
const SKILL_SOUND_PATH := "res://assets/sounds/skills/%s.wav"
const CREATURE_CALL_PATH := "res://assets/creatures/%s/call.wav"
const HIT_SOUND_PATH := "res://assets/sounds/hits/%s.wav"
const HIT_SOUNDS: Dictionary[String, String] = {"normal": "normal", "super": "super efetivo", "weak": "pouco efetivo"}
const TAMER_CREDITS_PATH := "res://assets/tamer/CREDITOS.md"
const COMMON_SURFACES: Array[String] = ["cliff", "side", "contour", "highlight"]
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
const NO_ROW := -1
const BATTLE_IDLE_DIRECTIONS: Array[Dictionary] = [
	{"label": "frente", "row": BattleSheets.IDLE_SOUTH, "mirrored": false},
	{"label": "desce à direita", "row": BattleSheets.IDLE_DOWN, "mirrored": false},
	{"label": "direita", "row": BattleSheets.IDLE_SIDE, "mirrored": false},
	{"label": "sobe à direita", "row": BattleSheets.IDLE_UP, "mirrored": false},
	{"label": "costas", "row": BattleSheets.IDLE_NORTH, "mirrored": false},
	{"label": "sobe à esquerda", "row": BattleSheets.IDLE_UP, "mirrored": true},
	{"label": "esquerda", "row": BattleSheets.IDLE_SIDE, "mirrored": true},
	{"label": "desce à esquerda", "row": BattleSheets.IDLE_DOWN, "mirrored": true},
]
const BATTLE_WALK_DIRECTIONS: Array[Dictionary] = [
	{"label": "frente", "row": BattleSheets.WALK_SOUTH, "mirrored": false},
	{"label": "desce à direita", "row": BattleSheets.WALK_DOWN, "mirrored": false},
	{"label": "direita", "row": BattleSheets.WALK_SIDE, "mirrored": false},
	{"label": "sobe à direita", "row": BattleSheets.WALK_UP, "mirrored": false},
	{"label": "costas", "row": BattleSheets.WALK_NORTH, "mirrored": false},
	{"label": "sobe à esquerda", "row": BattleSheets.WALK_UP, "mirrored": true},
	{"label": "esquerda", "row": BattleSheets.WALK_SIDE, "mirrored": true},
	{"label": "desce à esquerda", "row": BattleSheets.WALK_DOWN, "mirrored": true},
]


class Entry:
	extends RefCounted
	var label: String
	var path: String
	var kind: Kind
	var slug: String
	var sheet: String
	var cycle := 0.0
	var optional := false

	func _init(entry_label: String, entry_path: String, entry_kind: Kind, entry_slug := "", entry_sheet := "") -> void:
		label = entry_label
		path = entry_path
		kind = entry_kind
		slug = entry_slug
		sheet = entry_sheet

	func exists() -> bool:
		return ContentFiles.exists(path)

	func directions() -> Array[Dictionary]:
		var empty: Array[Dictionary] = []
		match kind:
			Kind.EXPLORE_SHEET:
				return ContentFiles.EXPLORE_DIRECTIONS
			Kind.BATTLE_SHEET:
				return ContentFiles.BATTLE_IDLE_DIRECTIONS if sheet == BattleSheets.IDLE else ContentFiles.BATTLE_WALK_DIRECTIONS
		return empty

	func has_direction(direction: Dictionary) -> bool:
		var row: int = direction["row"]
		if row == NO_ROW:
			return false
		if kind != Kind.BATTLE_SHEET:
			return true
		var sheets := BattleSheets.for_slug(slug)
		return sheets != null and sheets.has_row(sheet, row)

	func missing_directions() -> Array[String]:
		var labels: Array[String] = []
		for direction: Dictionary in directions():
			if not direction["mirrored"] and not has_direction(direction):
				labels.append(direction["label"])
		return labels

	func complete() -> bool:
		return exists() and missing_directions().is_empty()

	func missing_text() -> String:
		if not exists():
			return label
		var count := missing_directions().size()
		return "%s (%d %s)" % [label, count, "direção" if count == 1 else "direções"]


static func exists(path: String) -> bool:
	return ResourceLoader.exists(path)


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
		Entry.new("call", CREATURE_CALL_PATH % slug, Kind.SOUND),
	]
	return files


static func skill_files(slug: String) -> Array[Entry]:
	var files: Array[Entry] = [
		Entry.new("ícone", SKILL_ICON_PATH % slug, Kind.IMAGE),
		Entry.new("efeito", SKILL_EFFECT_PATH % slug, Kind.EFFECT),
		Entry.new("som", SKILL_SOUND_PATH % slug, Kind.SOUND),
	]
	return files


static func skill_optional_files(slug: String) -> Array[Entry]:
	var projectile := Entry.new("projétil", SKILL_PROJECTILE_PATH % slug, Kind.EFFECT)
	projectile.optional = true
	var files: Array[Entry] = [projectile]
	return files


static func tamer_files() -> Array[Entry]:
	var files: Array[Entry] = []
	for sheet_name: String in [TamerSprite.IDLE, TamerSprite.RUN]:
		var entry := Entry.new(sheet_name, TamerSprite.SHEET_PATH % sheet_name, Kind.EXPLORE_SHEET, "", sheet_name)
		entry.cycle = TamerSprite.IDLE_SECONDS if sheet_name == TamerSprite.IDLE else TamerSprite.RUN_SECONDS
		files.append(entry)
	return files


static func hit_sounds() -> Array[Entry]:
	var files: Array[Entry] = []
	for kind: String in HIT_SOUNDS:
		files.append(Entry.new(HIT_SOUNDS[kind], HIT_SOUND_PATH % kind, Kind.SOUND))
	return files


static func item_icon(slug: String) -> Entry:
	return Entry.new("ícone", ItemIcon.SPRITE_PATH % slug, Kind.IMAGE)


static func biome_surface(slug: String) -> Entry:
	return Entry.new("superfície", HexMapView.SURFACE_PATH % slug, Kind.IMAGE)


static func decorations_sheet() -> Entry:
	return Entry.new("decorações", HexDecorations.TEXTURE_PATH, Kind.IMAGE)


static func common_pieces() -> Array[Entry]:
	var pieces: Array[Entry] = []
	for surface: String in COMMON_SURFACES:
		var path := HexMapView.SURFACE_PATH % surface
		pieces.append(Entry.new(path.get_file(), path, Kind.IMAGE))
	for path: String in [HexTransitions.TEXTURE_PATH, HexTransitions.DRIP_TEXTURE_PATH]:
		pieces.append(Entry.new(path.get_file(), path, Kind.IMAGE))
	return pieces


static func count_complete(files: Array[Entry]) -> int:
	var count := 0
	for entry: Entry in files:
		if entry.complete():
			count += 1
	return count


static func missing_labels(files: Array[Entry]) -> Array[String]:
	var labels: Array[String] = []
	for entry: Entry in files:
		if not entry.complete():
			labels.append(entry.missing_text())
	return labels


static func folders(dir: String) -> Array[String]:
	var names: Array[String] = []
	names.assign(DirAccess.get_directories_at(dir))
	names.sort()
	return names


static func orphan_folders(dir: String, slugs: Array[String]) -> Array[String]:
	var orphans: Array[String] = []
	for folder: String in folders(dir):
		if folder not in slugs:
			orphans.append(folder)
	return orphans
