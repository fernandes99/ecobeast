class_name DebugTabs
extends VBoxContainer

signal tab_changed(index: int)

const TAB_HEIGHT := 48.0

## As páginas ficam da altura da maior, para o painel não mudar de tamanho ao trocar de aba.
var equal_heights := false
var current := -1
var _bar := HBoxContainer.new()
var _tabs: Array[Button] = []
var _pages: Array[Control] = []


func _init() -> void:
	add_theme_constant_override(&"separation", 12)
	var bar_panel := PanelContainer.new()
	bar_panel.theme_type_variation = &"TabBarPanel"
	bar_panel.add_child(_bar)
	add_child(bar_panel)


## A página devolvida é onde o painel põe os controles da aba.
func add_page(title: String) -> VBoxContainer:
	var tab := Button.new()
	tab.text = title
	tab.focus_mode = Control.FOCUS_NONE
	tab.custom_minimum_size.y = TAB_HEIGHT
	tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var index := _tabs.size()
	tab.pressed.connect(show_page.bind(index))
	_bar.add_child(tab)
	_tabs.append(tab)
	var page := VBoxContainer.new()
	page.add_theme_constant_override(&"separation", 12)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(page)
	_pages.append(page)
	show_page(maxi(current, 0))
	return page


func _ready() -> void:
	if equal_heights:
		_equalize.call_deferred()


func _equalize() -> void:
	var tallest := 0.0
	for page: Control in _pages:
		tallest = maxf(tallest, page.get_combined_minimum_size().y)
	for page: Control in _pages:
		page.custom_minimum_size.y = tallest


func show_page(index: int) -> void:
	if index < 0 or index >= _pages.size():
		return
	var changed := index != current
	current = index
	for i: int in _pages.size():
		_pages[i].visible = i == index
		_tabs[i].theme_type_variation = &"CurrentTabButton" if i == index else &"TabButton"
	if changed:
		tab_changed.emit(index)
