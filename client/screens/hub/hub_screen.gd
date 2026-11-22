extends Control

## O Hub, a primeira tela do jogo (.specs/hub-start/): a barra de abas embaixo, com a
## Home no meio, e as outras abas trocando a página dentro dele (03-tab-bar.md). A Home
## é o céu da parte do dia com a ilhota do Domador e do Ecobeast (04-game-look.md).

const ICON_PATH := "res://ui/icons/%s.svg"
const HOME := &"home"
const SHOP := &"shop"
## As abas, da esquerda para a direita; o id é a tela do Router mostrada na aba.
const TABS: Array[Dictionary] = [
	{"id": SHOP, "title": "Loja", "icon": "shop"},
	{"id": &"heal_station", "title": "Refúgio", "icon": "refuge"},
	{"id": HOME, "title": "Home", "icon": "home"},
	{"id": &"team", "title": "Ecobeasts", "icon": "team"},
	{"id": &"bag", "title": "Mochila", "icon": "bag"},
]

const BAR_HEIGHT := 96
const RAISED_HEIGHT := 124
const RAISED_RATIO := 1.6
const TAB_ICON := 40
const RAISED_ICON := 52
const TAB_FONT := 20
const TAB_RADIUS := 20
const TAB_BORDER := 3
const TAB_SWITCH_SECONDS := 0.15
const TAB_LINE := 2

const OUTLINE := 8
const BIG_OUTLINE := 12
const SHADE_ALPHA := 0.55
const SHADE_BOTTOM_ALPHA := 0.85
const SHADE_FADE := 120.0

const PLATE_GAP := 10.0
const LEVEL_BADGE_BORDER := 3
const LEVEL_BADGE_SIZE := 40
const PARTY_LEVEL_FONT := 18

const EXPLORE_RADIUS := 24
const EXPLORE_EDGE := 3
const EXPLORE_LIP := 10
const EXPLORE_PRESSED_LIP := 4
const EXPLORE_LIGHTEN := 0.3
const EXPLORE_LIP_DARKEN := 0.4
const EXPLORE_TEXT_DARKEN := 0.65
const BOUNCE_SCALE := 1.04
const BOUNCE_SECONDS := 0.18
const BOUNCE_EVERY := 3.0

var _featured_uid := ""
var _current := HOME
var _pages: Dictionary[StringName, Control] = {}
var _tab_buttons: Dictionary[StringName, Button] = {}
var _tab_tween: Tween = null
var _bounce: Tween = null
var _tamer := TamerSprite.new()
var _creature: Node = null
var _party_levels: Array[Label] = []
var _bubbles: Array[PartyBubble] = []

@onready var _pages_host: Control = %Pages
@onready var _home_page: Control = %HomePage
@onready var _home_safe: SafeArea = %SafeArea
@onready var _sky: TextureRect = %Sky
@onready var _scene_shade: TextureRect = %SceneShade
@onready var _vignette: TextureRect = %Vignette
@onready var _back_clouds: HubClouds = %BackClouds
@onready var _front_clouds: HubClouds = %FrontClouds
@onready var _player_area: Control = %Player
@onready var _avatar_initial: Label = %AvatarInitial
@onready var _name_label: Label = %NameLabel
@onready var _level_badge: PanelContainer = %LevelBadge
@onready var _level_label: Label = %LevelLabel
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _coin_chip: PanelContainer = %CoinChip
@onready var _coins_label: Label = %CoinsLabel
@onready var _settings_button: Button = %SettingsButton
@onready var _stage: Control = %Stage
@onready var _island: HubIsland = %Island
@onready var _creature_tap: TapPanel = %CreatureTap
@onready var _plate: PanelContainer = %Plate
@onready var _featured_name: Label = %FeaturedName
@onready var _featured_level: Label = %FeaturedLevel
@onready var _featured_hp: HpBar = %FeaturedHp
@onready var _party_row: HBoxContainer = %PartyRow
@onready var _explore_button: Button = %ExploreButton
@onready var _tab_bar: Control = %TabBar
@onready var _tab_background: Panel = %TabBackground
@onready var _tabs: HBoxContainer = %Tabs


