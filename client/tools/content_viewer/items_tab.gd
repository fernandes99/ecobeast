class_name ItemsTab
extends ListDetail
## A aba Itens (content-viewer/03, RF-04): a lista na ordem da Loja (`sort_order`),
## com o ícone e a categoria, e o detalhe com o preço e o que o item faz. Os dados
## saem das linhas do catálogo, que dizem quais campos estão vazios.

const ICON_BOX := Vector2(128, 128)


func _init(content_viewer: ContentViewer) -> void:
	super(content_viewer)
	var rows: Array[ListDetail.Row] = []
	for item: Dictionary in _items():
		var row := ListDetail.Row.new(item["id"], item["name"])
		var icon := ContentFiles.item_icon(item["slug"])
		if icon.exists():
			row.icon = load(icon.path)
		else:
			row.dot = UiPalette.DANGER
		row.tail = ContentViewer.row_name("item_categories", item.get("item_category_id"))
		rows.append(row)
	set_rows(rows)


func tab_title() -> String:
	return "Itens (%d)" % GameData.get_rows("items").size()


func _items() -> Array[Dictionary]:
	var items := GameData.get_rows("items")
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0)))
	return items


func _build_detail(id: int, box: VBoxContainer) -> void:
	var item: Dictionary = GameData.get_row("items", id)
	if item.is_empty():
		return
	var header := HBoxContainer.new()
	header.add_theme_constant_override(&"separation", 14)
	box.add_child(header)
	header.add_child(FilePreview.create(ContentFiles.item_icon(item["slug"]), ICON_BOX))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override(&"separation", 6)
	header.add_child(info)
	info.add_child(ContentViewer.text(item["name"], ContentViewer.TITLE_SIZE))
	info.add_child(ContentViewer.text("%s · %s moedas" % [ContentViewer.row_name("item_categories", item.get("item_category_id")), ContentViewer.value_or_dash(item.get("price"))], 0, UiPalette.TEXT_SECONDARY))
	info.add_child(ContentViewer.paragraph(str(item.get("description", ""))))

	var does := ContentViewer.block(box, "O que faz")
	var effects := effect_lines(item)
	if effects.is_empty():
		does.add_child(ContentViewer.text(ContentViewer.EMPTY))
	for line: String in effects:
		does.add_child(ContentViewer.text(line))


## O que o item faz, uma frase por campo preenchido.
static func effect_lines(item: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if item.get("capture_bonus") != null:
		lines.append("Bônus de captura ×%s" % ContentViewer.decimal(float(item["capture_bonus"])))
	if item.get("heal_amount") != null:
		lines.append("Cura %d de HP" % int(item["heal_amount"]))
	if item.get("cures_status", false):
		lines.append("Tira um Estado que dura depois da luta")
	return lines
