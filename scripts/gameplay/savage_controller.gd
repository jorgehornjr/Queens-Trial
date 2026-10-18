class_name SavageController
extends Node
## Separate from the Vanilla edict state machine and authored starting cell.
const Catalog = preload("res://scripts/data/savage_catalog.gd")
const Piece = preload("res://scripts/pieces/savage_enemy_piece.gd")
const Attacks = preload("res://scripts/gameplay/attack_visualizer.gd")
const UI = preload("res://scripts/ui/savage_hud.gd")
const Effects = preload("res://scripts/environment/savage_effects.gd")
enum Stage { INACTIVE, PRESENTATION, PREPARATION, MOVING, RESOLVING, FAILED, CLEARED }
var stage := Stage.INACTIVE
var remaining := 0.0
var wave_index := 0
var edict_origin := Vector2i.ZERO
var random_spawn := Vector2i.ZERO
var data: Dictionary = {}
var ui: SavageHUD
var effects: Node3D
var _generation := 0
var _pieces: Node3D
var _waves: Array = []
var _pending := 0
var _attack: AttackVisualizer
var _rng := RandomNumberGenerator.new()
@onready var manager: PhaseManager = get_node("../PhaseManager")
@onready var board: Board3D = get_node("../World/Board")
@onready var player: GridPlayer = get_node("../World/Player")
@onready var audio: GameAudio = get_node("../GameAudio")
@onready var hud: GameHUD = get_node("../HUD")

func _ready() -> void:
	_rng.randomize()
	ui = UI.new()
	ui.name = "SavageHUD"
	add_child(ui)
	_attack = Attacks.new()
	_attack.name = "SavageAttacks"
	board.add_child(_attack)
	_attack.configure(board)
	effects = Effects.new()
	effects.name = "SavageAtmosphere"
	get_node("../World").add_child(effects)
	effects.configure(get_parent())
	manager.phase_started.connect(_phase_started)
	var errors := Catalog.validate()
	for error in errors: push_error(error)

func _phase_started(number: int, phase_data: Dictionary, _seed_value: int) -> void:
	_generation += 1
	stage = Stage.INACTIVE
	ui.cancel()
	_attack.clear()
	if is_instance_valid(_pieces):
		_pieces.queue_free()
	_pieces = null
	_waves.clear()
	_pending = 0
	effects.set_active(Catalog.contains(number))
	if not Catalog.contains(number): return
	data = phase_data.duplicate(true)
	_begin.call_deferred(_generation)

func _begin(run_id: int) -> void:
	await get_tree().process_frame
	if run_id != _generation: return
	board.state.clear_dynamic_occupants()
	board.set_safe_spot_cell(Catalog.cell(data.safe_spot))
	board.set_safe_spot_visible(true)
	player.reset_to_start()
	random_spawn = Vector2i(_rng.randi_range(0,4), _rng.randi_range(0,4))
	player.current_cell = random_spawn
	player.position = board.grid_to_world(random_spawn) + Vector3.UP * player.surface_offset
	player.show()
	_pieces = Node3D.new()
	_pieces.name = "SavagePieces"
	board.add_child(_pieces)
	for index in range(2):
		var wave: Array[SavageEnemyPiece] = []
		for definition: Dictionary in data.piece_waves[index]:
			var piece := Piece.new() as SavageEnemyPiece
			_pieces.add_child(piece)
			if not piece.configure(board, definition, int(data.edict_values[index]), index):
				push_error("Peça Chaotic inválida.")
				piece.queue_free()
				continue
			piece.show_planning(index == 0)
			wave.append(piece)
		_waves.append(wave)
	wave_index = 0
	stage = Stage.PRESENTATION
	ui.present(manager.current_phase, data.edict_values)
	await get_tree().create_timer(2.3,false).timeout
	if run_id != _generation: return
	var cards: CardPresentation = get_node("../HUD").card_presentation
	await cards.present(data.edict_values, CardPresentation.CARD_BACK_CHAOTIC)
	if run_id != _generation: return
	remaining = float(data.preparation_seconds)
	stage = Stage.PREPARATION
	ui.update_timer(remaining, true, 0)
	player.set_input_enabled(true)

func _process(delta: float) -> void:
	if stage not in [Stage.PREPARATION, Stage.MOVING]: return
	remaining = maxf(0.0, remaining - delta)
	ui.update_timer(remaining, stage == Stage.PREPARATION, wave_index)
	if remaining > 0.0: return
	var preparing := stage == Stage.PREPARATION
	stage = Stage.RESOLVING
	player.input_enabled = false
	if preparing: _finish_preparation(_generation)
	else: _resolve(_generation)