func _ready() -> void:
	_pages[HOME] = _home_page
	_home_safe.bottom_override = RAISED_HEIGHT - BAR_HEIGHT
	_player_area.gui_input.connect(_on_player_input)
	_coin_chip.gui_input.connect(_on_coins_input)
	_settings_button.icon = load(ICON_PATH % "gear") as Texture2D
	_settings_button.pressed.connect(Router.push.bind(&"settings"))
	_paint_level_badge()
	for label: Label in [_name_label, _level_label, _coins_label, _featured_name, _featured_level]:
		_outline(label, OUTLINE)
	_vignette.texture = _vignette_texture()
	_build_stage()
	_build_party()
	_build_explore()
	_build_tab_bar()
	get_viewport().size_changed.connect(_place_tab_bar)
	_place_tab_bar()
	resized.connect(_layout_scene)
	_party_row.item_rect_changed.connect(_layout_scene)
	_layout_scene.call_deferred()
	WorldClock.phase_changed.connect(_paint_sky.unbind(1))
	WorldClock.synced.connect(_paint_sky)
	_paint_sky()
	Session.player_changed.connect(_refresh)
	_refresh()


## Numa aba, a tela dela fecha o que tem aberto; sem nada, o Voltar leva à Home.
func handle_back() -> bool:
	if _current == HOME:
		return false
	var page := _pages[_current]
	if page.has_method(&"handle_back") and page.call(&"handle_back"):
		return true
	_select(HOME)
	return true


static func _outline(label: Label, size: int) -> void:
	label.add_theme_constant_override(&"outline_size", size)
	label.add_theme_color_override(&"font_outline_color", UiPalette.TEXT_OUTLINE)


# --- A barra de abas ---


func _build_tab_bar() -> void:
	var bar := StyleBoxFlat.new()
	bar.bg_color = UiPalette.BACKGROUND_DEEP
	bar.border_color = UiPalette.BORDER
	bar.border_width_top = TAB_LINE
	_tab_background.add_theme_stylebox_override(&"panel", bar)
	for tab: Dictionary in TABS:
		_tabs.add_child(_make_tab(tab))
	_show_tabs(false)


func _place_tab_bar() -> void:
	var bottom := SafeArea.screen_insets(get_viewport())[3]
	_tab_bar.offset_top = -(BAR_HEIGHT + bottom)
	_tabs.offset_top = -(RAISED_HEIGHT + bottom)
	_tabs.offset_bottom = -bottom
	_pages_host.offset_bottom = -(BAR_HEIGHT + bottom)


func _make_tab(tab: Dictionary) -> Button:
	var button := Button.new()
	button.icon = load(ICON_PATH % tab["icon"]) as Texture2D
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.size_flags_vertical = SIZE_SHRINK_END
	button.focus_mode = FOCUS_NONE
	button.add_theme_font_size_override(&"font_size", TAB_FONT)
	button.add_theme_constant_override(&"outline_size", OUTLINE)
	button.add_theme_color_override(&"font_outline_color", UiPalette.TEXT_OUTLINE)
	button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	button.pressed.connect(_select.bind(tab["id"]))
	_tab_buttons[tab["id"]] = button
	return button


func _select(id: StringName) -> void:
	if id == _current:
		return
	_open_page(id)
	_pages[_current].hide()
	_current = id
	_pages[id].show()
	_show_tabs(true)


## A tela da aba, criada na primeira vez e guardada até sair do Hub.
func _open_page(id: StringName) -> void:
	if _pages.has(id):
		return
	var page: Control = (load(Router.SCREENS[id]) as PackedScene).instantiate()
	page.set_meta(Router.SCREEN_ID_META, id)
	if page.has_method(&"setup"):
		page.call(&"setup", {"in_tab": true})
	var safe := page.get_node_or_null("SafeArea") as SafeArea
	if safe != null:
		safe.bottom_override = RAISED_HEIGHT - BAR_HEIGHT
	page.hide()
	_pages_host.add_child(page)
	_pages[id] = page


