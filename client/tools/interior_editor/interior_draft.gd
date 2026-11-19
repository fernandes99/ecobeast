class_name InteriorDraft
extends RefCounted

## A sala em edição no modo Interiores do F2 (interiors/03), sobre uma cópia do `Interior`,
## com as regras de pôr, mover e apagar. Sem `Node`, para ser conferida sozinha.

const NPC_NEEDS_FREE := "O NPC precisa de um quadrado livre."
const DOOR_NEEDS_FLOOR := "A porta precisa estar num quadrado de chão, sem bloqueio."
const MIN_SIZE := 4
const MAX_SIZE := 64

var interior: Interior


func _init(source: Interior) -> void:
	interior = Interior.from_dict(source.to_dict())


## O canto do carimbo que cobre `cell` numa pincelada que começou em `stroke_start`.
static func stamp_origin(stroke_start: Vector2i, cell: Vector2i, size: Vector2i) -> Vector2i:
	var offset := cell - stroke_start
	return stroke_start + Vector2i(floori(float(offset.x) / size.x) * size.x, floori(float(offset.y) / size.y) * size.y)


## Põe o retângulo da folha com o canto em `cell`, cortado na borda. Na parede, o tile
## sólido marca o quadrado como bloqueado. Devolve os quadrados mudados.
func paint(layer: String, cell: Vector2i, sheet: String, atlas: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	for dy: int in size.y:
		for dx: int in size.x:
			var at := cell + Vector2i(dx, dy)
			var tile_atlas := atlas + Vector2i(dx, dy)
			if not interior.has_cell(at) or not InteriorTiles.has_tile(sheet, tile_atlas):
				continue
			var old := interior.tile_at(layer, at)
			if old != null and old.sheet == sheet and old.atlas == tile_atlas:
				continue
			if old != null:
				erase(layer, at)
			interior.tiles.append(InteriorTile.make(layer, at, sheet, tile_atlas))
			if layer == "wall" and InteriorTiles.is_solid(sheet, tile_atlas):
				set_block(at, true)
			changed.append(at)
	return changed


## Apaga o tile da camada; apagar uma parede sólida desmarca o quadrado.
func erase(layer: String, cell: Vector2i) -> bool:
	for index: int in interior.tiles.size():
		var tile := interior.tiles[index]
		if tile.layer == layer and tile.cell == cell:
			interior.tiles.remove_at(index)
			if layer == "wall" and InteriorTiles.is_solid(tile.sheet, tile.atlas):
				set_block(cell, false)
			return true
	return false


## Põe o objeto com o canto em `cell` e marca a linha de baixo dele; -1 se passa da borda.
func place_object(cell: Vector2i, sheet: String, atlas: Vector2i, size: Vector2i) -> int:
	if not interior.has_cell(cell) or not interior.has_cell(cell + size - Vector2i.ONE):
		return -1
	var item := InteriorObject.new()
	item.cell = cell
	item.sheet = sheet
	item.atlas = atlas
	item.size = size
	interior.objects.append(item)
	_block_foot(item)
	return interior.objects.size() - 1


## O objeto que cobre o quadrado, o de pé mais baixo; -1 sem nenhum.
func object_at(cell: Vector2i) -> int:
	var best := -1
	for index: int in interior.objects.size():
		var item := interior.objects[index]
		if item.rect().has_point(cell) and (best < 0 or item.foot_y() > interior.objects[best].foot_y()):
			best = index
	return best


## Move o objeto, preso dentro da sala, com os bloqueios da linha de baixo dele.
func move_object(index: int, cell: Vector2i) -> bool:
	var item := interior.objects[index]
	var target := Vector2i(clampi(cell.x, 0, interior.width - item.size.x), clampi(cell.y, 0, interior.height - item.size.y))
	if target == item.cell:
		return false
	_unblock_foot(index)
	item.cell = target
	_block_foot(item)
	return true


func remove_object(index: int) -> void:
	_unblock_foot(index)
	interior.objects.remove_at(index)


func _foot_cells(item: InteriorObject) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x: int in item.size.x:
		cells.append(Vector2i(item.cell.x + x, item.foot_y() - 1))
	return cells


func _block_foot(item: InteriorObject) -> void:
	for cell: Vector2i in _foot_cells(item):
		set_block(cell, true)


## Desmarca a linha de baixo do objeto, menos onde outro objeto ou uma parede sólida
## ainda bloqueia.
func _unblock_foot(index: int) -> void:
	for cell: Vector2i in _foot_cells(interior.objects[index]):
		var kept := false
		for other: int in interior.objects.size():
			if other != index and _foot_cells(interior.objects[other]).has(cell):
				kept = true
		var wall := interior.tile_at("wall", cell)
		if wall != null and InteriorTiles.is_solid(wall.sheet, wall.atlas):
			kept = true
		if not kept:
			set_block(cell, false)


func set_block(cell: Vector2i, on: bool) -> bool:
	if not interior.has_cell(cell) or interior.blocks.has(cell) == on:
		return false
	if on:
		interior.blocks.append(cell)
	else:
		interior.blocks.erase(cell)
	return true


func place_npc(cell: Vector2i, npc_id: int, dialogue: String, action_type_id: int) -> String:
	if not _npc_fits(cell, -1):
		return NPC_NEEDS_FREE
	var npc := InteriorNpc.new()
	npc.npc_id = npc_id
	npc.cell = cell
	npc.dialogue = dialogue
	npc.action_type_id = action_type_id
	interior.npcs.append(npc)
	return ""


func npc_at(cell: Vector2i) -> int:
	for index: int in interior.npcs.size():
		if interior.npcs[index].cell == cell:
			return index
	return -1


func move_npc(index: int, cell: Vector2i) -> String:
	if not _npc_fits(cell, index):
		return NPC_NEEDS_FREE
	interior.npcs[index].cell = cell
	return ""


func update_npc(index: int, npc_id: int, dialogue: String, action_type_id: int) -> void:
	var npc := interior.npcs[index]
	npc.npc_id = npc_id
	npc.dialogue = dialogue
	npc.action_type_id = action_type_id


func remove_npc(index: int) -> void:
	interior.npcs.remove_at(index)


func set_door(cell: Vector2i) -> String:
	if not _is_free_floor(cell) or npc_at(cell) >= 0:
		return DOOR_NEEDS_FLOOR
	interior.door = cell
	return ""


## Corta o que fica de fora; a porta que sobra vai ao quadrado de dentro mais perto.
func resize(width: int, height: int) -> void:
	interior.width = clampi(width, MIN_SIZE, MAX_SIZE)
	interior.height = clampi(height, MIN_SIZE, MAX_SIZE)
	interior.tiles = interior.tiles.filter(func(tile: InteriorTile) -> bool: return interior.has_cell(tile.cell))
	interior.objects = interior.objects.filter(func(item: InteriorObject) -> bool: return interior.has_cell(item.cell) and interior.has_cell(item.rect().end - Vector2i.ONE))
	interior.blocks = interior.blocks.filter(func(cell: Vector2i) -> bool: return interior.has_cell(cell))
	interior.npcs = interior.npcs.filter(func(npc: InteriorNpc) -> bool: return interior.has_cell(npc.cell))
	interior.door = interior.door.clamp(Vector2i.ZERO, Vector2i(interior.width - 1, interior.height - 1))


## A primeira regra que impede o salvar, como o servidor confere: os NPCs e a porta.
func save_error() -> String:
	for index: int in interior.npcs.size():
		if not _npc_fits(interior.npcs[index].cell, index):
			return NPC_NEEDS_FREE
	if not _is_free_floor(interior.door):
		return DOOR_NEEDS_FLOOR
	return ""


func snapshot() -> Dictionary:
	return interior.to_dict()


func restore(data: Dictionary) -> void:
	interior = Interior.from_dict(data)


func _is_free_floor(cell: Vector2i) -> bool:
	return interior.has_cell(cell) and interior.tile_at("floor", cell) != null and not interior.blocks.has(cell)


func _npc_fits(cell: Vector2i, ignore: int) -> bool:
	if not _is_free_floor(cell) or cell == interior.door:
		return false
	for index: int in interior.npcs.size():
		if index != ignore and interior.npcs[index].cell == cell:
			return false
	return true
