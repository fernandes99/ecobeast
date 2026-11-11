@abstract
class_name DataSource
extends RefCounted


@abstract func load_tables(names: PackedStringArray) -> Dictionary


@abstract func get_errors() -> Array[String]
