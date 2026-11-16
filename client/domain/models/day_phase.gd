class_name DayPhase
extends RefCounted
## Uma parte do dia do relógio do mundo (.specs/day-night/).

var id: int
var slug: String
var name: String
var start_minute: int


static func from_row(row: Dictionary) -> DayPhase:
	var phase := DayPhase.new()
	phase.id = row["id"]
	phase.slug = row["slug"]
	phase.name = row["name"]
	phase.start_minute = row["start_minute"]
	return phase


## A de maior início até `minute`; sem nenhuma, a de maior início (a noite atravessa a 0h).
## `phases` vem em ordem de início.
static func at(minute: float, phases: Array[DayPhase]) -> DayPhase:
	if phases.is_empty():
		return null
	var found: DayPhase = phases.back()
	for phase: DayPhase in phases:
		if phase.start_minute <= minute:
			found = phase
	return found
