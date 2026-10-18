class_name VanillaBoardGenerator
extends RefCounted
## Keeps the authored enemy lessons, varying only solvable starts, refuge and edicts.

const Board = preload("res://scripts/board/board_state.gd")
const VALUES := [1, 2, 3, 4]
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


static func generate(template: Dictionary, seed_value: int, history: Array = []) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var candidates: Array = []
	for first in VALUES:
		if int(template.edict_count) == 1:
			candidates.append([first])
		else:
			for second in VALUES:
				if first != second: candidates.append([first, second])
	_shuffle(candidates, rng)
	# Prefer a new combination, then a reversed combination before an exact repeat.
	candidates.sort_custom(func(a: Array, b: Array): return _repeat_score(a, history) < _repeat_score(b, history))
	var cells: Array = []
	for y in range(5):
		for x in range(5): cells.append(Vector2i(x, y))
	_shuffle(cells, rng)
	var hazards := wave_geometry(template)
	for values: Array in candidates:
		for start: Vector2i in cells:
			# Leave room for the approved opening walk toward the starting tile.
			if int(template.number) == 1 and start.y > 2: continue
			if not history.is_empty() and history[-1].get("starting_cell", []) == [start.x, start.y]: continue
			var refuges := cells.duplicate()
			_shuffle(refuges, rng)
			for refuge: Vector2i in refuges:
				if refuge == start: continue
				var middles := _intermediates(start, refuge, values, hazards)
				# Vanilla allows several first-edict answers, unlike the Chaotic bottleneck.
				if middles.size() < (1 if values.size() == 1 else 2): continue
				var result := template.duplicate(true)
				result.edict_values = values.duplicate()
				result.starting_cell = [start.x, start.y]
				result.safe_spot = [refuge.x, refuge.y]
				result.erase("tutorial_path")
				if values.size() == 1:
					result.tutorial_path = []
					for cell: Vector2i in shortest_path(start, refuge): result.tutorial_path.append([cell.x, cell.y])
				return result
	push_error("Não foi possível gerar uma fase Vanilla solucionável.")
	return {}


static func _repeat_score(values: Array, history: Array) -> int:
	var score := 0
	var sorted := values.duplicate()
	sorted.sort()
	for index in range(history.size()):
		var previous: Array = history[index].get("edict_values", [])
		var previous_sorted := previous.duplicate()
		previous_sorted.sort()
		if sorted == previous_sorted: score += 10
		if values == previous: score += 1
		if index == history.size() - 1:
			if sorted == previous_sorted: score += 100
			if values == previous: score += 1000
	return score


static func wave_geometry(data: Dictionary) -> Array:
	var state := Board.new()
	var result: Array = []
	for wave: Array in data.get("piece_waves", []):
		var occupied: Array = []
		var attacked: Array = []
		for piece: Dictionary in wave:
			var value := int(piece.move_value)
			var lane := int(piece.edge_slot) + int(piece.edge_direction) * value
			var destination: Vector2i
			match String(piece.side):
				"left": destination = Vector2i(value - 1, lane)
				"right": destination = Vector2i(5 - value, lane)
				"top": destination = Vector2i(lane, value - 1)
				_: destination = Vector2i(lane, 5 - value)
			occupied.append(destination)
			attacked.append(destination)
			attacked.append_array(state.attack_cells(StringName(piece.type), destination))
		result.append({"occupied": occupied, "attacked": attacked})
	while result.size() < 2: result.append({"occupied": [], "attacked": []})
	return result


static func _intermediates(start: Vector2i, refuge: Vector2i, values: Array, hazards: Array) -> Array:
	if values.size() == 1:
		return [refuge] if _distance(start, refuge) == int(values[0]) else []
	if refuge in hazards[1].attacked or refuge in hazards[0].occupied: return []
	var result: Array = []
	for y in range(5):
		for x in range(5):
			var middle := Vector2i(x, y)
			if middle in hazards[0].attacked: continue
			if _distance(start, middle) != int(values[0]) or _distance(middle, refuge) != int(values[1]): continue
			if shortest_path(middle, refuge, hazards[0].occupied).size() == int(values[1]): result.append(middle)
	return result


static func solution(data: Dictionary) -> Array:
	var start := Vector2i(int(data.starting_cell[0]), int(data.starting_cell[1]))
	var refuge := Vector2i(int(data.safe_spot[0]), int(data.safe_spot[1]))
	var hazards := wave_geometry(data)
	var middles := _intermediates(start, refuge, data.edict_values, hazards)
	if middles.is_empty(): return []
	if data.edict_values.size() == 1: return [shortest_path(start, refuge)]
	return [shortest_path(start, middles[0]), shortest_path(middles[0], refuge, hazards[0].occupied)]


static func shortest_path(start: Vector2i, target: Vector2i, blocked: Array = []) -> Array:
	var queue: Array = [start]
	var previous := {start: start}
	var cursor := 0
	while cursor < queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		if cell == target:
			var path: Array = []
			while cell != start:
				path.push_front(cell)
				cell = previous[cell]
			return path
		for direction: Vector2i in DIRECTIONS:
			var next := cell + direction
			if next.x < 0 or next.y < 0 or next.x >= 5 or next.y >= 5 or next in blocked or previous.has(next): continue
			previous[next] = cell
			queue.append(next)
	return []


static func _distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for index in range(items.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var value: Variant = items[index]
		items[index] = items[other]
		items[other] = value
