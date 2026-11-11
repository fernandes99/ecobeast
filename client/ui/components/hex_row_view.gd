class_name HexRowView
extends Node2D

## Desenhadas nesta ordem: cada malha com a textura de mesmo índice.
var meshes: Array[ArrayMesh] = []
var textures: Array[Texture2D] = []
var highlight: Texture2D = null
var highlight_position := Vector2.ZERO


func _draw() -> void:
	for index: int in meshes.size():
		draw_mesh(meshes[index], textures[index])
	if highlight != null:
		draw_texture(highlight, highlight_position)
