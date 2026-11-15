class_name Stamp
extends RefCounted
## Os carimbos do editor (free-props/04): uma parte da ilha guardada num arquivo, com o
## chão e as peças soltas, que vira peças comuns ao ser posta. O jogo e o servidor nunca
## veem um carimbo.

const DIR := "res://tools/map_editor/stamps"
const ACCENTS := {"á": "a", "à": "a", "â": "a", "ã": "a", "é": "e", "ê": "e", "í": "i", "ó": "o", "ô": "o", "õ": "o", "ú": "u", "ç": "c"}
## Os objetos de grade de um carimbo antigo viram peças (free-objects/04): o tipo de peça
## de cada tipo de objeto e o formato de quem não guardou os hexágonos.
const OBJECT_PROP_TYPES: Dictionary[int, int] = {21: 22, 22: 23, 24: 24, 25: 25, 26: 26, 41: 27}
const OBJECT_FOOTPRINTS: Dictionary[int, Array] = {
	24: [Vector2i(0, 0)],
	25: [Vector2i(0, 0), Vector2i(1, 0)],
}
const DEFAULT_FOOTPRINT: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1)]
const CENTER_TO_BOTTOM := 29.0


## O hexágono de apoio: o da área mais perto do meio dela.
static func anchor_of(coords: Array[Vector2i]) -> Vector2i:
	var middle := Vector2.ZERO
	for coord: Vector2i in coords:
		middle += HexMapView.flat_center(coord)
	middle /= maxi(1, coords.size())
	var best := coords[0] if not coords.is_empty() else Vector2i.ZERO
	for coord: Vector2i in coords:
		if HexMapView.flat_center(coord).distance_to(middle) < HexMapView.flat_center(best).distance_to(middle):
			best = coord
	return best


## O chão dos hexágonos da área que são da ilha e as peças com o pé nela, a partir do
## hexágono de apoio.
static func capture(draft: IslandDraft, area: Array[Vector2i], stamp_name: String) -> Dictionary:
	var inside: Dictionary[Vector2i, bool] = {}
	for coord: Vector2i in area:
		if draft.tiles.has(coord):
			inside[coord] = true
	var coords: Array[Vector2i] = []
	coords.assign(inside.keys())
	var anchor := anchor_of(coords)
	var tiles: Array = []
	for coord: Vector2i in coords:
		var tile: HexTile = draft.tiles[coord]
		tiles.append({"dq": coord.x - anchor.x, "dr": coord.y - anchor.y, "ground": tile.ground, "bare": tile.bare})
	var props: Array = []
	for index: int in draft.props.size():
		var coord := draft.prop_coord(index)
		if not inside.has(coord):
			continue
		var prop: Dictionary = draft.props[index]
		var entry := {
			"prop_type_id": int(prop["prop_type_id"]),
			"dq": coord.x - anchor.x,
			"dr": coord.y - anchor.y,
			"dx": int(prop["dx"]),
			"dy": int(prop["dy"]),
			"variant": int(prop.get("variant", 1)),
			"mirrored": bool(prop.get("mirrored", false)),
		}
		_copy_extras(prop, entry)
		props.append(entry)
	return {"name": stamp_name, "tiles": tiles, "props": props}


static func targets(stamp: Dictionary, anchor: Vector2i, flip: bool) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for tile: Variant in stamp.get("tiles", []):
		coords.append(_at(tile, anchor, flip))
	return coords


## Põe o carimbo com o apoio em `anchor`. Nos hexágonos dele que são da ilha, o chão
## dele troca o chão; entram as peças com o pé na ilha. Devolve os hexágonos que mudaram.
## `allowed`, se dado, diz quais hexágonos da ilha valem; os outros ficam como estão,
## como se não fossem da ilha (o corte de altura, terrain-height/03).
static func place(draft: IslandDraft, stamp: Dictionary, anchor: Vector2i, flip: bool, allowed := Callable()) -> Array[Vector2i]:
	var inside := func(coord: Vector2i) -> bool: return draft.tiles.has(coord) and (not allowed.is_valid() or allowed.call(coord))
	var changed: Array[Vector2i] = []
	for tile: Variant in stamp.get("tiles", []):
		var coord := _at(tile, anchor, flip)
		if not inside.call(coord):
			continue
		(draft.tiles[coord] as HexTile).ground = str((tile as Dictionary).get("ground", ""))
		# Os carimbos sem a marca foram montados numa ilha sem decorações (free-props/05).
		(draft.tiles[coord] as HexTile).bare = bool((tile as Dictionary).get("bare", true))
		changed.append(coord)
	for prop: Variant in _props_of(stamp):
		var coord := _at(prop, anchor, flip)
		if not inside.call(coord):
			continue
		var dx := -int(prop["dx"]) if flip else int(prop["dx"])
		# Na divisa, o espelho cairia no vizinho: o hexágono desempata pelo lado.
		if HexMapView.grid_coord(HexMapView.flat_center(coord) + Vector2(dx, int(prop["dy"]))) != coord:
			dx -= signi(dx)
		var placed := {
			"prop_type_id": int(prop["prop_type_id"]),
			"q": coord.x,
			"r": coord.y,
			"dx": dx,
			"dy": int(prop["dy"]),
			"variant": int(prop.get("variant", 1)),
			"mirrored": bool(prop.get("mirrored", false)) != flip,
		}
		_copy_extras(prop, placed)
		draft.props.append(placed)
	return changed


