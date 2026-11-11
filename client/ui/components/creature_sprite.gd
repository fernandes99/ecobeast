class_name CreatureSprite
extends WanderingSprite

const SHEET_PATH := "res://assets/creatures/%s/explore/%s.png"
const IDLE := "idle"
const WALK := "walk"
const IDLE_SECONDS := 0.8
const WALK_SECONDS := 0.6

static var _frames_by_slug: Dictionary[String, SpriteFrames] = {}


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
