class_name BattleNarrator
extends RefCounted
## Escreve cada evento da batalha em uma linha em pt-BR
## (.specs/battle-screen/architecture.md, "O texto de cada evento"). Só escreve:
## não muda nada. Um evento sem linha, ou desconhecido, devolve texto vazio.

const EMERGENCY_SKILL_NAME := "Golpe de Esforço"
## A partir de quantos estágios a mudança é "muito".
const BIG_STAT_CHANGE := 2
const CANNOT_ACT: Dictionary[String, String] = {
	"fear": "%s ficou com medo e não agiu.",
	"freeze": "%s está congelado.",
	"sleep": "%s está dormindo.",
	"paralysis": "%s está paralisado e não agiu.",
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
var _is_opening := true


func set_side_name(side: String, display_name: String) -> void:
	_names[side] = display_name


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
	return ""


func _entered(side: String, who: String) -> String:
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


func _status_name(event: Dictionary) -> String:
	return GameData.get_status_name(DictFields.get_string(event, "status")).to_lower()