## As peças do carimbo, com os objetos de um carimbo antigo convertidos.
static func _props_of(stamp: Dictionary) -> Array:
	var props: Array = (stamp.get("props", []) as Array).duplicate()
	for object: Variant in stamp.get("objects", []):
		if object is Dictionary and OBJECT_PROP_TYPES.has(int(object.get("object_type_id", 0))):
			props.append(_object_as_prop(object))
	return props


## O pé da peça é o do objeto: o meio dos centros dos hexágonos dele, na borda de baixo
## do mais baixo.
static func _object_as_prop(object: Dictionary) -> Dictionary:
	var type_id := int(object["object_type_id"])
	var mirrored := bool(object.get("mirrored", false))
	var coords: Array[Vector2i] = []
	for at: Variant in object.get("tiles", []):
		if at is Dictionary:
			coords.append(Vector2i(int(at.get("dq", 0)), int(at.get("dr", 0))))
	if coords.is_empty():
		var base := Vector2i(int(object.get("dq", 0)), int(object.get("dr", 0)))
		for offset: Vector2i in OBJECT_FOOTPRINTS.get(type_id, DEFAULT_FOOTPRINT):
			coords.append(base + mirror(offset, mirrored))
	var x := 0.0
	var bottom := -INF
	for coord: Vector2i in coords:
		var center := HexMapView.flat_center(coord)
		x += center.x
		bottom = maxf(bottom, center.y + CENTER_TO_BOTTOM)
	var foot := Vector2(x / coords.size(), bottom)
	var hex := HexMapView.grid_coord(foot)
	var offset := Vector2i((foot - HexMapView.flat_center(hex)).round())
	return {
		"prop_type_id": OBJECT_PROP_TYPES[type_id],
		"dq": hex.x,
		"dr": hex.y,
		"dx": offset.x,
		"dy": offset.y,
		"variant": int(object.get("variant", 1)),
		"mirrored": mirrored,
	}


## O bloqueio ajustado (free-objects): as linhas ficam sem o espelho, que a peça leva.
static func _copy_extras(from: Dictionary, to: Dictionary) -> void:
	if from.get("block") is Array:
		to["block"] = (from["block"] as Array).duplicate(true)
	if int(from.get("action_type_id", 0)) > 0:
		to["action_type_id"] = int(from["action_type_id"])


static func list(dir := DIR) -> Array[Dictionary]:
	var stamps: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(dir):
		return stamps
	var files := DirAccess.get_files_at(dir)
	files.sort()
	for file: String in files:
		if not file.ends_with(".json"):
			continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(file)))
		if data is Dictionary and (data as Dictionary).has("tiles"):
			stamps.append(data)
	return stamps


static func save(stamp: Dictionary, dir := DIR) -> Error:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var file := FileAccess.open(dir.path_join(slug_of(str(stamp.get("name", ""))) + ".json"), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(stamp, "\t") + "\n")
	return OK


static func slug_of(stamp_name: String) -> String:
	var slug := ""
	for character: String in stamp_name.to_lower():
		character = ACCENTS.get(character, character)
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9"):
			slug += character
		elif not slug.ends_with("_"):
			slug += "_"
	return slug.strip_edges().trim_prefix("_").trim_suffix("_")


## Espelhar na vertical, em coordenadas axiais: (dq, dr) vira (-dq - dr, dr).
static func mirror(offset: Vector2i, flip: bool) -> Vector2i:
	return Vector2i(-offset.x - offset.y, offset.y) if flip else offset


static func _at(entry: Variant, anchor: Vector2i, flip: bool) -> Vector2i:
	var offset := Vector2i(int((entry as Dictionary).get("dq", 0)), int(entry.get("dr", 0)))
	return anchor + mirror(offset, flip)
