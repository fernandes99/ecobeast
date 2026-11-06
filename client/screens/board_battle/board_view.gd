class_name BoardView
extends Control
## O tabuleiro da luta (board-battle/04 e 06): os hexágonos, as marcas no chão,
## o que está aceso e os Ecobeasts. Só desenha e conta toques: quem decide é o
## servidor, e quem pede é a tela.
##
## Um nó (Node) é cada peça da cena. Este é um Control com, na ordem de desenho:
## o chão do mapa de Explorar (um HexMapView, board-battle/08), que cobre a tela
## inteira, um nó que desenha o limite do tabuleiro, as marcas e o que está aceso, e
## um nó por Ecobeast, com a sombra, o sprite e a barra.

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
## O chão é o do mapa (board-battle/08): o hexágono dele, de 64 × 58 pixels da arte,
## ampliado até o do tabuleiro, na mesma grade axial.
const GROUND_SCALE := HEX_WIDTH / HexMapView.TILE_SIZE.x
## Sem o hexágono do Domador, como na luta de teste sem mapa.
const DEFAULT_BIOME := "temperate"
const DEFAULT_SHAPE := "flat"
## No tabuleiro e na volta dele, só as decorações baixas: árvores, arbustos e rochas
## cobririam os Ecobeasts. Mais longe, todas as do bioma.
const LOW_DECORATIONS: Array[String] = ["tuft", "flowers", "pebbles", "fern", "moss", "dry_tuft"]
const LOW_DECORATION_DISTANCE := 1
## O chão passa da tela por estes hexágonos, para a borda do mapa nunca aparecer.
const COVER_MARGIN := 2
## Mais que isso de hexágonos por lado é uma conta errada, não uma tela.
const MAX_COVER_CELLS := 64
const OUTLINE_WIDTH := 3.0
## O que está aceso fica um pouco para dentro do contorno do chão.
const HEX_GAP := 3.0
const LIT_BORDER_WIDTH := 3.0
const ACTIVE_WIDTH := 4.0
const GLOW_WIDTH := 12.0
const GLOW_ALPHA := 0.35

## As folhas da luta (board-battle/07) aparecem sem ampliar: 1 pixel da arte vale 1
## pixel do tabuleiro, e o tabuleiro inteiro é ampliado para caber. A revisar.
const BATTLE_SPRITE_SCALE := 1.0
## Sem elas, o sprite do tabuleiro (`board.png`, gerado do front.png por
## tools/board_sprites.gd) aparece 2× maior, sem filtro. A revisar.
const BOARD_SPRITE_PATH := "res://assets/creatures/%s/board.png"
const FRONT_PATH := "res://assets/creatures/%s/front.png"
const SPRITE_SCALE := 2.0
## Sem board.png, o front.png fica nesta altura.
const FALLBACK_HEIGHT := 80.0
## Onde ficam os pés: um pouco abaixo do centro do hexágono.
const FEET_Y := HEX_HEIGHT * 0.2
const SHADOW_COLOR := Color(0, 0, 0, 0.35)
const SHADOW_FLATTEN := 0.32
## Respirar: o corpo estica e encolhe de leve, preso nos pés.
const BREATH_SECONDS := 1.6
const BREATH_STRETCH := 0.035
## Andar: um pulinho por hexágono.
const STEP_SECONDS := 0.34
const HOP_HEIGHT := 12.0
const BAR_HEIGHT := 8
const BAR_WIDTH := HEX_WIDTH * 0.7
const NUMBER_FONT_SIZE := 34
## O número do dano sobe e ondula de um lado para o outro enquanto some (board-battle/09).
const NUMBER_RISE := 50.0
## O dono achou 1,2 s rápido demais: agora são 2 s, e o número só começa a sumir
## depois da metade do caminho.
const NUMBER_SECONDS := 2.0
const NUMBER_FADE_FROM := 0.5
const NUMBER_SWAY := 8.0
const NUMBER_SWAYS := 2.0
## Quem ataca treme de lado, como se tomasse impulso (board-battle/09). A revisar.
const ATTACK_SHAKE_SECONDS := 0.25
const ATTACK_SHAKE := 3.0
## Quem é atingido treme mais e pisca.
const HIT_SECONDS := 0.35
const HIT_SHAKE := 4.0
const HIT_BLINK_SECONDS := 0.07
const HIT_BLINK_ALPHA := 0.25
## Quantas idas e vindas cabem em cada tremida.
const SHAKES := 4
## O selvagem derrotado some de vez e, no lugar dele, uma moeda sobe girando e some
## (board-battle/09). A revisar.
const VANISH_SECONDS := 0.3
const COIN_PATH := "res://ui/icons/coin.svg"
const COIN_SIZE := 40.0
const COIN_RISE := 70.0
const COIN_SECONDS := 1.1
const COIN_SPINS := 3.0
## A moeda só começa a sumir depois deste ponto da subida.
const COIN_FADE_FROM := 0.55
## O efeito da Técnica: um quadro a cada tanto, sobre o meio do corpo, ampliado
## para cobrir o Ecobeast. A revisar.
const EFFECT_FRAME_SECONDS := 0.05
const EFFECT_SCALE := 1.5


