class_name BattleStatuses
extends RefCounted

const ORDER: Array[String] = ["burn", "poison", "paralysis", "sleep", "freeze", "confusion", "fear", "trapped"]
const MAIN: Array[String] = ["burn", "poison", "paralysis", "sleep", "freeze"]
const VOLATILE: Array[String] = ["confusion", "fear", "trapped"]

var _by_key: Dictionary[String, Array] = {}
var _actor := ""


func of(key: String) -> Array[String]:
	var slugs: Array[String] = []
	var have: Array = _by_key.get(key, [])
	for slug: String in ORDER:
		if have.has(slug):
			slugs.append(slug)
	for slug: String in have:
		if not slugs.has(slug):
			slugs.append(slug)
	return slugs


func apply(event: Dictionary, key: String) -> Array[String]:
	var changed: Array[String] = []
	match DictFields.get_string(event, "type"):
		"creature_entered":
			_by_key[key] = []
			var status := DictFields.get_string(event, "status")
			if not status.is_empty():
				_by_key[key].append(status)
			changed.append(key)
		"status_applied":
			if _add(key, DictFields.get_string(event, "status")):
				changed.append(key)
		"woke_up":
			if _remove(key, "sleep"):
				changed.append(key)
		"thawed":
			if _remove(key, "freeze"):
				changed.append(key)
		"status_ended":
			if _remove(key, DictFields.get_string(event, "status")):
				changed.append(key)
		"cannot_act":
			if DictFields.get_string(event, "reason") == "fear" and _remove(key, "fear"):
				changed.append(key)
		"vez_started":
			# O servidor tira o medo no fim da vez de quem tinha.
			if not _actor.is_empty() and _actor != key and _remove(_actor, "fear"):
				changed.append(_actor)
			_actor = key
		"fainted":
			if not of(key).is_empty():
				changed.append(key)
			_by_key[key] = []
		"creature_left":
			if not of(key).is_empty():
				changed.append(key)
			_by_key.erase(key)
		"battle_ended":
			for other: String in _by_key.keys():
				for slug: String in VOLATILE:
					if _remove(other, slug) and not changed.has(other):
						changed.append(other)
	return changed


func cure(key: String) -> void:
	for slug: String in MAIN:
		_remove(key, slug)


## O que o servidor diz no fim da resposta: o principal (vazio sem nenhum) e se está
## confuso. O medo e o preso, que ele não manda, ficam como os eventos deixaram.
func sync(key: String, status: String, confused: bool) -> void:
	var kept: Array = []
	for slug: String in _by_key.get(key, []):
		if not MAIN.has(slug) and slug != "confusion":
			kept.append(slug)
	if not status.is_empty():
		kept.append(status)
	if confused:
		kept.append("confusion")
	_by_key[key] = kept


func erase(key: String) -> void:
	_by_key.erase(key)


func _add(key: String, slug: String) -> bool:
	if slug.is_empty():
		return false
	var have: Array = _by_key.get_or_add(key, [])
	if have.has(slug):
		return false
	have.append(slug)
	return true


func _remove(key: String, slug: String) -> bool:
	var have: Array = _by_key.get(key, [])
	if not have.has(slug):
		return false
	have.erase(slug)
	return true
