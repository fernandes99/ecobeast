extends Control
## Hub (visual-theme/02, TELAS.md #3): cenário atrás de tudo, o Domador e as
## moedas no topo, a equipe numa linha de cards, as ações em cards coloridos e
## a barra inferior com ícones. Toda feature abre a tela de DESTINATIONS com
## Router.push; ligar uma feature nova é trocar o id dela ali.

const CreatureSlotScene := preload("res://ui/components/creature_slot.tscn")
const ActionTileScene := preload("res://ui/components/action_tile.tscn")
const ProfileDebugPanelScene := preload("res://screens/hub/profile_debug_panel.tscn")

const PARTY_SIZE := 6
const TAB_HEIGHT := 76
const CURRENT_TAB := "Home"
const ICON_PATH := "res://ui/icons/%s.svg"

## Cenário do Hub. Sem o arquivo, um gradiente de céu ocupa o topo.
const SCENE_PATH := "res://assets/backgrounds/hub.png"
## Parte de cima da imagem que fica fora da tela, para o castelo cair acima da
## equipe. 0 para uma imagem já composta com o castelo no terço de cima.
const SCENE_TOP_CROP := 0.22
## Onde o conteúdo começa, em fração da altura da tela; acima, o cenário aparece.
const CONTENT_START := 0.30
## Altura do céu de reserva, em fração da altura da tela.
const SKY_HEIGHT := 0.45
## Escurecimento do cenário até perto do fim da imagem.
const SHADE_ALPHA := 0.55
## Distância, em fração da altura da tela, em que o cenário some no fundo.
const SHADE_FADE := 0.10

## Cards de ação, nesta ordem. O título é também o rótulo em DESTINATIONS; as
## cores ficam em UiPalette.ACTION_COLORS.
const ACTIONS: Array[Dictionary] = [
	{"id": &"explore", "title": "Explorar zona", "subtitle": "Conheça novas áreas e capture criaturas."},
	{"id": &"challenge", "title": "Desafiar Domador", "subtitle": "Enfrente outros Domadores."},
	{"id": &"arenas", "title": "Arenas", "subtitle": "Derrote os 8 Mestres e conquiste a Liga."},
	{"id": &"shop", "title": "Loja", "subtitle": "Compre itens, Esferas de Vínculo e mais."},
	{"id": &"heal", "title": "Refúgio", "subtitle": "Cure sua equipe."},
	{"id": &"storage", "title": "Santuário", "subtitle": "Guarde suas criaturas."},
	{"id": &"codex", "title": "Bestiário", "subtitle": "Veja todas as espécies."},
	{"id": &"bag", "title": "Mochila", "subtitle": "Organize seus itens."},
]
## Abas da barra inferior: rótulo e ícone.
const TABS: Array[Dictionary] = [
	{"label": "Home", "icon": "home"},
	{"label": "Equipe", "icon": "team"},
	{"label": "Bestiário", "icon": "book"},
	{"label": "Loja", "icon": "cart"},
	{"label": "Perfil", "icon": "person"},
]

## Rótulo da ação ou aba -> tela que ele abre. Rótulo fora daqui (Home) não
## abre nada; a ação e a aba com o mesmo rótulo abrem a mesma tela.
const DESTINATIONS: Dictionary[String, Dictionary] = {
	"Explorar zona": {"id": &"placeholder", "params": {"title": "Explorar zona"}},
	"Desafiar Domador": {"id": &"placeholder", "params": {"title": "Desafiar Domador"}},
	"Arenas": {"id": &"placeholder", "params": {"title": "Arenas"}},
	"Loja": {"id": &"placeholder", "params": {"title": "Loja"}},
	"Refúgio": {"id": &"placeholder", "params": {"title": "Refúgio"}},
	"Santuário": {"id": &"placeholder", "params": {"title": "Santuário"}},
	"Bestiário": {"id": &"placeholder", "params": {"title": "Bestiário"}},
	"Mochila": {"id": &"placeholder", "params": {"title": "Mochila"}},
	"Equipe": {"id": &"placeholder", "params": {"title": "Equipe"}},
	"Perfil": {"id": &"placeholder", "params": {"title": "Perfil", "extra": ProfileDebugPanelScene}},
}

var _scene_texture: Texture2D = null

@onready var _scene_art: TextureRect = %SceneArt
@onready var _scene_shade: TextureRect = %SceneShade
@onready var _scene_spacer: Control = %SceneSpacer
@onready var _scroll: ScrollContainer = %Scroll
@onready var _avatar_initial: Label = %AvatarInitial
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _coins_label: Label = %CoinsLabel
@onready var _party_row: HBoxContainer = %PartyRow
@onready var _actions_grid: GridContainer = %ActionsGrid
@onready var _tabs: HBoxContainer = %Tabs


