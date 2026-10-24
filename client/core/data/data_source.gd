@abstract
class_name DataSource
extends RefCounted
## De onde vêm as tabelas do catálogo. Hoje: StaticJsonDataSource (res://data/).
## No futuro: uma fonte que baixa as mesmas tabelas da API.


## Devolve um Dictionary de nome da tabela para Array de linhas (Dictionary).
## Tabelas que não puderam ser lidas vêm vazias, com o motivo em get_errors().
@abstract func load_tables(names: PackedStringArray) -> Dictionary


## Erros da última chamada a load_tables, um por linha.
@abstract func get_errors() -> Array[String]
