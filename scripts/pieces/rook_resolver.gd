class_name RookResolver
extends RefCounted


static func resolve_pair(board_state, rook_positions: Array, player_cell: Vector2i) -> Dictionary:
	var attacked_cells: Array[Vector2i] = []
	for position_value in rook_positions:
		var position := position_value as Vector2i
		for cell in board_state.rook_attack_cells(position):
			if not attacked_cells.has(cell):
				attacked_cells.append(cell)

	return {
		"attacked_cells": attacked_cells,
		"player_hit": attacked_cells.has(player_cell),
	}
