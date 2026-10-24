extends SceneTree
## Valida o catálogo (res://data/*.json) pela linha de comando:
##   godot --headless --path . --script res://tools/validate_data.gd
## Sai com 0 quando está íntegro e 1 quando há erros.
## Não usa autoloads (o modo --script não os carrega).


func _initialize() -> void:
	var catalog := Catalog.new()
	var errors := catalog.load_from(StaticJsonDataSource.new())
	for error: String in errors:
		printerr(error)
	if errors.is_empty():
		print("Catálogo OK: %d tabelas, %d linhas" % [catalog.table_count(), catalog.row_count()])
		quit(0)
	else:
		print("%d erros" % errors.size())
		quit(1)
