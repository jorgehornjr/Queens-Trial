extends SceneTree

const Piece = preload("res://scripts/pieces/enemy_piece_controller.gd")
const Board = preload("res://scripts/board/board.gd")
const Catalog = preload("res://scripts/data/phase_catalog.gd")

func _initialize() -> void:
	var board := Board.new()
	var failures := PackedStringArray()
	var phase := Catalog.find_phase(Catalog.load_campaign(), 4)
	if not Catalog.validate_piece_borders(phase).is_empty():
		failures.append("A fase IV deve ter uma peça em cada uma das quatro bordas.")
	phase.piece_waves[1][0].side = "left"
	if Catalog.validate_piece_borders(phase).is_empty():
		failures.append("Uma borda duplicada em ondas diferentes deve ser rejeitada.")
	for side in ["left", "right", "top", "bottom"]:
		for direction in [-1, 1]:
			for value in range(1, 5):
				var slot := 0 if direction == 1 else 4
				var piece := Piece.new()
				var definition := {"side": side, "edge_slot": slot, "edge_direction": direction, "move_value": value}
				if not piece.configure(board, definition, 2, 0):
					failures.append("Configuração válida rejeitada: %s" % definition)
				else:
					var lane: int = slot + direction * value
					var depth: int = piece.destination_cell.x + 1 if side == "left" else 5 - piece.destination_cell.x
					if side == "top": depth = piece.destination_cell.y + 1
					if side == "bottom": depth = 5 - piece.destination_cell.y
					if piece.edge_steps != value or depth != value or piece.entry_lane != lane:
						failures.append("Borda e profundidade devem corresponder ao numeral: %s" % definition)
					var arrow := piece.get_node("DirectionEtching") as MeshInstance3D
					var flat_position := Vector3(arrow.position.x, 0.0, arrow.position.z)
					var near_gap := flat_position.length() - (arrow.mesh as PlaneMesh).size.y * 0.5
					if not is_equal_approx(near_gap, 5.5) or not (arrow.mesh as PlaneMesh).size.is_equal_approx(Vector2(2.4, 6.7)):
						failures.append("As flechas devem manter distância e tamanho fixos em todos os lados e valores.")
					var expected_direction := (piece._edge_target - piece.position).normalized()
					if flat_position.normalized().dot(expected_direction) < 0.999 or arrow.basis.z.dot(expected_direction) < 0.999:
						failures.append("As flechas devem permanecer alinhadas à direção da peça.")
				piece.free()
	for definition in [
		{"side": "left", "edge_slot": 0, "edge_direction": -1, "move_value": 2},
		{"side": "right", "edge_slot": 4, "edge_direction": 1, "move_value": 1},
		{"side": "top", "edge_slot": 0, "edge_direction": 1, "move_value": 5},
		{"side": "bottom", "edge_slot": 0, "lane": 4, "move_value": 2},
	]:
		var piece := Piece.new()
		if piece.configure(board, definition, 2, 0):
			failures.append("Deslocamento inválido aceito: %s" % definition)
		piece.free()
	board.free()
	for failure in failures:
		printerr("FALHA: " + failure)
	if failures.is_empty():
		print("OK: numeral único em ambas as etapas, quatro lados e duas direções; limites rejeitados.")
	quit(0 if failures.is_empty() else 1)
