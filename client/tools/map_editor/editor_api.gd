class_name EditorApi
extends RefCounted

const ISLANDS_PATH := "/v1/editor/islands"
const GENERATOR_PATH := "/v1/editor/map-generator"
const SKILLS_PATH := "/v1/editor/skills"
const PROP_TYPES_PATH := "/v1/editor/prop-types"
const NPCS_PATH := "/v1/editor/npcs"
const TIMEOUT_SECONDS := 60.0
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


static func set_island_home(id: int, home: bool) -> ApiResponse:
	return await _call(HTTPClient.METHOD_PUT, "%s/%d/home" % [ISLANDS_PATH, id], {"home": home})


static func set_npc_appearance(id: int, appearance: Dictionary) -> ApiResponse:
	return await _call(HTTPClient.METHOD_PUT, "%s/%d/appearance" % [NPCS_PATH, id], appearance)


static func set_npc_voice(id: int, voice_id: int) -> ApiResponse:
	return await _call(HTTPClient.METHOD_PUT, "%s/%d/voice" % [NPCS_PATH, id], {"voice_id": voice_id})


static func delete_island(id: int) -> ApiResponse:
	return await _call(HTTPClient.METHOD_DELETE, "%s/%d" % [ISLANDS_PATH, id])


static func generator_params() -> ApiResponse:
	return await _call(HTTPClient.METHOD_GET, GENERATOR_PATH)


static func generate(map_seed: int, config: Dictionary) -> ApiResponse:
	return await _call(HTTPClient.METHOD_POST, GENERATOR_PATH, {"seed": map_seed, "config": config})


static func create_skill(body: Dictionary) -> ApiResponse:
	return await _call(HTTPClient.METHOD_POST, SKILLS_PATH, body)


static func save_skill(id: int, body: Dictionary) -> ApiResponse:
	return await _call(HTTPClient.METHOD_PUT, "%s/%d" % [SKILLS_PATH, id], body)


## As linhas de bloqueio padrão de uma variante de um tipo de peça, 0 para todas
## (free-objects/02, prop-depth-blocks/02).
static func save_prop_type_blocks(prop_type_id: int, variant: int, blocks: Array) -> ApiResponse:
	return await _call(HTTPClient.METHOD_PUT, "%s/%d/blocks" % [PROP_TYPES_PATH, prop_type_id], {"variant": variant, "blocks": blocks})


static func _call(method: HTTPClient.Method, path: String, body: Variant = null) -> ApiResponse:
	return await Api.request(method, path, body, true, TIMEOUT_SECONDS)
