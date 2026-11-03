class_name CreatureSprite
extends SheetSprite
## Um Ecobeast no mapa (wild-battle/13 e biome-encounters/04): para um pouco e anda até
## um ponto sorteado do mesmo hexágono. Quem sabe onde ele está é o servidor.

const SHEET_PATH := "res://assets/creatures/%s/%s.png"
const IDLE := "idle"
const WALK := "walk"
## Um ciclo de cada folha, em segundos. A revisar.
const IDLE_SECONDS := 0.8
const WALK_SECONDS := 0.6
## Pixels da arte por segundo. A revisar.
const WALK_SPEED := 18.0
const MIN_PAUSE := 1.0
const MAX_PAUSE := 2.5
## Um passeio mais curto que isso mal mostra o walk.
const MIN_TRIP := 12.0
## Quantos pontos sorteia antes de aceitar um perto demais ou voltar ao centro.
const SPOT_TRIES := 8
## O seno do ângulo em que a direção troca de linha da folha: 67,5° e 22,5°.
const STRAIGHT_SINE := 0.92
const DIAGONAL_SINE := 0.38

## As animações de cada espécie, montadas uma vez: são 50 quadros, e o mapa pode ter
## vários Ecobeasts iguais.
static var _frames_by_slug: Dictionary[String, SpriteFrames] = {}

var _coord := Vector2i.ZERO
## O centro do hexágono, em pixels da arte, na altura dele.
var _center := Vector2.ZERO
## A posição antes de arredondar, para o passo não depender do pixel.
var _exact := Vector2.ZERO
var _target := Vector2.ZERO
var _pause_left := 0.0


## Quem ainda não tem as duas folhas não pode entrar no mapa.
static func has_sheets(slug: String) -> bool:
	return ResourceLoader.exists(SHEET_PATH % [slug, IDLE]) and ResourceLoader.exists(SHEET_PATH % [slug, WALK])


func _init(slug: String) -> void:
	super()
	if not _frames_by_slug.has(slug):
		_add_sheet(IDLE, SHEET_PATH % [slug, IDLE], IDLE_SECONDS)
		_add_sheet(WALK, SHEET_PATH % [slug, WALK], WALK_SECONDS)
		_frames_by_slug[slug] = sprite_frames
	sprite_frames = _frames_by_slug[slug]
	play_idle()
	set_process(false)


func _process(delta: float) -> void:
	if _pause_left > 0.0:
		_pause_left -= delta
		if _pause_left <= 0.0:
			_walk_to(_next_spot())
		return
	_exact = _exact.move_toward(_target, WALK_SPEED * delta)
	position = _exact.round()
	if _exact == _target:
		_rest()


## Começa a passear em um hexágono, a partir de um ponto sorteado.
func wander_in(coord: Vector2i, center: Vector2) -> void:
	_coord = coord
	_center = center
	_exact = random_spot(center)
	position = _exact.round()
	_rest()
	set_process(true)


## Um ponto do hexágono, no mesmo limite das decorações: longe da borda.
func random_spot(center: Vector2) -> Vector2:
	for _index: int in SPOT_TRIES:
		var spot := Vector2(randf_range(-HexDecorations.MAX_X, HexDecorations.MAX_X), randf_range(-HexDecorations.MAX_Y, HexDecorations.MAX_Y))
		if absf(spot.x) / 2.0 + absf(spot.y) <= HexDecorations.MAX_EDGE_DISTANCE:
			return center + spot
	return center


## Vira para uma direção do mapa; vale a partir da próxima animação.
func face_toward(direction: Vector2) -> void:
	var sine := direction.normalized().y
	if sine > STRAIGHT_SINE:
		_row = FRONT_ROW
	elif sine > DIAGONAL_SINE:
		_row = LOWER_ROW
	elif sine > -DIAGONAL_SINE:
		_row = SIDE_ROW
	elif sine > -STRAIGHT_SINE:
		_row = UPPER_ROW
	else:
		_row = BACK_ROW
	flip_h = direction.x < 0.0


func play_idle() -> void:
	play_sheet(IDLE)


func play_walk() -> void:
	play_sheet(WALK)


func _rest() -> void:
	play_idle()
	_pause_left = randf_range(MIN_PAUSE, MAX_PAUSE)


func _walk_to(spot: Vector2) -> void:
	_target = spot
	face_toward(_target - _exact)
	play_walk()


func _next_spot() -> Vector2:
	var spot := random_spot(_center)
	for _index: int in SPOT_TRIES:
		if spot.distance_to(_exact) >= MIN_TRIP:
			break
		spot = random_spot(_center)
	return spot