func _ready() -> void:
	if ResourceLoader.exists(SCENE_PATH):
		_scene_texture = load(SCENE_PATH) as Texture2D
	_scene_art.texture = _scene_texture if _scene_texture != null else _sky_gradient()
	for index: int in PARTY_SIZE:
		var slot: CreatureSlot = CreatureSlotScene.instantiate()
		slot.pressed.connect(_open_details.bind(index))
		_party_row.add_child(slot)
	for action: Dictionary in ACTIONS:
		var tile: ActionTile = ActionTileScene.instantiate()
		var colors: Array = UiPalette.ACTION_COLORS[action["id"]]
		tile.setup(action["id"], action["title"], action["subtitle"], colors[0], colors[1])
		tile.pressed.connect(_open.bind(action["title"]))
		_actions_grid.add_child(tile)
	for tab: Dictionary in TABS:
		_tabs.add_child(_make_tab(tab["label"], tab["icon"]))
	%EditButton.pressed.connect(_open.bind("Equipe"))
	# O Domador ainda não sobe de nível (o GDD não define como).
	_xp_bar.value = 0.0
	resized.connect(_layout_scene)
	_layout_scene.call_deferred()
	Session.player_changed.connect(_refresh)
	_refresh()


func _make_tab(label: String, icon: String) -> Button:
	var button := Button.new()
	button.text = label
	button.icon = load(ICON_PATH % icon) as Texture2D
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.theme_type_variation = &"CurrentTabButton" if label == CURRENT_TAB else &"TabButton"
	button.custom_minimum_size.y = TAB_HEIGHT
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.pressed.connect(_open.bind(label))
	return button


## Posiciona o cenário, o escurecimento e o espaço vazio do topo do conteúdo
## para o tamanho atual da tela.
func _layout_scene() -> void:
	var height := size.y
	if height <= 0.0:
		return
	var art_height := height * SKY_HEIGHT
	var art_top := 0.0
	if _scene_texture != null:
		art_height = size.x * _scene_texture.get_height() / _scene_texture.get_width()
		art_top = -art_height * SCENE_TOP_CROP
	_scene_art.position = Vector2(0.0, art_top)
	_scene_art.size = Vector2(size.x, art_height)
	_scene_shade.texture = _shade_gradient(clampf((art_top + art_height) / height, 0.0, 1.0))
	# O conteúdo começa em CONTENT_START da tela, contando o topo acima da rolagem.
	var scroll_top := _scroll.get_global_rect().position.y - get_global_rect().position.y
	_scene_spacer.custom_minimum_size.y = maxf(0.0, height * CONTENT_START - scroll_top)


## Transparente até onde o conteúdo começa, escurece até perto do fim do
## cenário e, no fim dele, fica da cor do fundo da tela naquela altura (sem
## emenda); abaixo, transparente de novo.
func _shade_gradient(art_bottom: float) -> GradientTexture2D:
	var clear := UiPalette.BACKGROUND
	clear.a = 0.0
	var dim := UiPalette.BACKGROUND
	dim.a = SHADE_ALPHA
	var solid := UiPalette.BACKGROUND.lerp(UiPalette.BACKGROUND_DEEP, art_bottom)
	var fade_start := maxf(CONTENT_START, art_bottom - SHADE_FADE)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, CONTENT_START, fade_start, art_bottom, minf(art_bottom + 0.001, 1.0)])
	gradient.colors = PackedColorArray([clear, clear, dim, solid, clear if art_bottom < 1.0 else solid])
	return _vertical(gradient)


func _sky_gradient() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, UiPalette.SKY)
	gradient.set_color(1, UiPalette.BACKGROUND)
	return _vertical(gradient)


static func _vertical(gradient: Gradient) -> GradientTexture2D:
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	return texture


func _refresh() -> void:
	var player := Session.player
	# Sem jogador só depois de "Apagar progresso", quando o Router já está
	# trocando para a tela de entrada.
	if player == null:
		return
	_avatar_initial.text = player.name.left(1).to_upper()
	_name_label.text = player.name
	_level_label.text = "Nv. %d" % player.level
	_coins_label.text = _format_thousands(player.coins)
	for index: int in PARTY_SIZE:
		var slot := _party_row.get_child(index) as CreatureSlot
		if index < player.party.size():
			slot.set_creature(player.party[index])
		else:
			slot.set_empty()


func _open(label: String) -> void:
	if not DESTINATIONS.has(label):
		return
	var destination := DESTINATIONS[label]
	Router.push(destination["id"], destination["params"])


func _open_details(index: int) -> void:
	var party := Session.player.party
	if index >= party.size():
		return
	Router.push(&"creature_details", {"uid": party[index].uid})


## 1000 -> "1.000".
static func _format_thousands(value: int) -> String:
	var digits := str(absi(value))
	var groups := PackedStringArray()
	while digits.length() > 3:
		groups.insert(0, digits.right(3))
		digits = digits.left(-3)
	groups.insert(0, digits)
	return ("-" if value < 0 else "") + ".".join(groups)
