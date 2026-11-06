class_name ContentViewer
extends Window
## O visualizador de conteúdo (content-viewer/01): uma janela só de desenvolvimento,
## aberta com F1 quando o jogo roda pelo editor, com os dados do catálogo e os
## arquivos que o jogo usa, em abas.
##
## Um `Window` do Godot é desenhado, por padrão, dentro da janela do jogo. Com
## `force_native`, ele vira uma janela de verdade do Windows, que pode ficar ao lado do
## jogo, que é em retrato. Esconder a janela (em vez de apagá-la) guarda a aba e o item
## escolhidos até o jogo fechar.

const TITLE := "Ecobeast: conteúdo"
const WINDOW_SIZE := Vector2i(1280, 720)
const MIN_SIZE := Vector2i(960, 540)
## A distância entre a janela do jogo e esta, quando ela cabe ao lado.
const GAP := 16
## Tamanhos de texto: a janela é lida no monitor, não no celular.
const FONT_SIZE := 16
const SMALL_SIZE := 13
const HEADING_SIZE := 12
const TITLE_SIZE := 24
const NUMBER_SIZE := 30
const OFFLINE_MESSAGE := "Sem catálogo: o servidor não respondeu."

## As abas, para `show_item`.
const TAB_SUMMARY := &"summary"
const TAB_SPECIES := &"species"
const TAB_SKILLS := &"skills"
const TAB_ELEMENTS := &"elements"
const TAB_BIOMES := &"biomes"
const TAB_ITEMS := &"items"
const TAB_TRAITS := &"traits"
const TAB_TEMPERAMENTS := &"temperaments"
const TAB_STATUSES := &"statuses"
## O que aparece no lugar de um valor vazio.
const EMPTY := "—"

const ElementBadgeScene := preload("res://ui/components/element_badge.tscn")

static var _block_style: StyleBoxFlat = null

var _tabs: TabContainer
var _warning: HBoxContainer
var _warning_label: Label
var _retry_button: Button
var _pages: Dictionary[StringName, Control] = {}


func _init() -> void:
	# O force_native só pode mudar com a janela escondida: quem cria chama show().
	visible = false
	title = TITLE
	size = WINDOW_SIZE
	min_size = MIN_SIZE
	force_native = true
	initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
	close_requested.connect(hide)
	window_input.connect(_on_window_input)
	var project_theme := ThemeDB.get_project_theme()
	theme = project_theme.duplicate() if project_theme != null else Theme.new()
	theme.default_font_size = FONT_SIZE
	_build_frame()


func _ready() -> void:
	position = _place_beside_game()
	rebuild()


## Sem catálogo, o servidor não respondeu na abertura ou o catálogo veio com erro.
static func has_catalog() -> bool:
	return GameData.catalog.table_count() > 0 and GameData.errors.is_empty()


## Monta as abas de novo, a partir do catálogo atual, voltando à aba de antes.
func rebuild() -> void:
	var current := _current_tab()
	for page: Control in _pages.values():
		_tabs.remove_child(page)
		page.queue_free()
	_pages.clear()
	var online := has_catalog()
	_warning.visible = not online
	if not online:
		_warning_label.text = OFFLINE_MESSAGE if GameData.errors.is_empty() else "Sem catálogo: %s" % GameData.errors[0]
	_add_page(TAB_SUMMARY, SummaryTab.new(self))
	if online:
		_add_page(TAB_SPECIES, SpeciesTab.new(self))
		_add_page(TAB_SKILLS, SkillsTab.new(self))
		_add_page(TAB_ELEMENTS, ElementsTab.new(self))
		_add_page(TAB_BIOMES, BiomesTab.new(self))
		_add_page(TAB_ITEMS, ItemsTab.new(self))
		_add_page(TAB_TRAITS, TraitsTab.new(self))
		_add_page(TAB_TEMPERAMENTS, TemperamentsTab.new(self))
		_add_page(TAB_STATUSES, StatusesTab.new(self))
	if _pages.has(current):
		_tabs.current_tab = _pages[current].get_index()


## Troca para a aba e escolhe o item. Os links dos detalhes chamam isto.
func show_item(tab: StringName, id: int) -> void:
	if not _pages.has(tab):
		return
	var page: Control = _pages[tab]
	_tabs.current_tab = page.get_index()
	if page.has_method(&"select"):
		page.call(&"select", id)


## Um nome que leva ao item na aba dele.
func link(label: String, tab: StringName, id: int) -> LinkButton:
	var button := LinkButton.new()
	button.text = label
	button.underline = LinkButton.UNDERLINE_MODE_ON_HOVER
	button.add_theme_color_override(&"font_color", UiPalette.ACCENT)
	button.add_theme_color_override(&"font_hover_color", UiPalette.SKY)
	button.pressed.connect(show_item.bind(tab, id))
	return button


