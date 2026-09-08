class_name PhaseLoopController
extends Node

signal wave_movement_finished

const EditoMachineModel = preload("res://scripts/gameplay/edito_state_machine.gd")
const EnemyPieceModel = preload("res://scripts/pieces/enemy_piece_controller.gd")
const AttackVisualizerModel = preload("res://scripts/gameplay/attack_visualizer.gd")
const Constants = preload("res://scripts/core/game_constants.gd")
const CELESTIAL_FONT = preload("res://assets/fonts/jupiter_pro.otf")
const PhaseCatalogModel = preload("res://scripts/data/phase_catalog.gd")

@export var phase_manager_path: NodePath
@export var board_path: NodePath
@export var player_path: NodePath
@export var hud_path: NodePath

var _phase_manager: PhaseManager
var _board: Board3D
var _player: GridPlayer
var _hud: GameHUD
var _edito_machine
var _attack_visualizer: AttackVisualizer
var _current_phase_data: Dictionary = {}
var _waves: Array = []
var _piece_root: Node3D
var _player_numeral: Label3D
var _numeral_tween: Tween
var _pending_piece_movements := 0
var _generation := 0
var _intro_running := false


func _ready() -> void:
	_phase_manager = get_node(phase_manager_path)
	_board = get_node(board_path)
	_player = get_node(player_path)
	_hud = get_node(hud_path)

	_edito_machine = EditoMachineModel.new()
	add_child(_edito_machine)
	_edito_machine.estado_mudou.connect(_on_estado_mudou)
	_edito_machine.edito_iniciado.connect(_on_edito_iniciado)
	_edito_machine.movimento_registrado.connect(_on_movimento_registrado)
	_edito_machine.falha.connect(_on_falha)
	_edito_machine.sucesso.connect(_on_sucesso)

	_attack_visualizer = AttackVisualizerModel.new()
	_attack_visualizer.name = "AttackVisualizer"
	_board.add_child(_attack_visualizer)
	_attack_visualizer.configure(_board)
	_phase_manager.phase_started.connect(_on_phase_started)


func _on_phase_started(phase_number: int, phase_data: Dictionary, _phase_seed: int) -> void:
	_generation += 1
	var run_id := _generation
	if _player.cell_changed.is_connected(_on_player_moved):
		_player.cell_changed.disconnect(_on_player_moved)
	_player.set_input_enabled(false)
	_clear_pieces()
	if _board.state != null:
		_board.state.clear_dynamic_occupants()
	_attack_visualizer.clear()
	_board.clear_tutorial_path()
	_set_player_numeral(0, false)
	_current_phase_data = phase_data
	if phase_number > 5:
		return
	call_deferred("_begin_phase", run_id)


func _begin_phase(run_id: int) -> void:
	await get_tree().process_frame
	if run_id != _generation:
		return
	var safe_cell: Array = _current_phase_data.get("safe_spot", [])
	if safe_cell.size() != 2:
		push_error("A fase precisa definir um safe spot válido.")
		return
	var safe_spot := Vector2i(int(safe_cell[0]), int(safe_cell[1]))
	if not _board.set_safe_spot_cell(safe_spot):
		push_error("Safe spot inválido para a fase: %s" % safe_spot)
		return

	var border_errors := PhaseCatalogModel.validate_piece_borders(_current_phase_data)
	if not border_errors.is_empty():
		push_error(" ".join(border_errors))
		return
	_spawn_phase_pieces()
	var editos := _build_editos(_current_phase_data)
	_intro_running = true
	if not _edito_machine.configurar_fase(editos, _player.current_cell):
		push_error("Não foi possível configurar os éditos da fase atual.")
		_intro_running = false
		return
	_set_player_numeral(0, false)
	if not _player.cell_changed.is_connected(_on_player_moved):
		_player.cell_changed.connect(_on_player_moved)
	var values: Array = _current_phase_data.get("edict_values", [])
	await _hud.play_phase_intro(values)
	if run_id != _generation:
		return
	_intro_running = false
	_set_player_numeral(_edito_machine.passos_necessarios, true)
	var tutorial_path: Array = _current_phase_data.get("tutorial_path", [])
	if not tutorial_path.is_empty():
		_board.show_tutorial_path(tutorial_path)
	_player.set_input_enabled(true)


func _build_editos(phase_data: Dictionary) -> Array:
	var edict_count := int(phase_data.get("edict_count", 1))
	var values: Array = phase_data.get("edict_values", [])
	if values.size() != edict_count:
		return []
	var editos: Array = []
	for index in range(edict_count):
		editos.append({
			"valor": int(values[index]),
			"par": "first_pair" if index == 0 else "second_pair",
		})
	return editos


func _spawn_phase_pieces() -> void:
	_piece_root = Node3D.new()
	_piece_root.name = "ActiveEnemyPieces"
	_board.add_child(_piece_root)
	_waves.clear()
	var definitions: Array = _current_phase_data.get("piece_waves", [])
	var values: Array = _current_phase_data.get("edict_values", [])
	for wave_index in range(values.size()):
		var wave: Array[EnemyPieceController] = []
		var wave_definitions: Array = definitions[wave_index] if wave_index < definitions.size() else []
		for definition in wave_definitions:
			var piece := EnemyPieceModel.new() as EnemyPieceController
			_piece_root.add_child(piece)
			if piece.configure(_board, definition, int(values[wave_index]), wave_index):
				wave.append(piece)
			else:
				piece.queue_free()
		_waves.append(wave)


func _on_player_moved(cell: Vector2i, previous_cell: Vector2i) -> void:
	if _edito_machine.estado_atual == EditoMachineModel.Estado.AGUARDANDO_MOVIMENTO:
		_edito_machine.registrar_movimento(cell - previous_cell)


