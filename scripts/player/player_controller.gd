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
var input_enabled := false
var _initialized := false
var _board: Node
var _move_tween: Tween
var _animation_player: AnimationPlayer
var _animation_state := &""

func _ready() -> void:
	call_deferred("_initialize_on_board")
	call_deferred("_discover_animation_player")


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	if event.is_action_pressed("restart_phase"):
		restart_requested.emit()
		get_viewport().set_input_as_handled()
		return
	if not input_enabled:
		return
	for action in [&"move_up", &"move_left", &"move_down", &"move_right"]:
		if not event.is_action_pressed(action):
			continue
		var view_camera := get_viewport().get_camera_3d()
		var view_yaw := view_camera.global_rotation.y if view_camera != null else 0.0
		_try_move(camera_direction_for_action(view_yaw, action))
		get_viewport().set_input_as_handled()
		return


func _physics_process(_delta: float) -> void:
	if _animation_state == &"death":
		return
	# Movement is deliberately grid-locked and driven by one tween per key press.
	# Keep physics processing only for the non-looping death state guard.
	if not movement_locked:
		_set_animation_state(false)


func reset_to_start() -> void:
	if not _initialized:
		return
	if _move_tween != null:
		_move_tween.kill()
		_move_tween = null
	var previous_cell := current_cell
	current_cell = starting_cell
	facing_direction = Vector2i.UP
	movement_locked = false
	input_enabled = false
	position = _board.grid_to_world(current_cell) + Vector3(0.0, surface_offset, 0.0)
	rotation.y = _yaw_for_direction(facing_direction)
	_set_animation_state(false)
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
	if not _initialized or movement_locked or not input_enabled:
		return

	var target_cell := current_cell + direction
	if not _board.can_player_enter(target_cell):
		move_rejected.emit(target_cell)
		return

	var previous_cell := current_cell
	current_cell = target_cell
	facing_direction = direction
	movement_locked = true
	_set_animation_state(true)

	var tween := create_tween()
	_move_tween = tween
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


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled and _initialized:
		position = _board.grid_to_world(current_cell) + Vector3(0.0, surface_offset, 0.0)
		_set_animation_state(false)


func _on_move_finished(previous_cell: Vector2i) -> void:
	_move_tween = null
	rotation.y = wrapf(rotation.y, -PI, PI)
	movement_locked = false
	_set_animation_state(false)
	cell_changed.emit(current_cell, previous_cell)


func _discover_animation_player() -> void:
	_animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	_set_animation_state(false)


func play_death_animation() -> void:
	input_enabled = false
	movement_locked = true
	_animation_state = &"death"
	if _animation_player == null:
		await get_tree().create_timer(2.15).timeout
		return
	var animation_name := _find_animation(PackedStringArray(["standing_death", "death"]))
	if animation_name == &"":
		await get_tree().create_timer(2.15).timeout
		return
	var animation := _animation_player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_NONE
	_animation_player.play(animation_name, 0.12)
	while _animation_player.is_playing() and _animation_player.current_animation == animation_name:
		await get_tree().process_frame


func _set_animation_state(moving: bool) -> void:
	var desired := &"move" if moving else &"idle"
	if desired == _animation_state:
		return
	_animation_state = desired
	if _animation_player == null:
		return
	var hints := PackedStringArray(["jogging", "jog", "run", "walk"]) if moving else PackedStringArray(["breathing", "idle"])
	var animation_name := _find_animation(hints)
	if animation_name == &"":
		return
	var animation := _animation_player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR
	_animation_player.play(animation_name, 0.16)


func _find_animation(hints: PackedStringArray) -> StringName:
	if _animation_player == null:
		return &""
	for animation_name in _animation_player.get_animation_list():
		var lower_name := String(animation_name).to_lower()
		for hint in hints:
			if hint in lower_name:
				return animation_name
	return &""


static func camera_direction_for_action(camera_yaw: float, action: StringName) -> Vector2i:
	# The game remains cardinal/cell-based, even when the view is diagonal.
	# Quantize the camera, never the player's last heading; exact ties use the next sector.
	var sector := posmod(int(floor((camera_yaw + PI / 4.0) / (PI / 2.0))), 4)
	var forwards: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]
	return relative_direction_for_action(forwards[sector], action)


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
