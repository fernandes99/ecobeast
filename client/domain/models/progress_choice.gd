class_name ProgressChoice
extends RefCounted
## A resposta de uma escolha depois da vitória: evoluir ou não, ou a Técnica
## pendente (.specs/progression/architecture.md, "Contrato").

## O Ecobeast como ficou, com a espécie e as Técnicas já gravadas.
var creature: CreatureInstance = null
## Na evolução, as Técnicas aprendidas com vaga; vazio na escolha de Técnica.
var learned_skill_ids: Array[int] = []
## As Técnicas que ainda esperam a escolha do jogador.
var pending_skill_ids: Array[int] = []
## Na evolução, a espécie nova, se ela entrou capturada no Bestiário agora (codex/03).
var registered_species_ids: Array[int] = []


## null se a resposta não tiver `creature`.
static func from_dict(d: Dictionary) -> ProgressChoice:
	var row := DictFields.get_dict(d, "creature")
	if row.is_empty():
		return null
	var choice := ProgressChoice.new()
	choice.creature = CreatureInstance.from_dict(row)
	choice.learned_skill_ids = _ids(DictFields.get_array(d, "learned_skill_ids"))
	choice.pending_skill_ids = _ids(DictFields.get_array(d, "pending_skill_ids"))
	choice.registered_species_ids = _ids(DictFields.get_array(d, "registered_species_ids"))
	return choice


static func _ids(values: Array) -> Array[int]:
	var ids: Array[int] = []
	for value: Variant in values:
		if value is int or value is float:
			ids.append(int(value))
	return ids
