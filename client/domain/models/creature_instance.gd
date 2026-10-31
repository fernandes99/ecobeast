class_name CreatureInstance
extends RefCounted
## Um Ecobeast de um Domador (.specs/onboarding/architecture.md, "Modelos").
## Guarda só ids do catálogo; from_dict lê o JSON da API.

var uid: String
var species_id: int
## "" = sem apelido.
var nickname: String = ""
var level: int = 1
## XP total acumulado.
var current_xp: int = 0
## XP total para chegar ao nível atual.
var level_xp: int = 0
## XP total para chegar ao próximo nível; -1 no nível máximo.
var next_level_xp: int = -1
var current_hp: int = 0
## Calculado pelo servidor a cada resposta.
var stats := StatBlock.new()
var genes := StatBlock.new()
## A soma dos 6 Genes, calculada pelo servidor.
var genes_total: int = 0
## A raridade dessa soma, decidida pelo servidor.
var genes_rank_slug: String = ""
var genes_rank_name: String = ""
var training_points := StatBlock.new()
var temperament_id: int
var trait_id: int
## "male", "female" ou "none".
var gender: String = "none"
var is_prismatic: bool = false
var bond: int = 0
var skills: Array[SkillSlot] = []
## -1 = nenhum.
var status_condition_id: int = -1
## -1 = nenhum.
var held_item_id: int = -1
var original_player_id: String
## ISO 8601 em UTC.
var caught_at: String
## -1 = sem zona (o inicial não tem zona).
var caught_zone_id: int = -1


## O apelido, ou o nome da espécie quando não há apelido.
func display_name(species: CreatureSpecies) -> String:
	return nickname if not nickname.is_empty() else species.name


static func from_dict(d: Dictionary) -> CreatureInstance:
	var creature := CreatureInstance.new()
	creature.uid = DictFields.get_string(d, "uid")
	creature.species_id = DictFields.get_int(d, "species_id")
	creature.nickname = DictFields.get_string(d, "nickname")
	creature.level = DictFields.get_int(d, "level", 1)
	creature.current_xp = DictFields.get_int(d, "current_xp")
	creature.level_xp = DictFields.get_int(d, "level_xp")
	creature.next_level_xp = DictFields.get_id(d, "next_level_xp")
	creature.current_hp = DictFields.get_int(d, "current_hp")
	creature.stats = StatBlock.from_dict(DictFields.get_dict(d, "stats"))
	creature.genes = StatBlock.from_dict(DictFields.get_dict(d, "genes"))
	creature.genes_total = DictFields.get_int(d, "genes_total")
	var genes_rank := DictFields.get_dict(d, "genes_rank")
	creature.genes_rank_slug = DictFields.get_string(genes_rank, "slug")
	creature.genes_rank_name = DictFields.get_string(genes_rank, "name")
	creature.training_points = StatBlock.from_dict(DictFields.get_dict(d, "training_points"))
	creature.temperament_id = DictFields.get_int(d, "temperament_id")
	creature.trait_id = DictFields.get_int(d, "trait_id")
	creature.gender = DictFields.get_string(d, "gender", "none")
	creature.is_prismatic = DictFields.get_bool(d, "is_prismatic")
	creature.bond = DictFields.get_int(d, "bond")
	for skill_dict: Variant in DictFields.get_array(d, "skills"):
		if skill_dict is Dictionary:
			creature.skills.append(SkillSlot.from_dict(skill_dict))
	creature.status_condition_id = DictFields.get_id(d, "status_condition_id")
	creature.held_item_id = DictFields.get_id(d, "held_item_id")
	creature.original_player_id = DictFields.get_string(d, "original_player_id")
	creature.caught_at = DictFields.get_string(d, "caught_at")
	creature.caught_zone_id = DictFields.get_id(d, "caught_zone_id")
	return creature
