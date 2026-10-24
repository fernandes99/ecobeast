class_name CreatureTrait
extends RefCounted
## Um Traço (tabela traits). O efeito em batalha é implementado pelo slug.

var id: int
var slug: String
var name: String
var description: String


static func from_row(row: Dictionary) -> CreatureTrait:
	var creature_trait := CreatureTrait.new()
	creature_trait.id = row["id"]
	creature_trait.slug = row["slug"]
	creature_trait.name = row["name"]
	creature_trait.description = row["description"]
	return creature_trait