func _input(event: InputEvent) -> void:
	if stage not in [Stage.PREPARATION, Stage.MOVING] or get_tree().paused: return
	if not event is InputEventKey or not event.pressed or event.echo: return
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		if not event.is_action_pressed(action): continue
		get_viewport().set_input_as_handled()
		if player.movement_locked: return
		var camera := get_viewport().get_camera_3d()
		var direction := GridPlayer.camera_direction_for_action(camera.global_rotation.y, action)
		var target := player.current_cell + direction
		if stage == Stage.MOVING and board.state.manhattan_distance(edict_origin, target) > int(data.edict_values[wave_index]):
			return
		player._try_move(direction)
		return

func _settle(run_id: int) -> bool:
	player.input_enabled = false
	while player.movement_locked and run_id == _generation:
		await get_tree().process_frame
	return run_id == _generation

func _finish_preparation(run_id: int) -> void:
	if not await _settle(run_id): return
	_open_edict()

func _open_edict() -> void:
	edict_origin = player.current_cell
	remaining = float(data.seconds_per_edict)
	stage = Stage.MOVING
	for index in range(_waves.size()):
		for piece: SavageEnemyPiece in _waves[index]:
			if index < wave_index: piece.finish_wave()
			else: piece.show_planning(index == wave_index)
	ui.update_timer(remaining, false, wave_index)
	player.set_input_enabled(true)

func _resolve(run_id: int) -> void:
	if not await _settle(run_id): return
	ui.resolving()
	var correct_distance: bool = board.state.manhattan_distance(edict_origin, player.current_cell) == int(data.edict_values[wave_index])
	var pieces: Array = _waves[wave_index]
	_pending = pieces.size()
	for piece: EnemyPieceController in pieces:
		piece.movement_finished.connect(_piece_finished, CONNECT_ONE_SHOT)
		piece.play_resolution()
	while _pending > 0 and run_id == _generation: await get_tree().process_frame
	if run_id != _generation: return
	var attacked: Array[Vector2i] = []
	var origins: Array[Vector2i] = []
	var paths: Array = []
	for piece: EnemyPieceController in pieces:
		origins.append(piece.destination_cell)
		board.state.set_occupant(piece.destination_cell, &"savage_enemy")
		var cells: Array[Vector2i] = board.state.attack_cells(piece.piece_type, piece.destination_cell)
		paths.append(cells)
		if piece.destination_cell not in attacked: attacked.append(piece.destination_cell)
		for cell in cells:
			if cell not in attacked: attacked.append(cell)
	audio.play_effect(&"attack")
	await _attack.play_attack(attacked, origins, paths)
	if run_id != _generation: return
	audio.stop_effect(&"attack")
	var reasons: Array = []
	if not correct_distance:
		var distance: int = board.state.manhattan_distance(edict_origin, player.current_cell)
		var expected := int(data.edict_values[wave_index])
		var position_feedback := "Você voltou ao ponto de partida." if distance == 0 else "Você terminou a %d %s do ponto de partida." % [distance, "casa" if distance == 1 else "casas"]
		reasons.append("A carta %s pedia uma distância de %d %s.\n%s" % [GameConstants.to_roman(expected), expected, "casa" if expected == 1 else "casas", position_feedback])
	if player.current_cell in attacked: reasons.append("Uma peça atacou a casa onde você parou.")
	if not reasons.is_empty(): _fail(reasons, run_id)
	elif wave_index == 1 and player.current_cell != board.state.safe_spot: _fail(["Você cumpriu os éditos, mas terminou fora da casa iluminada."], run_id)
	elif wave_index == 0:
		wave_index = 1
		audio.play_effect(&"round_success")
		_open_edict()
	else: _clear(run_id)

func _piece_finished(_piece: EnemyPieceController) -> void:
	_pending -= 1

func _fail(reasons: Array, run_id: int) -> void:
	stage = Stage.FAILED
	player.set_input_enabled(false)
	audio.play_effect(&"fail")
	player.play_death_animation()
	var accepted := await hud.show_failure(reasons)
	if accepted and run_id == _generation: manager.restart_phase()

func _clear(run_id: int) -> void:
	stage = Stage.CLEARED
	player.set_input_enabled(false)
	audio.play_effect(&"next_phase")
	await hud.show_success()
	if run_id != _generation: return
	await get_tree().create_timer(0.15, false).timeout
	if run_id == _generation: manager.advance_phase()

func _exit_tree() -> void:
	_generation += 1