## Um Ecobeast no tabuleiro: a sombra no chão, o corpo (que respira e pula) com o
## sprite, e a barra de HP por cima. Com as folhas da luta (board-battle/07), o
## sprite toca o idle e o walk, um quadro por vez, e não respira nem pula.
class Token:
	extends Node2D
	var side: String = ""
	var cell := Vector2i.ZERO
	## A altura do sprite na tela, para a barra e os números ficarem logo acima.
	var height := 0.0
	var shadow_radius := 0.0
	var body := Node2D.new()
	var sprite := Sprite2D.new()
	var bar: HpBar = null
	var breath: Tween = null
	## As folhas da luta; null para quem usa o board.png ou o front.png.
	var sheets: BattleSheets = null
	var _sheet := ""
	var _row := 0
	var _elapsed := 0.0

	## Toca uma linha de uma folha, do primeiro quadro, se ainda não estiver nela.
	func play(sheet: String, row: int) -> void:
		if sheet == _sheet and row == _row:
			return
		_sheet = sheet
		_row = row
		_elapsed = 0.0
		sprite.texture = sheets.textures[sheet]
		sprite.hframes = sheets.columns(sheet)
		sprite.vframes = BattleSheets.ROW_COUNTS[sheet]
		sprite.frame_coords = Vector2i(0, row)

	# O Godot liga o `_process` sozinho para todo nó com ele; sem folhas, não faz nada.
	func _process(delta: float) -> void:
		if sheets == null or _sheet == "":
			return
		_elapsed += delta
		var count := sheets.frame_count(_sheet, _row)
		var frame := int(_elapsed / BattleSheets.FRAME_SECONDS[_sheet]) % count
		sprite.frame_coords = Vector2i(frame, _row)

	func _draw() -> void:
		draw_set_transform(Vector2(0, BoardView.FEET_Y), 0.0, Vector2(1.0, BoardView.SHADOW_FLATTEN))
		draw_circle(Vector2.ZERO, shadow_radius, BoardView.SHADOW_COLOR)


var _cells: Array[Vector2i] = []
var _ground := HexMapView.new()
var _ground_seed := 0
var _biome := DEFAULT_BIOME
var _shape := DEFAULT_SHAPE
## Os hexágonos de chão fora do tabuleiro, que ficam escurecidos.
var _outside: Array[Vector2i] = []
## Desenha as marcas, o que está aceso e quem joga, por cima do chão.
var _overlay := Node2D.new()
var _marks: Dictionary[Vector2i, Color] = {}
var _lit: Dictionary[Vector2i, Color] = {}
var _tokens: Dictionary[String, Token] = {}
var _active_key: String = ""
## Onde o hexágono (0, 0) do tabuleiro começa, para o tabuleiro todo caber a partir de 0.
var _origin := Vector2.ZERO
var _board_size := Vector2.ZERO


# Os dois nascem antes de qualquer Ecobeast: quem é filho antes é desenhado antes.
func _init() -> void:
	_ground.fixed_scale = GROUND_SCALE
	_ground.allows_decoration = _allows_decoration
	add_child(_ground)
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)


## O tabuleiro e o chão em volta dele têm o bioma e a forma do hexágono do Domador,
## na mesma altura; as áreas de cada lado não têm cor própria.
func set_board(cells: Array[Vector2i], biome: String = DEFAULT_BIOME, shape: String = DEFAULT_SHAPE) -> void:
	_cells = cells
	_biome = biome
	_shape = shape
	_ground_seed = randi()
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
	cover(Rect2(Vector2.ZERO, _board_size))


