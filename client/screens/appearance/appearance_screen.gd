extends Control
## A tela Aparência (tamer-appearance/03): o corpo, a pele e cada peça com a sua cor,
## numa prévia que gira. Na entrada sem ilha casa (liora-intro/03), pede também o nome e
## segue para a escolha do inicial; pelo Hub, volta para ele. No modo NPC (liora-intro/02),
## aberta pelo F2 numa janela, veste um NPC pessoa e avisa pelo `closed`. As opções são
## do `TamerEditor`.

## Só no modo NPC: a janela fecha, com `saved` verdadeiro depois de salvar.
signal closed(saved: bool)

const PREVIEW_SCALE := 8.0
const PREVIEW_FOOT_GAP := 24.0
## As linhas da folha, na ordem do giro, e se cada uma é espelhada.
const TURNS: Array[Array] = [
	[SheetSprite.FRONT_ROW, false],
	[SheetSprite.LOWER_ROW, false],
	[SheetSprite.SIDE_ROW, false],
	[SheetSprite.UPPER_ROW, false],
	[SheetSprite.BACK_ROW, false],
	[SheetSprite.UPPER_ROW, true],
	[SheetSprite.SIDE_ROW, true],
	[SheetSprite.LOWER_ROW, true],
]
const SAVE_TEXT := "Salvar"
const SAVING_TEXT := "Salvando..."

var _onboarding: bool = false
var _npc_id: int = 0
var _saving: bool = false
var _turn: int = 0

@onready var _preview_area: Control = %PreviewArea
@onready var _preview: TamerSprite = %Preview
@onready var _turn_button: Button = %TurnButton
@onready var _editor: TamerEditor = %Editor
@onready var _message: Label = %Message
@onready var _save_button: Button = %SaveButton
@onready var _back_button: Button = %BackButton
@onready var _title: Label = $SafeArea/Column/Title


func setup(params: Dictionary) -> void:
	_onboarding = params.get("onboarding", false)
	_npc_id = int(params.get("npc_id", 0))


func _ready() -> void:
	var appearance := TamerAppearance.standard()
	var ask_name := false
	if _npc_id > 0:
		var look := TamerAppearance.for_npc(_npc_id)
		if look != null:
			appearance = look
		_title.text = "Aparência de %s" % GameData.get_npc(_npc_id).get("name", "")
	elif Session.player != null:
		appearance = Session.player.appearance
		ask_name = _onboarding and not Session.player.has_name()
	_preview.scale = Vector2.ONE * PREVIEW_SCALE
	_preview_area.resized.connect(_place_preview)
	_turn_button.pressed.connect(_turn_preview)
	_save_button.pressed.connect(_save)
	_back_button.pressed.connect(_leave)
	_back_button.visible = not _onboarding
	_editor.changed.connect(_preview.set_appearance)
	_editor.name_changed.connect(_update_save)
	_editor.open(appearance, ask_name)
	_update_save()
	_place_preview()


func handle_back() -> bool:
	return _saving or _onboarding


func _leave() -> void:
	if _npc_id > 0:
		closed.emit(false)
	else:
		Router.back()


func _place_preview() -> void:
	_preview.position = Vector2(_preview_area.size.x / 2.0, _preview_area.size.y - PREVIEW_FOOT_GAP).round()


func _turn_preview() -> void:
	_turn = (_turn + 1) % TURNS.size()
	_preview.face_row(TURNS[_turn][0], TURNS[_turn][1])


func _update_save() -> void:
	_save_button.disabled = _saving or not _editor.is_ready()


func _save() -> void:
	if _saving or not _editor.is_ready():
		return
	_saving = true
	_message.hide()
	_save_button.disabled = true
	_back_button.disabled = true
	_save_button.text = SAVING_TEXT
	var result := await _store()
	_saving = false
	_back_button.disabled = false
	_save_button.text = SAVE_TEXT
	_update_save()
	if not result.ok:
		_message.text = result.error
		_message.show()
		return
	if _npc_id > 0:
		closed.emit(true)
	elif _onboarding:
		Router.go_to(&"starter_select")
	else:
		Router.back()


## O Domador pelo Session (o nome antes, se faltava); o NPC pela rota do editor, e o
## catálogo vem de novo.
func _store() -> Result:
	if _npc_id > 0:
		var response: ApiResponse = await EditorApi.set_npc_appearance(_npc_id, _editor.draft.to_dict())
		if not response.ok:
			return Result.failure(response.error)
		await GameData.load_catalog()
		return Result.success(null)
	if _editor.asks_name():
		var named: Result = await Session.set_tamer_name(_editor.tamer_name())
		if not named.ok:
			return named
	return await Session.update_appearance(_editor.draft)
