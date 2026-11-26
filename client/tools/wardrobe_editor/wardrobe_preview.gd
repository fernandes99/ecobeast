class_name WardrobePreview
extends Control
## O corpo e a peça montados numa linha, animando no ritmo do jogo, com as cores-chave
## trocadas pela paleta escolhida (o mesmo shader do TamerSprite).

const PREVIEW_SCALE := 4

var _body: WardrobeSheet = null
var _part: WardrobeSheet = null
var _row := 0
var _seconds := TamerSprite.IDLE_SECONDS
var _time := 0.0
var _body_layer := TextureRect.new()
var _part_layer := TextureRect.new()
var _body_atlas := AtlasTexture.new()
var _part_atlas := AtlasTexture.new()


func _init() -> void:
	custom_minimum_size = Vector2(WardrobeSheet.CELL * PREVIEW_SCALE)
	mouse_filter = MOUSE_FILTER_IGNORE
	for layer: TextureRect in [_body_layer, _part_layer]:
		layer.texture_filter = TEXTURE_FILTER_NEAREST
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.stretch_mode = TextureRect.STRETCH_SCALE
		layer.size = custom_minimum_size
		layer.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(layer)
	_body_layer.texture = _body_atlas
	_part_layer.texture = _part_atlas
	resized.connect(_place)


func show_sheets(body: WardrobeSheet, part: WardrobeSheet, row: int, seconds: float, palette_id: int, body_palette_id: int) -> void:
	for old: WardrobeSheet in [_body, _part]:
		if old != null and old.changed.is_connected(_refresh):
			old.changed.disconnect(_refresh)
	_body = body
	_part = part
	_row = row
	_seconds = seconds
	_body_layer.material = TamerSprite.palette_material(body_palette_id) if body_palette_id > 0 else null
	_part_layer.material = TamerSprite.palette_material(palette_id) if palette_id > 0 else null
	for sheet: WardrobeSheet in [_body, _part]:
		if sheet != null:
			sheet.changed.connect(_refresh)
	# A folha _back fica atrás do corpo, como no TamerSprite.
	move_child(_part_layer, 0 if part != null and part.path.contains(TamerSprite.BACK_SUFFIX) else 1)
	_refresh()


func _refresh() -> void:
	_body_atlas.atlas = ImageTexture.create_from_image(_body.image) if _body != null else null
	_part_atlas.atlas = ImageTexture.create_from_image(_part.image) if _part != null else null
	_body_layer.visible = _body != null
	_part_layer.visible = _part != null
	_show_column()


func _process(delta: float) -> void:
	_time = fmod(_time + delta, _seconds)
	_show_column()


func _show_column() -> void:
	var lead := _body if _body != null else _part
	if lead == null:
		return
	var columns := lead.columns()
	var column := mini(floori(_time / _seconds * columns), columns - 1)
	_body_atlas.region = Rect2(Vector2i(column, _row) * WardrobeSheet.CELL, WardrobeSheet.CELL)
	_part_atlas.region = _body_atlas.region


func _place() -> void:
	var at := ((size - custom_minimum_size) / 2.0).floor()
	for layer: TextureRect in [_body_layer, _part_layer]:
		layer.position = at
