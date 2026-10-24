class_name StatBlock
extends RefCounted
## Um valor para cada stat (HP, Atq, Def, Atq.E, Def.E, Vel).
## Usado para stats base, Genes, Treino e stats calculados.

const SLUGS: Array[String] = ["hp", "atk", "def", "sp_atk", "sp_def", "spd"]

var hp: int = 0
var atk: int = 0
var def: int = 0
var sp_atk: int = 0
var sp_def: int = 0
var spd: int = 0


func get_value(slug: String) -> int:
	assert(SLUGS.has(slug), "stat desconhecido: %s" % slug)
	return get(slug)


func set_value(slug: String, value: int) -> void:
	assert(SLUGS.has(slug), "stat desconhecido: %s" % slug)
	set(slug, value)


func total() -> int:
	return hp + atk + def + sp_atk + sp_def + spd


func to_dict() -> Dictionary:
	var result: Dictionary = {}
	for slug: String in SLUGS:
		result[slug] = get_value(slug)
	return result


static func from_dict(values: Dictionary) -> StatBlock:
	var block := StatBlock.new()
	for slug: String in SLUGS:
		var value: Variant = values.get(slug)
		block.set_value(slug, int(value) if value != null else 0)
	return block
