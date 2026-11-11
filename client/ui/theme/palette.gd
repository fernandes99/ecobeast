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
## A sombra de um Ecobeast só visto no Bestiário (codex/02).
const SILHOUETTE := Color("#060E18")

## Céu do cenário do Hub quando não há res://assets/backgrounds/hub.png.
const SKY := Color("#52C4F5")
## As cores das áreas de Ecobeasts no editor de ilhas, na ordem em que as áreas
## novas as recebem (map-editor/04). Só o editor as usa.
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

## Cards de ação do Hub (visual-theme/02, RF-12): id -> [cor da arte, cor do corpo].
const ACTION_COLORS: Dictionary[StringName, Array] = {
	&"explore": [Color("#3E9B4F"), Color("#0B4436")],
	# Um azul de mar (islands/03). A revisar.
	&"islands": [Color("#2C8FA8"), Color("#0B3A47")],
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

## Forma provisória dos itens (inventory-shop/02, RF-19): categoria -> cor.
const ITEM_CATEGORY_COLORS: Dictionary[String, Color] = {
	"capture": ACCENT,
	"heal": HP_HIGH,
}

## Cena da batalha (battle-screen/04): painéis e caixa por cima do cenário.
const BATTLE_PANEL := Color("#0E1C33E6")
const BATTLE_PANEL_BORDER := Color("#3D6FB0")
const BATTLE_LEVEL_ENEMY := Color("#C62828")
const BATTLE_LEVEL_PLAYER := Color("#2E7D32")
## Botões da batalha (battle-screen/04, RF-20): id -> cor. A revisar.
const BATTLE_ACTION_COLORS: Dictionary[StringName, Color] = {
	&"fight": Color("#E8481F"),
	&"team": Color("#2370E0"),
	&"bag": Color("#46A82C"),
	&"flee": Color("#8A45E6"),
}

## Luta no tabuleiro (board-battle/06, no estilo do print do dono). A revisar.
## O chão dos hexágonos é o do mapa de Explorar e cobre a tela (board-battle/08):
## o que fica fora do tabuleiro escurece, e a borda dele fica clara.
const BOARD_OUTSIDE := Color("#0000004D")
const BOARD_EDGE := Color("#FFFFFFB3")
## O hexágono de quem joga agora: a cor do lado por dentro e o brilho em volta.
const BOARD_ACTIVE_CELL := Color("#1F6FE08C")
const BOARD_ACTIVE_GLOW := Color("#7FD8FF")
const BOARD_ACTIVE_ENEMY_CELL := Color("#E0402A8C")
const BOARD_ACTIVE_ENEMY_GLOW := Color("#FF8A5C")
## Onde o Ecobeast chega andando, e os alvos da Técnica escolhida.
const BOARD_REACH := Color("#C8F5D447")
const BOARD_TARGET := Color("#F2B33D80")
## A área da Técnica, por um instante, quando ela é usada.
const BOARD_AREA := Color("#FFFFFF99")
## A borda de quem joga agora, na fila.
const BOARD_ACTIVE := Color("#FFD54A")
const BOARD_PLAYER := BATTLE_LEVEL_PLAYER
const BOARD_ENEMY := BATTLE_LEVEL_ENEMY

## Faixas da barra de HP.
const HP_MID := WARNING
const HP_LOW := DANGER

## O sinal de stat sobre o Ecobeast na luta (board-battle/12).
const STAT_UP := HP_HIGH
const STAT_DOWN := DANGER
## A cor do sinal de cada estado, pelo slug de `status_conditions` (board-battle/12). A revisar.
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
