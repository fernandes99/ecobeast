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

## Faixas da barra de HP.
const HP_MID := WARNING
const HP_LOW := DANGER

## Modulate de um painel tocável enquanto o dedo está nele: clareia, porque
## escurecer não aparece no fundo escuro.
const PRESSED_TINT := Color(1.25, 1.25, 1.25)
