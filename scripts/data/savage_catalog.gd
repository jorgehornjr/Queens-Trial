class_name SavageCatalog
extends RefCounted

const FIRST := 101
const LAST := 105
const PATH := "res://data/savage/challenges.json"
const BoardModel = preload("res://scripts/board/board_state.gd")

static func contains(number: int) -> bool:
	return number in range(FIRST, LAST + 1)

static func stages() -> Array:
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null: return []
	var data: Variant = JSON.parse_string(file.get_as_text())
	return data.get("stages", []) if data is Dictionary else []

static func find(number: int) -> Dictionary:
	for stage: Dictionary in stages():
		if int(stage.get("id", 0)) == number: return stage.duplicate(true)
	return {}

static func cell(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))

static func destination(piece: Dictionary) -> Vector2i:
	var amount := int(piece.move_value)
	var lane := int(piece.edge_slot) + int(piece.edge_direction) * amount
	match String(piece.side):
		"left": return Vector2i(amount - 1, lane)
		"right": return Vector2i(5 - amount, lane)
		"top": return Vector2i(lane, amount - 1)
		_: return Vector2i(lane, 5 - amount)

static func attacked(wave: Array) -> Array[Vector2i]:
	var board := BoardModel.new()
	var result: Array[Vector2i] = []
	for piece: Dictionary in wave:
		var origin := destination(piece)
		if origin not in result: result.append(origin)
		for target in board.attack_cells(StringName(piece.type), origin):
			if target not in result: result.append(target)
	return result

static func route(origin: Vector2i, target: Vector2i, limit: int, occupied: Array[Vector2i] = []) -> Array[Vector2i]:
	var board := BoardModel.new()
	var queue: Array = [[origin]]
	var visited := {origin: true}
	while not queue.is_empty():
		var path: Array = queue.pop_front()
		var current: Vector2i = path.back()
		if current == target:
			var typed: Array[Vector2i] = []
			typed.assign(path)
			return typed
		for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next := current + direction
			if board.is_inside(next) and next not in occupied and not visited.has(next) and board.manhattan_distance(origin, next) <= limit:
				visited[next] = true
				queue.append(path + [next])
	return []

static func solutions(stage: Dictionary) -> Array:
	var board := BoardModel.new()
	var result: Array = []
	var first := attacked(stage.piece_waves[0])
	var second := attacked(stage.piece_waves[1])
	var final := cell(stage.safe_spot)
	var occupied: Array[Vector2i] = []
	for piece: Dictionary in stage.piece_waves[0]: occupied.append(destination(piece))
	if final in second or final in occupied: return []
	for x in range(5):
		for y in range(5):
			var middle := Vector2i(x, y)
			if middle in first or board.manhattan_distance(middle, final) != int(stage.edict_values[1]): continue
			var second_path := route(middle, final, int(stage.edict_values[1]), occupied)
			if second_path.is_empty(): continue
			for sx in range(5):
				for sy in range(5):
					var start := Vector2i(sx, sy)
					if board.manhattan_distance(start, middle) != int(stage.edict_values[0]): continue
					var first_path := route(start, middle, int(stage.edict_values[0]))
					if not first_path.is_empty(): result.append({"start": start, "middle": middle, "first": first_path, "second": second_path})
	return result

static func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var all := stages()
	if all.size() != 5: errors.append("Chaotic precisa de cinco desafios.")
	var board := BoardModel.new()
	for index in range(all.size()):
		var stage: Dictionary = all[index]
		if int(stage.get("id", 0)) != FIRST + index: errors.append("ID Chaotic inválido.")
		var values: Array = stage.get("edict_values", [])
		if values.size() != 2 or int(values[0]) not in range(1,5) or int(values[1]) not in range(1,5) or int(values[0]) + int(values[1]) > 7:
			errors.append("Éditos Chaotic inválidos.")
			continue
		if float(stage.get("preparation_seconds", 0)) != 10.0: errors.append("A preparação deve durar dez segundos.")
		var slots := {}
		var sides := {}
		var landings := {}
		for wave: Array in stage.piece_waves:
			for piece: Dictionary in wave:
				if sides.has(String(piece.side)): errors.append("Chaotic permite somente uma peça por lado.")
				sides[String(piece.side)] = true
				var key := "%s:%s" % [piece.side, piece.edge_slot]
				var landing := destination(piece)
				if slots.has(key) or landings.has(landing): errors.append("Colisão de peças Chaotic.")
				slots[key] = true
				landings[landing] = true
				if not board.is_inside(landing) or int(piece.move_value) not in range(1,5) or int(piece.edge_direction) not in [-1,1] or int(piece.edge_slot) not in range(5) or String(piece.side) not in ["left","right","top","bottom"] or String(piece.type) not in ["rook","bishop"]:
					errors.append("Peça Chaotic inválida.")
		if solutions(stage).is_empty(): errors.append("Chaotic %d não possui solução." % (index+1))
	return errors
