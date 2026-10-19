class_name VanillaBoardGenerator
extends RefCounted


const Board = preload("res://scripts/board/board_state.gd")
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


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
	var occupied: Array = hazards[0].occupied + hazards[1].occupied
	if start in hazards[0].attacked or refuge in occupied: return []
	var result: Array = []
	for y in range(5):
		for x in range(5):
			var middle := Vector2i(x, y)
			if middle in hazards[1].attacked or middle in hazards[0].occupied: continue
			if _distance(start, middle) != int(values[0]) or _distance(middle, refuge) != int(values[1]): continue
			if shortest_path(start, middle, hazards[0].occupied).size() != int(values[0]): continue
			if shortest_path(middle, refuge, occupied).size() == int(values[1]): result.append(middle)
	return result


static func plans(data: Dictionary) -> Array:
	var result: Array = []
	var refuge := Vector2i(int(data.safe_spot[0]), int(data.safe_spot[1]))
	var hazards := wave_geometry(data)
	for y in range(5):
		for x in range(5):
			var start := Vector2i(x, y)
			for middle: Vector2i in _intermediates(start, refuge, data.edict_values, hazards):
				result.append({
					"start": start, "middle": middle,
					"first": [start] + shortest_path(start, middle, hazards[0].occupied),
					"second": [middle] + shortest_path(middle, refuge, hazards[0].occupied + hazards[1].occupied),
				})
	return result


static func solution(data: Dictionary) -> Array:
	var start := Vector2i(int(data.starting_cell[0]), int(data.starting_cell[1]))
	var refuge := Vector2i(int(data.safe_spot[0]), int(data.safe_spot[1]))
	if data.edict_values.size() == 1: return [shortest_path(start, refuge)]
	var choices := plans(data)
	if choices.is_empty(): return []
	return [choices[0].first.slice(1), choices[0].second.slice(1)]


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
