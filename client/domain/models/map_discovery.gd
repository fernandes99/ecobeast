class_name MapDiscovery
extends RefCounted
## Os hexágonos que o Domador já descobriu no mapa de Explorar (.specs/fog-of-war/).

## A revisar.
const REVEAL_RADIUS := 4

var _found: Dictionary[Vector2i, bool] = {}


func is_discovered(coord: Vector2i) -> bool:
	return _found.has(coord)


func add(coords: Array[Vector2i]) -> void:
	for coord: Vector2i in coords:
		_found[coord] = true


func all() -> Array[Vector2i]:
	return _found.keys()


func clear() -> void:
	_found.clear()


## Descobre os hexágonos do mapa a até `radius` de `center` e devolve só os novos.
func reveal_around(map: ExplorationMap, center: Vector2i, radius: int = REVEAL_RADIUS) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for dq: int in range(-radius, radius + 1):
		for dr: int in range(maxi(-radius, -dq - radius), mini(radius, -dq + radius) + 1):
			var coord := center + Vector2i(dq, dr)
			if map.has(coord) and not _found.has(coord):
				_found[coord] = true
				found.append(coord)
	return found
