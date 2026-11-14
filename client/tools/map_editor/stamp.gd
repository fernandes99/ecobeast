class_name Stamp
extends RefCounted
## Os carimbos do editor (free-props/04): uma parte da ilha guardada num arquivo, com o
## chão, os objetos e as peças soltas, que vira peças comuns ao ser posta. O jogo e o
## servidor nunca veem um carimbo.

const DIR := "res://tools/map_editor/stamps"
const ACCENTS := {"á": "a", "à": "a", "â": "a", "ã": "a", "é": "e", "ê": "e", "í": "i", "ó": "o", "ô": "o", "õ": "o", "ú": "u", "ç": "c"}


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


## O chão dos hexágonos da área que são da ilha, os objetos inteiros dentro dela e as
## peças com o pé nela, a partir do hexágono de apoio.
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
		tiles.append({"dq": coord.x - anchor.x, "dr": coord.y - anchor.y, "ground": (draft.tiles[coord] as HexTile).ground})
	var objects: Array = []
	for object: Variant in draft.objects:
		var occupied := ObjectPanel.coords_of((object as Dictionary).get("tiles", []))
		if occupied.is_empty() or not occupied.all(func(coord: Vector2i) -> bool: return inside.has(coord)):
			continue
		var relative: Array = []
		for at: Variant in object.get("tiles", []):
			relative.append({"dq": int(at["q"]) - anchor.x, "dr": int(at["r"]) - anchor.y, "blocks": bool(at.get("blocks", true))})
		objects.append({
			"object_type_id": int(object["object_type_id"]),
			"dq": int(object["q"]) - anchor.x,
			"dr": int(object["r"]) - anchor.y,
			"variant": int(object.get("variant", 1)),
			"mirrored": bool(object.get("mirrored", false)),
			"tiles": relative,
		})
	var props: Array = []
	for index: int in draft.props.size():
		var coord := draft.prop_coord(index)
		if not inside.has(coord):
			continue
		var prop: Dictionary = draft.props[index]
		props.append({
			"prop_type_id": int(prop["prop_type_id"]),
			"dq": coord.x - anchor.x,
			"dr": coord.y - anchor.y,
			"dx": int(prop["dx"]),
			"dy": int(prop["dy"]),
			"variant": int(prop.get("variant", 1)),
			"mirrored": bool(prop.get("mirrored", false)),
		})
	return {"name": stamp_name, "tiles": tiles, "objects": objects, "props": props}


static func targets(stamp: Dictionary, anchor: Vector2i, flip: bool) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for tile: Variant in stamp.get("tiles", []):
		coords.append(_at(tile, anchor, flip))
	return coords


## Põe o carimbo com o apoio em `anchor`. Nos hexágonos dele que são da ilha, o chão
## dele troca o chão e os objetos que ocupam algum saem; entram os objetos dele que
## cabem inteiros e as peças com o pé na ilha. Devolve os hexágonos que mudaram.
static func place(draft: IslandDraft, stamp: Dictionary, anchor: Vector2i, flip: bool) -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	for tile: Variant in stamp.get("tiles", []):
		var coord := _at(tile, anchor, flip)
		if not draft.tiles.has(coord):
			continue
		(draft.tiles[coord] as HexTile).ground = str((tile as Dictionary).get("ground", ""))
		changed.append(coord)
	for index: int in range(draft.objects.size() - 1, -1, -1):
		if draft.object_tiles(index).any(func(coord: Vector2i) -> bool: return changed.has(coord)):
			draft.objects.remove_at(index)
	for object: Variant in stamp.get("objects", []):
		var tiles: Array = []
		for at: Variant in object.get("tiles", []):
			var coord := _at(at, anchor, flip)
			tiles.append({"q": coord.x, "r": coord.y, "blocks": bool(at.get("blocks", true))})
		if not draft.object_fits(ObjectPanel.coords_of(tiles)):
			continue
		var base := _at(object, anchor, flip)
		draft.objects.append({
			"object_type_id": int(object["object_type_id"]),
			"q": base.x,
			"r": base.y,
			"variant": int(object.get("variant", 1)),
			"mirrored": bool(object.get("mirrored", false)) != flip,
			"tiles": tiles,
		})
	for prop: Variant in stamp.get("props", []):
		var coord := _at(prop, anchor, flip)
		if not draft.tiles.has(coord):
			continue
		var dx := -int(prop["dx"]) if flip else int(prop["dx"])
		# Na divisa, o espelho cairia no vizinho: o hexágono desempata pelo lado.
		if HexMapView.grid_coord(HexMapView.flat_center(coord) + Vector2(dx, int(prop["dy"]))) != coord:
			dx -= signi(dx)
		draft.props.append({
			"prop_type_id": int(prop["prop_type_id"]),
			"q": coord.x,
			"r": coord.y,
			"dx": dx,
			"dy": int(prop["dy"]),
			"variant": int(prop.get("variant", 1)),
			"mirrored": bool(prop.get("mirrored", false)) != flip,
		})
	return changed


static func list(dir := DIR) -> Array[Dictionary]:
	var stamps: Array[Dictionary] = []
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


static func _at(entry: Variant, anchor: Vector2i, flip: bool) -> Vector2i:
	var offset := Vector2i(int((entry as Dictionary).get("dq", 0)), int(entry.get("dr", 0)))
	return anchor + ObjectPanel.mirror(offset, flip)