func _show_tabs(animate: bool) -> void:
	if _tab_tween != null:
		_tab_tween.kill()
	_tab_tween = create_tween().set_parallel() if animate else null
	for tab: Dictionary in TABS:
		var button := _tab_buttons[tab["id"]]
		var raised: bool = tab["id"] == _current
		button.text = tab["title"] if raised else ""
		button.add_theme_constant_override(&"icon_max_width", RAISED_ICON if raised else TAB_ICON)
		_paint_tab(button, raised)
		var height := float(RAISED_HEIGHT if raised else BAR_HEIGHT)
		var ratio := RAISED_RATIO if raised else 1.0
		if animate:
			_tab_tween.tween_property(button, "custom_minimum_size:y", height, TAB_SWITCH_SECONDS)
			_tab_tween.tween_property(button, "size_flags_stretch_ratio", ratio, TAB_SWITCH_SECONDS)
		else:
			button.custom_minimum_size.y = height
			button.size_flags_stretch_ratio = ratio


func _paint_tab(button: Button, raised: bool) -> void:
	var style: StyleBox = StyleBoxEmpty.new()
	if raised:
		var flat := StyleBoxFlat.new()
		flat.bg_color = UiPalette.SURFACE_RAISED
		flat.border_color = UiPalette.ACCENT
		flat.border_width_top = TAB_BORDER
		flat.border_width_left = TAB_BORDER
		flat.border_width_right = TAB_BORDER
		flat.corner_radius_top_left = TAB_RADIUS
		flat.corner_radius_top_right = TAB_RADIUS
		flat.content_margin_top = 14
		flat.content_margin_bottom = 10
		style = flat
	else:
		style.content_margin_top = 26
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed"]:
		button.add_theme_stylebox_override(state, style)
	var icon_color := UiPalette.TEXT if raised else UiPalette.TEXT_SECONDARY
	for state: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_pressed_color", &"icon_hover_pressed_color", &"icon_focus_color"]:
		button.add_theme_color_override(state, icon_color)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color", &"font_focus_color"]:
		button.add_theme_color_override(state, UiPalette.TEXT)


# --- A Home ---


func _paint_level_badge() -> void:
	var badge := StyleBoxFlat.new()
	badge.bg_color = UiPalette.ACCENT
	badge.border_color = UiPalette.TEXT
	badge.set_border_width_all(LEVEL_BADGE_BORDER)
	badge.set_corner_radius_all(LEVEL_BADGE_SIZE)
	_level_badge.add_theme_stylebox_override(&"panel", badge)


func _paint_sky() -> void:
	var phase := WorldClock.phase()
	var colors: Array = UiPalette.HUB_SKY.get(phase.slug if phase != null else "", UiPalette.HUB_SKY["afternoon"])
	var gradient := Gradient.new()
	gradient.set_color(0, colors[0])
	gradient.set_color(1, colors[1])
	_sky.texture = _vertical(gradient)
	var tint: Color = UiPalette.HUB_CLOUD_TINT.get(phase.slug if phase != null else "", Color.WHITE)
	for clouds: HubClouds in [_back_clouds, _front_clouds]:
		for cloud: Node in clouds.get_children():
			(cloud as CanvasItem).self_modulate = tint


## As bordas da Home escurecem de leve, por baixo da interface.
func _vignette_texture() -> GradientTexture2D:
	var clear := UiPalette.HUB_VIGNETTE
	clear.a = 0.0
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([clear, clear, UiPalette.HUB_VIGNETTE])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.1, 0.5)
	return texture


func _build_stage() -> void:
	_island.set_tamer(_tamer)
	_island.moved.connect(_place_plate)
	_stage.gui_input.connect(_island.handle_touch)
	_stage.item_rect_changed.connect(_focus_island)
	_creature_tap.pressed.connect(_open_featured)


func _build_party() -> void:
	for index: int in Player.PARTY_SIZE:
		var column := VBoxContainer.new()
		column.mouse_filter = MOUSE_FILTER_IGNORE
		column.add_theme_constant_override(&"separation", 2)
		var bubble := PartyBubble.new()
		bubble.pressed.connect(_feature.bind(index))
		column.add_child(bubble)
		var level := Label.new()
		level.theme_type_variation = &"BoldLabel"
		level.add_theme_font_size_override(&"font_size", PARTY_LEVEL_FONT)
		level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_outline(level, OUTLINE)
		column.add_child(level)
		_party_row.add_child(column)
		_bubbles.append(bubble)
		_party_levels.append(level)


