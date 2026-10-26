class_name PhaseLoopController
extends Node

const Sequence = preload("res://scripts/gameplay/edict_run.gd")
const Piece = preload("res://scripts/pieces/enemy_piece_controller.gd")
const Attack = preload("res://scripts/gameplay/attack_visualizer.gd")

@export var phase_manager_path: NodePath
@export var board_path: NodePath
@export var player_path: NodePath
@export var hud_path: NodePath
@export var audio_path: NodePath

@onready var manager := get_node(phase_manager_path) as PhaseManager
@onready var board := get_node(board_path) as Board3D
@onready var player := get_node(player_path) as GridPlayer
@onready var hud := get_node(hud_path) as GameHUD
@onready var audio := get_node(audio_path) as GameAudio

var edicts := Sequence.new()
var _attack_visualizer: AttackVisualizer
var _waves: Array = []
var _piece_root: Node3D
var _pending_piece_movements := 0
var _generation := 0
var _intro_running := false
var _preparing := false
var _two_edicts := false
var _phase: Dictionary = {}


func _ready() -> void:
	_attack_visualizer = Attack.new() as AttackVisualizer
	_attack_visualizer.name = "AttackVisualizer"
	board.add_child(_attack_visualizer)
	_attack_visualizer.configure(board)
	edicts.edict_started.connect(_present_edict)
	edicts.movement_finished.connect(_movement_complete)
	edicts.failed.connect(_fail_trial)
	edicts.completed.connect(_complete_trial)
	player.cell_changed.connect(_record_step)
	hud.position_confirmed.connect(confirm_preparation)
	manager.phase_started.connect(_load_trial)


func _load_trial(_number: int, definition: Dictionary, _seed: int) -> void:
	_generation += 1
	_preparing = false
	_intro_running = false
	_pending_piece_movements = 0
	edicts.cancel()
	hud.end_preparation()
	audio.stop_effects()
	player.set_input_enabled(false)
	if is_instance_valid(_piece_root): _piece_root.queue_free()
	_piece_root = null
	_waves.clear()
	board.state.clear_dynamic_occupants()
	_attack_visualizer.clear()
	board.clear_tutorial_path()
	_phase = definition
	_two_edicts = int(definition.get("edict_count", 0)) == 2
	var playable := String(definition.get("resolution", "")) == "moves"
	board.set_safe_spot_visible(playable)
	if playable: _open_trial.call_deferred(_generation)


func _open_trial(ticket: int) -> void:
	await get_tree().process_frame
	if ticket != _generation: return
	var refuge: Array = _phase.get("safe_spot", [])
	if refuge.size() != 2 or not board.set_safe_spot_cell(Vector2i(int(refuge[0]), int(refuge[1]))):
		push_error("A fase precisa definir uma casa iluminada válida.")
		return
	var errors := PhaseCatalog.validate_piece_borders(_phase)
	if not errors.is_empty():
		push_error(" ".join(errors))
		return
	_create_guards()
	_intro_running = true
	if _two_edicts:
		for group: Array in _waves:
			for guard: EnemyPieceController in group: guard.show_preparation()
	elif not _start_sequence(): return
	await hud.play_phase_intro(_phase.get("edict_values", []))
	if ticket != _generation: return
	if _two_edicts:
		_preparing = true
		hud.begin_preparation()
	else:
		var route: Array = _phase.get("tutorial_path", [])
		if not route.is_empty():
			var shown := await board.show_tutorial_path(route, player.current_cell)
			if not shown or ticket != _generation: return
		_intro_running = false
	player.set_input_enabled(true)


func _create_guards() -> void:
	_piece_root = Node3D.new()
	_piece_root.name = "ActiveEnemyPieces"
	board.add_child(_piece_root)
	var values: Array = _phase.get("edict_values", [])
	var definitions: Array = _phase.get("piece_waves", [])
	for index in range(values.size()):
		var group: Array[EnemyPieceController] = []
		var entries: Array = definitions[index] if index < definitions.size() else []
		for entry: Dictionary in entries:
			var guard := Piece.new() as EnemyPieceController
			_piece_root.add_child(guard)
			if guard.configure(board, entry, int(values[index]), index): group.append(guard)
			else: guard.queue_free()
		_waves.append(group)


