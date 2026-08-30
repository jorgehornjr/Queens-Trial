class_name BoardState
extends RefCounted

const Constants = preload("res://scripts/core/game_constants.gd")

var safe_spot := Vector2i(4, 0)
var _occupants: Dictionary = {}


func _init() -> void:
	reset()


func reset() -> void:
	_occupants.clear()
	_occupants[Constants.QUEEN_CELL] = &"queen"


func is_inside(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.x < Constants.BOARD_SIZE
		and cell.y >= 0
		and cell.y < Constants.BOARD_SIZE
	)


func is_occupied(cell: Vector2i) -> bool:
	return _occupants.has(cell)


func can_player_enter(cell: Vector2i) -> bool:
	return is_inside(cell) and not is_occupied(cell)


func set_safe_spot(cell: Vector2i) -> bool:
	if not is_inside(cell) or cell == Constants.QUEEN_CELL:
		return false
	safe_spot = cell
	return true


func set_occupant(cell: Vector2i, occupant: StringName) -> bool:
	if not is_inside(cell) or occupant.is_empty():
		return false
	if cell == Constants.QUEEN_CELL and occupant != &"queen":
		return false
	_occupants[cell] = occupant
	return true


func clear_occupant(cell: Vector2i) -> bool:
	if cell == Constants.QUEEN_CELL or not _occupants.has(cell):
		return false
	_occupants.erase(cell)
	return true


func clear_dynamic_occupants() -> void:
	reset()


func get_occupant(cell: Vector2i) -> StringName:
	return StringName(_occupants.get(cell, &""))


func manhattan_distance(origin: Vector2i, destination: Vector2i) -> int:
	return absi(destination.x - origin.x) + absi(destination.y - origin.y)


func attack_cells(piece_type: StringName, origin: Vector2i) -> Array[Vector2i]:
	match piece_type:
		Constants.PIECE_ROOK:
			return rook_attack_cells(origin)
		Constants.PIECE_BISHOP:
			return bishop_attack_cells(origin)
		_:
			return []


func rook_attack_cells(origin: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not is_inside(origin):
		return cells

	for index in range(Constants.BOARD_SIZE):
		if index != origin.x:
			cells.append(Vector2i(index, origin.y))
		if index != origin.y:
			cells.append(Vector2i(origin.x, index))
	return cells


func bishop_attack_cells(origin: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not is_inside(origin):
		return cells

	var directions: Array[Vector2i] = [
		Vector2i(1, 1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(-1, -1),
	]
	for direction in directions:
		var cursor := origin + direction
		while is_inside(cursor):
			cells.append(cursor)
			cursor += direction
	return cells
