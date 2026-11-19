class_name ZonePanel
extends VBoxContainer

## As zonas do catálogo para a ferramenta Zona (biome-zones/03), separadas por bioma.
## A Comum de cada bioma não aparece: o botão de trás volta o hexágono para ela.

signal picked(slug: String)

const SWATCH_SIZE := Vector2(14.0, 14.0)
const GOLDEN := 0.618034

var selected := ""
var _buttons: Dictionary[String, Button] = {}
var _biome_of: Dictionary[String, String] = {}


func _init() -> void:
	add_theme_constant_override(&"separation", 4)
	var biome_slugs: Dictionary[int, String] = {}
	for biome: Dictionary in GameData.get_rows("biomes"):
		biome_slugs[int(biome["id"])] = str(biome["slug"])
	var zones := GameData.get_rows("biome_zones").duplicate()
	zones.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return [int(a["biome_id"]), int(a["sort_order"])] < [int(b["biome_id"]), int(b["sort_order"])])
	var group := ButtonGroup.new()
	var last_biome := -1
	for zone: Dictionary in zones:
		var slug := str(zone["slug"])
		var biome_slug: String = biome_slugs.get(int(zone["biome_id"]), "")
		_biome_of[slug] = biome_slug
		if slug == biome_slug:
			continue
		if int(zone["biome_id"]) != last_biome:
			last_biome = int(zone["biome_id"])
			var title := Label.new()
			title.text = EditorTools.BIOME_NAMES.get(biome_slug, biome_slug)
			title.add_theme_color_override(&"font_color", UiPalette.TEXT_SECONDARY)
			add_child(title)
		var button := Button.new()
		button.text = str(zone["name"])
		button.toggle_mode = true
		button.button_group = group
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.icon = _swatch(color_of(slug))
		button.pressed.connect(_pick.bind(slug))
		add_child(button)
		_buttons[slug] = button
	if _buttons.is_empty():
		var empty := Label.new()
		empty.text = "Nenhuma zona no catálogo."
		add_child(empty)
	else:
		_pick(_buttons.keys()[0])


func biome_of(slug: String) -> String:
	return _biome_of.get(slug, "")


## Uma cor fixa por zona, espalhada pelo círculo das cores.
static func color_of(slug: String) -> Color:
	var hue := fposmod(float(hash(slug) % 1000) * GOLDEN, 1.0)
	return Color.from_hsv(hue, 0.75, 0.95)


func _pick(slug: String) -> void:
	selected = slug
	_buttons[slug].set_pressed_no_signal(true)
	picked.emit(slug)


func _swatch(color: Color) -> ImageTexture:
	var image := Image.create(int(SWATCH_SIZE.x), int(SWATCH_SIZE.y), false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
