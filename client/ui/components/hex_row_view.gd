class_name HexRowView
extends Node2D

## Desenhadas nesta ordem: cada malha com a textura de mesmo índice.
var meshes: Array[ArrayMesh] = []
var textures: Array[Texture2D] = []
## Os hexágonos acima do corte de altura do editor, transparentes (terrain-height/03).
var ghost_meshes: Array[ArrayMesh] = []
var ghost_textures: Array[Texture2D] = []
var ghost_color := Color.WHITE
var highlight: Texture2D = null
var highlight_position := Vector2.ZERO


func _draw() -> void:
	for index: int in meshes.size():
		draw_mesh(meshes[index], textures[index])
	for index: int in ghost_meshes.size():
		draw_mesh(ghost_meshes[index], ghost_textures[index], Transform2D.IDENTITY, ghost_color)
	if highlight != null:
		draw_texture(highlight, highlight_position)
