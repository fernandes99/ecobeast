class_name InteriorTiles
extends RefCounted

## As folhas das salas (interiors/02): as 3 do pacote Main Characters Home e a do
## Refúgio, montada com as peças do Fantasy Dreamland Reborn (interiors/04); o `TileSet`
## montado por código, uma fonte de atlas por folha (o id é o índice em SHEETS), e a regra
## do bloqueio (.specs/interiors/architecture.md).

const SHEETS: Array[String] = ["walls_floor", "interior", "doors_windows", "refuge"]
const SHEET_PATHS: Dictionary[String, String] = {
	"walls_floor": "res://assets/interiors/main_home/walls_floor.png",
	"interior": "res://assets/interiors/main_home/interior.png",
	"doors_windows": "res://assets/interiors/main_home/doors_windows.png",
	"refuge": "res://assets/interiors/fdr/refuge.png",
}
const CELL := 16
const SOLID_PIXELS := 128
## O `TileMapLayer` ordena pelo meio do quadrado; +8 ordena pela borda de baixo.
const Y_SORT_ORIGIN := 8

static var _tile_set: TileSet = null
static var _solid: Dictionary[String, Dictionary] = {}


static func tile_set() -> TileSet:
	if _tile_set != null:
		return _tile_set
	_tile_set = TileSet.new()
	_tile_set.tile_size = Vector2i(CELL, CELL)
	for index: int in SHEETS.size():
		var source := TileSetAtlasSource.new()
		source.texture = sheet_texture(SHEETS[index])
		source.texture_region_size = Vector2i(CELL, CELL)
		var cells := sheet_cells(SHEETS[index])
		for row: int in cells.y:
			for col: int in cells.x:
				var coords := Vector2i(col, row)
				source.create_tile(coords)
				source.get_tile_data(coords, 0).y_sort_origin = Y_SORT_ORIGIN
		_tile_set.add_source(source, index)
	return _tile_set


static func source_id(sheet: String) -> int:
	return SHEETS.find(sheet)


static func sheet_texture(sheet: String) -> Texture2D:
	if not SHEETS.has(sheet):
		return null
	return load(SHEET_PATHS[sheet]) as Texture2D


## O tamanho da folha em tiles.
static func sheet_cells(sheet: String) -> Vector2i:
	var texture := sheet_texture(sheet)
	if texture == null:
		return Vector2i.ZERO
	return Vector2i(texture.get_size()) / CELL


static func has_tile(sheet: String, atlas: Vector2i) -> bool:
	var cells := sheet_cells(sheet)
	return atlas.x >= 0 and atlas.y >= 0 and atlas.x < cells.x and atlas.y < cells.y


## Se o tile tem pelo menos SOLID_PIXELS pixels com alfa: a parede de verdade, e não o
## contorno fino que a camada de parede também guarda.
static func is_solid(sheet: String, atlas: Vector2i) -> bool:
	if not has_tile(sheet, atlas):
		return false
	if not _solid.has(sheet):
		_solid[sheet] = _solid_tiles(sheet)
	return _solid[sheet].has(atlas)


static func _solid_tiles(sheet: String) -> Dictionary:
	var solid: Dictionary = {}
	var image := sheet_texture(sheet).get_image()
	if image.is_compressed():
		image.decompress()
	var cells := sheet_cells(sheet)
	for row: int in cells.y:
		for col: int in cells.x:
			var count := 0
			for y: int in CELL:
				for x: int in CELL:
					if image.get_pixel(col * CELL + x, row * CELL + y).a > 0.0:
						count += 1
			if count >= SOLID_PIXELS:
				solid[Vector2i(col, row)] = true
	return solid


## Os quadrados que bloqueiam o andar sem contar os NPCs: sem chão ou em `blocks`.
static func blocked(interior: Interior) -> Dictionary[Vector2i, bool]:
	var floor_cells: Dictionary[Vector2i, bool] = {}
	for tile: InteriorTile in interior.tiles:
		if tile.layer == "floor":
			floor_cells[tile.cell] = true
	var result: Dictionary[Vector2i, bool] = {}
	for y: int in interior.height:
		for x: int in interior.width:
			if not floor_cells.has(Vector2i(x, y)):
				result[Vector2i(x, y)] = true
	for cell: Vector2i in interior.blocks:
		result[cell] = true
	return result


static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell * CELL) + Vector2(CELL, CELL) / 2.0


static func cell_of(point: Vector2) -> Vector2i:
	return Vector2i((point / CELL).floor())
