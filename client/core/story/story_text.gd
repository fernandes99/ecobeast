class_name StoryText
extends RefCounted

## O texto das falas e das opções (liora-intro/03): `{nome}` vira o nome do Domador e
## `{forma masculina|forma feminina}` vira a forma do corpo dele.

const NAME_TOKEN := "nome"
const MAX_SIDE := 40
const FEMALE_SLUG := "female"


static func render(text: String, player: Player) -> String:
	var female := false
	var tamer_name := ""
	if player != null:
		tamer_name = player.name
		female = str(GameData.get_row("body_types", player.appearance.body_type_id).get("slug", "")) == FEMALE_SLUG
	var out := ""
	var at := 0
	while at < text.length():
		var open := text.find("{", at)
		var close := text.find("}", open + 1) if open >= 0 else -1
		if open < 0 or close < 0:
			out += text.substr(at)
			break
		out += text.substr(at, open - at)
		var inside := text.substr(open + 1, close - open - 1)
		if inside == NAME_TOKEN:
			out += tamer_name
		elif inside.count("|") == 1:
			var sides := inside.split("|")
			out += sides[1] if female else sides[0]
		else:
			out += text.substr(open, close - open + 1)
		at = close + 1
	return out


## O erro do texto, ou "" quando ele está certo.
static func check(text: String) -> String:
	var at := 0
	while at < text.length():
		var open := text.find("{", at)
		var stray := text.find("}", at)
		if stray >= 0 and (open < 0 or stray < open):
			return "um \"}\" sem \"{\"."
		if open < 0:
			return ""
		var close := text.find("}", open + 1)
		if close < 0:
			return "um \"{\" sem \"}\"."
		var inside := text.substr(open + 1, close - open - 1)
		if inside.contains("{"):
			return "chaves dentro de chaves."
		if inside != NAME_TOKEN:
			var error := _check_forms(inside)
			if not error.is_empty():
				return error
		at = close + 1
	return ""


static func _check_forms(inside: String) -> String:
	var bars := inside.count("|")
	if bars == 0:
		return "{%s} não existe: use {nome} ou {forma masculina|forma feminina}." % inside
	if bars > 1:
		return "{%s} tem mais de uma \"|\"." % inside
	for side: String in inside.split("|"):
		if side.strip_edges().is_empty():
			return "{%s} tem um lado vazio." % inside
		if side.length() > MAX_SIDE:
			return "{%s} tem um lado com mais de %d caracteres." % [inside, MAX_SIDE]
	return ""
