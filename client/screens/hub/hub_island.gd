class_name HubIsland
extends Control
## A ilha da Home do Hub (hub-start/04 e 05): um ExplorationMap só do cliente, de enfeite,
## desenhado pelo mesmo HexMapView de Explorar. Tocar num hexágono anda o Domador até ele,
## e o Ecobeast em destaque segue um hexágono atrás; a câmera acompanha o Domador.

## Os atores andaram ou a câmera mexeu: quem segue um ator na tela se reposiciona.
signal moved

const ZOOM := 3
const MAP_SEED := 4242
const TAMER_START := Vector2i(0, 0)
const CREATURE_START := Vector2i(1, 0)
## A meia largura da ilha em cada linha, em pixels da arte, de r = -3 a 3.
const HALF_WIDTHS: Array[int] = [96, 160, 192, 224, 192, 160, 96]
const FIRST_ROW := -3
## A altura de cada linha, de trás para a frente; alguns hexágonos sobem um nível.
const ROW_HEIGHTS: Array[int] = [4, 3, 3, 2, 2, 1, 1]
const POND: Array[Vector2i] = [Vector2i(3, 0), Vector2i(2, 1)]
const POND_BIOME := "wshallow"
const LAND_BIOME := "temperate"
const PINE_BIOME := "boreal"
## A folga em cima da ilha, em pixels da arte, para as árvores e os atores no alto.
const TOP_ROOM := 28.0
const CAMERA_SHARPNESS := 6.0
const TAP_SLOP := 24.0
const FALLBACK_HEIGHT := 28.0


## Quem anda pela ilha: o nó, o hexágono em que está ou para onde vai e os próximos.
class Walker:
	var node: Node2D
	var coord: Vector2i
	var from_flat: Vector2
	var to_flat: Vector2
	var from_surface: Vector2
	var to_surface: Vector2
	var progress := 1.0
	var queue: Array[Vector2i] = []

	func moving() -> bool:
		return progress < 1.0 or not queue.is_empty()


var _view := HexMapView.new()
var _map := ExplorationMap.new()
var _tamer := Walker.new()
var _creature := Walker.new()
var _camera := Vector2.INF
var _press := Vector2.INF
## Onde o Domador fica na tela, no espaço desta ilha; sem valor, o meio dela.
var _focus := Vector2.INF


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_build_map()
	add_child(_view)
	_view.zoom_level = ZOOM
	_view.set_map(_map)
	_view.build_all_rows()
	_tamer.coord = TAMER_START
	_creature.coord = CREATURE_START
	resized.connect(_follow_camera.bind(0.0, true))
	_follow_camera.call_deferred(0.0, true)


func _build_map() -> void:
	_map.map_seed = MAP_SEED
	for row: int in HALF_WIDTHS.size():
		var r := FIRST_ROW + row
		for q: int in range(-8, 9):
			var x := HexMapView.STEP_X * q + HexMapView.ROW_SHIFT * r
			if absi(x) > HALF_WIDTHS[row]:
				continue
			var coord := Vector2i(q, r)
			var tile := HexTile.new()
			tile.coord = coord
			tile.variant = 1
			var start := coord == TAMER_START or coord == CREATURE_START
			if POND.has(coord):
				tile.biome = POND_BIOME
				tile.height = 0
			else:
				tile.biome = PINE_BIOME if r <= -2 and posmod(q, 2) == 1 else LAND_BIOME
				var bump := 0 if start else int(posmod(q * 7 + r * 13, 4) == 0)
				tile.height = mini(ROW_HEIGHTS[row] + bump, 4)
			tile.bare = start
			_map.tiles[coord] = tile


func set_tamer(node: Node2D) -> void:
	_put(_tamer, node)
	_face_each_other()


## Troca o Ecobeast em destaque no lugar do anterior.
func set_creature(node: Node2D) -> void:
	if _creature.node != null:
		_creature.node.queue_free()
	_put(_creature, node)
	_face_each_other()
	moved.emit()


func creature_node() -> Node2D:
	return _creature.node