## O selo do Elemento, que leva à aba Elementos.
func element_link(element_id: int) -> ElementBadge:
	var badge := element_badge(element_id)
	badge.mouse_filter = Control.MOUSE_FILTER_STOP
	badge.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	badge.tooltip_text = "Abrir o Elemento"
	badge.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			show_item(TAB_ELEMENTS, element_id))
	return badge


# --- Peças de tela, usadas pelas abas ---------------------------------------------

## O nome de uma linha de tabela de referência, ou "—" sem ela.
static func row_name(table_name: String, id: Variant) -> String:
	if id == null:
		return EMPTY
	var row: Dictionary = GameData.get_row(table_name, int(id))
	return str(row.get("name", EMPTY))


## O valor, ou "—" quando vazio.
static func value_or_dash(value: Variant) -> String:
	return EMPTY if value == null else str(value)


## Um texto; `font_size` 0 é o tamanho da janela.
static func text(value: String, font_size := 0, color := UiPalette.TEXT) -> Label:
	var label := Label.new()
	label.text = value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font_size > 0:
		label.add_theme_font_size_override(&"font_size", font_size)
	if color != UiPalette.TEXT:
		label.add_theme_color_override(&"font_color", color)
	return label


## Um texto que quebra linha na largura de quem o contém.
static func paragraph(value: String, color := UiPalette.TEXT_SECONDARY) -> Label:
	var label := text(value, 0, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


## Um bloco do detalhe: um painel com o título pequeno em maiúsculas. Devolve onde
## pôr o conteúdo.
static func block(parent: Control, heading: String) -> VBoxContainer:
	if _block_style == null:
		_block_style = StyleBoxFlat.new()
		_block_style.bg_color = UiPalette.SURFACE
		_block_style.border_color = UiPalette.BORDER
		_block_style.set_border_width_all(1)
		_block_style.set_corner_radius_all(6)
		_block_style.content_margin_left = 12
		_block_style.content_margin_right = 12
		_block_style.content_margin_top = 8
		_block_style.content_margin_bottom = 10
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", _block_style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 4)
	if not heading.is_empty():
		box.add_child(text(heading.to_upper(), HEADING_SIZE, UiPalette.ACCENT))
	panel.add_child(box)
	parent.add_child(panel)
	return box


## O selo do Elemento, na cor dele.
static func element_badge(element_id: int) -> ElementBadge:
	var badge: ElementBadge = ElementBadgeScene.instantiate()
	badge.set_element(element_id)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return badge


## Uma linha de peças, que quebra quando não cabe.
static func flow(separation := 6) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override(&"h_separation", separation)
	row.add_theme_constant_override(&"v_separation", separation)
	return row


## Verde com tudo pronto, vermelho sem nada e amarelo no meio.
static func status_color(done: int, total: int) -> Color:
	if total > 0 and done >= total:
		return UiPalette.HP_HIGH
	if done <= 0:
		return UiPalette.DANGER
	return UiPalette.WARNING


## Um número com vírgula e sem zeros à toa: 0,5 e 9.
static func decimal(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return String.num(value, 2).replace(".", ",")


# --- Montagem ---------------------------------------------------------------------

func _build_frame() -> void:
	var background := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UiPalette.BACKGROUND
	background.add_theme_stylebox_override(&"panel", style)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	margin.add_child(column)

	_warning = HBoxContainer.new()
	_warning.add_theme_constant_override(&"separation", 12)
	_warning_label = text("", 0, UiPalette.WARNING)
	_warning_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_warning.add_child(_warning_label)
	_retry_button = Button.new()
	_retry_button.text = "Tentar de novo"
	_retry_button.pressed.connect(_retry)
	_warning.add_child(_retry_button)
	column.add_child(_warning)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_tabs)


func _add_page(tab: StringName, page: Control) -> void:
	_pages[tab] = page
	_tabs.add_child(page)
	_tabs.set_tab_title(page.get_index(), page.call(&"tab_title"))


func _current_tab() -> StringName:
	var index := _tabs.current_tab
	for tab: StringName in _pages:
		if _pages[tab].get_index() == index:
			return tab
	return TAB_SUMMARY


func _retry() -> void:
	_retry_button.disabled = true
	_warning_label.text = "Baixando o catálogo…"
	await GameData.load_catalog()
	_retry_button.disabled = false
	rebuild()


## F1 também fecha, com o foco nesta janela: as teclas vêm para ela, e não para o jogo.
func _on_window_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F1:
		set_input_as_handled()
		hide()


## À direita da janela do jogo, se couber na tela; senão, à esquerda; senão, no centro.
func _place_beside_game() -> Vector2i:
	var game := get_tree().root
	var screen := DisplayServer.screen_get_usable_rect(game.current_screen)
	var top := clampi(game.position.y, screen.position.y, maxi(screen.position.y, screen.end.y - size.y))
	var right := game.position.x + game.size.x + GAP
	if right + size.x <= screen.end.x:
		return Vector2i(right, top)
	var left := game.position.x - GAP - size.x
	if left >= screen.position.x:
		return Vector2i(left, top)
	return screen.position + (screen.size - size) / 2
