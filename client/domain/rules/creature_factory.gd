class_name CreatureFactory
extends RefCounted
## Cria uma criatura nova (.specs/onboarding/architecture.md, "Regras").
## Recebe tudo por parâmetro; com a mesma semente no rng, o resultado é o mesmo.

const MAX_GENE := 31
const MAX_SKILLS := 4
const START_BOND := 70


## params:
##   species: CreatureSpecies, level: int, uid: String, owner_id: String,
##   now: String (ISO 8601 UTC), learnset: Array[LearnsetEntry],
##   max_pp_by_skill: Dictionary (id da técnica -> PP máximo),
##   trait_ids: Array[int] (traços normais da espécie),
##   temperaments: Array[Temperament], xp_multiplier: float,
##   rng: RandomNumberGenerator
static func create(params: Dictionary) -> CreatureInstance:
	var species: CreatureSpecies = params["species"]
	var level: int = params["level"]
	var rng: RandomNumberGenerator = params["rng"]
	var trait_ids: Array[int] = params["trait_ids"]
	var temperaments: Array[Temperament] = params["temperaments"]

	var creature := CreatureInstance.new()
	creature.uid = params["uid"]
	creature.species_id = species.id
	creature.level = level

	for slug: String in StatBlock.SLUGS:
		creature.genes.set_value(slug, rng.randi_range(0, MAX_GENE))
	var temperament := temperaments[rng.randi_range(0, temperaments.size() - 1)]
	creature.temperament_id = temperament.id
	creature.trait_id = trait_ids[rng.randi_range(0, trait_ids.size() - 1)]
	creature.gender = _pick_gender(species.gender_ratio, rng)
	creature.skills = _starting_skills(params["learnset"], params["max_pp_by_skill"], level)

	creature.current_xp = XpCurve.total_xp_for_level(params["xp_multiplier"], level)
	creature.stats = StatCalculator.calculate(species.base_stats, creature.genes, creature.training_points,
			level, temperament)
	creature.current_hp = creature.stats.hp

	creature.is_prismatic = false
	creature.bond = START_BOND
	creature.original_player_id = params["owner_id"]
	creature.caught_at = params["now"]
	return creature


## "none" se a espécie não tem gênero (proporção < 0); senão "male" com a
## chance da proporção.
static func _pick_gender(gender_ratio: float, rng: RandomNumberGenerator) -> String:
	if gender_ratio < 0.0:
		return "none"
	return "male" if rng.randf() < gender_ratio else "female"


## As 4 últimas técnicas aprendidas por nível até o nível atual, com PP cheio.
## O learnset já vem ordenado por nível (empate: ordem do arquivo).
static func _starting_skills(learnset: Array[LearnsetEntry], max_pp_by_skill: Dictionary, level: int) -> Array[SkillSlot]:
	var learned: Array[SkillSlot] = []
	for entry: LearnsetEntry in learnset:
		if entry.method_slug == "level_up" and entry.level <= level:
			learned.append(SkillSlot.create(entry.skill_id, max_pp_by_skill[entry.skill_id]))
	return learned.slice(maxi(0, learned.size() - MAX_SKILLS))
