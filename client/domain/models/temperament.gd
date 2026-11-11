class_name Temperament
extends RefCounted

var id: int
var slug: String
var name: String
var increased_stat_id: int
var decreased_stat_id: int
var increased_stat_slug: String
var decreased_stat_slug: String


func is_neutral() -> bool:
	return increased_stat_id == decreased_stat_id


static func from_row(row: Dictionary) -> Temperament:
	var temperament := Temperament.new()
	temperament.id = row["id"]
	temperament.slug = row["slug"]
	temperament.name = row["name"]
	temperament.increased_stat_id = row["increased_stat_id"]
	temperament.decreased_stat_id = row["decreased_stat_id"]
	return temperament