## Cobre de chão a tela inteira, onde o tabuleiro está agora (board-battle/08).
## Quem chama é a tela, depois de pôr o tabuleiro no lugar.
func cover_screen() -> void:
	var to_local := get_global_transform_with_canvas().affine_inverse()
	cover(to_local * get_viewport_rect())


## Monta o chão em todos os hexágonos que encostam em `area`, nas coordenadas deste nó.
func cover(area: Rect2) -> void:
	if _cells.is_empty() or not area.is_finite():
		return
	if area.size.x > MAX_COVER_CELLS * STEP_X or area.size.y > MAX_COVER_CELLS * STEP_Y:
		push_error("BoardView: área de chão grande demais: %s" % area)
		return
	var map := ExplorationMap.new()
	map.map_seed = _ground_seed
	var first_row := floori((area.position.y - _origin.y) / STEP_Y) - COVER_MARGIN
	var last_row := ceili((area.end.y - _origin.y) / STEP_Y) + COVER_MARGIN
	_outside.clear()
	for row: int in range(first_row, last_row + 1):
		var shift := _origin.x + ROW_SHIFT * row
		for column: int in range(floori((area.position.x - shift) / STEP_X) - COVER_MARGIN, ceili((area.end.x - shift) / STEP_X) + COVER_MARGIN + 1):
			var tile := HexTile.new()
			tile.coord = Vector2i(column, row)
			tile.biome = _biome
			tile.shape = _shape
			tile.variant = 1
			map.tiles[tile.coord] = tile
			if not _cells.has(tile.coord):
				_outside.append(tile.coord)
	# O mapa sobe cada hexágono pela altura do nível: aqui ele desce o mesmo tanto,
	# para a superfície cair na grade do tabuleiro.
	var level := map.tiles[_cells[0]].level()
	_ground.position = _origin + Vector2(0.0, HexMapView.LEVEL_HEIGHTS[level] * GROUND_SCALE)
	_ground.set_map(map)
	_ground.build_all_rows()
	_redraw()


func board_size() -> Vector2:
	return _board_size


## As marcas no chão, cada uma na cor do efeito.
func set_marks(marks: Dictionary[Vector2i, Color]) -> void:
	_marks = marks
	_redraw()


## Acende hexágonos com uma cor; vazio apaga tudo.
func light(cells: Array[Vector2i], color: Color) -> void:
	_lit.clear()
	for cell: Vector2i in cells:
		_lit[cell] = color
	_redraw()


## Quem joga agora fica destacado só pelo hexágono: o contorno branco no sprite saiu
## a pedido do dono (board-battle/07).
func set_active(key: String) -> void:
	_active_key = key
	_redraw()


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
func place(key: String, side: String, species_id: int, hp: int, max_hp: int, cell: Vector2i) -> void:
	remove(key)
	var token := Token.new()
	token.side = side
	token.cell = cell
	token.position = cell_center(cell)
	var species := GameData.get_species(species_id)
	_dress(token, species.slug)
	token.body.position = Vector2(0, FEET_Y)
	token.body.add_child(token.sprite)
	token.add_child(token.body)
	_rest(token)

	token.bar = HpBarScene.instantiate()
	token.bar.bar_height = BAR_HEIGHT
	token.bar.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	token.bar.position = Vector2(-BAR_WIDTH / 2.0, FEET_Y - token.height - BAR_HEIGHT - 6.0)
	token.bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.bar.set_hp(hp, max_hp)
	token.add_child(token.bar)

	_tokens[key] = token
	add_child(token)
	# Com as folhas, o idle já respira; só a pose de uma imagem parada precisa da escala.
	if token.sheets == null or token.sheets.frame_count(BattleSheets.IDLE, _rest_row(side)) <= 1:
		_breathe(token)
	_redraw()


func remove(key: String) -> void:
	if not _tokens.has(key):
		return
	var token: Token = _tokens[key]
	_tokens.erase(key)
	token.queue_free()
	_redraw()


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
	token.body.position = Vector2(0, FEET_Y)
	_rest(token)
	_redraw()


