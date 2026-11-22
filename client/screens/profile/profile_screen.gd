extends Control
## O Perfil (hub-start/02 e player-stats/03): o Domador, os 3 destaques e os números em abas.

const PREVIEW_SCALE := 5.0
const PREVIEW_FOOT_GAP := 16.0
const ROW_FONT := 24
const BIG_FONT := 40
const SMALL_FONT := 20
const PARTNER_FACE := 72
const LOADING_TEXT := "…"
const NONE_TEXT := "—"
const TABS: Array[String] = ["Luta", "Captura", "Mapa", "Ecobeasts", "Geral"]

var _codex: Codex = null
var _counters: PlayerCounters = null
var _highlights: Array[Label] = []
var _tabs := DebugTabs.new()
var _pages: Array[VBoxContainer] = []

@onready var _preview_area: Control = %PreviewArea
@onready var _preview: TamerSprite = %Preview
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _xp_label: Label = %XpLabel
@onready var _since_label: Label = %SinceLabel
@onready var _highlights_row: HBoxContainer = %Highlights
@onready var _body: VBoxContainer = %Body
@onready var _message: Label = %Message
@onready var _appearance_button: Button = %AppearanceButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_preview.scale = Vector2.ONE * PREVIEW_SCALE
	_preview_area.resized.connect(_place_preview)
	for title: String in ["Vitórias", "Capturas", "Jogadas"]:
		_highlights.append(_add_highlight(title))
	_build_tabs()
	_appearance_button.pressed.connect(Router.push.bind(&"appearance"))
	_back_button.pressed.connect(Router.back)
	Session.player_changed.connect(_refresh_player)
	_refresh_player()
	_place_preview()
	_fill_pages()
	_load()


func _add_highlight(title: String) -> Label:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"SectionPanel"
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	var value := Label.new()
	value.text = LOADING_TEXT
	value.theme_type_variation = &"TitleLabel"
	value.add_theme_font_size_override(&"font_size", BIG_FONT)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(value)
	var label := Label.new()
	label.text = title
	label.theme_type_variation = &"SecondaryLabel"
	label.add_theme_font_size_override(&"font_size", SMALL_FONT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)
	panel.add_child(column)
	_highlights_row.add_child(panel)
	return value


## As páginas ocupam o espaço que sobra e rolam sozinhas, para trocar de aba não mexer no resto.
func _build_tabs() -> void:
	_tabs.size_flags_vertical = SIZE_EXPAND_FILL
	_body.add_child(_tabs)
	for title: String in TABS:
		var page := _tabs.add_page(title)
		page.size_flags_vertical = SIZE_EXPAND_FILL
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		page.add_child(scroll)
		var rows := VBoxContainer.new()
		rows.size_flags_horizontal = SIZE_EXPAND_FILL
		rows.add_theme_constant_override(&"separation", 12)
		scroll.add_child(rows)
		_pages.append(rows)
	_tabs.show_page(0)


func _place_preview() -> void:
	_preview.position = Vector2(_preview_area.size.x / 2.0, _preview_area.size.y - PREVIEW_FOOT_GAP).round()


func _refresh_player() -> void:
	var player := Session.player
	if player == null:
		return
	_preview.set_appearance(player.appearance)
	_name_label.text = player.name
	_level_label.text = "Nível %d" % player.level
	if player.is_max_level():
		_xp_label.text = "Nível máximo"
	else:
		_xp_label.text = "%s / %s XP" % [
			NumberFormat.thousands(player.xp - player.level_xp),
			NumberFormat.thousands(player.next_level_xp - player.level_xp),
		]
	if _counters != null:
		_fill_pages()


func _load() -> void:
	var results: Array[Result] = [await Session.load_counters(), await Session.load_codex()]
	if not is_inside_tree():
		return
	for result: Result in results:
		if not result.ok:
			_message.text = result.error
			_message.show()
			_tabs.hide()
			for label: Label in _highlights:
				label.text = NONE_TEXT
			return
	_counters = results[0].data as PlayerCounters
	_codex = results[1].data as Codex
	_since_label.text = "Domador desde %s" % _date_text(_counters.created_at)
	_highlights[0].text = _number(_wins())
	_highlights[1].text = _number(_value("captures"))
	_highlights[2].text = _short_time(_value("play_seconds"))
	_fill_pages()


func _fill_pages() -> void:
	for rows: VBoxContainer in _pages:
		for child: Node in rows.get_children():
			child.queue_free()
	_fill_battle(_pages[0])
	_fill_capture(_pages[1])
	_fill_map(_pages[2])
	_fill_creatures(_pages[3])
	_fill_general(_pages[4])


func _fill_battle(rows: VBoxContainer) -> void:
	_add_row(rows, "Vitórias contra selvagens", _number(_value("wins_wild")))
	_add_row(rows, "Vitórias contra Domadores", _number(_value("wins_tamer")))
	_add_row(rows, "Derrotas", _number(_value("defeats")))
	_add_row(rows, "Taxa de vitória", _win_rate())


