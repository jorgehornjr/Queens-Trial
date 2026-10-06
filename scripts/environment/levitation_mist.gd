extends Node3D
## The standalone board editor has no WorldEnvironment. Keep the raymarched
## preview there; create the volumetric component only in the running world.

@export var fog_material: ShaderMaterial
@export var fog_size := Vector3(72, 14, 72)
var _volume: FogVolume
var _board: Node3D
var _rest_transform: Transform3D
var _rest_world_basis: Basis
var _nebula_material: ShaderMaterial
var _follow_tilt := false

func _ready() -> void:
	_board = get_parent() as Node3D
	_rest_transform = transform
	_rest_world_basis = global_basis
	_nebula_material = $NebulaVolume.material_override.duplicate() as ShaderMaterial
	$NebulaVolume.material_override = _nebula_material
	fog_material = fog_material.duplicate() as ShaderMaterial
	var volume := FogVolume.new()
	volume.name = "VolumetricMist"
	volume.size = fog_size
	volume.material = fog_material
	add_child(volume)
	_volume = volume
	set_process(false)


func set_follow_tilt(enabled: bool) -> void:
	_follow_tilt = enabled
	var pose := global_transform
	top_level = enabled
	if enabled:
		global_transform = pose
	else:
		transform = _rest_transform
	fog_material.set_shader_parameter("follow_tilt", enabled)
	_update_fog_transform()
	set_process(enabled)


func _process(delta: float) -> void:
	if not _follow_tilt or _board == null:
		return
	# Clouds follow only part of the board's roll, with inertia rather than a hinge.
	var board_orientation := _board.global_basis.get_rotation_quaternion() * _rest_transform.basis.get_rotation_quaternion()
	var orientation := _rest_world_basis.get_rotation_quaternion().slerp(board_orientation, 0.55)
	var target := Transform3D(Basis(orientation), _board.to_global(_rest_transform.origin))
	global_transform = global_transform.interpolate_with(target, 1.0 - exp(-delta * 5.0))
	_update_fog_transform()


func _update_fog_transform() -> void:
	fog_material.set_shader_parameter("world_to_mist", global_transform.affine_inverse())
