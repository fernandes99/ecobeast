class_name TamerAppearance
extends RefCounted

## A aparência do Domador (tamer-appearance): o corpo, a pele e as peças
## vestidas, na ordem de desenho. Uma peça sem cor tem `palette_id` -1.
var body_type_id: int = 1
var skin_palette_id: int = 1
var parts: Array[Dictionary] = []


## A aparência padrão, a mesma que o servidor dá a quem é criado: o corpo 1, a pele 1
## e o rosto 1.
static func standard() -> TamerAppearance:
	var appearance := TamerAppearance.new()
	appearance.parts.append({"part_id": 1, "palette_id": -1})
	return appearance


## A aparência de um NPC pessoa pelo catálogo (liora-intro/02), ou null para um NPC de
## Ecobeast ou que não existe.
static func for_npc(npc_id: int) -> TamerAppearance:
	if npc_id <= 0:
		return null
	var npc := GameData.get_npc(npc_id)
	if npc.get("body_type_id") == null or npc.get("skin_palette_id") == null:
		return null
	var appearance := TamerAppearance.new()
	appearance.body_type_id = int(npc["body_type_id"])
	appearance.skin_palette_id = int(npc["skin_palette_id"])
	var rows: Array[Dictionary] = []
	for row: Dictionary in GameData.get_rows("npc_appearance_parts"):
		if int(row["npc_id"]) == npc_id:
			rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _slot_layer(a) < _slot_layer(b))
	for row: Dictionary in rows:
		var palette: Variant = row["palette_id"]
		appearance.parts.append({"part_id": int(row["appearance_part_id"]), "palette_id": int(palette) if palette != null else -1})
	return appearance


static func _slot_layer(row: Dictionary) -> int:
	return int(GameData.get_row("appearance_slots", int(row["appearance_slot_id"])).get("layer", 0))


func duplicate_appearance() -> TamerAppearance:
	var copy := TamerAppearance.new()
	copy.body_type_id = body_type_id
	copy.skin_palette_id = skin_palette_id
	for part: Dictionary in parts:
		copy.parts.append(part.duplicate())
	return copy


static func from_dict(d: Dictionary) -> TamerAppearance:
	var appearance := TamerAppearance.new()
	appearance.body_type_id = DictFields.get_int(d, "body_type_id", 1)
	appearance.skin_palette_id = DictFields.get_int(d, "skin_palette_id", 1)
	for part: Variant in DictFields.get_array(d, "parts"):
		if part is Dictionary:
			appearance.parts.append({
				"part_id": DictFields.get_id(part, "part_id"),
				"palette_id": DictFields.get_id(part, "palette_id"),
			})
	return appearance


func to_dict() -> Dictionary:
	var worn: Array[Dictionary] = []
	for part: Dictionary in parts:
		var palette_id: Variant = part["palette_id"] if part["palette_id"] > 0 else null
		worn.append({"part_id": part["part_id"], "palette_id": palette_id})
	return {"body_type_id": body_type_id, "skin_palette_id": skin_palette_id, "parts": worn}
