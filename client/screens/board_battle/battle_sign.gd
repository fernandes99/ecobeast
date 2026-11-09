class_name BattleSign
extends RefCounted
## O sinal que sobe sobre um Ecobeast quando algo muda nele na luta (board-battle/12):
## um stat que sobe ou desce, com setas, ou um estado novo, na cor dele. Um tipo
## novo de sinal entra só em `from_event`.

## Mais níveis que isso numa vez só ainda mostram 3 setas.
const MAX_ARROWS := 3

var text: String = ""
var color: Color = UiPalette.TEXT
## Setas ao lado do texto: positivo para cima, negativo para baixo, 0 sem seta.
var arrows: int = 0


func _init(sign_text: String, sign_color: Color, sign_arrows: int = 0) -> void:
	text = sign_text
	color = sign_color
	arrows = sign_arrows


## O sinal de um evento da luta, ou null quando o evento não tem sinal.
static func from_event(event: Dictionary) -> BattleSign:
	match DictFields.get_string(event, "type"):
		"stat_changed":
			var stages := clampi(DictFields.get_int(event, "stages"), -MAX_ARROWS, MAX_ARROWS)
			if stages == 0:
				return null
			var stat_name := GameData.get_stat_name(DictFields.get_string(event, "stat"))
			return BattleSign.new(stat_name, UiPalette.STAT_UP if stages > 0 else UiPalette.STAT_DOWN, stages)
		"status_applied":
			var slug := DictFields.get_string(event, "status")
			return BattleSign.new(GameData.get_status_name(slug), UiPalette.STATUS_COLORS.get(slug, UiPalette.WARNING))
	return null
