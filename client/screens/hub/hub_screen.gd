extends Control

## O Hub, a primeira tela do jogo (.specs/hub-start/01-hub.md).

const CreatureSlotScene := preload("res://ui/components/creature_slot.tscn")

const ICON_PATH := "res://ui/icons/%s.svg"

const SCENE_PATH := "res://assets/backgrounds/hub.png"
const SCENE_TOP_CROP := 0.22
const SKY_HEIGHT := 0.45
const SHADE_ALPHA := 0.75
const SHADE_FADE := 140.0

const BUTTON_RADIUS := 20
const BUTTON_BORDER := 2
const BORDER_LIGHTEN := 0.25
const PRESSED_DARKEN := 0.2
const SHORTCUT_HEIGHT := 104
const SHORTCUT_ICON := 40
const SHORTCUT_FONT := 20

## Os atalhos embaixo do Explorar, nesta ordem; as cores ficam em UiPalette.ACTION_COLORS.
const SHORTCUTS: Array[Dictionary] = [
	{"id": &"shop", "title": "Loja", "icon": "shop", "screen": &"shop"},
	{"id": &"heal", "title": "Refúgio", "icon": "heal", "screen": &"heal_station"},
	{"id": &"team", "title": "Ecobeasts", "icon": "team", "screen": &"team"},
	{"id": &"bag", "title": "Mochila", "icon": "bag", "screen": &"bag"},
]

var _scene_texture: Texture2D = null
var _featured_uid := ""

@onready var _scene_art: TextureRect = %SceneArt
@onready var _scene_shade: TextureRect = %SceneShade
@onready var _player_area: Control = %Player
@onready var _avatar_initial: Label = %AvatarInitial
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _coins_label: Label = %CoinsLabel
@onready var _settings_button: Button = %SettingsButton
@onready var _featured: TapPanel = %Featured
@onready var _featured_portrait: CreaturePortrait = %FeaturedPortrait
@onready var _featured_plate: PanelContainer = %FeaturedPlate
@onready var _featured_name: Label = %FeaturedName
@onready var _featured_level: Label = %FeaturedLevel
@onready var _featured_hp: HpBar = %FeaturedHp
@onready var _party_row: HBoxContainer = %PartyRow
@onready var _explore_button: Button = %ExploreButton
@onready var _shortcuts: HBoxContainer = %Shortcuts


func _ready() -> void:
	_player_area.gui_input.connect(_on_player_input)
	_settings_button.icon = load(ICON_PATH % "gear") as Texture2D
	_settings_button.pressed.connect(Router.push.bind(&"settings"))
	if ResourceLoader.exists(SCENE_PATH):
		_scene_texture = load(SCENE_PATH) as Texture2D
	_scene_art.texture = _scene_texture if _scene_texture != null else _sky_gradient()
	_featured.pressed.connect(_open_featured)
	for index: int in Player.PARTY_SIZE:
		var slot: CreatureSlot = CreatureSlotScene.instantiate()
		slot.pressed.connect(_feature.bind(index))
		_party_row.add_child(slot)
	_explore_button.icon = load(ICON_PATH % "explore") as Texture2D
	_paint_button(_explore_button, UiPalette.ACTION_COLORS[&"explore"][0])
	_explore_button.pressed.connect(_explore)
	for shortcut: Dictionary in SHORTCUTS:
		_shortcuts.add_child(_make_shortcut(shortcut))
	# O Domador ainda não sobe de nível (o GDD não define como).
	_xp_bar.value = 0.0
	resized.connect(_layout_scene)
	_party_row.item_rect_changed.connect(_layout_scene)
	_layout_scene.call_deferred()
	Session.player_changed.connect(_refresh)
	_refresh()


func _make_shortcut(shortcut: Dictionary) -> Button:
	var button := Button.new()
	button.text = shortcut["title"]
	button.icon = load(ICON_PATH % shortcut["icon"]) as Texture2D
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.custom_minimum_size.y = SHORTCUT_HEIGHT
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.add_theme_constant_override(&"icon_max_width", SHORTCUT_ICON)
	button.add_theme_font_size_override(&"font_size", SHORTCUT_FONT)
	_paint_button(button, UiPalette.ACTION_COLORS[shortcut["id"]][1], UiPalette.ACTION_COLORS[shortcut["id"]][0])
	button.pressed.connect(Router.push.bind(shortcut["screen"]))
	return button


