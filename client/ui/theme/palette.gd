class_name UiPalette
extends RefCounted
## Cores da interface (foundation/02, RF-02). As cores dos Elementos não ficam
## aqui: vêm do catálogo (elements.color_hex).
## res://ui/theme/main_theme.tres repete estas cores nos estilos; ao mudar uma,
## mude as duas.

const BACKGROUND := Color("#FFF8EC")
const SURFACE := Color("#FFFFFF")
const TEXT := Color("#2D2A32")
const TEXT_SECONDARY := Color("#6E6873")
const PRIMARY := Color("#2BAE8E")
const PRIMARY_PRESSED := Color("#1F8A70")
const DANGER := Color("#E5534B")
const DANGER_PRESSED := Color("#C0433C")
const WARNING := Color("#F2B33D")
const BORDER := Color("#E9E1D3")

## Faixas da barra de HP (RF-13).
const HP_HIGH := Color("#4CB050")
const HP_MID := WARNING
const HP_LOW := DANGER
