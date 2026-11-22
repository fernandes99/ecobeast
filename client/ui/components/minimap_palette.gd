class_name MinimapPalette
extends RefCounted
## As cores chapadas do minimapa e do mapa grande (.specs/minimap/architecture.md). A revisar.

const BIOMES: Dictionary[String, Color] = {
	"temperate": Color("#6fa84a"),
	"boreal": Color("#3f7a4a"),
	"stone": Color("#8b8b80"),
	"hill": Color("#9aa65a"),
	"mountain": Color("#8a7766"),
	"wshallow": Color("#4f8fc0"),
	"wdeep": Color("#2c5a8c"),
	"desert": Color("#d9b35e"),
	"snow": Color("#eef3f6"),
	"beach": Color("#e3cf8f"),
	"glacier": Color("#9fd4ee"),
	"volcano": Color("#3b3433"),
	"lshallow": Color("#ff8a1e"),
	"ldeep": Color("#c2361a"),
}
const TRAIL := Color("#a8814f")
const FLOOR := Color("#b9a58a")
const BRIDGE := Color("#7a5430")
const FOG := UiPalette.BACKGROUND_DEEP
const SHORE_SHADE := 0.72

static var _warned: Dictionary[String, bool] = {}


static func biome(slug: String) -> Color:
	if BIOMES.has(slug):
		return BIOMES[slug]
	if not _warned.has(slug):
		_warned[slug] = true
		push_warning("MinimapPalette: bioma sem cor no minimapa: %s" % slug)
	return BIOMES["temperate"]
