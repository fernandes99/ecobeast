class_name StarterCard
extends TapPanel
## Cartão de uma espécie na escolha do inicial (visual-theme/03, RF-05 a RF-09):
## moldura, moeda e cena do Elemento, a arte da espécie, o nome, o Elemento, a
## descrição e o botão. O cartão inteiro é tocável (TapPanel). As peças ficam em
## res://assets/ui/elements/<slug>/; um Elemento sem elas mostra o cartão em cor
## lisa, com a borda na cor do Elemento.

const ELEMENT_ART_PATH := "res://assets/ui/elements/%s/%s"
const BORDER_WIDTH := 3
## Distância entre a borda da moldura e o conteúdo.
const FRAME_PADDING := 7
## Partes da moldura que não esticam: os cantos e o pé, que tem desenho.
const FRAME_MARGIN := 30
const FRAME_BOTTOM_MARGIN := 110
## Largura de cada ponta do botão; só o meio estica.
const BUTTON_TIP_WIDTH := 34

var _species: CreatureSpecies

@onready var _art: TextureRect = %Art
@onready var _portrait: CreaturePortrait = %Portrait
@onready var _coin: TextureRect = %Coin
@onready var _name_label: Label = %NameLabel
@onready var _badge: ElementBadge = %Badge
@onready var _description: Label = %Description
@onready var _choose_button: Button = %ChooseButton


func setup(species: CreatureSpecies) -> void:
	_species = species


func _ready() -> void:
	var element := GameData.get_element(_species.element_ids[0])
	_portrait.set_species(_species.id)
	_name_label.text = _species.name
	_badge.set_element(element.id)
	_description.text = _species.description
	_art.texture = _element_art(element, "scene.webp")
	_coin.texture = _element_art(element, "icon.png")
	_apply_frame(element)
	_apply_button(element)


func _element_art(element: Element, file: String) -> Texture2D:
	var path := ELEMENT_ART_PATH % [element.slug, file]
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func _apply_frame(element: Element) -> void:
	var frame := _element_art(element, "card_frame.png")
	if frame == null:
		var flat := (get_theme_stylebox(&"panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
		flat.border_color = element.color
		flat.set_border_width_all(BORDER_WIDTH)
		flat.set_content_margin_all(FRAME_PADDING)
		add_theme_stylebox_override(&"panel", flat)
		return
	var style := StyleBoxTexture.new()
	style.texture = frame
	style.set_texture_margin_all(FRAME_MARGIN)
	style.texture_margin_bottom = FRAME_BOTTOM_MARGIN
	style.set_content_margin_all(FRAME_PADDING)
	add_theme_stylebox_override(&"panel", style)


func _apply_button(element: Element) -> void:
	var texture := _element_art(element, "button.png")
	if texture == null:
		return
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = BUTTON_TIP_WIDTH
	style.texture_margin_right = BUTTON_TIP_WIDTH
	style.set_content_margin_all(0)
	_choose_button.add_theme_stylebox_override(&"normal", style)
