class_name BoardSpot
extends RefCounted
## Um lugar no tabuleiro: o lado e a vaga (.specs/board-battle/architecture.md).

## "player" ou "enemy".
var side: String = ""
var position: int = 0


static func create(spot_side: String, spot_position: int) -> BoardSpot:
	var spot := BoardSpot.new()
	spot.side = spot_side
	spot.position = spot_position
	return spot


static func from_dict(d: Dictionary) -> BoardSpot:
	return create(DictFields.get_string(d, "side"), DictFields.get_int(d, "position"))


## Uma chave única por lugar, para dicionários: "player:0".
func key() -> String:
	return "%s:%d" % [side, position]


func is_player() -> bool:
	return side == "player"
