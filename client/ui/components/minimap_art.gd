class_name MinimapArt
extends RefCounted
## A arte do minimapa e do mapa grande, gerada por assets/ui/minimap/make_minimap_art.py
## (.specs/minimap/architecture.md).

const DIR := "res://assets/ui/minimap/"
## Pontos da tela lógica por pixel da arte. A revisar.
const ART_SCALE := 3
const RING_SIZE := 64
const HOLE_SIZE := 48
## As cantoneiras da moldura do mapa grande, em pixels da arte.
const FRAME_MARGIN := 9

static var _cache: Dictionary[String, Texture2D] = {}


static func icon(kind: StringName) -> Texture2D:
	return _load(str(kind))


static func ring() -> Texture2D:
	return _load("ring")


static func mask() -> Texture2D:
	return _load("mask")


static func frame() -> Texture2D:
	return _load("frame")


static func _load(name: String) -> Texture2D:
	if not _cache.has(name):
		var path := DIR + name + ".png"
		_cache[name] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _cache[name]
