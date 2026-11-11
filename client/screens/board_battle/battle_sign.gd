class_name BattleSign
extends RefCounted

const MAX_ARROWS := 3

var text: String = ""
var color: Color = UiPalette.TEXT
var arrows: int = 0


func _init(sign_text: String, sign_color: Color, sign_arrows: int = 0) -> void:
	text = sign_text
	color = sign_color
	arrows = sign_arrows


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
