class_name ExplorationDebugPanel
extends PanelContainer

signal whole_map_toggled
signal god_toggled
signal forget_pressed
signal scene_chosen(scene: StoryScene)
signal species_chosen(species: CreatureSpecies)
signal clear_spawns_pressed
signal board_test_pressed(slots: int)
signal tamer_pressed(team_size: int)
signal almost_level_up_pressed
signal contour_toggled
signal rounded_toggled
signal height_cues_changed(lips: bool, shadows: bool, tint: bool)
signal next_hour_pressed
signal time_chosen(minute: float)
signal real_time_pressed

const PortraitScene := preload("res://ui/components/creature_portrait.tscn")

const TITLE_TEXT := "Debug"
const CLOSE_TEXT := "×"
const BUTTON_HEIGHT := 56.0
const SCENES_HEIGHT := 200.0
const SPECIES_HEIGHT := 112.0
const SPECIES_LIST_HEIGHT := 360.0
const SPECIES_COLUMNS := 5
const PORTRAIT_SIZE := 64
const NAME_FONT_SIZE := 18
const DISABLED_ALPHA := 0.35
const NO_SCENES_TEXT := "Esta ilha não tem cenas."

static var _last_tab := 0

var _tabs := DebugTabs.new()
var _whole_map := CheckButton.new()
var _god := CheckButton.new()
var _forget := Button.new()
var _scenes := VBoxContainer.new()
var _species := GridContainer.new()
var _clear := Button.new()
var _xp := Button.new()
var _contour := CheckButton.new()
var _rounded := CheckButton.new()
var _lips := CheckButton.new()
var _shadows := CheckButton.new()
var _tint := CheckButton.new()
var _time_label := Label.new()
var _time_slider := HSlider.new()


func _init() -> void:
	theme_type_variation = &"SectionPanel"
	mouse_filter = Control.MOUSE_FILTER_STOP
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	add_child(column)
	column.add_child(_header())
	column.add_child(_tabs)
	_build_map(_tabs.add_page("Mapa"))
	_build_spawn(_tabs.add_page("Spawn"))
	_build_battle(_tabs.add_page("Luta"))
	_build_visual(_tabs.add_page("Visual"))
	_build_time(_tabs.add_page("Hora"))
	_tabs.show_page(_last_tab)
	_tabs.tab_changed.connect(func(index: int) -> void: _last_tab = index)
	refresh_toggles()


func _header() -> Control:
	var row := HBoxContainer.new()
	var title := Label.new()
	title.text = TITLE_TEXT
	title.theme_type_variation = &"BoldLabel"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)
	var close := _button(CLOSE_TEXT)
	close.custom_minimum_size.x = BUTTON_HEIGHT
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(hide)
	row.add_child(close)
	return row


func _build_map(page: VBoxContainer) -> void:
	_check(page, _whole_map, "Mapa inteiro, sem névoa", whole_map_toggled.emit)
	_check(page, _god, "Modo deus (God)", god_toggled.emit)
	_forget.text = "Esquecer ilha"
	_style(_forget)
	_forget.pressed.connect(forget_pressed.emit)
	page.add_child(_forget)
	page.add_child(_section("Cenas da ilha (tocam sem gravar)"))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = SCENES_HEIGHT
	_scenes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scenes.add_theme_constant_override(&"separation", 8)
	scroll.add_child(_scenes)
	page.add_child(scroll)
	set_scenes([])


func _build_spawn(page: VBoxContainer) -> void:
	page.add_child(_section("Pôr um Ecobeast no hexágono do Domador"))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = SPECIES_LIST_HEIGHT
	_species.columns = SPECIES_COLUMNS
	_species.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_species.add_theme_constant_override(&"h_separation", 8)
	_species.add_theme_constant_override(&"v_separation", 8)
	scroll.add_child(_species)
	page.add_child(scroll)
	_clear.text = "Remover spawns"
	_style(_clear)
	_clear.disabled = true
	_clear.pressed.connect(clear_spawns_pressed.emit)
	page.add_child(_clear)


func _build_battle(page: VBoxContainer) -> void:
	page.add_child(_section("Luta de teste com a equipe"))
	var tests := _row(page)
	for slots: int in [2, 3]:
		var button := _button("Teste %d×%d" % [slots, slots])
		button.pressed.connect(board_test_pressed.emit.bind(slots))
		tests.add_child(button)
	page.add_child(_section("Domador NPC no hexágono"))
	var tamers := _row(page)
	for team_size: int in [1, 2, 3]:
		var button := _button("%d×%d" % [team_size, team_size])
		button.pressed.connect(tamer_pressed.emit.bind(team_size))
		tamers.add_child(button)
	page.add_child(_section("Equipe"))
	_xp.text = "Quase subir de nível"
	_style(_xp)
	_xp.pressed.connect(almost_level_up_pressed.emit)
	page.add_child(_xp)


