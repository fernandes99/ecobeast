class_name ExplorePlates
extends VBoxContainer
## As placas do canto de cima de Explorar (.specs/explore-hud/04-top-info.md): o ícone e o
## nome do bioma do hexágono do Domador e, embaixo, o ícone da parte do dia, a hora do mundo
## e o nome da parte na cor dela.

const ICON_SIDE := 32
const BIOME_ICON := "res://assets/ui/biomes/%s.png"
const PHASE_ICON := "res://assets/ui/day_phases/%s.png"
const SEPARATOR := "|"
const NAME_FONT := 26
const TIME_FONT := 20
const OUTLINE := 6
const PANEL_ALPHA := 0.88
const PANEL_RADIUS := 18

var _biome_plate := PanelContainer.new()
var _biome_icon := TextureRect.new()
var _biome_name := Label.new()
var _time_plate := PanelContainer.new()
var _phase_icon := TextureRect.new()
var _clock := Label.new()
var _phase_name := Label.new()
var _timer := Timer.new()
var _biome := ""
static var _names: Dictionary[String, String] = {}


func _init() -> void:
	add_theme_constant_override(&"separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var biome_row := _plate(_biome_plate)
	_icon_rect(_biome_icon)
	biome_row.add_child(_biome_icon)
	_text(_biome_name, NAME_FONT, &"TitleLabel")
	biome_row.add_child(_biome_name)
	var time_row := _plate(_time_plate)
	_icon_rect(_phase_icon)
	time_row.add_child(_phase_icon)
	_text(_clock, TIME_FONT, &"BoldLabel")
	time_row.add_child(_clock)
	var separator := Label.new()
	separator.text = SEPARATOR
	_text(separator, TIME_FONT, &"SecondaryLabel")
	time_row.add_child(separator)
	_text(_phase_name, TIME_FONT, &"BoldLabel")
	time_row.add_child(_phase_name)
	_timer.wait_time = 1.0
	_timer.timeout.connect(_show_clock)
	add_child(_timer)


func _ready() -> void:
	WorldClock.phase_changed.connect(_show_phase)
	_show_phase(WorldClock.phase())
	_timer.start()


## O painel escuro dos cantos de Explorar: a placa, o quadro de missões e o aviso.
static func panel_style(radius: int = PANEL_RADIUS) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(UiPalette.BACKGROUND_DEEP, PANEL_ALPHA)
	style.border_color = UiPalette.BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


## O bioma do hexágono do Domador; vazio esconde a placa.
func set_biome(slug: String) -> void:
	if slug == _biome:
		return
	_biome = slug
	_biome_plate.visible = not slug.is_empty()
	var path := BIOME_ICON % slug
	_biome_icon.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_biome_icon.visible = _biome_icon.texture != null
	_biome_name.text = biome_name(slug)


static func biome_name(slug: String) -> String:
	if _names.is_empty():
		for row: Dictionary in GameData.get_rows("biomes"):
			_names[str(row.get("slug", ""))] = str(row.get("name", ""))
	return _names.get(slug, slug)


func _show_phase(phase: DayPhase) -> void:
	_time_plate.visible = phase != null
	if phase == null:
		return
	var path := PHASE_ICON % phase.slug
	_phase_icon.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_phase_name.text = phase.name
	_phase_name.add_theme_color_override(&"font_color", UiPalette.HUD_PHASE_COLORS.get(phase.slug, UiPalette.TEXT))
	_show_clock()


func _show_clock() -> void:
	var minute := int(WorldClock.minute_of_day())
	_clock.text = "%02d:%02d" % [floori(minute / 60.0), minute % 60]


func _plate(plate: PanelContainer) -> HBoxContainer:
	plate.add_theme_stylebox_override(&"panel", panel_style())
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(row)
	return row


func _icon_rect(rect: TextureRect) -> void:
	rect.custom_minimum_size = Vector2(ICON_SIDE, ICON_SIDE)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _text(label: Label, font_size: int, variation: StringName) -> void:
	label.theme_type_variation = variation
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_constant_override(&"outline_size", OUTLINE)
	label.add_theme_color_override(&"font_outline_color", UiPalette.TEXT_OUTLINE)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
