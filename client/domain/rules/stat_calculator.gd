class_name StatCalculator
extends RefCounted
## Stats de uma criatura a partir da espécie, Genes, Treino, nível e
## Temperamento (fórmulas do GDD; .specs/onboarding/architecture.md, "Regras").

const INCREASED_MULTIPLIER := 1.1
const DECREASED_MULTIPLIER := 0.9


## HP = floor((2·base + genes + floor(treino/4)) · nível / 100) + nível + 10
## Outros = floor((floor((2·base + genes + floor(treino/4)) · nível / 100) + 5) · T),
## com T = 1,1 no stat aumentado, 0,9 no diminuído e 1,0 nos demais.
static func calculate(base: StatBlock, genes: StatBlock, training: StatBlock, level: int,
		temperament: Temperament) -> StatBlock:
	var result := StatBlock.new()
	for slug: String in StatBlock.SLUGS:
		var points := 2 * base.get_value(slug) + genes.get_value(slug) + _floor_div(training.get_value(slug), 4)
		var scaled := _floor_div(points * level, 100)
		if slug == "hp":
			result.set_value(slug, scaled + level + 10)
		else:
			result.set_value(slug, floori((scaled + 5) * _temperament_multiplier(temperament, slug)))
	return result


static func _temperament_multiplier(temperament: Temperament, slug: String) -> float:
	if temperament.is_neutral():
		return 1.0
	if slug == temperament.increased_stat_slug:
		return INCREASED_MULTIPLIER
	if slug == temperament.decreased_stat_slug:
		return DECREASED_MULTIPLIER
	return 1.0


## Divisão inteira arredondada para baixo (sem o aviso de divisão inteira do GDScript).
static func _floor_div(value: int, divisor: int) -> int:
	return floori(float(value) / divisor)
