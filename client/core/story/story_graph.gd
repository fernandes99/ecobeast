class_name StoryGraph
extends RefCounted

## As cenas ligadas pelos Marcos (story/05): quem liga cada Marco, as setas de quem liga
## para quem exige, a coluna de cada cena e os avisos dos buracos.

var scenes: Array[StoryScene] = []
## De cada cena que liga um Marco para cada cena que o exige (índices em `scenes`).
var edges: Array[Vector2i] = []
## Os Marcos de cada seta.
var edge_marks: Dictionary[Vector2i, Array] = {}
var columns: Array[int] = []
var warnings: Array[String] = []
## As cenas de cada aviso, para a vista destacar.
var warning_scenes: Array[Array] = []

var _setters: Dictionary[String, Array] = {}


static func build(list: Array[StoryScene]) -> StoryGraph:
	var graph := StoryGraph.new()
	graph.scenes = list
	graph._index_setters()
	graph._link()
	graph._place()
	graph._check()
	return graph


## As cenas que ligam o Marco, pelo nome do arquivo.
func setters(mark: String) -> Array[String]:
	var result: Array[String] = []
	for index: int in _setters.get(mark, []):
		result.append(scenes[index].slug)
	return result


func _index_setters() -> void:
	for index: int in scenes.size():
		for mark: String in StoryValidator.marks_set_by(scenes[index]):
			if not _setters.has(mark):
				_setters[mark] = []
			_setters[mark].append(index)


func _link() -> void:
	for target: int in scenes.size():
		for mark: String in scenes[target].requires:
			for source: int in _setters.get(mark, []):
				if source == target:
					continue
				var edge := Vector2i(source, target)
				if not edge_marks.has(edge):
					edges.append(edge)
					edge_marks[edge] = []
				edge_marks[edge].append(mark)


## A coluna é 1 a mais que a maior das cenas de que ela depende; num ciclo, 0.
func _place() -> void:
	columns.resize(scenes.size())
	columns.fill(-1)
	var in_cycle: Dictionary[int, bool] = {}
	for cycle: Array[int] in _cycles():
		for index: int in cycle:
			in_cycle[index] = true
	for index: int in scenes.size():
		_column(index, in_cycle, {})


func _column(index: int, in_cycle: Dictionary[int, bool], visiting: Dictionary) -> int:
	if columns[index] >= 0:
		return columns[index]
	if in_cycle.has(index) or visiting.has(index):
		columns[index] = 0
		return 0
	visiting[index] = true
	var best := -1
	for edge: Vector2i in edges:
		if edge.y == index:
			best = maxi(best, _column(edge.x, in_cycle, visiting))
	visiting.erase(index)
	columns[index] = best + 1
	return columns[index]


## Os ciclos de dependência, um por conjunto de cenas, na ordem em que se esperam.
func _cycles() -> Array[Array]:
	var found: Array[Array] = []
	var seen_keys: Dictionary[String, bool] = {}
	var state: Array[int] = []
	state.resize(scenes.size())
	state.fill(0)
	var stack: Array[int] = []
	for start: int in scenes.size():
		if state[start] == 0:
			_walk(start, state, stack, found, seen_keys)
	return found


func _walk(index: int, state: Array[int], stack: Array[int], found: Array[Array], seen_keys: Dictionary[String, bool]) -> void:
	state[index] = 1
	stack.append(index)
	for edge: Vector2i in edges:
		if edge.y != index:
			continue
		var before := edge.x
		if state[before] == 1:
			var cycle: Array[int] = []
			cycle.assign(stack.slice(stack.find(before)))
			var key_list := cycle.duplicate()
			key_list.sort()
			var key := str(key_list)
			if not seen_keys.has(key):
				seen_keys[key] = true
				found.append(cycle)
		elif state[before] == 0:
			_walk(before, state, stack, found, seen_keys)
	stack.pop_back()
	state[index] = 2


func _check() -> void:
	for index: int in scenes.size():
		var scene := scenes[index]
		for mark: String in scene.requires:
			if not _setters.has(mark):
				_warn("Ninguém liga o Marco %s, que a cena %s exige." % [mark, scene.name], [index])
			if scene.forbids.has(mark):
				_warn("A cena %s exige e proíbe o Marco %s." % [scene.name, mark], [index])
		if not scene.repeatable and scene.forbids.has(scene.slug):
			_warn("A cena %s proíbe o próprio Marco." % scene.name, [index])
	for cycle: Array in _cycles():
		var names: Array[String] = []
		for index: int in cycle:
			names.append(scenes[index].name)
		var text := names[0] if names.size() == 1 else ", ".join(names.slice(0, names.size() - 1)) + " e " + names[names.size() - 1]
		_warn("As cenas %s esperam uma pela outra em ciclo." % text, cycle)


func _warn(text: String, involved: Array) -> void:
	warnings.append(text)
	warning_scenes.append(involved)
