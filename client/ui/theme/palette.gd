class_name UiPalette
extends RefCounted

const BACKGROUND := Color("#0F2337")
const BACKGROUND_DEEP := Color("#0A1A2B")
const SURFACE := Color("#142A43")
const SURFACE_RAISED := Color("#1E3C58")
const BORDER := Color("#1D4665")
const TRACK := Color("#103654")
const TEXT := Color("#FFFFFF")
const TEXT_SECONDARY := Color("#9DB7D2")
const TEXT_MUTED := Color("#59708E")
const PRIMARY := Color("#0E5FAF")
const PRIMARY_PRESSED := Color("#094C92")
const ACCENT := Color("#0DA4F6")
const WARNING := Color("#F2B33D")
const DANGER := Color("#E5534B")
const DANGER_PRESSED := Color("#C0433C")
const HP_HIGH := Color("#68C661")
const OVERLAY := Color(0.0, 0.0, 0.0, 0.6)
const SILHOUETTE := Color("#060E18")

const SKY := Color("#52C4F5")
const MAP_ROUTE := Color("#FFFFFFD9")
const MAP_ROUTE_SHADOW := Color("#0000004D")
const MAP_AREA_COLORS: Array[Color] = [
	Color("#E8C547"),
	Color("#E0607E"),
	Color("#4FC3F7"),
	Color("#9C6ADE"),
	Color("#F28C38"),
	Color("#5BD38A"),
	Color("#F25F5C"),
	Color("#B0BEC5"),
]

const ACTION_COLORS: Dictionary[StringName, Array] = {
	&"explore": [Color("#3E9B4F"), Color("#0B4436")],
	&"islands": [Color("#2C8FA8"), Color("#0B3A47")],
	&"travel": [Color("#2C8FA8"), Color("#0B3A47")],
	&"challenge": [Color("#B9473F"), Color("#3A2433")],
	&"arenas": [Color("#4A52C8"), Color("#1D335F")],
	&"shop": [Color("#D08A22"), Color("#4D3C28")],
	&"heal": [Color("#159080"), Color("#044247")],
	&"storage": [Color("#6A44C2"), Color("#2A2360")],
	&"codex": [Color("#1E7FD0"), Color("#0E3C61")],
	&"bag": [Color("#9C6E43"), Color("#3E362F")],
}

const GENE_RANK_COLORS: Dictionary[String, Color] = {
	"common": SURFACE_RAISED,
	"uncommon": HP_HIGH,
	"rare": WARNING,
	"epic": Color("#A56BE8"),
	"exceptional": Color("#E86AA8"),
}

const ITEM_CATEGORY_COLORS: Dictionary[String, Color] = {
	"capture": ACCENT,
	"heal": HP_HIGH,
}

const BATTLE_PANEL := Color("#0E1C33E6")
const BATTLE_PANEL_BORDER := Color("#3D6FB0")
const BATTLE_LEVEL_ENEMY := Color("#C62828")
const BATTLE_LEVEL_PLAYER := Color("#2E7D32")
const BATTLE_ACTION_COLORS: Dictionary[StringName, Color] = {
	&"fight": Color("#E8481F"),
	&"team": Color("#2370E0"),
	&"bag": Color("#46A82C"),
	&"flee": Color("#8A45E6"),
}

const BOARD_OUTSIDE := Color("#0000004D")
const BOARD_EDGE := Color("#FFFFFFB3")
const BOARD_ACTIVE_CELL := Color("#1F6FE08C")
const BOARD_ACTIVE_GLOW := Color("#7FD8FF")
const BOARD_ACTIVE_ENEMY_CELL := Color("#E0402A8C")
const BOARD_ACTIVE_ENEMY_GLOW := Color("#FF8A5C")
const BOARD_REACH := Color("#C8F5D447")
const BOARD_TARGET := Color("#F2B33D80")
const BOARD_AREA := Color("#FFFFFF99")
const BOARD_ACTIVE := Color("#FFD54A")
const BOARD_PLAYER := BATTLE_LEVEL_PLAYER
const BOARD_ENEMY := BATTLE_LEVEL_ENEMY

const HP_MID := WARNING
const HP_LOW := DANGER
const XP_LINE := Color("#7FD8FF")

const STAT_UP := HP_HIGH
const STAT_DOWN := DANGER
const STATUS_COLORS: Dictionary[String, Color] = {
	"burn": Color("#F04438"),
	"poison": Color("#5CCB4A"),
	"paralysis": Color("#F2D13D"),
	"sleep": Color("#9DB7D2"),
	"freeze": Color("#7FD8FF"),
	"confusion": Color("#F28AD0"),
	"fear": Color("#8C7AE6"),
	"trapped": Color("#C9A66B"),
	"dazed": Color("#F2B84B"),
	"soaked": Color("#4A90D9"),
	"sprouting": Color("#7FCB6B"),
	"protect": Color("#5AA9FF"),
}
## Os efeitos que duram no corpo e no chão (board-battle/23).
const AURA_FLAME_CORE := Color("#FFE27A")
const AURA_STAR := Color("#FFE27A")
const AURA_SWEAT := Color("#BFE9FF")
const AURA_SHINE := Color("#FFFFFF")
## O desenho de cada marca no chão (board-battle/35).
const GROUND_FEATHER := Color("#FFFFFF")
const GROUND_FEATHER_SHAFT := Color("#9CC4BA")
const GROUND_WHIRL := Color("#E4FFF8")
const GROUND_WHIRL_DUST := Color("#4E9C8A")
const GROUND_THORN := Color("#4A2F1C")
const GROUND_THORN_LIGHT := Color("#B08A5A")
const GROUND_TIDE_WAVE := Color("#BFE6FF")
const GROUND_TIDE_SPARK := Color("#FFE45C")
const GROUND_MUD_BLOT := Color("#4A321E")
const GROUND_MUD := Color("#5E4128")
const GROUND_MUD_SHINE := Color("#A88560")
const GROUND_FROST := Color("#6FB3DE")
const GROUND_FROST_CORE := Color("#FFFFFF")
const GROUND_TOXIC := Color("#B565D9")
const GROUND_TOXIC_SHINE := Color("#E8C6F5")
const GROUND_TOXIC_VAPOR := Color("#C79BE0")
const GROUND_SAND_RING := Color("#9C7440")
const GROUND_SAND_GRAIN := Color("#6E5028")
const GROUND_STEM := Color("#3F7A2E")
const GROUND_PETALS: Array[Color] = [Color("#F7A8C8"), Color("#FFE27A"), Color("#FFFFFF")]
const GROUND_FLOWER_CORE := Color("#F2B33D")
const GROUND_GARDEN_SPARKLE := Color("#E9FFD9")
const GROUND_RIPPLE := Color("#DDF0FF")

## Modulate de um painel tocável enquanto o dedo está nele: clareia, porque
## escurecer não aparece no fundo escuro.
const PRESSED_TINT := Color(1.25, 1.25, 1.25)

## A cor de cada grupo de passo na ferramenta Cenas do editor (story/06). A revisar.
const STORY_STEP_COLORS: Dictionary[String, Color] = {
	"talk": Color("#7C5CD6"),
	"choice": Color("#D6455C"),
	"mark": Color("#4A7BD1"),
	"actor": Color("#2E9E5B"),
	"camera": Color("#C27A1A"),
	"screen": Color("#5B7590"),
}
