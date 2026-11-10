class_name BattleNarrator
extends RefCounted
## Escreve cada evento da batalha em uma linha em pt-BR
## (.specs/battle-screen/architecture.md, "O texto de cada evento"). Só escreve:
## não muda nada. Um evento sem linha, ou desconhecido, devolve texto vazio.

const EMERGENCY_SKILL_NAME := "Golpe de Esforço"
## Marca o lugar do ícone nas linhas de moedas; a tela troca pela imagem.
const COIN_ICON := "{moeda}"
## A partir de quantos estágios a mudança é "muito".
const BIG_STAT_CHANGE := 2
const CANNOT_ACT: Dictionary[String, String] = {
	"fear": "%s ficou com medo e não agiu.",
	"freeze": "%s está congelado.",
	"sleep": "%s está dormindo.",
	"paralysis": "%s está paralisado e não agiu.",
}
## `captured_to` -> texto com o nome do capturado.
const CAPTURED_TO: Dictionary[String, String] = {
	"party": "%s entrou na equipe.",
	"storage": "%s foi para o Santuário.",
}
## Tipo do evento -> texto com o nome de quem o sofre.
const SIMPLE_LINES: Dictionary[String, String] = {
	"woke_up": "%s acordou.",
	"thawed": "%s descongelou.",
	"missed": "%s errou.",
	"blocked": "%s se protegeu.",
	"no_effect": "Não afetou %s.",
	"fainted": "%s desmaiou.",
}

var _names: Dictionary[String, String] = {"player": "", "enemy": ""}
var _team_names: Array[String] = []
var _is_opening := true
## O Domador NPC adversário (npc-tamers/04); vazio contra selvagem.
var _tamer_name := ""


func set_side_name(side: String, display_name: String) -> void:
	_names[side] = display_name


## Contra um Domador NPC, quem entra do lado dele é enviado por ele.
func set_tamer_name(tamer_name: String) -> void:
	_tamer_name = tamer_name


## O nome de cada criatura da equipe, para o item usado em um reserva.
func set_team_names(names: Array[String]) -> void:
	_team_names = names


## Termina a abertura: daqui em diante, quem entra "entra na luta".
func begin_turns() -> void:
	_is_opening = false


func describe(event: Dictionary) -> String:
	var type := DictFields.get_string(event, "type")
	var side := DictFields.get_string(event, "side")
	var who: String = _names.get(side, "")
	if SIMPLE_LINES.has(type):
		return SIMPLE_LINES[type] % who
	match type:
		"creature_entered":
			return _entered(side, who)
		"skill_used":
			return "%s usou %s." % [who, _skill_name(event)]
		"cannot_act":
			var line: String = CANNOT_ACT.get(DictFields.get_string(event, "reason"), "")
			return line % who if not line.is_empty() else ""
		"confused_hit":
			return "%s está confuso e se atingiu: perdeu %d de HP." % [who, DictFields.get_int(event, "damage")]
		"effect_failed":
			return "Não funcionou."
		"damage":
			return _damage(event, who)
		"recoil":
			return "%s sofreu %d de recuo." % [who, DictFields.get_int(event, "damage")]
		"healed":
			return "%s recuperou %d de HP." % [who, DictFields.get_int(event, "amount")]
		"status_applied":
			return "%s ficou %s." % [who, _status_name(event)]
		"status_damage":
			return "%s perdeu %d de HP: %s." % [who, DictFields.get_int(event, "damage"), _status_name(event)]
		"status_ended":
			return "%s não está mais %s." % [who, _status_name(event)]
		"stat_changed":
			return _stat_changed(event, who)
		"flee_failed":
			return "Não conseguiu fugir!"
		"item_used":
			return _item_used(event)
		"xp_gained":
			return _xp_gained(event)
		"coins_gained":
			return "Você recebeu %s %d por derrotar %s." % [COIN_ICON, DictFields.get_int(event, "amount"), _names["enemy"]]
		"coins_lost":
			return "Você perdeu %s %d para %s." % [COIN_ICON, DictFields.get_int(event, "amount"), _names["enemy"]]
		"capture_attempted":
			return _capture_attempted(event)
	return ""


## Para onde foi o capturado; "" sem captura.
func describe_captured_to(captured_to: String) -> String:
	var line: String = CAPTURED_TO.get(captured_to, "")
	return line % _names["enemy"] if not line.is_empty() else ""


func _entered(side: String, who: String) -> String:
	if side == "enemy" and not _tamer_name.is_empty():
		return "%s enviou %s!" % [_tamer_name, who]
	if not _is_opening:
		return "%s entrou na luta." % who
	return "Um %s selvagem apareceu!" % who if side == "enemy" else ""


func _skill_name(event: Dictionary) -> String:
	var skill_id := DictFields.get_id(event, "skill_id")
	return EMERGENCY_SKILL_NAME if skill_id < 0 else GameData.get_skill(skill_id).name


func _damage(event: Dictionary, who: String) -> String:
	var parts := PackedStringArray()
	if DictFields.get_bool(event, "is_critical"):
		parts.append("Crítico!")
	var multiplier: float = event.get("multiplier", 1.0)
	if multiplier > 1.0:
		parts.append("Muito eficaz!")
	elif multiplier < 1.0:
		parts.append("Pouco eficaz.")
	parts.append("%s perdeu %d de HP." % [who, DictFields.get_int(event, "damage")])
	return " ".join(parts)


func _stat_changed(event: Dictionary, who: String) -> String:
	var stages := DictFields.get_int(event, "stages")
	var verb := "subiu" if stages > 0 else "caiu"
	var strength := " muito" if absi(stages) >= BIG_STAT_CHANGE else ""
	return "%s de %s %s%s." % [GameData.get_stat_name(DictFields.get_string(event, "stat")), who, verb, strength]


func _item_used(event: Dictionary) -> String:
	var item_name := GameData.get_item(DictFields.get_id(event, "item_id")).name
	var target: String = _team_names[DictFields.get_int(event, "team_index")]
	var healed := DictFields.get_int(event, "healed")
	if healed > 0:
		return "Você usou %s em %s: +%d de HP." % [item_name, target, healed]
	var status := GameData.get_status_name(DictFields.get_string(event, "cured_status")).to_lower()
	return "Você usou %s em %s: não está mais %s." % [item_name, target, status]


## Quem recebeu é da equipe, e pode não estar em campo.
func _xp_gained(event: Dictionary) -> String:
	var index := DictFields.get_int(event, "team_index")
	if index < 0 or index >= _team_names.size():
		return ""
	return "%s recebeu %d de XP." % [_team_names[index], DictFields.get_int(event, "amount")]


func _capture_attempted(event: Dictionary) -> String:
	var item_name := GameData.get_item(DictFields.get_id(event, "item_id")).name
	var outcome := "foi capturado!" if DictFields.get_bool(event, "success") else "escapou!"
	return "Você usou %s: %s %s" % [item_name, _names["enemy"], outcome]


func _status_name(event: Dictionary) -> String:
	return GameData.get_status_name(DictFields.get_string(event, "status")).to_lower()
