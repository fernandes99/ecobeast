class_name XpCurve
extends RefCounted
## XP total para chegar a um nível (.specs/onboarding/architecture.md, "Regras").


## floor(multiplicador · nível³). Médio (1,0) no nível 5 = 125.
static func total_xp_for_level(xp_multiplier: float, level: int) -> int:
	return floori(xp_multiplier * level * level * level)
