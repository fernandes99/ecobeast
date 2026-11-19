class_name ActionScreens
extends RefCounted

## A tela de cada tipo de ação (`action_types.slug`) e a regra sem equipe, para Explorar
## e para o interior (interiors/02).

const SCREENS: Dictionary[String, StringName] = {
	"refuge": &"heal_station",
	"shop": &"shop",
	"travel": &"travel",
}
## Sem equipe, em Liora (liora-intro/03).
const NO_TEAM_TRAVEL_TEXT := "Você precisa de um Ecobeast para viajar."
const NO_TEAM_HEAL_TEXT := "Você ainda não tem Ecobeasts para cuidar."


static func screen_for(type_id: int) -> StringName:
	if type_id <= 0:
		return &""
	return SCREENS.get(str(GameData.get_row("action_types", type_id).get("slug", "")), &"")


## Abre a tela do tipo por cima da atual e devolve ""; sem equipe, não abre e devolve a
## frase para a barra de mensagem.
static func open(type_id: int) -> String:
	var screen := screen_for(type_id)
	if screen == &"":
		return ""
	var has_team := Session.player != null and Session.player.has_starter()
	if not has_team and (screen == &"travel" or screen == &"heal_station"):
		return NO_TEAM_TRAVEL_TEXT if screen == &"travel" else NO_TEAM_HEAL_TEXT
	Router.push(screen)
	return ""
