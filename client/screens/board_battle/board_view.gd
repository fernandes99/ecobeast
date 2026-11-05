class_name BoardView
extends Control
## O tabuleiro da luta (board-battle/04): os hexágonos, as áreas, as marcas no
## chão, o que está aceso e os Ecobeasts. Só desenha e conta toques: quem decide
## é o servidor, e quem pede é a tela.
##
## Um nó (Node) é cada peça da cena; este é um Control que desenha os hexágonos
## no `_draw()` e tem um nó filho por Ecobeast, com o sprite, o nome e a barra.

signal cell_tapped(cell: Vector2i)

const HpBarScene := preload("res://ui/components/hp_bar.tscn")

## As proporções do hexágono do mapa (wild-battle/architecture.md), em 1,5×.
const HEX_WIDTH := 96.0
const HEX_HEIGHT := 87.0
const STEP_X := 96.0
const STEP_Y := 63.0
const ROW_SHIFT := 48.0
## Cantos a partir do canto de cima à esquerda, no sentido do relógio.
const CORNERS: Array[Vector2] = [
	Vector2(48, 0), Vector2(96, 24), Vector2(96, 63),
	Vector2(48, 87), Vector2(0, 63), Vector2(0, 24),
]
const BORDER_WIDTH := 2.0
const ACTIVE_WIDTH := 4.0
## As folhas animadas são da escala do mapa: aqui elas aparecem 4× maiores. A revisar.
const SPRITE_ZOOM := 4.0
## A escala do Domador nas folhas: 1,70 m são 25 pixels.
const PIXELS_PER_METER := 25.0 / 1.70
const FRONT_PATH := "res://assets/creatures/%s/front.png"
const LABEL_FONT_SIZE := 16
const LABEL_WIDTH := 120.0
const BAR_HEIGHT := 8
## Um passo leva um ciclo inteiro da folha walk.
const STEP_SECONDS := CreatureSprite.WALK_SECONDS
const NUMBER_FONT_SIZE := 26
const NUMBER_RISE := 40.0
const NUMBER_SECONDS := 0.9

## Um Ecobeast no tabuleiro.
class Token:
	extends Node2D
	var side: String = ""
	var cell := Vector2i.ZERO
	## A altura do Ecobeast na tela, para o nome e a barra ficarem logo acima.
	var height := 0.0
	var sprite: Node2D = null
	var bar: HpBar = null
	var label: Label = null

var _cells: Array[Vector2i] = []
var _zones: Dictionary[Vector2i, Color] = {}
var _marks: Dictionary[Vector2i, Color] = {}
var _lit: Dictionary[Vector2i, Color] = {}
var _tokens: Dictionary[String, Token] = {}
var _active_key: String = ""
## Onde o hexágono (0, 0) do tabuleiro começa, para o tabuleiro todo caber a partir de 0.
var _origin := Vector2.ZERO
var _board_size := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)


func set_board(cells: Array[Vector2i], player_zone: Array[Vector2i], enemy_zone: Array[Vector2i]) -> void:
	_cells = cells
	_zones.clear()
	for cell: Vector2i in player_zone:
		_zones[cell] = UiPalette.BOARD_ZONE_PLAYER
	for cell: Vector2i in enemy_zone:
		_zones[cell] = UiPalette.BOARD_ZONE_ENEMY
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for cell: Vector2i in cells:
		var corner := _raw_corner(cell)
		low = low.min(corner)
		high = high.max(corner + Vector2(HEX_WIDTH, HEX_HEIGHT))
	_origin = -low
	_board_size = high - low
	custom_minimum_size = _board_size
	for token: Token in _tokens.values():
		token.position = cell_center(token.cell)
	queue_redraw()


func board_size() -> Vector2:
	return _board_size


## As marcas no chão, cada uma na cor do efeito.
func set_marks(marks: Dictionary[Vector2i, Color]) -> void:
	_marks = marks
	queue_redraw()


## Acende hexágonos com uma cor; vazio apaga tudo.
func light(cells: Array[Vector2i], color: Color) -> void:
	_lit.clear()
	for cell: Vector2i in cells:
		_lit[cell] = color
	queue_redraw()


