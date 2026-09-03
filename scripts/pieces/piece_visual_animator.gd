class_name PieceVisualAnimator
extends Node3D

@export_category("Idle Presentation")
@export_range(0.0, 0.20, 0.005) var idle_float_height := 0.045
@export_range(0.1, 6.0, 0.1) var idle_float_speed := 1.35
@export_range(-45.0, 45.0, 0.5) var halo_turn_degrees_per_second := 15.0

@export_category("Movement Presentation")
@export_range(0.0, 0.8, 0.01) var move_lift_height := 0.30
@export_range(0.0, 12.0, 0.1) var move_lean_degrees := 4.0

var _idle_time := 0.0
var _motion_lift := 0.0
var _motion_lean := 0.0
var _motion_scale := 1.0
var _motion_tween: Tween
var halo_pivot: Node3D


func _ready() -> void:
	halo_pivot = find_child("HaloRotation", true, false) as Node3D


func _process(delta: float) -> void:
	_idle_time += delta
	if halo_pivot != null:
		# O eixo Y local do pivô é perpendicular ao plano do halo.
		halo_pivot.rotate_object_local(Vector3.UP, deg_to_rad(halo_turn_degrees_per_second) * delta)
	position.y = sin(_idle_time * idle_float_speed) * idle_float_height + _motion_lift
	rotation.x = _motion_lean
	scale = Vector3.ONE * _motion_scale


func play_move(duration: float) -> void:
	_stop_motion_tween()
	_motion_lift = 0.0
	_motion_lean = 0.0
	_motion_scale = 1.0

	var rise_duration := duration * 0.42
	var settle_duration := duration - rise_duration
	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_SINE)
	_motion_tween.set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "_motion_lift", move_lift_height, rise_duration)
	_motion_tween.parallel().tween_property(self, "_motion_lean", deg_to_rad(-move_lean_degrees), rise_duration)
	_motion_tween.parallel().tween_property(self, "_motion_scale", 0.975, rise_duration)
	_motion_tween.set_ease(Tween.EASE_IN_OUT)
	_motion_tween.tween_property(self, "_motion_lift", 0.0, settle_duration)
	_motion_tween.parallel().tween_property(self, "_motion_lean", 0.0, settle_duration)
	_motion_tween.parallel().tween_property(self, "_motion_scale", 1.0, settle_duration)


func play_blocked() -> void:
	_stop_motion_tween()
	_motion_lift = 0.0
	_motion_lean = 0.0
	_motion_scale = 1.0
	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_BACK)
	_motion_tween.set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "_motion_lean", deg_to_rad(3.0), 0.10)
	_motion_tween.parallel().tween_property(self, "_motion_scale", 0.965, 0.10)
	_motion_tween.set_trans(Tween.TRANS_SINE)
	_motion_tween.set_ease(Tween.EASE_IN_OUT)
	_motion_tween.tween_property(self, "_motion_lean", 0.0, 0.16)
	_motion_tween.parallel().tween_property(self, "_motion_scale", 1.0, 0.16)


func reset_presentation() -> void:
	_stop_motion_tween()
	_motion_lift = 0.0
	_motion_lean = 0.0
	_motion_scale = 1.0


func _stop_motion_tween() -> void:
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_tween = null
