class_name Counter
extends RefCounted
## Um número do Domador no Perfil, do catálogo `counters` (.specs/player-stats/).

var id: int
var slug: String
var name: String
## `none`, `element`, `day_phase` ou `biome`: o que o recorte de cada linha quer dizer.
var subject: String


static func from_row(row: Dictionary) -> Counter:
	var counter := Counter.new()
	counter.id = row["id"]
	counter.slug = row["slug"]
	counter.name = row["name"]
	counter.subject = row["subject"]
	return counter
