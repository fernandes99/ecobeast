class_name CreatureSpecies
extends RefCounted
## Uma espécie de Ecobeast (tabela species), com elementos e stats já juntados.

var id: int
var slug: String
var name: String
var description: String
var growth_rate_id: int
var rarity_id: int
var base_xp_yield: int
var capture_rate: int
## Fração de machos (0–1); -1 = sem gênero.
var gender_ratio: float
var height_m: float
var weight_kg: float
## -1 na forma base.
var evolves_from_species_id: int = -1
## Ids dos elementos, na ordem dos slots (1 ou 2 itens).
var element_ids: Array[int] = []
var base_stats := StatBlock.new()
var training_yield := StatBlock.new()


static func from_row(row: Dictionary) -> CreatureSpecies:
	var species := CreatureSpecies.new()
	species.id = row["id"]
	species.slug = row["slug"]
	species.name = row["name"]
	species.description = row["description"]
	species.growth_rate_id = row["growth_rate_id"]
	species.rarity_id = row["rarity_id"]
	species.base_xp_yield = row["base_xp_yield"]
	species.capture_rate = row["capture_rate"]
	species.gender_ratio = row["gender_ratio"]
	species.height_m = row["height_m"]
	species.weight_kg = row["weight_kg"]
	var evolves_from: Variant = row["evolves_from_species_id"]
	species.evolves_from_species_id = evolves_from if evolves_from != null else -1
	return species