func _paint_button(button: Button, fill: Color, border: Color = Color.TRANSPARENT) -> void:
	var edge := border if border.a > 0.0 else fill.lightened(BORDER_LIGHTEN)
	var normal := _button_style(fill, edge)
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", normal)
	button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	var pressed := _button_style(fill.darkened(PRESSED_DARKEN), edge)
	button.add_theme_stylebox_override(&"pressed", pressed)
	button.add_theme_stylebox_override(&"hover_pressed", pressed)
	button.add_theme_stylebox_override(&"disabled", _button_style(UiPalette.SURFACE_RAISED, UiPalette.BORDER))
	for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
		button.add_theme_color_override(state, UiPalette.TEXT)
	button.add_theme_color_override(&"font_disabled_color", UiPalette.TEXT_MUTED)


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(BUTTON_BORDER)
	style.set_corner_radius_all(BUTTON_RADIUS)
	style.set_content_margin_all(12)
	return style


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
	var party_top := _party_row.get_global_rect().position.y - get_global_rect().position.y
	var art_bottom := clampf((art_top + art_height) / height, 0.0, 1.0)
	var dim_at := clampf(party_top / height, 0.0, art_bottom)
	var fade_start := clampf((party_top - SHADE_FADE) / height, 0.0, dim_at)
	_scene_shade.texture = _shade_gradient(fade_start, dim_at, art_bottom)


## O fundo fica limpo atrás do destaque e escurece da fileira para baixo, até o fim da arte.
func _shade_gradient(fade_start: float, dim_at: float, art_bottom: float) -> GradientTexture2D:
	var clear := UiPalette.BACKGROUND
	clear.a = 0.0
	var dim := UiPalette.BACKGROUND
	dim.a = SHADE_ALPHA
	var solid := UiPalette.BACKGROUND.lerp(UiPalette.BACKGROUND_DEEP, art_bottom)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, fade_start, dim_at, art_bottom])
	gradient.colors = PackedColorArray([clear, clear, dim, solid])
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
	_coins_label.text = NumberFormat.thousands(player.coins)
	for index: int in Player.PARTY_SIZE:
		var slot := _party_row.get_child(index) as CreatureSlot
		if index < player.party.size():
			slot.set_creature(player.party[index])
		else:
			slot.set_empty()
	_explore_button.disabled = player.party.is_empty()
	_show_featured()


func _featured_index() -> int:
	var party := Session.player.party
	for index: int in party.size():
		if party[index].uid == _featured_uid:
			return index
	return 0 if not party.is_empty() else -1


func _show_featured() -> void:
	var index := _featured_index()
	var party := Session.player.party
	for slot_index: int in Player.PARTY_SIZE:
		(_party_row.get_child(slot_index) as CreatureSlot).set_selected(slot_index == index)
	_featured_portrait.visible = index >= 0
	_featured_plate.visible = index >= 0
	if index < 0:
		_featured_uid = ""
		return
	var creature := party[index]
	_featured_uid = creature.uid
	var species := GameData.get_species(creature.species_id)
	_featured_portrait.set_species(species.id)
	_featured_name.text = creature.display_name(species)
	_featured_level.text = "Nv. %d" % creature.level
	_featured_hp.set_hp(creature.current_hp, creature.stats.hp)


## Só muda quem aparece no Hub; o líder continua o mesmo.
func _feature(index: int) -> void:
	var party := Session.player.party
	if index >= party.size():
		return
	_featured_uid = party[index].uid
	_show_featured()


func _open_featured() -> void:
	var index := _featured_index()
	if index >= 0:
		Router.push(&"creature_details", {"uid": Session.player.party[index].uid})


func _explore() -> void:
	if not Session.player.party.is_empty():
		Router.go_to(&"exploration")


func _on_player_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
		Router.push(&"profile")
