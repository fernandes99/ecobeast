class_name CreatureInstance
extends RefCounted
## Um Ecobeast de um Domador (.specs/onboarding/architecture.md, "Modelos").
## Guarda só ids do catálogo; to_dict/from_dict é o formato do save e da API.

var uid: String
var species_id: int
## "" = sem apelido.
var nickname: String = ""
var level: int = 1
## XP total acumulado.
var current_xp: int = 0
var current_hp: int = 0
## Calculado pelo serviço (no futuro, pelo servidor); não entra no save.
var stats := StatBlock.new()
var genes := StatBlock.new()
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


## Formato do save: tudo menos stats, que é recalculado ao carregar.
func to_dict() -> Dictionary:
	var skill_dicts: Array[Dictionary] = []
	for slot: SkillSlot in skills:
		skill_dicts.append(slot.to_dict())
	return {
		"uid": uid,
		"species_id": species_id,
		"nickname": nickname,
		"level": level,
		"current_xp": current_xp,
		"current_hp": current_hp,
		"genes": genes.to_dict(),
		"training_points": training_points.to_dict(),
		"temperament_id": temperament_id,
		"trait_id": trait_id,
		"gender": gender,
		"is_prismatic": is_prismatic,
		"bond": bond,
		"skills": skill_dicts,
		"status_condition_id": DictFields.id_or_null(status_condition_id),
		"held_item_id": DictFields.id_or_null(held_item_id),
		"original_player_id": original_player_id,
		"caught_at": caught_at,
		"caught_zone_id": DictFields.id_or_null(caught_zone_id),
	}


## Lê também "stats", quando vier (a API manda pronto).
static func from_dict(d: Dictionary) -> CreatureInstance:
	var creature := CreatureInstance.new()
	creature.uid = DictFields.get_string(d, "uid")
	creature.species_id = DictFields.get_int(d, "species_id")
	creature.nickname = DictFields.get_string(d, "nickname")
	creature.level = DictFields.get_int(d, "level", 1)
	creature.current_xp = DictFields.get_int(d, "current_xp")
	creature.current_hp = DictFields.get_int(d, "current_hp")
	creature.stats = StatBlock.from_dict(DictFields.get_dict(d, "stats"))
	creature.genes = StatBlock.from_dict(DictFields.get_dict(d, "genes"))
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