func _fill_capture(rows: VBoxContainer) -> void:
	_add_row(rows, "Capturas", _number(_value("captures")))
	_add_row(rows, "Esferas usadas", _number(_value("spheres_used")))
	_add_row(rows, "Na primeira Esfera", _number(_value("captures_first_sphere")))
	_add_row(rows, "Espécies vistas", LOADING_TEXT if _codex == null else _number(_codex.seen_count()))
	_add_row(rows, "Espécies capturadas", LOADING_TEXT if _codex == null else _number(_codex.caught_count()))
	if _counters == null:
		return
	var by_element := _counters.by_subject(GameData.counter_id("captures_by_element"))
	for element: Element in GameData.get_elements():
		if by_element.has(element.id):
			var row := _add_row(rows, "Capturas de %s" % element.name, _number(by_element[element.id]))
			(row.get_child(0) as Label).add_theme_color_override(&"font_color", element.color)
	var by_phase := _counters.by_subject(GameData.counter_id("captures_by_day_phase"))
	for phase: DayPhase in GameData.get_day_phases():
		if by_phase.has(phase.id):
			_add_row(rows, "Capturas: %s" % phase.name, _number(by_phase[phase.id]))


func _fill_map(rows: VBoxContainer) -> void:
	_add_row(rows, "Hexágonos andados", _number(_value("hexes_walked")))
	_add_row(rows, "Mapas explorados", _number(_value("maps_explored")))
	var biomes := LOADING_TEXT
	if _counters != null:
		var walked := _counters.by_subject(GameData.counter_id("biome_hexes")).size()
		biomes = "%d de %d" % [walked, _counters.walkable_biomes]
	_add_row(rows, "Biomas pisados", biomes)


func _fill_creatures(rows: VBoxContainer) -> void:
	_add_row(rows, "XP ganho", _number(_value("xp_gained")))
	if _counters == null:
		return
	var partner := HBoxContainer.new()
	partner.add_theme_constant_override(&"separation", 16)
	var title := _row_label("Parceiro", &"SecondaryLabel")
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	partner.add_child(title)
	var species := GameData.get_species(_counters.partner_species_id) if _counters.partner_species_id > 0 else null
	if species == null:
		partner.add_child(_row_label("Ainda nenhum", &"BoldLabel"))
	else:
		var face := CreatureFace.new()
		face.face_size = PARTNER_FACE
		face.set_species(species.id)
		partner.add_child(face)
		var text := VBoxContainer.new()
		text.size_flags_vertical = SIZE_SHRINK_CENTER
		text.add_child(_row_label(species.name, &"BoldLabel"))
		var battles := _row_label("%s lutas" % _number(_counters.partner_battles), &"SecondaryLabel")
		battles.add_theme_font_size_override(&"font_size", SMALL_FONT)
		text.add_child(battles)
		partner.add_child(text)
	rows.add_child(partner)


func _fill_general(rows: VBoxContainer) -> void:
	_add_row(rows, "Horas jogadas", _long_time(_value("play_seconds")))
	_add_row(rows, "Dias jogados", _number(_value("play_days")))
	_add_row(rows, "Dias seguidos", _number(_value("play_streak")))
	var player := Session.player
	_add_row(rows, "Moedas", NumberFormat.thousands(player.coins) if player != null else LOADING_TEXT)
	_add_row(rows, "Moedas ganhas", _number(_value("coins_earned")))
	_add_row(rows, "Moedas gastas", _number(_value("coins_spent")))
	_add_row(rows, "Curas no Refúgio", _number(_value("heals")))


func _add_row(rows: VBoxContainer, title: String, value: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := _row_label(title, &"SecondaryLabel")
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(label)
	var shown := _row_label(value, &"BoldLabel")
	shown.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(shown)
	rows.add_child(row)
	return row


func _row_label(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.add_theme_font_size_override(&"font_size", ROW_FONT)
	return label


## -1 enquanto os contadores não chegaram.
func _value(slug: String) -> int:
	if _counters == null:
		return -1
	return _counters.value(GameData.counter_id(slug))


func _number(value: int) -> String:
	return LOADING_TEXT if value < 0 else NumberFormat.thousands(value)


func _wins() -> int:
	if _counters == null:
		return -1
	return _value("wins_wild") + _value("wins_tamer")


func _win_rate() -> String:
	if _counters == null:
		return LOADING_TEXT
	var wins := _wins()
	var played := wins + _value("defeats")
	if played == 0:
		return NONE_TEXT
	return "%d%%" % roundi(100.0 * wins / played)


func _short_time(seconds: int) -> String:
	if seconds < 0:
		return LOADING_TEXT
	var minutes := floori(seconds / 60.0)
	return "%dh" % floori(minutes / 60.0) if minutes >= 60 else "%dmin" % minutes


func _long_time(seconds: int) -> String:
	if seconds < 0:
		return LOADING_TEXT
	var minutes := floori(seconds / 60.0)
	if minutes < 60:
		return "%dmin" % minutes
	return "%dh %dmin" % [floori(minutes / 60.0), minutes % 60]


func _date_text(iso: String) -> String:
	if iso.is_empty():
		return NONE_TEXT
	var unix := Time.get_unix_time_from_datetime_string(iso)
	unix += Time.get_time_zone_from_system().get("bias", 0) * 60
	var date := Time.get_date_dict_from_unix_time(unix)
	return "%02d/%02d/%04d" % [date["day"], date["month"], date["year"]]