## Anda pelo caminho, virando para cada passo: com as folhas da luta, tocando o walk
## na vista do passo; sem elas, com um pulinho por hexágono. Parado, toca o idle.
func walk(key: String, path: Array[Vector2i]) -> void:
	if not _tokens.has(key) or path.is_empty():
		return
	var token: Token = _tokens[key]
	for cell: Vector2i in path:
		var target := cell_center(cell)
		_face(token, target - token.position)
		var step := create_tween().set_parallel()
		if token.sheets != null:
			step.tween_property(token, ^"position", target, token.sheets.step_seconds())
		else:
			step.tween_property(token, ^"position", target, STEP_SECONDS)
			step.tween_method(func(t: float) -> void:
				token.body.position.y = FEET_Y - sin(t * PI) * HOP_HEIGHT, 0.0, 1.0, STEP_SECONDS)
		await step.finished
		token.cell = cell
		_redraw()
	token.body.position = Vector2(0, FEET_Y)
	_rest(token)


## Um número que sobe e some sobre o Ecobeast, como o dano: ele ondula de um lado
## para o outro enquanto sobe e vai sumindo aos poucos. Não precisa ser esperado.
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
	add_child(number)
	# O meio do número fica sobre o Ecobeast, logo acima da barra de HP.
	var text_size := number.get_combined_minimum_size()
	var start := token.position + Vector2(-text_size.x / 2.0, token.bar.position.y - text_size.y)
	number.position = start
	var rise := create_tween()
	rise.tween_method(func(t: float) -> void:
		number.position = start + Vector2(sin(t * TAU * NUMBER_SWAYS) * NUMBER_SWAY, -t * NUMBER_RISE)
		number.modulate.a = 1.0 - clampf((t - NUMBER_FADE_FROM) / (1.0 - NUMBER_FADE_FROM), 0.0, 1.0), 0.0, 1.0, NUMBER_SECONDS)
	rise.finished.connect(number.queue_free)


## Quem ataca treme de lado e volta ao lugar. Pode ser esperado.
func attack_shake(key: String) -> void:
	if _tokens.has(key):
		await _shake(_tokens[key], ATTACK_SHAKE, ATTACK_SHAKE_SECONDS)


## Quem é atingido treme e pisca. Pode ser esperado.
func hit(key: String) -> void:
	if not _tokens.has(key):
		return
	var token: Token = _tokens[key]
	var blink := create_tween().set_loops(roundi(HIT_SECONDS / (HIT_BLINK_SECONDS * 2.0)))
	blink.bind_node(token)
	blink.tween_property(token.sprite, ^"self_modulate:a", HIT_BLINK_ALPHA, 0.0)
	blink.tween_interval(HIT_BLINK_SECONDS)
	blink.tween_property(token.sprite, ^"self_modulate:a", 1.0, 0.0)
	blink.tween_interval(HIT_BLINK_SECONDS)
	await _shake(token, HIT_SHAKE, HIT_SECONDS)
	if is_instance_valid(token):
		token.sprite.self_modulate.a = 1.0


## Toca o efeito de uma Técnica sobre o meio do corpo do alvo: uma tira de quadros
## quadrados, da esquerda para a direita. `mirrored`: o atacante está à direita.
## Pode ser esperado; o efeito some no fim.
func play_effect(key: String, texture: Texture2D, mirrored: bool) -> void:
	if not _tokens.has(key) or texture == null:
		return
	var token: Token = _tokens[key]
	var effect := Sprite2D.new()
	effect.texture = texture
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effect.hframes = maxi(1, roundi(texture.get_width() / float(texture.get_height())))
	effect.flip_h = mirrored
	effect.scale = Vector2.ONE * EFFECT_SCALE
	effect.position = token.position + Vector2(0.0, FEET_Y - token.height / 2.0)
	add_child(effect)
	for frame: int in effect.hframes:
		effect.frame = frame
		await get_tree().create_timer(EFFECT_FRAME_SECONDS).timeout
	effect.queue_free()


## O centro do hexágono de quem está na vaga, ou null sem ninguém.
func token_position(key: String) -> Variant:
	return _tokens[key].position if _tokens.has(key) else null


## O corpo vai e volta de lado, `SHAKES` vezes, e volta ao lugar.
func _shake(token: Token, amount: float, seconds: float) -> void:
	var shake := create_tween()
	shake.bind_node(token)
	var step := seconds / (SHAKES * 2.0)
	for _index: int in SHAKES:
		shake.tween_property(token.body, ^"position:x", amount, step)
		shake.tween_property(token.body, ^"position:x", -amount, step)
	shake.tween_property(token.body, ^"position:x", 0.0, step / 2.0)
	# Um timer, e não o fim do Tween: se o Ecobeast sair do tabuleiro, o Tween morre sem
	# avisar, e a luta ficaria esperando para sempre.
	await get_tree().create_timer(seconds + step / 2.0).timeout


