class_name SavageEnemyPiece
extends EnemyPieceController

var _motion: Tween
const NEON_RED := Color(1.0,0.025,0.035,1.0)

func _create_edge_arrows() -> void:

	super._create_edge_arrows()
	for arrow in _arrows:
		var material := arrow.mesh.material as ShaderMaterial
		material.set_shader_parameter("neon_color",NEON_RED)
		material.set_shader_parameter("core_color",Vector3(1.0,0.20,0.14))

func show_planning(active_pair: bool) -> void:

	set_wave_active(active_pair)

func play_resolution() -> void:
	set_wave_active(false)
	var animator := _visual.find_child("Visual", true, false) if _visual != null else null
	if animator != null and animator.has_method("play_move"): animator.play_move(1.45)
	_motion = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_motion.tween_property(self, "position", _edge_target, 0.62)
	_motion.tween_interval(0.10)
	_motion.set_trans(Tween.TRANS_QUART)
	_motion.tween_property(self, "position", _final_target + Vector3.UP * 0.26, 0.92)
	_motion.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion.tween_property(self, "position", _final_target, 0.24)
	_motion.tween_callback(func(): movement_finished.emit(self))

func _exit_tree() -> void:
	if _motion != null and _motion.is_valid(): _motion.kill()
