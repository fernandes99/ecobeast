class_name GrowthRate
extends RefCounted
## Uma curva de XP (tabela growth_rates): XP total = floor(xp_multiplier · nível³).

var id: int
var slug: String
var name: String
var xp_multiplier: float


static func from_row(row: Dictionary) -> GrowthRate:
	var growth_rate := GrowthRate.new()
	growth_rate.id = row["id"]
	growth_rate.slug = row["slug"]
	growth_rate.name = row["name"]
	growth_rate.xp_multiplier = row["xp_multiplier"]
	return growth_rate
