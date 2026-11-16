class_name DayPhaseBadge
extends PanelContainer
## O ícone e o nome da parte do dia (.specs/day-night/02-day-light.md). Escondido até o
## relógio sincronizar.

const ICON_PATH := "res://assets/ui/day_phases/%s.png"

@onready var _icon: TextureRect = %Icon
@onready var _name: Label = %PhaseName


func _ready() -> void:
	WorldClock.phase_changed.connect(_show_phase)
	_show_phase(WorldClock.phase())


func _show_phase(phase: DayPhase) -> void:
	visible = phase != null
	if phase == null:
		return
	_name.text = phase.name
	var path := ICON_PATH % phase.slug
	_icon.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
