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
	"wind": 6, "metal": 6, "earth": 6,
	"fire": 8,
	"shadow": 9, "arcane": 9,
}

## Elementos cuja linha é tingida pela cor deles no catálogo (board-battle/20 e /22):
## a cinza vira o verde-água do Vento e o marrom da Terra.
const ELEMENT_TINTS := {
	"wind": Color("#7CC9B8"),
	"earth": Color("#B07A43"),
}

## slug da Técnica: [Elemento, "Part/número"]
const EFFECTS := {
	"mordida_brasa": ["fire", "11/509"],
	"fumaca_densa": ["fire", "10/476"],
	"presa_ignea": ["fire", "10/477"],
	"chama_espiral": ["fire", "6/296"],
	"couraca_de_cinzas": ["fire", "14/674"],
	"erupcao_solar": ["fire", "9/436"],
	"jato_de_mare": ["water", "12/566"],
	"espuma_densa": ["water", "11/519"],
	"garra_de_mare": ["water", "11/509"],
	"casca_fechada": ["water", "11/528"],
	"lamina_d_agua": ["water", "12/589"],
	"mare_restauradora": ["water", "14/673"],
	"torrente": ["water", "10/484"],
	"muralha_de_coral": ["water", "15/712"],
	"maremoto": ["water", "14/654"],
	"chicote_de_raiz": ["flora", "11/516"],
	"esporos_sonolentos": ["flora", "12/568"],
	"seiva_vital": ["flora", "3/135"],
	"folha_navalha": ["flora", "6/283"],
	"banho_de_sol": ["flora", "14/652"],
	"tempestade_de_petalas": ["flora", "4/174"],
	"explosao_florida": ["flora", "2/79"],
	"uivo": ["beast", "12/586"],
	"patada": ["beast", "2/71"],
	"olhar_manhoso": ["beast", "15/703"],
	"lufada_cortante": ["wind", "9/438"],
	"danca_do_vento": ["wind", "12/567"],
	"ciclone": ["wind", "1/03"],
	"lamina_sombria": ["shadow", "5/242"],
	"pinca_de_aco": ["metal", "13/622"],
	"garra_de_picareta": ["metal", "3/126"],
	"beliscao": ["beast", "2/64"],
	"couraca": ["metal", "13/623"],
	"geada_silenciosa": ["ice", "4/176"],
	"nuvem_de_poeira": ["earth", "10/476"],
	"floco_cortante": ["ice", "7/325"],
	"arremesso_de_torrao": ["earth", "2/76"],
	"manto_de_neve": ["ice", "1/26"],
	"eco_mental": ["mind", "10/475"],
	"garra_de_pedra": ["earth", "6/295"],
	"garra_do_eclipse": ["shadow", "3/123"],
	"martelo_de_ferro": ["metal", "10/486"],
	"lanca_de_cristal": ["ice", "11/529"],
	"inverno_mudo": ["ice", "13/615"],
	"grito_congelado": ["mind", "13/633"],
	"palavra_guardada": ["mind", "14/655"],
	"pena_afiada": ["wind", "5/222"],
	"vento_a_favor": ["wind", "6/296"],
	"rajada_de_penas": ["wind", "6/275"],
	"nuvem_de_penas": ["wind", "3/125"],
	"vendaval": ["wind", "10/464"],
	"rasante": ["wind", "7/316"],
	"bicada_de_folha": ["flora", "5/231"],
	"garra_de_espinho": ["flora", "3/126"],
	"asa_semeadora": ["flora", "11/527"],
	"faisca_de_alga": ["volt", "7/324"],
	"corrente_viva": ["volt", "4/195"],
	"mare_eletrica": ["volt", "13/614"],
	"desabamento": ["earth", "13/634"],
	"abalo_profundo": ["earth", "2/70"],
	"tempestade_de_algas": ["volt", "4/196"],
	"esguicho": ["water", "11/517"],
	"poca_d_agua": ["water", "10/466"],
	"laco_de_raizes": ["flora", "3/134"],
	"brotar": ["flora", "4/185"],
	"semear_jardim": ["flora", "12/569"],
	"lama_grudenta": ["earth", "12/577"],
	"areia_movedica": ["earth", "6/286"],
	"chao_de_geada": ["ice", "8/398"],
	"espinho_venenoso": ["toxin", "8/378"],
}

const PROJECTILES := {
	"chama_espiral": ["fire", "12/578"],
	"pena_afiada": ["wind", "12/579"],
	"faisca_de_alga": ["volt", "12/579"],
	"jato_de_mare": ["water", "12/579"],
	"folha_navalha": ["flora", "12/579"],
	"lufada_cortante": ["wind", "12/579"],
	"floco_cortante": ["ice", "12/579"],
	"rajada_de_penas": ["wind", "12/579"],
	"lanca_de_cristal": ["ice", "12/579"],
	"arremesso_de_torrao": ["earth", "12/578"],
	"esguicho": ["water", "12/579"],
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
	if ELEMENT_TINTS.has(entry[0]):
		var tint: Color = ELEMENT_TINTS[entry[0]]
		for py in CELL:
			for px in strip.get_width():
				var color := strip.get_pixel(px, py)
				strip.set_pixel(px, py, Color(color.r * tint.r, color.g * tint.g, color.b * tint.b, color.a))
	strip.save_png(ProjectSettings.globalize_path(OUT % name))
	print("%s: %d quadros" % [name, count])
