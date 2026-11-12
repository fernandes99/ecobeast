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
}

## Modulate de um painel tocável enquanto o dedo está nele: clareia, porque
## escurecer não aparece no fundo escuro.
const PRESSED_TINT := Color(1.25, 1.25, 1.25)