func _show_creature(creature: CreatureInstance) -> void:
	if creature == null:
		_island.set_creature(null)
		return
	var species := GameData.get_species(creature.species_id)
	if CreatureSprite.has_sheets(species.slug):
		_island.set_creature(CreatureSprite.new(species.slug))
		return
	var front := CreaturePortrait.SPRITE_PATH % species.slug
	if ResourceLoader.exists(front):
		_island.set_creature(HubIsland.fallback_creature(load(front) as Texture2D))
	else:
		_island.set_creature(null)


## A câmera da ilha põe o Domador no meio do palco.
func _focus_island() -> void:
	var stage := _stage.get_global_rect()
	_island.set_focus(_island.get_global_transform_with_canvas().affine_inverse() * stage.get_center())


## A etiqueta e a área de toque acompanham o Ecobeast na ilha.
func _place_plate() -> void:
	var node := _island.creature_node()
	_plate.visible = node != null
	_creature_tap.visible = node != null
	if node == null:
		return
	var art_scale := _island.pixel_scale()
	var feet := _stage.get_global_transform_with_canvas().affine_inverse() * (_island.get_global_transform_with_canvas() * _island.to_local_point(node.position))
	var height := HubIsland.FALLBACK_HEIGHT
	if node is CreatureSprite:
		height = _visible_height(node as CreatureSprite)
	var top := feet.y - height * art_scale
	var half_width := SheetSprite.CELL_SIZE.x * art_scale / 2.0
	_plate.size = _plate.get_combined_minimum_size()
	_plate.position = Vector2(feet.x - _plate.size.x / 2.0, top - PLATE_GAP - _plate.size.y).round()
	_plate.position.x = clampf(_plate.position.x, 0.0, _stage.size.x - _plate.size.x)
	_creature_tap.position = Vector2(feet.x - half_width, top)
	_creature_tap.size = Vector2(half_width * 2.0, feet.y - top)


## A altura dos pixels do Ecobeast no quadro parado, do pé até o topo.
static func _visible_height(sprite: CreatureSprite) -> float:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	if texture == null:
		return SheetSprite.CELL_SIZE.y
	var used := texture.get_image().get_used_rect()
	return SheetSprite.CELL_SIZE.y - used.position.y


func _build_explore() -> void:
	_explore_button.icon = load(ICON_PATH % "explore") as Texture2D
	var fill: Color = UiPalette.ACTION_COLORS[&"explore"][0]
	var edge := fill.lightened(EXPLORE_LIGHTEN)
	var lip := fill.darkened(EXPLORE_LIP_DARKEN)
	var normal := _explore_style(fill, edge, lip, EXPLORE_LIP)
	_explore_button.add_theme_stylebox_override(&"normal", normal)
	_explore_button.add_theme_stylebox_override(&"hover", normal)
	_explore_button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	var pressed := _explore_style(fill.darkened(0.08), edge, lip, EXPLORE_PRESSED_LIP)
	_explore_button.add_theme_stylebox_override(&"pressed", pressed)
	_explore_button.add_theme_stylebox_override(&"hover_pressed", pressed)
	var off := UiPalette.SURFACE_RAISED
	_explore_button.add_theme_stylebox_override(&"disabled", _explore_style(off, off.lightened(EXPLORE_LIGHTEN), off.darkened(EXPLORE_LIP_DARKEN), EXPLORE_LIP))
	for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
		_explore_button.add_theme_color_override(state, UiPalette.TEXT)
	_explore_button.add_theme_color_override(&"font_disabled_color", UiPalette.TEXT_SECONDARY)
	_explore_button.add_theme_constant_override(&"outline_size", BIG_OUTLINE)
	_explore_button.add_theme_color_override(&"font_outline_color", fill.darkened(EXPLORE_TEXT_DARKEN))
	_explore_button.pressed.connect(_explore)
	_explore_button.button_down.connect(_stop_bounce)
	_explore_button.button_up.connect(_start_bounce)
	_explore_button.resized.connect(func() -> void: _explore_button.pivot_offset = _explore_button.size / 2.0)
	_start_bounce()


