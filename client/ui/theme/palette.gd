class_name UiPalette
extends RefCounted
## Cores da interface (.specs/visual-theme/README.md, "Paleta"). As cores dos
## Elementos não ficam aqui: vêm do catálogo (elements.color_hex).
## res://ui/theme/main_theme.tres repete estas cores nos estilos; ao mudar uma,
## mude as duas.

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

## Céu do cenário do Hub quando não há res://assets/backgrounds/hub.png.
const SKY := Color("#52C4F5")

## Cards de ação do Hub (visual-theme/02, RF-12): id -> [cor da arte, cor do corpo].
const ACTION_COLORS: Dictionary[StringName, Array] = {
	&"explore": [Color("#3E9B4F"), Color("#0B4436")],
	&"challenge": [Color("#B9473F"), Color("#3A2433")],
	&"arenas": [Color("#4A52C8"), Color("#1D335F")],
	&"shop": [Color("#D08A22"), Color("#4D3C28")],
	&"heal": [Color("#159080"), Color("#044247")],
	&"storage": [Color("#6A44C2"), Color("#2A2360")],
	&"codex": [Color("#1E7FD0"), Color("#0E3C61")],
	&"bag": [Color("#9C6E43"), Color("#3E362F")],
}

## Selo da raridade dos Genes (creature-details/03, RF-06): slug -> cor.
const GENE_RANK_COLORS: Dictionary[String, Color] = {
	"common": SURFACE_RAISED,
	"uncommon": HP_HIGH,
	"rare": WARNING,
	"epic": Color("#A56BE8"),
	"exceptional": Color("#E86AA8"),
}

## Faixas da barra de HP.
const HP_MID := WARNING
const HP_LOW := DANGER

## Modulate de um painel tocável enquanto o dedo está nele: clareia, porque
## escurecer não aparece no fundo escuro.
const PRESSED_TINT := Color(1.25, 1.25, 1.25)
