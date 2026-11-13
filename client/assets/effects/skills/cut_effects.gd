## Recorta os efeitos das Técnicas do kit "Effect and FX Pixel All Free" (fora do repositório).
## Cada folha do kit tem 9 linhas de cor com os mesmos quadros de 64; a linha vem do Elemento
## (.specs/board-battle/18-element-skill-effects.md).
## godot --headless -s res://assets/effects/skills/cut_effects.gd -- "<pasta Free do kit>" [slugs]
extends SceneTree

const CELL := 64
const OUT := "res://assets/effects/skills/%s.png"

const ELEMENT_ROWS := {
	"volt": 1, "light": 1,
	"toxin": 2, "mind": 2,
	"water": 3, "ice": 3,
	"flora": 4, "bug": 4,
	"beast": 5,
	"wind": 6, "metal": 6,
	"earth": 7,
	"fire": 8,
	"shadow": 9, "arcane": 9,
}

## slug da Técnica: [Elemento, "Part/número"]
const EFFECTS := {
	"mordida_brasa": ["fire", "2/64"],
	"fumaca_densa": ["fire", "10/476"],
	"presa_ignea": ["fire", "13/622"],
	"chama_espiral": ["fire", "6/296"],
	"couraca_de_cinzas": ["fire", "14/674"],
	"erupcao_solar": ["fire", "11/527"],
	"jato_de_mare": ["water", "12/566"],
	"espuma_densa": ["water", "11/519"],
	"garra_de_mare": ["water", "11/509"],
	"casca_fechada": ["water", "11/528"],
	"lamina_d_agua": ["water", "3/114"],
	"mare_restauradora": ["water", "14/673"],
	"torrente": ["water", "10/484"],
	"muralha_de_coral": ["water", "15/712"],
	"maremoto": ["water", "3/124"],
	"chicote_de_raiz": ["flora", "11/516"],
	"esporos_sonolentos": ["flora", "12/568"],
	"seiva_vital": ["flora", "3/135"],
	"folha_navalha": ["flora", "6/283"],
	"banho_de_sol": ["flora", "14/652"],
	"tempestade_de_petalas": ["flora", "4/174"],
	"explosao_florida": ["flora", "2/79"],
}

const PROJECTILES := {
	"chama_espiral": ["fire", "12/578"],
}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Passe a pasta Free do kit.")
		quit(1)
		return
	var kit: String = args[0]
	var only := args.slice(1)
	for slug: String in EFFECTS:
		if only.is_empty() or slug in only:
			_cut(kit, EFFECTS[slug], slug)
	for slug: String in PROJECTILES:
		if only.is_empty() or slug in only:
			_cut(kit, PROJECTILES[slug], slug + "_projectile")
	quit()


func _cut(kit: String, entry: Array, name: String) -> void:
	var sheet_id: PackedStringArray = (entry[1] as String).split("/")
	var sheet := Image.load_from_file("%s/Part %s/%s.png" % [kit, sheet_id[0], sheet_id[1]])
	if sheet == null:
		push_error("Folha %s não encontrada." % entry[1])
		return
	sheet.convert(Image.FORMAT_RGBA8)
	var y: int = (ELEMENT_ROWS[entry[0]] - 1) * CELL
	var frames: Array[int] = []
	for frame in sheet.get_width() / CELL:
		if not sheet.get_region(Rect2i(frame * CELL, y, CELL, CELL)).is_invisible():
			frames.append(frame)
	var first: int = frames[0]
	var count: int = frames[-1] - first + 1
	var strip := Image.create(count * CELL, CELL, false, Image.FORMAT_RGBA8)
	strip.blit_rect(sheet, Rect2i(first * CELL, y, count * CELL, CELL), Vector2i.ZERO)
	strip.save_png(ProjectSettings.globalize_path(OUT % name))
	print("%s: %d quadros" % [name, count])
