class_name GridPlayer
extends Node3D

signal cell_changed(cell: Vector2i, previous_cell: Vector2i)
signal move_rejected(target_cell: Vector2i)
signal restart_requested

@export var board_path: NodePath
@export var starting_cell := Vector2i(0, 4)
@export_range(0.05, 2.0, 0.01) var move_duration := 0.62
@export_range(0.05, 1.0, 0.01) var turn_duration := 0.34
@export_range(0.0, 2.0, 0.01) var surface_offset := 0.72

var current_cell := Vector2i.ZERO
var facing_direction := Vector2i.UP
var movement_locked := false
var _initialized := false
var _board: Node


func _ready() -> void:
	call_deferred("_initialize_on_board")


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	if event.is_action_pressed("restart_phase"):
		restart_requested.emit()
		get_viewport().set_input_as_handled()
		return

	var action := &""
	if event.is_action_pressed("move_up"):
		action = &"move_up"
	elif event.is_action_pressed("move_left"):
		action = &"move_left"
	elif event.is_action_pressed("move_down"):
		action = &"move_down"
	elif event.is_action_pressed("move_right"):
		action = &"move_right"
	else:
		return

	_try_move(relative_direction_for_action(facing_direction, action))
	get_viewport().set_input_as_handled()


func reset_to_start() -> void:
	if not _initialized:
		return
	var previous_cell := current_cell
	current_cell = starting_cell
	facing_direction = Vector2i.UP
	movement_locked = false
	position = _board.grid_to_world(current_cell) + Vector3(0.0, surface_offset, 0.0)
	rotation.y = _yaw_for_direction(facing_direction)
	cell_changed.emit(current_cell, previous_cell)


func _initialize_on_board() -> void:
	_board = get_node_or_null(board_path)
	if _board == null:
		push_error("GridPlayer precisa de um Board3D válido.")
		return
	if not _board.can_player_enter(starting_cell):
		push_error("Casa inicial inválida para o jogador: %s" % starting_cell)
		return

	current_cell = starting_cell
	facing_direction = Vector2i.UP
	position = _board.grid_to_world(current_cell) + Vector3(0.0, surface_offset, 0.0)
	rotation.y = _yaw_for_direction(facing_direction)
	_initialized = true
	cell_changed.emit(current_cell, current_cell)


func _try_move(direction: Vector2i) -> void:
	if not _initialized or movement_locked:
		return

	var target_cell := current_cell + direction
	if not _board.can_player_enter(target_cell):
		move_rejected.emit(target_cell)
		return

	var previous_cell := current_cell
	current_cell = target_cell
	facing_direction = direction
	movement_locked = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		self,
		"position",
		_board.grid_to_world(current_cell) + Vector3(0.0, surface_offset, 0.0),
		move_duration
	)
	var desired_yaw := _yaw_for_direction(facing_direction)
	var shortest_turn := wrapf(desired_yaw - rotation.y, -PI, PI)
	tween.tween_property(
		self,
		"rotation:y",
		rotation.y + shortest_turn,
		minf(turn_duration, move_duration)
	)
	tween.finished.connect(_on_move_finished.bind(previous_cell))


func _on_move_finished(previous_cell: Vector2i) -> void:
	rotation.y = wrapf(rotation.y, -PI, PI)
	movement_locked = false
	cell_changed.emit(current_cell, previous_cell)


static func relative_direction_for_action(facing: Vector2i, action: StringName) -> Vector2i:
	match action:
		&"move_up":
			return facing
		&"move_down":
			return -facing
		&"move_left":
			return Vector2i(facing.y, -facing.x)
		&"move_right":
			return Vector2i(-facing.y, facing.x)
		_:
			return Vector2i.ZERO


static func _yaw_for_direction(direction: Vector2i) -> float:
	return atan2(-float(direction.x), -float(direction.y))