func _build_visual(page: VBoxContainer) -> void:
	_check(page, _contour, "Contorno dos hexágonos", contour_toggled.emit)
	_check(page, _rounded, "Pontas arredondadas", rounded_toggled.emit)
	page.add_child(_section("Altura do terreno"))
	_check(page, _lips, "Beirada", func() -> void: height_cues_changed.emit(not HexMapView.height_lips, HexMapView.foot_shadows, HexMapView.height_tint))
	_check(page, _shadows, "Sombra no pé", func() -> void: height_cues_changed.emit(HexMapView.height_lips, not HexMapView.foot_shadows, HexMapView.height_tint))
	_check(page, _tint, "Tom por altura", func() -> void: height_cues_changed.emit(HexMapView.height_lips, HexMapView.foot_shadows, not HexMapView.height_tint))


func _build_time(page: VBoxContainer) -> void:
	page.add_child(_section("Só neste aparelho"))
	var row := _row(page)
	_time_label.theme_type_variation = &"BoldLabel"
	_time_label.custom_minimum_size.x = 72.0
	_time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_time_label)
	_time_slider.max_value = 1425.0
	_time_slider.step = 15.0
	_time_slider.custom_minimum_size.y = BUTTON_HEIGHT
	_time_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_time_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_time_slider.value_changed.connect(time_chosen.emit)
	row.add_child(_time_slider)
	var buttons := _row(page)
	var next_hour := _button("+1 hora")
	next_hour.pressed.connect(next_hour_pressed.emit)
	buttons.add_child(next_hour)
	var real_time := _button("Hora real")
	real_time.pressed.connect(real_time_pressed.emit)
	buttons.add_child(real_time)


func fill_species() -> void:
	if _species.get_child_count() > 0:
		return
	for species: CreatureSpecies in GameData.get_all_species():
		var button := Button.new()
		button.theme_type_variation = &"OutlineButton"
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(0.0, SPECIES_HEIGHT)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = not CreatureSprite.has_sheets(species.slug)
		button.pressed.connect(species_chosen.emit.bind(species))
		button.add_child(_species_card(species, button.disabled))
		_species.add_child(button)


func set_scenes(scenes: Array[StoryScene]) -> void:
	for child: Node in _scenes.get_children():
		child.queue_free()
	if scenes.is_empty():
		var label := Label.new()
		label.text = NO_SCENES_TEXT
		label.theme_type_variation = &"SecondaryLabel"
		_scenes.add_child(label)
	for scene: StoryScene in scenes:
		var button := _button("%s (%s)" % [scene.name, scene.slug])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.pressed.connect(scene_chosen.emit.bind(scene))
		_scenes.add_child(button)


func set_whole_map(on: bool) -> void:
	_whole_map.set_pressed_no_signal(on)


func set_forget_enabled(enabled: bool) -> void:
	_forget.disabled = not enabled


func set_clear_enabled(enabled: bool) -> void:
	_clear.disabled = not enabled


func set_xp_busy(busy: bool) -> void:
	_xp.disabled = busy


func show_time(text: String, minute: float) -> void:
	_time_label.text = text
	_time_slider.set_value_no_signal(snappedf(minute, 15.0))


func refresh_toggles() -> void:
	_god.set_pressed_no_signal(Session.debug_god)
	_contour.set_pressed_no_signal(HexMapView.contour_visible)
	_rounded.set_pressed_no_signal(HexMapView.rounded_corners)
	_lips.set_pressed_no_signal(HexMapView.height_lips)
	_shadows.set_pressed_no_signal(HexMapView.foot_shadows)
	_tint.set_pressed_no_signal(HexMapView.height_tint)


func _species_card(species: CreatureSpecies, disabled: bool) -> Control:
	var card := VBoxContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.modulate.a = DISABLED_ALPHA if disabled else 1.0
	var portrait: CreaturePortrait = PortraitScene.instantiate()
	portrait.portrait_size = PORTRAIT_SIZE
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(portrait)
	portrait.set_species(species.id)
	var label := Label.new()
	label.text = species.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override(&"font_size", NAME_FONT_SIZE)
	card.add_child(label)
	return card


func _check(page: VBoxContainer, check: CheckButton, text: String, on_toggle: Callable) -> void:
	check.text = text
	check.flat = true
	check.focus_mode = Control.FOCUS_NONE
	check.custom_minimum_size.y = BUTTON_HEIGHT
	check.pressed.connect(on_toggle)
	page.add_child(check)


func _section(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"SecondaryLabel"
	return label


func _row(page: VBoxContainer) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	page.add_child(row)
	return row


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	_style(button)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


func _style(button: Button) -> void:
	button.theme_type_variation = &"OutlineButton"
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = BUTTON_HEIGHT