func set_active(key: String) -> void:
	_active_key = key
	queue_redraw()


## O centro do hexágono, nas coordenadas deste nó.
func cell_center(cell: Vector2i) -> Vector2:
	return _raw_corner(cell) + _origin + Vector2(HEX_WIDTH, HEX_HEIGHT) / 2.0


## O hexágono do tabuleiro sob o ponto; o mais perto do centro, ou null fora.
func cell_at(point: Vector2) -> Variant:
	var best: Variant = null
	var best_distance := INF
	for cell: Vector2i in _cells:
		var gap := point.distance_to(cell_center(cell))
		if gap < best_distance:
			best_distance = gap
			best = cell
	if best_distance > HEX_WIDTH / 2.0:
		return null
	return best


func has_token(key: String) -> bool:
	return _tokens.has(key)


func token_cell(key: String) -> Vector2i:
	return _tokens[key].cell


## Põe (ou troca) o Ecobeast da vaga `key` no hexágono.
func place(key: String, side: String, species_id: int, display_name: String, level: int, hp: int, max_hp: int, cell: Vector2i) -> void:
	remove(key)
	var token := Token.new()
	token.side = side
	token.cell = cell
	token.position = cell_center(cell)
	var species := GameData.get_species(species_id)
	token.sprite = _sprite_for(species)
	token.height = maxf(species.height_m * PIXELS_PER_METER * SPRITE_ZOOM, 24.0)
	_face(token, Vector2(0, -1) if side == "player" else Vector2(0, 1))
	token.add_child(token.sprite)

	var top := HEX_HEIGHT * 0.18 - token.height - BAR_HEIGHT - LABEL_FONT_SIZE - 12.0
	token.label = Label.new()
	token.label.text = "%s Nv.%d" % [display_name, level]
	token.label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	token.label.clip_text = true
	token.label.size = Vector2(LABEL_WIDTH, LABEL_FONT_SIZE + 6)
	token.label.position = Vector2(-LABEL_WIDTH / 2.0, top)
	token.label.add_theme_font_size_override(&"font_size", LABEL_FONT_SIZE)
	token.label.add_theme_color_override(&"font_outline_color", UiPalette.BACKGROUND_DEEP)
	token.label.add_theme_constant_override(&"outline_size", 4)
	token.label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.add_child(token.label)

	token.bar = HpBarScene.instantiate()
	token.bar.bar_height = BAR_HEIGHT
	token.bar.size = Vector2(HEX_WIDTH * 0.8, BAR_HEIGHT)
	token.bar.position = Vector2(-HEX_WIDTH * 0.4, top + LABEL_FONT_SIZE + 8)
	token.bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.bar.set_hp(hp, max_hp)
	token.add_child(token.bar)

	_tokens[key] = token
	add_child(token)
	queue_redraw()


func remove(key: String) -> void:
	if not _tokens.has(key):
		return
	var token: Token = _tokens[key]
	_tokens.erase(key)
	token.queue_free()
	queue_redraw()


func set_hp(key: String, hp: int, max_hp: int) -> void:
	if _tokens.has(key):
		_tokens[key].bar.set_hp(hp, max_hp)


## Põe no hexágono na hora, sem andar: para desfazer um passo ou acertar com a resposta.
func snap(key: String, cell: Vector2i) -> void:
	if not _tokens.has(key):
		return
	var token: Token = _tokens[key]
	token.cell = cell
	token.position = cell_center(cell)
	_face(token, Vector2(0, -1) if token.side == "player" else Vector2(0, 1))
	queue_redraw()


## Anda pelo caminho, um hexágono por ciclo da folha walk, virando a cada passo.
func walk(key: String, path: Array[Vector2i]) -> void:
	if not _tokens.has(key) or path.is_empty():
		return
	var token: Token = _tokens[key]
	_play(token, CreatureSprite.WALK)
	for cell: Vector2i in path:
		var target := cell_center(cell)
		_face(token, target - token.position)
		_play(token, CreatureSprite.WALK)
		var step := create_tween()
		step.tween_property(token, ^"position", target, STEP_SECONDS)
		await step.finished
		token.cell = cell
		queue_redraw()
	_face(token, Vector2(0, -1) if token.side == "player" else Vector2(0, 1))
	_play(token, CreatureSprite.IDLE)


