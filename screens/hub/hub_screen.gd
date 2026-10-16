extends Control
## Hub (hub/01, TELAS.md #3): o Domador, a equipe, as ações e a barra
## inferior. Toda feature abre a tela de DESTINATIONS com Router.push; ligar
## uma feature nova é trocar o id dela ali.

const CreatureSlotScene := preload("res://ui/components/creature_slot.tscn")
const ProfileDebugPanelScene := preload("res://screens/hub/profile_debug_panel.tscn")

const PARTY_SIZE := 6
const ACTION_HEIGHT := 88
const TAB_HEIGHT := 72
const CURRENT_TAB := "Home"

const ACTIONS: Array[String] = [
	"Explorar zona", "Desafiar Domador", "Arenas", "Loja",
	"Refúgio", "Santuário", "Bestiário", "Mochila",
]
const TABS: Array[String] = ["Home", "Equipe", "Bestiário", "Loja", "Perfil"]

## Rótulo da ação ou aba -> tela que ele abre. Rótulo fora daqui (Home) não
## abre nada; a ação e a aba com o mesmo rótulo abrem a mesma tela.
const DESTINATIONS: Dictionary[String, Dictionary] = {
	"Explorar zona": {"id": &"placeholder", "params": {"title": "Explorar zona"}},
	"Desafiar Domador": {"id": &"placeholder", "params": {"title": "Desafiar Domador"}},
	"Arenas": {"id": &"placeholder", "params": {"title": "Arenas"}},
	"Loja": {"id": &"placeholder", "params": {"title": "Loja"}},
	"Refúgio": {"id": &"placeholder", "params": {"title": "Refúgio"}},
	"Santuário": {"id": &"placeholder", "params": {"title": "Santuário"}},
	"Bestiário": {"id": &"placeholder", "params": {"title": "Bestiário"}},
	"Mochila": {"id": &"placeholder", "params": {"title": "Mochila"}},
	"Equipe": {"id": &"placeholder", "params": {"title": "Equipe"}},
	"Perfil": {"id": &"placeholder", "params": {"title": "Perfil", "extra": ProfileDebugPanelScene}},
}

@onready var _avatar_initial: Label = %AvatarInitial
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _coins_label: Label = %CoinsLabel
@onready var _party_grid: GridContainer = %PartyGrid
@onready var _actions_grid: GridContainer = %ActionsGrid
@onready var _tabs: HBoxContainer = %Tabs


func _ready() -> void:
	for index: int in PARTY_SIZE:
		var slot: CreatureSlot = CreatureSlotScene.instantiate()
		slot.pressed.connect(_open_details.bind(index))
		_party_grid.add_child(slot)
	for label: String in ACTIONS:
		var button := _make_button(label, &"ActionButton", ACTION_HEIGHT)
		# Deixa o arraste chegar ao ScrollContainer, para rolar por cima dos botões.
		button.mouse_filter = MOUSE_FILTER_PASS
		_actions_grid.add_child(button)
	for label: String in TABS:
		var variation := &"CurrentTabButton" if label == CURRENT_TAB else &"TabButton"
		_tabs.add_child(_make_button(label, variation, TAB_HEIGHT))
	Session.player_changed.connect(_refresh)
	_refresh()


func _make_button(label: String, variation: StringName, height: int) -> Button:
	var button := Button.new()
	button.text = label
	button.theme_type_variation = variation
	button.custom_minimum_size.y = height
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.pressed.connect(_open.bind(label))
	return button


func _refresh() -> void:
	var player := Session.player
	# Sem jogador só depois de "Apagar progresso", quando o Router já está
	# trocando para a tela de entrada.
	if player == null:
		return
	_avatar_initial.text = player.name.left(1).to_upper()
	_name_label.text = player.name
	_level_label.text = "Domador · Nível %d" % player.level
	_coins_label.text = _format_thousands(player.coins)
	for index: int in PARTY_SIZE:
		var slot := _party_grid.get_child(index) as CreatureSlot
		if index < player.party.size():
			slot.set_creature(player.party[index])
		else:
			slot.set_empty()


func _open(label: String) -> void:
	if not DESTINATIONS.has(label):
		return
	var destination := DESTINATIONS[label]
	Router.push(destination["id"], destination["params"])


func _open_details(index: int) -> void:
	var party := Session.player.party
	if index >= party.size():
		return
	var creature := party[index]
	var species := GameData.get_species(creature.species_id)
	Router.push(&"placeholder", {"title": "Detalhes de %s" % creature.display_name(species)})


## 1000 -> "1.000".
static func _format_thousands(value: int) -> String:
	var digits := str(absi(value))
	var groups := PackedStringArray()
	while digits.length() > 3:
		groups.insert(0, digits.right(3))
		digits = digits.left(-3)
	groups.insert(0, digits)
	return ("-" if value < 0 else "") + ".".join(groups)