## O Ecobeast some de vez e sai do tabuleiro; com `coin`, uma moeda sobe girando no
## lugar dele. Pode ser esperado até ele sumir; a moeda segue sozinha.
func vanish(key: String, coin: bool) -> void:
	if not _tokens.has(key):
		return
	var token: Token = _tokens[key]
	create_tween().tween_property(token, ^"modulate:a", 0.0, VANISH_SECONDS)
	await get_tree().create_timer(VANISH_SECONDS).timeout
	var middle := token.position + Vector2(0.0, FEET_Y - token.height / 2.0)
	remove(key)
	if coin:
		_pop_coin(middle)


## A moeda gira (encolhe e estica na largura, como uma moeda de pé), sobe
## desacelerando e some aos poucos de baixo para cima do caminho.
func _pop_coin(at: Vector2) -> void:
	var coin := Sprite2D.new()
	coin.texture = load(COIN_PATH) as Texture2D
	var size := COIN_SIZE / coin.texture.get_height()
	coin.scale = Vector2.ONE * size
	coin.position = at
	add_child(coin)
	var rise := create_tween()
	rise.tween_method(func(t: float) -> void:
		coin.position = at - Vector2(0.0, COIN_RISE * (1.0 - pow(1.0 - t, 2.0)))
		coin.scale.x = size * cos(t * TAU * COIN_SPINS)
		coin.modulate.a = 1.0 - clampf((t - COIN_FADE_FROM) / (1.0 - COIN_FADE_FROM), 0.0, 1.0), 0.0, 1.0, COIN_SECONDS)
	rise.finished.connect(coin.queue_free)


## Apaga o Ecobeast que caiu, antes de ele sair do tabuleiro.
func fade(key: String) -> void:
	if _tokens.has(key):
		create_tween().tween_property(_tokens[key], ^"modulate:a", 0.3, 0.3)


func _redraw() -> void:
	_overlay.queue_redraw()


## O contorno de cada hexágono já vem do chão: aqui o limite do tabuleiro, com o
## chão de fora escurecido e uma borda clara, e o que muda na luta.
func _draw_overlay() -> void:
	var active: Variant = _tokens[_active_key].cell if _tokens.has(_active_key) else null
	var enemy_active := _tokens.has(_active_key) and _tokens[_active_key].side == "enemy"
	for cell: Vector2i in _outside:
		_overlay.draw_colored_polygon(_polygon(cell), UiPalette.BOARD_OUTSIDE)
	for cell: Vector2i in _cells:
		var corners := _polygon(cell)
		for edge: int in HexTransitions.NEIGHBORS.size():
			if not _cells.has(cell + HexTransitions.NEIGHBORS[edge]):
				_overlay.draw_line(corners[edge], corners[(edge + 1) % corners.size()], UiPalette.BOARD_EDGE, OUTLINE_WIDTH, true)
	for cell: Vector2i in _cells:
		var points := _polygon(cell, HEX_GAP)
		if _marks.has(cell):
			_overlay.draw_colored_polygon(points, _marks[cell])
		if _lit.has(cell):
			_overlay.draw_colored_polygon(points, _lit[cell])
			_overlay.draw_polyline(_closed(points), Color(_lit[cell], 1.0).lightened(0.25), LIT_BORDER_WIDTH, true)
	# Quem joga agora: o hexágono na cor do lado, com brilho em volta.
	if active != null:
		var points := _polygon(active, HEX_GAP)
		var glow := UiPalette.BOARD_ACTIVE_ENEMY_GLOW if enemy_active else UiPalette.BOARD_ACTIVE_GLOW
		_overlay.draw_colored_polygon(points, UiPalette.BOARD_ACTIVE_ENEMY_CELL if enemy_active else UiPalette.BOARD_ACTIVE_CELL)
		_overlay.draw_polyline(_closed(points), Color(glow, GLOW_ALPHA), GLOW_WIDTH, true)
		_overlay.draw_polyline(_closed(points), glow, ACTIVE_WIDTH, true)


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var outline := points.duplicate()
	outline.append(points[0])
	return outline


func _on_gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT or mouse.pressed:
		return
	var cell: Variant = cell_at(mouse.position)
	if cell != null:
		cell_tapped.emit(cell)


