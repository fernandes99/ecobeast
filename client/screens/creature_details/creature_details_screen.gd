extends Control
## Detalhes de um Ecobeast (creature-details/02, TELAS.md #8): topo fixo com o
## retrato, a identidade, o HP e o XP, e três abas sem rolagem. Parâmetro:
## {"uid": String}. Tudo vem do Session e do GameData; a tela só faz a conta da
## barra de XP com os números que o servidor mandou.

const ElementBadgeScene := preload("res://ui/components/element_badge.tscn")
const SkillRowScene := preload("res://screens/creature_details/skill_row.tscn")

const SKILL_SLOTS := 4
const GLOW_ALPHA := 0.55
const NO_ITEM := "Nenhum"
const MAX_LEVEL_TEXT := "Nível máximo"
const GENDERS: Dictionary[String, String] = {"male": "Macho", "female": "Fêmea", "none": "Sem gênero"}

var _uid: String = ""

@onready var _glow: TextureRect = %Glow
@onready var _portrait: CreaturePortrait = %Portrait
@onready var _back_button: Button = %BackButton
@onready var _name_label: Label = %NameLabel
@onready var _rename_button: Button = %RenameButton
@onready var _level_label: Label = %LevelLabel
@onready var _badges: HBoxContainer = %Badges
@onready var _species_label: Label = %SpeciesLabel
@onready var _hp_bar: HpBar = %HpBar
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _xp_label: Label = %XpLabel
@onready var _tabs: Array[Button] = [%ResumoTab, %AtributosTab, %TecnicasTab]
@onready var _pages: Array[Control] = [%ResumoPage, %AtributosPage, %TecnicasPage]
@onready var _description_label: Label = %DescriptionLabel
@onready var _temperament_label: Label = %TemperamentLabel
@onready var _trait_name_label: Label = %TraitNameLabel
@onready var _trait_description_label: Label = %TraitDescriptionLabel
@onready var _item_label: Label = %ItemLabel
@onready var _gender_label: Label = %GenderLabel
@onready var _radar: StatRadar = %Radar
@onready var _temperament_note: Label = %TemperamentNote
@onready var _skill_rows: VBoxContainer = %SkillRows
@onready var _nickname_panel: NicknamePanel = %NicknamePanel


func setup(params: Dictionary) -> void:
	_uid = params.get("uid", "")


func _ready() -> void:
	_back_button.pressed.connect(Router.back)
	_rename_button.pressed.connect(_open_nickname_panel)
	_nickname_panel.save_pressed.connect(_save_nickname)
	for index: int in _tabs.size():
		_tabs[index].pressed.connect(_show_page.bind(index))
	for index: int in SKILL_SLOTS:
		_skill_rows.add_child(SkillRowScene.instantiate())
	_show_page(0)
	Session.player_changed.connect(_refresh)
	_refresh()


## Chamado pelo Router no voltar do Android ou Esc: fecha o painel, se aberto.
func handle_back() -> bool:
	if _nickname_panel.visible:
		_nickname_panel.close()
		return true
	return false


func _show_page(current: int) -> void:
	for index: int in _pages.size():
		_pages[index].visible = index == current
		_tabs[index].theme_type_variation = &"" if index == current else &"OutlineButton"


## A criatura desta tela no jogador atual, ou null.
func _creature() -> CreatureInstance:
	if Session.player == null:
		return null
	for creature: CreatureInstance in Session.player.party:
		if creature.uid == _uid:
			return creature
	return null


func _refresh() -> void:
	var creature := _creature()
	# Sem criatura só enquanto o Router troca de tela (a sessão caiu, por exemplo).
	if creature == null:
		return
	var species := GameData.get_species(creature.species_id)
	_show_identity(creature, species)
	_show_xp(creature)
	_show_summary(creature, species)
	_show_attributes(creature)
	_show_skills(creature)


func _show_identity(creature: CreatureInstance, species: CreatureSpecies) -> void:
	_glow.texture = _glow_gradient(GameData.get_element(species.element_ids[0]).color)
	_portrait.set_species(species.id)
	_name_label.text = creature.display_name(species)
	_level_label.text = "Nv. %d" % creature.level
	_species_label.text = species.name
	_species_label.visible = not creature.nickname.is_empty()
	for badge: Node in _badges.get_children():
		_badges.remove_child(badge)
		badge.queue_free()
	for element_id: int in species.element_ids:
		var badge: ElementBadge = ElementBadgeScene.instantiate()
		badge.set_element(element_id)
		_badges.add_child(badge)
	_hp_bar.set_hp(creature.current_hp, creature.stats.hp)


## Brilho radial atrás do retrato, na cor do Elemento, sumindo nas bordas.
func _glow_gradient(color: Color) -> GradientTexture2D:
	var clear := color
	clear.a = 0.0
	var center := color
	center.a = GLOW_ALPHA
	var gradient := Gradient.new()
	gradient.set_color(0, center)
	gradient.set_color(1, clear)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func _show_xp(creature: CreatureInstance) -> void:
	if creature.next_level_xp < 0:
		_xp_bar.value = 1.0
		_xp_label.text = MAX_LEVEL_TEXT
		return
	var span := creature.next_level_xp - creature.level_xp
	_xp_bar.value = float(creature.current_xp - creature.level_xp) / span
	_xp_label.text = "faltam %d XP" % (creature.next_level_xp - creature.current_xp)


func _show_summary(creature: CreatureInstance, species: CreatureSpecies) -> void:
	var creature_trait := GameData.get_trait(creature.trait_id)
	_description_label.text = species.description
	_temperament_label.text = GameData.get_temperament(creature.temperament_id).name
	_trait_name_label.text = creature_trait.name
	_trait_description_label.text = creature_trait.description
	_item_label.text = NO_ITEM
	_gender_label.text = GENDERS[creature.gender]


func _show_attributes(creature: CreatureInstance) -> void:
	var temperament := GameData.get_temperament(creature.temperament_id)
	if temperament.is_neutral():
		_radar.set_stats(creature.stats, "", "")
		_temperament_note.text = "%s: sem efeito nos stats" % temperament.name
		return
	_radar.set_stats(creature.stats, temperament.increased_stat_slug, temperament.decreased_stat_slug)
	_temperament_note.text = "%s: +10%% em %s, −10%% em %s" % [
		temperament.name,
		GameData.get_row("stats", temperament.increased_stat_id)["short_name"],
		GameData.get_row("stats", temperament.decreased_stat_id)["short_name"],
	]


func _show_skills(creature: CreatureInstance) -> void:
	for index: int in SKILL_SLOTS:
		var row := _skill_rows.get_child(index) as SkillRow
		if index < creature.skills.size():
			row.set_skill(creature.skills[index])
		else:
			row.set_empty()


func _open_nickname_panel() -> void:
	var creature := _creature()
	if creature != null:
		_nickname_panel.open(creature.nickname)


func _save_nickname(nickname: String) -> void:
	_nickname_panel.set_busy(true)
	var result: Result = await Session.set_nickname(_uid, nickname)
	_nickname_panel.set_busy(false)
	if result.ok:
		_nickname_panel.close()
	else:
		_nickname_panel.show_error(result.error)
