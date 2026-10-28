class_name ActionTile
extends TapPanel
## Card de uma ação do Hub (visual-theme/02, RF-13 e RF-14): a arte em cima e,
## embaixo, título e subtítulo no fundo da cor do corpo. A arte é
## res://assets/ui/actions/<id>.webp se existir (quadrada, recortada no centro
## para caber na área), com a base se fundindo na cor do corpo; senão, um
## gradiente da cor da arte com o ícone da ação.

const ART_PATH := "res://assets/ui/actions/%s.webp"
const ICON_PATH := "res://ui/icons/%s.svg"
const CORNER_RADIUS := 16
const BORDER_WIDTH := 2
## Altura da área da arte em relação à largura do card.
const ART_HEIGHT_RATIO := 0.8
## Quanto a borda clareia em relação à cor do corpo.
const BORDER_LIGHTEN := 0.25
## Quanto o gradiente da arte escurece embaixo.
const ART_DARKEN := 0.3
const SUBTITLE_ALPHA := 0.75

var _id: StringName = &""
var _title := ""
var _subtitle := ""
var _art_color := Color.BLACK
var _body_color := Color.BLACK

@onready var _art: PanelContainer = %Art
@onready var _art_fill: TextureRect = %ArtFill
@onready var _art_fade: TextureRect = %ArtFade
@onready var _icon: TextureRect = %Icon
@onready var _title_label: Label = %Title
@onready var _subtitle_label: Label = %Subtitle


func _ready() -> void:
	_refresh()


# A largura vem da grade; a altura da arte acompanha a largura.
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_art.custom_minimum_size.y = roundf(size.x * ART_HEIGHT_RATIO)


## Pode ser chamado antes ou depois de o componente entrar na árvore.
func setup(id: StringName, title: String, subtitle: String, art_color: Color, body_color: Color) -> void:
	_id = id
	_title = title
	_subtitle = subtitle
	_art_color = art_color
	_body_color = body_color
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = _body_color
	style.border_color = _body_color.lightened(BORDER_LIGHTEN)
	style.set_border_width_all(BORDER_WIDTH)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.set_content_margin_all(BORDER_WIDTH)
	add_theme_stylebox_override(&"panel", style)

	# O formato da área da arte (cantos de cima arredondados) recorta a imagem
	# ou o gradiente que ficam dentro dela (clip_children).
	var art_shape := StyleBoxFlat.new()
	art_shape.bg_color = _art_color
	art_shape.corner_radius_top_left = CORNER_RADIUS - BORDER_WIDTH
	art_shape.corner_radius_top_right = CORNER_RADIUS - BORDER_WIDTH
	_art.add_theme_stylebox_override(&"panel", art_shape)

	var art_path := ART_PATH % _id
	if ResourceLoader.exists(art_path):
		_art_fill.texture = load(art_path) as Texture2D
		_art_fade.texture = _fade_gradient()
		_art_fade.visible = true
		_icon.visible = false
	else:
		_art_fade.visible = false
		_art_fill.texture = _art_gradient()
		var icon_path := ICON_PATH % _id
		_icon.texture = load(icon_path) as Texture2D if ResourceLoader.exists(icon_path) else null
		_icon.visible = _icon.texture != null

	_title_label.text = _title
	_subtitle_label.text = _subtitle
	var subtitle_color := UiPalette.TEXT
	subtitle_color.a = SUBTITLE_ALPHA
	_subtitle_label.add_theme_color_override(&"font_color", subtitle_color)


func _art_gradient() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, _art_color)
	gradient.set_color(1, _art_color.darkened(ART_DARKEN))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	return texture


# Faixa na base da arte, da cor do corpo transparente até a cor do corpo.
func _fade_gradient() -> GradientTexture2D:
	var clear := _body_color
	clear.a = 0.0
	var gradient := Gradient.new()
	gradient.set_color(0, clear)
	gradient.set_color(1, _body_color)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	return texture