func _raw_corner(cell: Vector2i) -> Vector2:
	return Vector2(STEP_X * cell.x + ROW_SHIFT * cell.y, STEP_Y * cell.y)


## Os cantos do hexágono, recolhidos `inset` pixels na direção do centro.
func _polygon(cell: Vector2i, inset: float = 0.0) -> PackedVector2Array:
	var corner := _raw_corner(cell) + _origin
	var center := Vector2(HEX_WIDTH, HEX_HEIGHT) / 2.0
	var shrink := 1.0 - inset / (HEX_WIDTH / 2.0)
	var points := PackedVector2Array()
	for offset: Vector2 in CORNERS:
		points.append(corner + center + (offset - center) * shrink)
	return points


## As folhas da luta, o sprite do tabuleiro ou o front.png reduzido, com os pés na
## origem do corpo.
func _dress(token: Token, slug: String) -> void:
	var sprite := token.sprite
	token.sheets = BattleSheets.for_slug(slug)
	if token.sheets != null:
		var sheets := token.sheets
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2.ONE * BATTLE_SPRITE_SCALE
		sprite.centered = false
		# O meio da célula e a linha dos pés ficam na origem do corpo.
		sprite.offset = -Vector2(sheets.cell / 2.0, sheets.feet + 1)
		token.height = sheets.height() * BATTLE_SPRITE_SCALE
		token.shadow_radius = sheets.rest_width * BATTLE_SPRITE_SCALE * 0.5
		return
	sprite.centered = true
	var board_path := BOARD_SPRITE_PATH % slug
	if ResourceLoader.exists(board_path):
		sprite.texture = load(board_path)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2.ONE * SPRITE_SCALE
	elif ResourceLoader.exists(FRONT_PATH % slug):
		sprite.texture = load(FRONT_PATH % slug)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.scale = Vector2.ONE * (FALLBACK_HEIGHT / sprite.texture.get_size().y)
	if sprite.texture == null:
		return
	var art_size := sprite.texture.get_size()
	sprite.offset = Vector2(0, -art_size.y / 2.0)
	token.height = art_size.y * sprite.scale.y
	token.shadow_radius = art_size.x * sprite.scale.x * 0.42


## Perto do tabuleiro, só as decorações baixas.
func _allows_decoration(coord: Vector2i, kind: String) -> bool:
	if LOW_DECORATIONS.has(kind):
		return true
	for cell: Vector2i in _cells:
		if ExplorationMap.distance(coord, cell) <= LOW_DECORATION_DISTANCE:
			return false
	return true


## O corpo estica e encolhe de leve, sem parar, preso nos pés.
func _breathe(token: Token) -> void:
	token.breath = create_tween().set_loops()
	token.breath.bind_node(token)
	token.breath.set_trans(Tween.TRANS_SINE)
	token.breath.tween_property(token.body, ^"scale", Vector2(1.0 - BREATH_STRETCH / 2.0, 1.0 + BREATH_STRETCH), BREATH_SECONDS / 2.0)
	token.breath.tween_property(token.body, ^"scale", Vector2.ONE, BREATH_SECONDS / 2.0)



## Parado, cada um olha para o adversário. Com as folhas da luta, os do jogador, que
## estão embaixo, ficam de costas, e os selvagens, em cima, de frente. Sem elas, os do
## jogador olham para a direita e os selvagens para a esquerda.
func _rest(token: Token) -> void:
	if token.sheets != null:
		token.sprite.flip_h = false
		token.play(BattleSheets.IDLE, _rest_row(token.side))
		return
	token.sprite.flip_h = token.side != "player"


func _rest_row(side: String) -> int:
	return BattleSheets.IDLE_NORTH if side == "player" else BattleSheets.IDLE_SOUTH


## Vira para o passo. Com as folhas, escolhe a vista do walk: no tabuleiro, todo passo
## é para o lado ou numa diagonal, descendo ou subindo; para a esquerda, espelha.
func _face(token: Token, direction: Vector2) -> void:
	if absf(direction.x) > 0.01:
		token.sprite.flip_h = direction.x < 0.0
	if token.sheets == null:
		return
	var row := BattleSheets.WALK_SIDE
	if direction.y > STEP_Y / 2.0:
		row = BattleSheets.WALK_DOWN
	elif direction.y < -STEP_Y / 2.0:
		row = BattleSheets.WALK_UP
	token.play(BattleSheets.WALK, row)
