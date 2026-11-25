class_name EditorApi
extends RefCounted

const ISLANDS_PATH := "/v1/editor/islands"
const GENERATOR_PATH := "/v1/editor/map-generator"
const SKILLS_PATH := "/v1/editor/skills"
const PROP_TYPES_PATH := "/v1/editor/prop-types"
const NPCS_PATH := "/v1/editor/npcs"
const INTERIORS_PATH := "/v1/editor/interiors"
const QUESTS_PATH := "/v1/editor/quests"
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


static func create_npc(body: Dictionary) -> ApiResponse:
	return await _call(HTTPClient.METHOD_POST, NPCS_PATH, body)


static func update_npc(id: int, body: Dictionary) -> ApiResponse:
	return await _call(HTTPClient.METHOD_PUT, "%s/%d" % [NPCS_PATH, id], body)


static func delete_npc(id: int) -> ApiResponse:
	return await _call(HTTPClient.METHOD_DELETE, "%s/%d" % [NPCS_PATH, id])


static func delete_island(id: int) -> ApiResponse:
	return await _call(HTTPClient.METHOD_DELETE, "%s/%d" % [ISLANDS_PATH, id])


static func list_interiors() -> ApiResponse:
	return await _call(HTTPClient.METHOD_GET, INTERIORS_PATH)


static func read_interior(id: int) -> ApiResponse:
	return await _call(HTTPClient.METHOD_GET, "%s/%d" % [INTERIORS_PATH, id])


static func create_interior(interior_name: String, width: int, height: int) -> ApiResponse:
	return await _call(HTTPClient.METHOD_POST, INTERIORS_PATH, {"name": interior_name, "width": width, "height": height})


static func save_interior(id: int, body: Dictionary) -> ApiResponse:
	return await _call(HTTPClient.METHOD_PUT, "%s/%d" % [INTERIORS_PATH, id], body)


static func delete_interior(id: int) -> ApiResponse:
	return await _call(HTTPClient.METHOD_DELETE, "%s/%d" % [INTERIORS_PATH, id])


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


## As missões da ilha (auralis/07): toda escrita responde a lista inteira.
static func list_quests(island_id: int) -> ApiResponse:
	return await _call(HTTPClient.METHOD_GET, "%s/%d/quests" % [ISLANDS_PATH, island_id])


static func create_quest(island_id: int, body: Dictionary) -> ApiResponse:
	return await _call(HTTPClient.METHOD_POST, "%s/%d/quests" % [ISLANDS_PATH, island_id], body)


static func save_quest(id: int, body: Dictionary) -> ApiResponse:
	return await _call(HTTPClient.METHOD_PUT, "%s/%d" % [QUESTS_PATH, id], body)


static func delete_quest(id: int) -> ApiResponse:
	return await _call(HTTPClient.METHOD_DELETE, "%s/%d" % [QUESTS_PATH, id])


static func move_quest(id: int, up: bool) -> ApiResponse:
	return await _call(HTTPClient.METHOD_POST, "%s/%d/move" % [QUESTS_PATH, id], {"direction": "up" if up else "down"})


## Nulo pede todas as missões que contam.
static func set_required_quests(island_id: int, required: Variant) -> ApiResponse:
	return await _call(HTTPClient.METHOD_PUT, "%s/%d/required-quests" % [ISLANDS_PATH, island_id], {"required_quests": required})


static func _call(method: HTTPClient.Method, path: String, body: Variant = null) -> ApiResponse:
	return await Api.request(method, path, body, true, TIMEOUT_SECONDS)