## Um número que sobe e some sobre o Ecobeast, como o dano.
func float_number(key: String, text: String, color: Color) -> void:
	if not _tokens.has(key):
		return
	var token: Token = _tokens[key]
	var number := Label.new()
	number.text = text
	number.add_theme_font_size_override(&"font_size", NUMBER_FONT_SIZE)
	number.add_theme_color_override(&"font_color", color)
	number.add_theme_color_override(&"font_outline_color", UiPalette.BACKGROUND_DEEP)
	number.add_theme_constant_override(&"outline_size", 6)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.position = token.position + Vector2(-20, HEX_HEIGHT * 0.18 - token.height - 10)
	add_child(number)
	var rise := create_tween().set_parallel()
	rise.tween_property(number, ^"position:y", number.position.y - NUMBER_RISE, NUMBER_SECONDS)
	rise.tween_property(number, ^"modulate:a", 0.0, NUMBER_SECONDS)
	rise.finished.connect(number.queue_free)


## Apaga o Ecobeast que caiu, antes de ele sair do tabuleiro.
func fade(key: String) -> void:
	if _tokens.has(key):
		create_tween().tween_property(_tokens[key], ^"modulate:a", 0.3, 0.3)


func _draw() -> void:
	for cell: Vector2i in _cells:
		var points := _polygon(cell)
		draw_colored_polygon(points, _zones.get(cell, UiPalette.BOARD_CELL))
		if _marks.has(cell):
			draw_colored_polygon(points, _marks[cell])
		if _lit.has(cell):
			draw_colored_polygon(points, _lit[cell])
		var outline := points.duplicate()
		outline.append(points[0])
		draw_polyline(outline, UiPalette.BOARD_CELL_BORDER, BORDER_WIDTH, true)
	if _tokens.has(_active_key):
		var center := cell_center(_tokens[_active_key].cell)
		draw_arc(center + Vector2(0, HEX_HEIGHT * 0.18), HEX_WIDTH * 0.32, 0.0, TAU, 32, UiPalette.BOARD_ACTIVE, ACTIVE_WIDTH, true)


func _on_gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT or mouse.pressed:
		return
	var cell: Variant = cell_at(mouse.position)
	if cell != null:
		cell_tapped.emit(cell)


func _raw_corner(cell: Vector2i) -> Vector2:
	return Vector2(STEP_X * cell.x + ROW_SHIFT * cell.y, STEP_Y * cell.y)


func _polygon(cell: Vector2i) -> PackedVector2Array:
	var corner := _raw_corner(cell) + _origin
	var points := PackedVector2Array()
	for offset: Vector2 in CORNERS:
		points.append(corner + offset)
	return points


## A folha animada, ou o front.png na mesma altura, ou um círculo sem arte.
func _sprite_for(species: CreatureSpecies) -> Node2D:
	if CreatureSprite.has_sheets(species.slug):
		var animated := CreatureSprite.new(species.slug)
		animated.scale = Vector2.ONE * SPRITE_ZOOM
		animated.position = Vector2(0, HEX_HEIGHT * 0.18)
		return animated
	var still := Sprite2D.new()
	still.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var path := FRONT_PATH % species.slug
	if ResourceLoader.exists(path):
		still.texture = load(path)
		var height := maxf(species.height_m * PIXELS_PER_METER * SPRITE_ZOOM, 24.0)
		still.scale = Vector2.ONE * (height / still.texture.get_size().y)
	still.centered = true
	still.offset = Vector2(0, -still.texture.get_size().y / 2.0) if still.texture != null else Vector2.ZERO
	still.position = Vector2(0, HEX_HEIGHT * 0.18)
	return still


func _face(token: Token, direction: Vector2) -> void:
	if token.sprite is CreatureSprite:
		(token.sprite as CreatureSprite).face_toward(direction)
		_play(token, CreatureSprite.IDLE)
	elif token.sprite is Sprite2D:
		(token.sprite as Sprite2D).flip_h = direction.x < 0.0


func _play(token: Token, sheet: String) -> void:
	if token.sprite is CreatureSprite:
		(token.sprite as CreatureSprite).play_sheet(sheet)
