class_name TamerSprite
extends WanderingSprite
## O Domador montado em camadas (tamer-appearance): o corpo é este sprite, com a pele
## trocada pelo shader de paleta, e cada peça vestida é um `TamerLayer` filho.

const BODY_FOLDER := "res://assets/tamer/bodies/%s"
const PART_FOLDER := "res://assets/tamer/parts/%s"
## As folhas das peças no tamanho da criança (village-crowd/02).
const CHILD_PART_FOLDER := "res://assets/tamer/parts/%s/child"
const IDLE := "idle"
const RUN := "run"
const BACK_SUFFIX := "_back"
const SHORT_SUFFIX := "_short"
const HAIR_SLOT := "hair"
const HEADWEAR_SLOT := "headwear"
const NEIGHBOR_ROWS: Dictionary[Vector2i, int] = {
	Vector2i(1, -1): UPPER_ROW,
	Vector2i(1, 0): SIDE_ROW,
	Vector2i(0, 1): LOWER_ROW,
	Vector2i(-1, 1): LOWER_ROW,
	Vector2i(-1, 0): SIDE_ROW,
	Vector2i(0, -1): UPPER_ROW,
}
const LEFT_NEIGHBORS: Array[Vector2i] = [Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(0, -1)]
const IDLE_SECONDS := 0.8
const RUN_SECONDS := 0.36
const PALETTE_SHADER := preload("res://ui/components/palette_swap.gdshader")

## As folhas montadas, por pasta e sufixo; null quando falta uma das duas.
static var _frames: Dictionary[String, SpriteFrames] = {}
static var _materials: Dictionary[int, ShaderMaterial] = {}


func _init() -> void:
	super()
	frame_changed.connect(_sync_layers)
	animation_changed.connect(_sync_layers)
	set_appearance(TamerAppearance.standard())
	play_idle()


func set_appearance(appearance: TamerAppearance) -> void:
	for child: Node in get_children():
		if child is TamerLayer:
			remove_child(child)
			child.queue_free()
	var body := GameData.get_row("body_types", appearance.body_type_id)
	var body_frames := frames_for(BODY_FOLDER % body.get("slug", "male"))
	if body_frames == null:
		body_frames = frames_for(BODY_FOLDER % "male")
	_swap_frames(body_frames)
	material = palette_material(appearance.skin_palette_id)
	var part_folder := CHILD_PART_FOLDER if is_child_body(body) else PART_FOLDER

	var hair_cut := "none"
	for part: Dictionary in appearance.parts:
		if _slot_slug(part) == HEADWEAR_SLOT:
			hair_cut = GameData.get_row("appearance_parts", part["part_id"]).get("hair_cut", "none")
	for part: Dictionary in appearance.parts:
		var row := GameData.get_row("appearance_parts", part["part_id"])
		if row.is_empty():
			continue
		var folder: String = part_folder % row["slug"]
		var front := frames_for(folder)
		if _slot_slug(part) == HAIR_SLOT:
			if hair_cut == "all":
				continue
			if hair_cut == "top" and frames_for(folder, SHORT_SUFFIX) != null:
				front = frames_for(folder, SHORT_SUFFIX)
		if front == null:
			continue
		_add_layer(front, false, part["palette_id"])
		var back := frames_for(folder, BACK_SUFFIX)
		if back != null:
			_add_layer(back, true, part["palette_id"])
	_sync_layers()


static func is_child_body(body: Dictionary) -> bool:
	return body.get("adult_body_type_id") != null


## A peça serve no corpo: é de todos, do próprio corpo ou do adulto da criança.
static func part_fits(part: Dictionary, body_id: int) -> bool:
	var owner: Variant = part.get("body_type_id")
	return owner == null or owner == body_id or owner == GameData.get_row("body_types", body_id).get("adult_body_type_id")


## Vira para uma linha da folha, espelhada ou não; a tela Aparência gira por elas.
func face_row(row: int, mirrored: bool) -> void:
	_row = row
	flip_h = mirrored
	play_idle()


func face(neighbor: Vector2i) -> void:
	_row = NEIGHBOR_ROWS[neighbor]
	flip_h = LEFT_NEIGHBORS.has(neighbor)


func play_idle() -> void:
	play_sheet(IDLE)


func play_run() -> void:
	play_sheet(RUN)


func _play_still() -> void:
	play_idle()


func _play_moving() -> void:
	play_run()


static func frames_for(folder: String, suffix: String = "") -> SpriteFrames:
	var key := folder + suffix
	if _frames.has(key):
		return _frames[key]
	var idle := "%s/%s%s.png" % [folder, IDLE, suffix]
	var run := "%s/%s%s.png" % [folder, RUN, suffix]
	var frames: SpriteFrames = null
	if ResourceLoader.exists(idle) and ResourceLoader.exists(run):
		frames = SpriteFrames.new()
		frames.remove_animation(&"default")
		add_sheet_to(frames, IDLE, load(idle), IDLE_SECONDS)
		add_sheet_to(frames, RUN, load(run), RUN_SECONDS)
	_frames[key] = frames
	return frames


## O material que troca as cores-chave pela paleta; null sem paleta.
static func palette_material(palette_id: int) -> ShaderMaterial:
	if _materials.has(palette_id):
		return _materials[palette_id]
	var row := GameData.get_row("palettes", palette_id)
	if row.is_empty():
		return null
	var colors := PackedColorArray()
	for shade: int in range(1, 5):
		colors.append(Color.html(row["color%d_hex" % shade]))
	var palette := ShaderMaterial.new()
	palette.shader = PALETTE_SHADER
	palette.set_shader_parameter("palette", colors)
	_materials[palette_id] = palette
	return palette


func _swap_frames(frames: SpriteFrames) -> void:
	if frames == sprite_frames:
		return
	var clip := animation
	var at := frame
	var was_playing := is_playing()
	sprite_frames = frames
	if frames.has_animation(clip):
		animation = clip
		frame = at
	if was_playing:
		play()


func _add_layer(frames: SpriteFrames, behind: bool, palette_id: int) -> void:
	var layer := TamerLayer.new(frames, behind)
	layer.material = palette_material(palette_id) if palette_id > 0 else null
	add_child(layer)


func _sync_layers() -> void:
	for child: Node in get_children():
		if child is TamerLayer:
			(child as TamerLayer).sync()


static func _slot_slug(part: Dictionary) -> String:
	var row := GameData.get_row("appearance_parts", part["part_id"])
	return GameData.get_row("appearance_slots", row.get("appearance_slot_id", -1)).get("slug", "")
