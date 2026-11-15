class_name TreeCanopy
extends RefCounted

## A base da copa de uma árvore dos pacotes (vegetation-wind/02): a linha mais baixa com
## pelo menos CANOPY_WIDTH da largura máxima, sem descer no tronco. Dali para cima os
## pixels se mexem no vento.

const SOLID := 0.5
const CANOPY_WIDTH := 0.6
const MIN_TRUNK := 0.12


static func base_of(art: Image) -> int:
	var image := art.duplicate() as Image
	if image.is_compressed():
		image.decompress()
	var height := image.get_height()
	var rows := PackedInt32Array()
	rows.resize(height)
	var top := -1
	var foot := -1
	var widest := 0
	for y: int in height:
		for x: int in image.get_width():
			if image.get_pixel(x, y).a >= SOLID:
				rows[y] += 1
		if rows[y] > 0:
			foot = y
			if top < 0:
				top = y
		widest = maxi(widest, rows[y])
	if top < 0:
		return 0
	var base := top
	for y: int in range(top, maxi(top, foot - roundi(height * MIN_TRUNK)) + 1):
		if rows[y] >= widest * CANOPY_WIDTH:
			base = y
	return base
