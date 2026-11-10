class_name Codex
extends RefCounted
## O Bestiário do jogador (codex/02): as espécies que ele já viu numa luta e as
## que capturou, como o servidor mandou. Espécie fora daqui nunca foi vista.

enum Status { UNKNOWN, SEEN, CAUGHT }

## species_id -> capturado.
var _caught: Dictionary[int, bool] = {}


## `entries` de GET /v1/me/codex. Uma entrada sem `species_id` válido fica de fora.
static func from_dict(d: Dictionary) -> Codex:
	var codex := Codex.new()
	for entry: Variant in DictFields.get_array(d, "entries"):
		if not entry is Dictionary:
			continue
		var species_id := DictFields.get_int(entry, "species_id")
		if species_id <= 0:
			continue
		codex._caught[species_id] = DictFields.get_bool(entry, "caught")
	return codex


func status(species_id: int) -> Status:
	if not _caught.has(species_id):
		return Status.UNKNOWN
	return Status.CAUGHT if _caught[species_id] else Status.SEEN


## Vistos, contando os capturados.
func seen_count() -> int:
	return _caught.size()


func caught_count() -> int:
	return _caught.values().count(true)