func _on_estado_mudou(estado: int) -> void:
	if estado == EditoMachineModel.Estado.PRIMEIRA_PECA:
		_player.set_input_enabled(false)
		_board.clear_tutorial_path()
		_hud.hide_tutorial_hint()
		var run_id := _generation
		call_deferred("_resolve_current_wave", run_id)


func _resolve_current_wave(run_id: int) -> void:
	var wave_index: int = _edito_machine.indice_edito_atual
	var pieces: Array = _waves[wave_index] if wave_index < _waves.size() else []
	var attacked_cells: Array[Vector2i] = []
	var origins: Array[Vector2i] = []
	var attack_paths: Array = []

	if not pieces.is_empty():
		_pending_piece_movements = pieces.size()
		for piece in pieces:
			piece.movement_finished.connect(_on_piece_movement_finished, CONNECT_ONE_SHOT)
			piece.play_resolution()
		# Every piece must be moving before the shared completion signal can fire.
		await wave_movement_finished
		if run_id != _generation:
			return
		await get_tree().create_timer(0.32).timeout
		for piece in pieces:
			origins.append(piece.destination_cell)
			attack_paths.append(_board.state.attack_cells(piece.piece_type, piece.destination_cell))
			if piece.destination_cell not in attacked_cells:
				attacked_cells.append(piece.destination_cell)
			_board.state.set_occupant(piece.destination_cell, StringName("enemy_%d" % piece.get_instance_id()))
			for cell in _board.state.attack_cells(piece.piece_type, piece.destination_cell):
				if cell not in attacked_cells:
					attacked_cells.append(cell)
	else:
		await get_tree().create_timer(0.18).timeout

	_edito_machine.avancar_primeira_peca()
	_edito_machine.avancar_segunda_peca()
	await _attack_visualizer.play_attack(attacked_cells, origins, attack_paths)
	if run_id != _generation:
		return
	_edito_machine.avancar_ataque()
	_edito_machine.julgar(attacked_cells, _board.state.safe_spot)


func _on_piece_movement_finished(_piece: EnemyPieceController) -> void:
	_pending_piece_movements -= 1
	if _pending_piece_movements <= 0:
		wave_movement_finished.emit()


func _on_edito_iniciado(index: int, value: int) -> void:
	if not _intro_running:
		_set_player_numeral(value, true)
	for wave_index in range(_waves.size()):
		for piece in _waves[wave_index]:
			piece.set_wave_active(wave_index == index)
	if index > 0 and not _intro_running:
		call_deferred("_open_next_edict", _generation)


func _open_next_edict(run_id: int) -> void:
	await get_tree().create_timer(0.46).timeout
	if run_id == _generation:
		_player.set_input_enabled(true)


func _on_movimento_registrado(steps: int, required: int) -> void:
	_set_player_numeral(maxi(required - steps, 0), true)


func _on_falha(reasons: Array) -> void:
	var run_id := _generation
	_player.set_input_enabled(false)
	_set_player_numeral(0, false)
	_hud.show_failure(reasons)
	_restart_after_feedback(run_id)


func _restart_after_feedback(run_id: int) -> void:
	await _player.play_death_animation()
	await get_tree().create_timer(0.35).timeout
	if run_id == _generation:
		_phase_manager.restart_phase()


func _on_sucesso() -> void:
	var run_id := _generation
	_player.set_input_enabled(false)
	_set_player_numeral(0, false)
	await _hud.show_success()
	if run_id == _generation:
		_advance_after_feedback(run_id)


func _advance_after_feedback(run_id: int) -> void:
	await get_tree().create_timer(0.15).timeout
	if run_id == _generation and _phase_manager.current_phase < 5:
		_phase_manager.advance_phase()


func _create_player_numeral() -> void:
	_player_numeral = Label3D.new()
	_player_numeral.name = "RemainingMoves"
	_player_numeral.position = Vector3(0.0, 7.35, 0.0)
	_player_numeral.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_player_numeral.no_depth_test = true
	_player_numeral.font = CELESTIAL_FONT
	_player_numeral.font_size = 112
	_player_numeral.pixel_size = 0.011
	_player_numeral.outline_size = 0
	_player_numeral.modulate = Color.WHITE
	_player.add_child(_player_numeral)
	_set_player_numeral(0, false)


func _set_player_numeral(value: int, animate: bool) -> void:
	if _player_numeral == null:
		return
	if _numeral_tween != null:
		_numeral_tween.kill()
	_player_numeral.scale = Vector3.ONE
	if value <= 0:
		if animate and _player_numeral.visible:
			var vanish := create_tween()
			_numeral_tween = vanish
			vanish.set_parallel(true)
			vanish.tween_property(_player_numeral, "scale", Vector3.ONE * 1.12, 0.22)
			vanish.tween_property(_player_numeral, "modulate:a", 0.0, 0.22)
			vanish.finished.connect(func():
				_player_numeral.visible = false
				_player_numeral.scale = Vector3.ONE
			)
		else:
			_player_numeral.visible = false
		return
	_player_numeral.text = Constants.to_roman(value)
	_player_numeral.visible = true
	_player_numeral.modulate.a = 1.0
	if animate:
		_player_numeral.scale = Vector3.ONE * 1.10
		var pulse := create_tween()
		_numeral_tween = pulse
		pulse.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pulse.tween_property(_player_numeral, "scale", Vector3.ONE, 0.24)


func _clear_pieces() -> void:
	if is_instance_valid(_piece_root):
		_piece_root.queue_free()
	_piece_root = null
	_waves.clear()
