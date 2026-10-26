class_name SavageCatalog
extends RefCounted

const FIRST := 101
const LAST := 105
const PATH := "res://data/savage/challenges.json"
const BoardModel = preload("res://scripts/board/board_state.gd")
const Routes = preload("res://scripts/data/vanilla_board_generator.gd")

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

static func operation_result(equation: Dictionary) -> int:
	var left := int(equation.get("left", 0))
	var right := int(equation.get("right", 0))
	if left not in range(1, 21) or right not in range(1, 21): return 0
	match String(equation.get("operator", "")):
		"subtract": return left - right
		"divide": return int(left / right) if left % right == 0 else 0
	return 0

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

static func solutions(stage: Dictionary) -> Array:
	return Routes.plans(stage)

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
		if float(stage.get("preparation_seconds", 0)) != 15.0: errors.append("A preparação deve durar quinze segundos.")
		var operations: Array = stage.get("edict_operations", [])
		if operations.size() != 2:
			errors.append("Chaotic precisa de duas operações e quatro cartas.")
		else:
			for operation_index in range(2):
				if operation_result(operations[operation_index]) != int(values[operation_index]):
					errors.append("A operação não corresponde ao édito Chaotic.")
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
