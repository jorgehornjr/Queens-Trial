class_name ThirdPersonCamera
extends Node3D

@export var target_path: NodePath = NodePath("../Player")
@export_range(0.5, 6.0, 0.1) var look_height := 2.2
@export_range(1.0, 20.0, 0.1) var follow_smoothing := 8.0
@export_range(1.0, 20.0, 0.1) var rotation_smoothing := 7.0

var _target: Node3D
var _tracking_started := false


func _ready() -> void:
	process_priority = 50
	if target_path.is_empty():
		target_path = NodePath("../Player")
	_target = get_node_or_null(target_path) as Node3D
	if _target == null:
		push_error("ThirdPersonCamera precisa de um alvo Node3D válido.")
		set_process(false)
		return

	if _target.has_signal("cell_changed"):
		_target.cell_changed.connect(_on_target_cell_changed)
	call_deferred("_begin_tracking_if_needed")


func _process(delta: float) -> void:
	if _target == null:
		return

	var position_weight := 1.0 - exp(-follow_smoothing * delta)
	var rotation_weight := 1.0 - exp(-rotation_smoothing * delta)
	var desired_position := _target.global_position + Vector3.UP * look_height
	global_position = global_position.lerp(desired_position, position_weight)
	rotation.y = lerp_angle(rotation.y, _target.global_rotation.y, rotation_weight)


func snap_to_target() -> void:
	if _target == null:
		return
	global_position = _target.global_position + Vector3.UP * look_height
	rotation.y = _target.global_rotation.y
	_tracking_started = true


func _begin_tracking_if_needed() -> void:
	if not _tracking_started:
		snap_to_target()


func _on_target_cell_changed(_cell: Vector2i, _previous_cell: Vector2i) -> void:
	if not _tracking_started:
		snap_to_target()
