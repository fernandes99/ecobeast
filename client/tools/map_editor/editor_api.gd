class_name EditorApi
extends RefCounted
## As chamadas do editor de ilhas a `/v1/editor` (map-editor/02), pelo `Api`, com a
## sessão de quem está logado no jogo. Só o editor usa; nenhuma tela do jogo.

const ISLANDS_PATH := "/v1/editor/islands"
const GENERATOR_PATH := "/v1/editor/map-generator"
## Criar ou salvar uma ilha de 20.000 hexágonos leva alguns segundos até o
## Supabase, mais que o prazo normal do `Api`.
const TIMEOUT_SECONDS := 60.0
## As respostas do servidor quando o editor está desligado ou não é para esta conta.
const NOT_FOUND := 404
const FORBIDDEN := 403


static func list_islands() -> ApiResponse:
	return await _call(HTTPClient.METHOD_GET, ISLANDS_PATH)


static func read_island(id: int) -> ApiResponse:
	return await _call(HTTPClient.METHOD_GET, "%s/%d" % [ISLANDS_PATH, id])


static func create_island(draft: Dictionary) -> ApiResponse:
	return await _call(HTTPClient.METHOD_POST, ISLANDS_PATH, draft)


static func save_island(id: int, draft: Dictionary) -> ApiResponse:
	return await _call(HTTPClient.METHOD_PUT, "%s/%d/draft" % [ISLANDS_PATH, id], draft)


static func publish_island(id: int) -> ApiResponse:
	return await _call(HTTPClient.METHOD_POST, "%s/%d/publish" % [ISLANDS_PATH, id])


static func delete_island(id: int) -> ApiResponse:
	return await _call(HTTPClient.METHOD_DELETE, "%s/%d" % [ISLANDS_PATH, id])


## `{defaults, ranges}`: os parâmetros do gerador, em snake_case.
static func generator_params() -> ApiResponse:
	return await _call(HTTPClient.METHOD_GET, GENERATOR_PATH)


## `{start, tiles}`, sem gravar nada.
static func generate(map_seed: int, config: Dictionary) -> ApiResponse:
	return await _call(HTTPClient.METHOD_POST, GENERATOR_PATH, {"seed": map_seed, "config": config})


static func _call(method: HTTPClient.Method, path: String, body: Variant = null) -> ApiResponse:
	return await Api.request(method, path, body, true, TIMEOUT_SECONDS)
