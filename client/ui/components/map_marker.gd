class_name MapMarker
extends RefCounted
## Um ícone por cima do minimapa e do mapa grande (.specs/minimap/architecture.md): o
## Refúgio, a Loja, um NPC e, no futuro, as missões. Só aparece com `coord` descoberto.

var kind: StringName = &""
var flat := Vector2.ZERO
var coord := Vector2i.ZERO
## O NPC que passeia: o marcador segue o hexágono dele.
var npc: NpcSprite = null


static func make(marker_kind: StringName, at: Vector2i, point: Variant = null) -> MapMarker:
	var marker := MapMarker.new()
	marker.kind = marker_kind
	marker.coord = at
	marker.flat = point if point is Vector2 else HexMapView.flat_center(at)
	return marker


static func following(sprite: NpcSprite) -> MapMarker:
	var marker := make(&"npc", sprite.coord)
	marker.npc = sprite
	return marker


func refresh() -> void:
	if npc != null and is_instance_valid(npc) and npc.coord != coord:
		coord = npc.coord
		flat = HexMapView.flat_center(coord)


static func shown(markers: Array, discovery: MapDiscovery, show_all: bool) -> Array[MapMarker]:
	var out: Array[MapMarker] = []
	for marker: MapMarker in markers:
		marker.refresh()
		if show_all or (discovery != null and discovery.is_discovered(marker.coord)):
			out.append(marker)
	return out
