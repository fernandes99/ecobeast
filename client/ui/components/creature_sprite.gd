class_name CreatureSprite
extends WanderingSprite
## Um Ecobeast no mapa (wild-battle/13 e biome-encounters/04): passeia dentro do
## hexágono, com o passeio do `WanderingSprite`. Quem sabe onde ele está é o servidor.

## As folhas do mapa ficam em explore/; as da luta, em battle/ (board-battle/07).
const SHEET_PATH := "res://assets/creatures/%s/explore/%s.png"
const IDLE := "idle"
const WALK := "walk"
## Um ciclo de cada folha, em segundos. A revisar.
const IDLE_SECONDS := 0.8
const WALK_SECONDS := 0.6

## As animações de cada espécie, montadas uma vez: são 50 quadros, e o mapa pode ter
## vários Ecobeasts iguais.
static var _frames_by_slug: Dictionary[String, SpriteFrames] = {}


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


func play_idle() -> void:
	play_sheet(IDLE)


func play_walk() -> void:
	play_sheet(WALK)


func _play_still() -> void:
	play_idle()


func _play_moving() -> void:
	play_walk()
