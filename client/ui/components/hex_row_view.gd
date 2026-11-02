class_name HexRowView
extends Node2D
## Uma linha de hexágonos do mapa (wild-battle/06). O HexMapView cria uma por
## linha, de trás para a frente, para quem está na frente cobrir quem está atrás.
## Sendo um nó, a linha que está fora da tela não é desenhada.

## Desenhadas nesta ordem: cada malha com a textura de mesmo índice.
var meshes: Array[ArrayMesh] = []
var textures: Array[Texture2D] = []
## O destaque do hexágono atual, por cima das malhas; null nas outras linhas.
var highlight: Texture2D = null
var highlight_position := Vector2.ZERO


func _draw() -> void:
	for index: int in meshes.size():
		draw_mesh(meshes[index], textures[index])
	if highlight != null:
		draw_texture(highlight, highlight_position)
