class_name PropArt
extends RefCounted
## A arte de um tipo de peça solta fora do mapa (free-props/03): o ícone de uma
## variante e o retângulo da arte em volta do pé, em pixels da arte.

## O espaço das peças de arte própria, que não estão em KIND_RADIUS: uma parte da largura
## da variante, entre os limites (vegetation-packs/01).
const ART_RADIUS_SHARE := 0.25
const MIN_ART_RADIUS := 4.0
const MAX_ART_RADIUS := 15.0

static var _icons: Dictionary[String, Texture2D] = {}
static var _thumbnails: Dictionary[String, Texture2D] = {}
static var _sheet: Image = null


static func slug_of(prop_type_id: int) -> String:
	return str(GameData.get_row("prop_types", prop_type_id).get("slug", ""))


static func icon(slug: String, variant: int) -> Texture2D:
	var key := "%s/%d" % [slug, variant]
	if _icons.has(key):
		return _icons[key]
	var texture: Texture2D = null
	if HexDecorations.KIND_ROWS.has(slug):
		var atlas := AtlasTexture.new()
		atlas.atlas = load(HexDecorations.TEXTURE_PATH) as Texture2D
		var cell := Vector2i(clampi(variant - 1, 0, HexDecorations.VARIANTS - 1), HexDecorations.KIND_ROWS[slug])
		atlas.region = Rect2(Vector2(cell * HexDecorations.CELL_SIZE), Vector2(HexDecorations.CELL_SIZE))
		texture = atlas
	else:
		var path := HexMapView.PROP_PATH % [slug, variant]
		texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_icons[key] = texture
	return texture


## O ícone recortado pelos pixels: a célula das decorações tem muito vazio em volta
## (editor-ui/01).
static func thumbnail(slug: String, variant: int) -> Texture2D:
	var key := "%s/%d" % [slug, variant]
	if _thumbnails.has(key):
		return _thumbnails[key]
	var texture := icon(slug, variant)
	var atlas := texture as AtlasTexture
	if atlas != null:
		if _sheet == null:
			_sheet = atlas.atlas.get_image()
		var region := Rect2i(atlas.region)
		var used := _sheet.get_region(region).get_used_rect()
		if used.has_area():
			var trimmed := AtlasTexture.new()
			trimmed.atlas = atlas.atlas
			trimmed.region = Rect2(Vector2(region.position + used.position), Vector2(used.size))
			texture = trimmed
	_thumbnails[key] = texture
	return texture


## O espaço que a peça ocupa no chão, em pixels da arte.
static func radius(slug: String, variant: int) -> float:
	if HexDecorations.KIND_RADIUS.has(slug):
		return HexDecorations.KIND_RADIUS[slug]
	return clampf(rect(slug, variant).size.x * ART_RADIUS_SHARE, MIN_ART_RADIUS, MAX_ART_RADIUS)


## O retângulo da arte, com o pé em (0, 0).
static func rect(slug: String, variant: int) -> Rect2:
	if HexDecorations.KIND_ROWS.has(slug):
		return Rect2(-Vector2(HexDecorations.CELL_BASE), Vector2(HexDecorations.CELL_SIZE))
	var texture := icon(slug, variant)
	if texture == null:
		return Rect2(-8.0, -16.0, 16.0, 16.0)
	var size := Vector2(texture.get_width(), texture.get_height())
	return Rect2(-floorf(size.x / 2.0), -size.y, size.x, size.y)
