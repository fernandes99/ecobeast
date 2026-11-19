class_name Interior
extends RefCounted

## O lado de dentro de um prédio (interiors/01): uma sala de quadrados de 16 px, com as
## 4 camadas de tiles, os objetos, os quadrados bloqueados, os NPCs e a porta. O corpo é
## o mesmo na leitura e no salvar.

const LAYERS: Array[String] = ["floor", "floor_detail", "wall", "wall_detail"]

var id: int = 0
var name := ""
var width: int = 0
var height: int = 0
var door := Vector2i.ZERO
var tiles: Array[InteriorTile] = []
var objects: Array[InteriorObject] = []
var blocks: Array[Vector2i] = []
var npcs: Array[InteriorNpc] = []


static func from_dict(d: Dictionary) -> Interior:
	var room := Interior.new()
	room.id = DictFields.get_int(d, "id")
	room.name = DictFields.get_string(d, "name")
	room.width = DictFields.get_int(d, "width")
	room.height = DictFields.get_int(d, "height")
	if room.width < 1 or room.height < 1:
		return null
	var door_dict := DictFields.get_dict(d, "door")
	room.door = Vector2i(DictFields.get_int(door_dict, "x"), DictFields.get_int(door_dict, "y"))
	for entry: Variant in DictFields.get_array(d, "tiles"):
		if entry is Dictionary:
			room.tiles.append(InteriorTile.from_dict(entry))
	for entry: Variant in DictFields.get_array(d, "objects"):
		if entry is Dictionary:
			room.objects.append(InteriorObject.from_dict(entry))
	for entry: Variant in DictFields.get_array(d, "blocks"):
		if entry is Dictionary:
			room.blocks.append(Vector2i(DictFields.get_int(entry, "x"), DictFields.get_int(entry, "y")))
	for entry: Variant in DictFields.get_array(d, "npcs"):
		if entry is Dictionary:
			room.npcs.append(InteriorNpc.from_dict(entry))
	return room


func to_dict() -> Dictionary:
	var tile_list: Array = []
	for tile: InteriorTile in tiles:
		tile_list.append(tile.to_dict())
	var object_list: Array = []
	for item: InteriorObject in objects:
		object_list.append(item.to_dict())
	var block_list: Array = []
	for cell: Vector2i in blocks:
		block_list.append({"x": cell.x, "y": cell.y})
	var npc_list: Array = []
	for npc: InteriorNpc in npcs:
		npc_list.append(npc.to_dict())
	return {
		"id": id,
		"name": name,
		"width": width,
		"height": height,
		"door": {"x": door.x, "y": door.y},
		"tiles": tile_list,
		"objects": object_list,
		"blocks": block_list,
		"npcs": npc_list,
	}


func has_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func tile_at(layer: String, cell: Vector2i) -> InteriorTile:
	for tile: InteriorTile in tiles:
		if tile.cell == cell and tile.layer == layer:
			return tile
	return null