## A lateral do botão é uma sombra sólida logo abaixo da face: apertado, a face desce
## sobre ela e o texto vai junto.
func _explore_style(fill: Color, edge: Color, lip: Color, lip_size: int) -> StyleBoxFlat:
	var sink := EXPLORE_LIP - lip_size
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(EXPLORE_EDGE)
	style.set_corner_radius_all(EXPLORE_RADIUS)
	style.expand_margin_top = -sink
	style.expand_margin_bottom = -lip_size
	style.shadow_color = lip
	style.shadow_size = 1
	style.shadow_offset = Vector2(0.0, lip_size)
	style.set_content_margin_all(12)
	style.content_margin_top = 12 + sink
	style.content_margin_bottom = 12 + lip_size
	return style


func _start_bounce() -> void:
	_stop_bounce()
	if _explore_button.disabled:
		return
	_bounce = create_tween().set_loops()
	_bounce.tween_interval(BOUNCE_EVERY)
	_bounce.tween_property(_explore_button, "scale", Vector2.ONE * BOUNCE_SCALE, BOUNCE_SECONDS).set_trans(Tween.TRANS_SINE)
	_bounce.tween_property(_explore_button, "scale", Vector2.ONE, BOUNCE_SECONDS).set_trans(Tween.TRANS_SINE)


func _stop_bounce() -> void:
	if _bounce != null:
		_bounce.kill()
		_bounce = null
	_explore_button.scale = Vector2.ONE


func _layout_scene() -> void:
	var page := _home_page.size
	if page.y <= 0.0:
		return
	var origin := _home_page.get_global_rect().position
	var party_top := _party_row.get_global_rect().position.y - origin.y
	var dim_at := clampf(party_top / page.y, 0.0, 1.0)
	_scene_shade.texture = _shade_gradient(clampf((party_top - SHADE_FADE) / page.y, 0.0, dim_at), dim_at)


## O céu fica limpo atrás da ilhota e escurece da fileira para baixo.
func _shade_gradient(fade_start: float, dim_at: float) -> GradientTexture2D:
	var clear := UiPalette.BACKGROUND
	clear.a = 0.0
	var dim := UiPalette.BACKGROUND
	dim.a = SHADE_ALPHA
	var solid := UiPalette.BACKGROUND_DEEP
	solid.a = SHADE_BOTTOM_ALPHA
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, fade_start, dim_at, 1.0])
	gradient.colors = PackedColorArray([clear, clear, dim, solid])
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
	_level_label.text = str(player.level)
	_xp_bar.value = player.level_ratio()
	_coins_label.text = NumberFormat.thousands(player.coins)
	_tamer.set_appearance(player.appearance)
	for index: int in Player.PARTY_SIZE:
		var creature: CreatureInstance = player.party[index] if index < player.party.size() else null
		_bubbles[index].set_creature(creature)
		_party_levels[index].text = "Nv. %d" % creature.level if creature != null else " "
	_explore_button.disabled = player.party.is_empty()
	if _explore_button.disabled:
		_stop_bounce()
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
	for slot: int in Player.PARTY_SIZE:
		_bubbles[slot].set_selected(slot == index)
	if index < 0:
		_featured_uid = ""
		_show_creature(null)
		return
	var creature := party[index]
	_featured_uid = creature.uid
	var species := GameData.get_species(creature.species_id)
	_show_creature(creature)
	_featured_name.text = creature.display_name(species)
	_featured_level.text = "Nv. %d" % creature.level
	_featured_hp.set_hp(creature.current_hp, creature.stats.hp)
	_place_plate.call_deferred()


## Só muda quem aparece na ilhota; o líder continua o mesmo.
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
		Router.push(&"explore_menu")


func _on_player_input(event: InputEvent) -> void:
	if _is_release(event):
		Router.push(&"profile")


func _on_coins_input(event: InputEvent) -> void:
	if _is_release(event):
		_select(SHOP)


static func _is_release(event: InputEvent) -> bool:
	var button := event as InputEventMouseButton
	return button != null and button.button_index == MOUSE_BUTTON_LEFT and not button.pressed
