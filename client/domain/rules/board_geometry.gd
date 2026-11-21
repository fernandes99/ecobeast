class_name BoardGeometry
extends RefCounted

const MOVE_RANGE := 1
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1),
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 1),
]
## As 6 direções no sentido horário da tela, como no servidor (board-battle/33).
const CLOCKWISE: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1),
]


static func distance(a: Vector2i, b: Vector2i) -> int:
	var dq := a.x - b.x
	var dr := a.y - b.y
	# A soma é sempre par: a divisão é exata.
	@warning_ignore("integer_division")
	return (absi(dq) + absi(dr) + absi(dq + dr)) / 2


static func reachable(cells: Array[Vector2i], blocked: Array[Vector2i], from: Vector2i, steps: int = MOVE_RANGE) -> Dictionary[Vector2i, Array]:
	var paths: Dictionary[Vector2i, Array] = {}
	var seen: Dictionary[Vector2i, bool] = {from: true}
	var frontier: Array[Vector2i] = [from]
	var routes: Dictionary[Vector2i, Array] = {from: []}
	for _step: int in steps:
		var next: Array[Vector2i] = []
		for cell: Vector2i in frontier:
			for direction: Vector2i in DIRECTIONS:
				var neighbor := cell + direction
				if seen.has(neighbor) or not cells.has(neighbor) or blocked.has(neighbor):
					continue
				seen[neighbor] = true
				var path: Array = routes[cell].duplicate()
				path.append(neighbor)
				routes[neighbor] = path
				paths[neighbor] = path
				next.append(neighbor)
		frontier = next
	return paths


static func targets(skill: Skill, cells: Array[Vector2i], foes: Array[Vector2i], from: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if skill.area_shape == "line":
		for direction: Vector2i in DIRECTIONS:
			for step: int in range(1, skill.area_range + 1):
				var cell := from + direction * step
				if not cells.has(cell):
					break
				result.append(cell)
		return result
	for cell: Vector2i in cells:
		var reach := distance(from, cell)
		if reach == 0 or reach > skill.area_range:
			continue
		if skill.has_ground_effect():
			result.append(cell)
		elif skill.area_shape == "triangle":
			if _foes_in(triangle(cells, foes, from, cell), foes) > 0:
				result.append(cell)
		elif foes.has(cell):
			result.append(cell)
	return result


static func ally_targets(skill: Skill, allies: Array[Vector2i], from: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in allies:
		if distance(from, cell) <= skill.area_range:
			result.append(cell)
	return result


static func area(skill: Skill, cells: Array[Vector2i], foes: Array[Vector2i], from: Vector2i, target: Vector2i) -> Array[Vector2i]:
	if skill.area_shape == "triangle":
		return triangle(cells, foes, from, target)
	if skill.area_shape != "line":
		return [target]
	var steps := distance(from, target)
	for direction: Vector2i in DIRECTIONS:
		if from + direction * steps != target:
			continue
		var covered: Array[Vector2i] = []
		for step: int in range(1, skill.area_range + 1):
			var cell := from + direction * step
			if not cells.has(cell):
				break
			covered.append(cell)
			if foes.has(cell) and not skill.pierces:
				break
		return covered
	return []


## O vértice e os 2 vizinhos mais longe de quem usa, com o vértice por último. Numa
## reta, fica o lado com mais inimigos, depois o com mais hexágonos, depois o horário.
static func triangle(cells: Array[Vector2i], foes: Array[Vector2i], from: Vector2i, vertex: Vector2i) -> Array[Vector2i]:
	var best: Array[Vector2i] = []
	var best_foes := -1
	for pair: Array[Vector2i] in _triangle_pairs(from, vertex):
		var covered: Array[Vector2i] = []
		for cell: Vector2i in pair + [vertex]:
			if cells.has(cell):
				covered.append(cell)
		var count := _foes_in(covered, foes)
		if count > best_foes or (count == best_foes and covered.size() > best.size()):
			best = covered
			best_foes = count
	return best


static func _triangle_pairs(from: Vector2i, vertex: Vector2i) -> Array[Array]:
	var steps := distance(from, vertex)
	var axis := -1
	for index: int in CLOCKWISE.size():
		if from + CLOCKWISE[index] * steps == vertex:
			axis = index
	if axis == -1:
		var far: Array[Vector2i] = []
		for direction: Vector2i in CLOCKWISE:
			if distance(from, vertex + direction) == steps + 1:
				far.append(vertex + direction)
		return [far]
	var ahead := vertex + CLOCKWISE[axis]
	var clockwise: Array[Vector2i] = [ahead, vertex + CLOCKWISE[(axis + 1) % CLOCKWISE.size()]]
	var counter: Array[Vector2i] = [ahead, vertex + CLOCKWISE[(axis + CLOCKWISE.size() - 1) % CLOCKWISE.size()]]
	return [clockwise, counter]


static func _foes_in(covered: Array[Vector2i], foes: Array[Vector2i]) -> int:
	var count := 0
	for cell: Vector2i in covered:
		if foes.has(cell):
			count += 1
	return count