## Sem as folhas do mapa, o `front.png` pequeno faz o papel do Ecobeast, sem animação.
static func fallback_creature(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	var height := float(texture.get_height())
	sprite.scale = Vector2.ONE * FALLBACK_HEIGHT / height
	sprite.offset = Vector2(-texture.get_width() / 2.0, -height)
	return sprite


## Um ponto da arte, no espaço desta ilha.
func to_local_point(art_point: Vector2) -> Vector2:
	return _view.position + art_point * _view.scale


func pixel_scale() -> float:
	return _view.scale.x


func _put(walker: Walker, node: Node2D) -> void:
	walker.node = node
	if node == null:
		return
	if node is WanderingSprite:
		node.scale = Vector2.ONE
	_view.add_child(node)
	var flat := HexMapView.flat_center(walker.coord)
	var surface := _view.surface_center(walker.coord)
	if walker.progress < 1.0:
		flat = walker.from_flat.lerp(walker.to_flat, walker.progress)
		surface = walker.from_surface.lerp(walker.to_surface, walker.progress)
		_run(walker)
	_place_walker(walker, flat, surface)


func _place_walker(walker: Walker, flat: Vector2, surface: Vector2) -> void:
	walker.node.position = surface
	_view.follow_depth(walker.node, flat, HexMapView.grid_coord(flat).y)


func _face_each_other() -> void:
	if _tamer.node == null or _creature.node == null or _tamer.moving() or _creature.moving():
		return
	var toward := _view.surface_center(_creature.coord) - _view.surface_center(_tamer.coord)
	_face(_tamer, toward)
	_face(_creature, -toward)
	_rest(_tamer)
	_rest(_creature)


func _face(walker: Walker, direction: Vector2) -> void:
	if direction != Vector2.ZERO and walker.node is WanderingSprite:
		(walker.node as WanderingSprite).face_toward(direction)


func _rest(walker: Walker) -> void:
	if walker.node is TamerSprite:
		(walker.node as TamerSprite).play_idle()
	elif walker.node is CreatureSprite:
		(walker.node as CreatureSprite).play_idle()


func _run(walker: Walker) -> void:
	if walker.node is TamerSprite:
		(walker.node as TamerSprite).play_run()
	elif walker.node is CreatureSprite:
		(walker.node as CreatureSprite).play_walk()


# --- Andar ---


## A interface fica por cima da ilha: quem recebe o toque, como o palco do Hub, passa
## o evento para cá. Um toque sem arrasto anda até o hexágono tocado.
func handle_touch(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	var point := get_global_transform_with_canvas().affine_inverse() * button.global_position
	if button.pressed:
		_press = point
	elif _press.is_finite() and point.distance_to(_press) <= TAP_SLOP:
		_press = Vector2.INF
		walk_to(_view.coord_at((point - _view.position) / _view.scale))


## O ponto da tela, no espaço desta ilha, onde a câmera põe o Domador.
func set_focus(point: Vector2) -> void:
	if point.is_equal_approx(_focus):
		return
	_focus = point
	_follow_camera(0.0, true)


## O Domador anda até `goal` depois do passo que está dando; sem caminho, nada muda.
func walk_to(goal: Vector2i) -> void:
	if not _map.has(goal) or _map.is_blocked_hex(goal):
		return
	if _tamer.coord == goal:
		_tamer.queue.clear()
		return
	var goals: Dictionary[Vector2i, bool] = {goal: true}
	var path := _map.path_to_any(_tamer.coord, goals)
	if not path.is_empty():
		_tamer.queue = path


func _process(delta: float) -> void:
	var was_moving := _tamer.moving() or _creature.moving()
	if _tamer.node != null:
		_step(_tamer, delta, true)
	if _creature.node != null:
		_step(_creature, delta, false)
	_follow_camera(delta, false)
	if was_moving and not (_tamer.moving() or _creature.moving()):
		_face_each_other()


## Anda o ator na direção do próximo hexágono; o Domador, ao deixar um hexágono, o põe na
## fila do Ecobeast.
func _step(walker: Walker, delta: float, leads: bool) -> void:
	if walker.progress >= 1.0:
		if walker.queue.is_empty():
			return
		var next: Vector2i = walker.queue.pop_front()
		walker.from_flat = HexMapView.flat_center(walker.coord)
		walker.from_surface = _view.surface_center(walker.coord)
		walker.to_flat = HexMapView.flat_center(next)
		walker.to_surface = _view.surface_center(next)
		walker.progress = 0.0
		if leads:
			_follow(walker.coord)
		walker.coord = next
		_face(walker, walker.to_surface - walker.from_surface)
		_run(walker)
	var length := maxf(walker.from_flat.distance_to(walker.to_flat), 1.0)
	walker.progress = minf(1.0, walker.progress + WalkRoute.WALK_SPEED * delta / length)
	_place_walker(walker,
		walker.from_flat.lerp(walker.to_flat, walker.progress),
		walker.from_surface.lerp(walker.to_surface, walker.progress))
	moved.emit()
	if walker.progress >= 1.0 and walker.queue.is_empty():
		_rest(walker)


## O Ecobeast vai para o hexágono que o Domador deixou.
func _follow(left: Vector2i) -> void:
	var last: Vector2i = _creature.queue.back() if not _creature.queue.is_empty() else _creature.coord
	if last == left:
		return
	var goals: Dictionary[Vector2i, bool] = {left: true}
	if _map.path_to_any(last, goals).size() == 1:
		_creature.queue.append(left)
	else:
		_creature.queue = _map.path_to_any(_creature.coord, goals)


# --- A câmera ---


## A câmera põe o Domador no foco, sem mostrar além da borda da ilha onde ela é maior
## que a tela; onde é menor, a ilha fica centrada no foco.
func _follow_camera(delta: float, snap: bool) -> void:
	if size.y <= 0.0:
		return
	var focus := _focus if _focus.is_finite() else size / 2.0
	var art_scale := _view.scale.x
	var bounds := _view.map_bounds().grow_side(SIDE_TOP, TOP_ROOM)
	var wanted := _view.surface_center(_tamer.coord) if _tamer.node == null else _tamer.node.position
	var target := Vector2(
		_clamp_axis(wanted.x, bounds.position.x, bounds.end.x, focus.x / art_scale, (size.x - focus.x) / art_scale),
		_clamp_axis(wanted.y, bounds.position.y, bounds.end.y, focus.y / art_scale, (size.y - focus.y) / art_scale))
	if snap or not _camera.is_finite():
		_camera = target
	else:
		_camera = _camera.lerp(target, 1.0 - exp(-CAMERA_SHARPNESS * delta))
	var placed := _view.snapped_to_pixels(focus - _camera * art_scale)
	if placed != _view.position:
		_view.position = placed
		moved.emit()


## `before` e `after` são quanto da tela fica antes e depois do foco, em pixels da arte.
static func _clamp_axis(value: float, low: float, high: float, before: float, after: float) -> float:
	if high - low <= before + after:
		return (low + high) / 2.0
	return clampf(value, low + before, high - after)
