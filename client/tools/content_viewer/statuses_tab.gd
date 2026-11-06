class_name StatusesTab
extends ListDetail
## A aba Estados (content-viewer/03, RF-07): os Estados pelo `id` e, depois deles, as
## marcas no chão. O detalhe do Estado diz se ele dura só na luta, quem é imune, quem
## o causa e quem o tira; o da marca, o dano, o Estado que causa e quem a deixa.

## As marcas ficam na mesma lista dos Estados: o id da linha é este mais o da marca.
const GROUND_OFFSET := 1000
const SWATCH := Vector2(18, 18)


func _init(content_viewer: ContentViewer) -> void:
	super(content_viewer)
	var rows: Array[ListDetail.Row] = []
	for status: Dictionary in GameData.get_rows("status_conditions"):
		var row := ListDetail.Row.new(status["id"], status["name"])
		row.tail = "só na luta" if status.get("is_volatile", false) else "dura"
		rows.append(row)
	for ground: Dictionary in GameData.get_rows("ground_effects"):
		var row := ListDetail.Row.new(GROUND_OFFSET + int(ground["id"]), ground["name"])
		row.dot = Color(str(ground.get("color_hex", "#FFFFFF")))
		row.tail = "marca"
		rows.append(row)
	set_rows(rows)


func tab_title() -> String:
	return "Estados (%d)" % GameData.get_rows("status_conditions").size()


## O id da linha de uma marca no chão, para os links.
static func ground_row_id(ground_id: int) -> int:
	return GROUND_OFFSET + ground_id


func _build_detail(id: int, box: VBoxContainer) -> void:
	if id >= GROUND_OFFSET:
		_ground(id - GROUND_OFFSET, box)
	else:
		_status(id, box)


func _status(id: int, box: VBoxContainer) -> void:
	var status: Dictionary = GameData.get_row("status_conditions", id)
	if status.is_empty():
		return
	var volatile: bool = status.get("is_volatile", false)
	box.add_child(ContentViewer.text(status["name"], ContentViewer.TITLE_SIZE))
	box.add_child(ContentViewer.text("só na luta" if volatile else "continua depois da luta", 0, UiPalette.TEXT_SECONDARY))

	var immune := ContentViewer.flow(6)
	for row: Dictionary in GameData.get_rows("status_condition_immunities"):
		if row["status_condition_id"] == id:
			immune.add_child(viewer.element_link(row["element_id"]))
	_fill(ContentViewer.block(box, "Elementos imunes"), immune)

	# Uma Técnica pode ter mais de um efeito com o mesmo Estado: aparece uma vez.
	var causes := ContentViewer.flow(14)
	var seen: Dictionary = {}
	for effect: Dictionary in GameData.get_rows("skill_effects"):
		if effect.get("status_condition_id") != id or seen.has(effect["skill_id"]):
			continue
		seen[effect["skill_id"]] = true
		var skill: Dictionary = GameData.get_row("skills", effect["skill_id"])
		if skill.is_empty():
			continue
		var cell := HBoxContainer.new()
		cell.add_child(viewer.link(skill["name"], ContentViewer.TAB_SKILLS, skill["id"]))
		if effect.get("chance") != null:
			cell.add_child(ContentViewer.text("%d%%" % int(effect["chance"]), 0, UiPalette.TEXT_SECONDARY))
		causes.add_child(cell)
	_fill(ContentViewer.block(box, "Técnicas que causam"), causes)

	var grounds := ContentViewer.flow(14)
	for ground: Dictionary in GameData.get_rows("ground_effects"):
		if ground.get("status_condition_id") == id:
			grounds.add_child(viewer.link(ground["name"], ContentViewer.TAB_STATUSES, ground_row_id(ground["id"])))
	_fill(ContentViewer.block(box, "Marcas no chão que causam"), grounds)

	# `cures_status` tira os Estados que duram depois da luta (o Bálsamo Puro tira
	# Queimado, Envenenado, Paralisado, Adormecido e Congelado); os da luta passam sozinhos.
	var cures := ContentViewer.flow(14)
	if not volatile:
		for item: Dictionary in GameData.get_rows("items"):
			if item.get("cures_status", false):
				cures.add_child(viewer.link(item["name"], ContentViewer.TAB_ITEMS, item["id"]))
	_fill(ContentViewer.block(box, "Itens que tiram"), cures)


func _ground(ground_id: int, box: VBoxContainer) -> void:
	var ground: Dictionary = GameData.get_row("ground_effects", ground_id)
	if ground.is_empty():
		return
	var title := ContentViewer.flow(10)
	var swatch := ColorRect.new()
	swatch.color = Color(str(ground.get("color_hex", "#FFFFFF")))
	swatch.custom_minimum_size = SWATCH
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.add_child(swatch)
	title.add_child(ContentViewer.text(ground["name"], ContentViewer.TITLE_SIZE))
	box.add_child(title)
	box.add_child(ContentViewer.text("Marca no chão · %s%% de dano por turno" % ContentViewer.value_or_dash(ground.get("damage_percent")), 0, UiPalette.TEXT_SECONDARY))

	var causes := ContentViewer.flow(6)
	if ground.get("status_condition_id") != null:
		var status_id := int(ground["status_condition_id"])
		causes.add_child(viewer.link(ContentViewer.row_name("status_conditions", status_id), ContentViewer.TAB_STATUSES, status_id))
	_fill(ContentViewer.block(box, "Estado que causa"), causes)

	var skills := ContentViewer.flow(14)
	for skill: Dictionary in GameData.get_rows("skills"):
		if skill.get("ground_effect_id") == ground_id:
			var cell := HBoxContainer.new()
			cell.add_child(viewer.link(skill["name"], ContentViewer.TAB_SKILLS, skill["id"]))
			cell.add_child(ContentViewer.text("%s turnos" % ContentViewer.value_or_dash(skill.get("ground_turns")), 0, UiPalette.TEXT_SECONDARY))
			skills.add_child(cell)
	_fill(ContentViewer.block(box, "Técnicas que deixam"), skills)


## Um grupo de links, ou "—" quando vazio.
func _fill(box: VBoxContainer, content: Control) -> void:
	if content.get_child_count() == 0:
		content.queue_free()
		box.add_child(ContentViewer.text(ContentViewer.EMPTY))
	else:
		box.add_child(content)