func _start_sequence() -> bool:
	var values: Array = _phase.get("edict_values", [])
	if values.size() == int(_phase.get("edict_count", 1)) and edicts.start(values, player.current_cell): return true
	push_error("Os éditos da fase não puderam ser iniciados.")
	return false


func confirm_preparation() -> void:
	if not _preparing or get_tree().paused: return
	_preparing = false
	hud.end_preparation()
	player.input_enabled = false
	var ticket := _generation
	while player.movement_locked and ticket == _generation: await get_tree().process_frame
	if ticket != _generation: return
	var attacked := await _animate_attack(0, ticket)
	if ticket != _generation: return
	if player.current_cell in attacked:
		_fail_trial(["O primeiro par atacou a posição que você escolheu."])
	elif _start_sequence():
		_intro_running = false
		player.set_input_enabled(true)


func _record_step(destination: Vector2i, previous: Vector2i) -> void:
	if edicts.status == Sequence.Status.WALKING and edicts.cell == previous:
		edicts.move_to(destination)


func _movement_complete() -> void:
	player.set_input_enabled(false)
	board.clear_tutorial_path()
	_resolve_edict.call_deferred(_generation)


func _resolve_edict(ticket: int) -> void:
	if ticket != _generation: return
	var threatened: Array[Vector2i] = []
	if _two_edicts and edicts.index == 1:
		audio.play_effect(&"attack")
		await _attack_visualizer.play_final_judgment()
		if ticket != _generation: return
		audio.stop_effect(&"attack")
	else:
		threatened = await _animate_attack(edicts.index + int(_two_edicts), ticket)
	if ticket == _generation: edicts.resolve(threatened, board.state.safe_spot)


func _animate_attack(index: int, ticket: int) -> Array[Vector2i]:
	var group: Array = _waves[index] if index < _waves.size() else []
	var threatened: Array[Vector2i] = []
	var origins: Array[Vector2i] = []
	var paths: Array = []
	_pending_piece_movements = group.size()
	for guard: EnemyPieceController in group:
		guard.movement_finished.connect(_guard_arrived.bind(ticket), CONNECT_ONE_SHOT)
		guard.play_resolution()
	while _pending_piece_movements > 0 and ticket == _generation: await get_tree().process_frame
	if ticket != _generation: return []
	await get_tree().create_timer(0.18 if group.is_empty() else 0.32).timeout
	if ticket != _generation: return []
	for guard: EnemyPieceController in group:
		var position := guard.destination_cell
		var line: Array[Vector2i] = board.state.attack_cells(guard.piece_type, position)
		origins.append(position)
		paths.append(line)
		board.state.set_occupant(position, StringName("enemy_%d" % guard.get_instance_id()))
		for cell: Vector2i in [position] + line:
			if cell not in threatened: threatened.append(cell)
	if not group.is_empty(): audio.play_effect(&"attack")
	await _attack_visualizer.play_attack(threatened, origins, paths)
	if ticket != _generation: return []
	audio.stop_effect(&"attack")
	for guard: EnemyPieceController in group: guard.finish_wave()
	return threatened


func _guard_arrived(_guard: EnemyPieceController, ticket: int) -> void:
	if ticket == _generation: _pending_piece_movements -= 1


func _present_edict(index: int, _value: int) -> void:
	var next_group := index + int(_two_edicts)
	for group_index in range(_waves.size()):
		for guard: EnemyPieceController in _waves[group_index]: guard.set_wave_active(group_index == next_group)
	if index == 0 or _intro_running: return
	audio.play_effect(&"round_success")
	var ticket := _generation
	await get_tree().create_timer(0.46).timeout
	if ticket == _generation: player.set_input_enabled(true)


func _fail_trial(reasons: Array) -> void:
	var ticket := _generation
	audio.play_effect(&"fail")
	player.set_input_enabled(false)
	player.play_death_animation()
	var retry := await hud.show_failure(reasons)
	if retry and ticket == _generation: manager.restart_phase()


func _complete_trial() -> void:
	var ticket := _generation
	audio.play_effect(&"next_phase")
	player.set_input_enabled(false)
	await hud.show_success()
	if ticket != _generation: return
	await get_tree().create_timer(0.15).timeout
	if ticket == _generation: manager.advance_phase()
