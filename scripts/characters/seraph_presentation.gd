extends Node3D
## Epic encounter figure staged just beyond the north edge of the board.

const CHARACTER_LAYER := 64

@export var player_path := NodePath("../Player")
@export_range(0.0, 12.0, 0.1) var orb_world_height_offset := 2.0

var _skeleton: Skeleton3D
var _player: Node3D
var _spine_bones: Array[int] = []
var _ornament_eye_bones: Array[int] = []
var _base_bone_rotations := {}
var _base_bone_scales := {}
var _head_bone := -1
var _neck_bone := -1
var _head_pose := Quaternion.IDENTITY
var _neck_pose := Quaternion.IDENTITY
var _elapsed := 0.0

const HEAD_CENTER_YAW := 0.0
const PLAYER_YAW_LIMIT := deg_to_rad(22.0)
const HEAD_TRACK_SPEED := 3.2


func _ready() -> void:
	for mesh: MeshInstance3D in $Model.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = CHARACTER_LAYER
	_hide_original_orb()
	_configure_character_appearance()
	_player = get_node_or_null(player_path) as Node3D
	_skeleton = $Model.find_child("Skeleton3D", true, false) as Skeleton3D
	_configure_procedural_animation()
	call_deferred("_raise_orb_vertically")


func _raise_orb_vertically() -> void:
	var orb := get_node_or_null("Model/Seraph/Skeleton3D/OrbAttachment/AstraiaOrb") as Node3D
	if orb == null or orb_world_height_offset <= 0.0:
		return
	var attachment := orb.get_parent() as Node3D
	# The attachment axes are rotated with the queen. Convert a world-up offset to
	# the bone's local space so height changes never push the orb into the board.
	orb.position += attachment.global_basis.inverse() * Vector3.UP * orb_world_height_offset


func _hide_original_orb() -> void:
	for node_name in ["Eye", "Fire", "Wheel1", "Wheel2", "Wheel3"]:
		var part := $Model.find_child(node_name, true, false) as MeshInstance3D
		if part != null:
			part.visible = false
			part.queue_free()


func _configure_character_appearance() -> void:
	var straps := $Model.find_child("Straps", true, false) as MeshInstance3D
	if straps != null:
		straps.visible = false
		straps.queue_free()
	var dress := $Model.find_child("Dress", true, false) as MeshInstance3D
	if dress == null or dress.mesh == null:
		return
	for surface in range(dress.mesh.get_surface_count()):
		var source := dress.get_active_material(surface) as StandardMaterial3D
		# Keep imported textures shared. Deep-copying compressed embedded textures can
		# duplicate an invalid texture RID and trigger `Parameter "tex" is null`.
		var black_fabric := source.duplicate(false) as StandardMaterial3D if source != null else StandardMaterial3D.new()
		black_fabric.albedo_color = Color(0.014, 0.014, 0.020, 1.0)
		black_fabric.metallic = 0.04
		black_fabric.roughness = 0.78
		dress.set_surface_override_material(surface, black_fabric)


func _configure_procedural_animation() -> void:
	if _skeleton == null:
		push_warning("A Seraph não possui Skeleton3D para animação procedural.")
		return
	for bone_name in ["spine", "spine1", "spine2"]:
		var bone_index := _skeleton.find_bone(bone_name)
		if bone_index >= 0:
			_spine_bones.append(bone_index)
			_remember_base_pose(bone_index)
	for number in range(1, 25):
		var bone_index := _skeleton.find_bone(str(number))
		if bone_index >= 0:
			_ornament_eye_bones.append(bone_index)
			_remember_base_pose(bone_index)
	_head_bone = _skeleton.find_bone("head")
	_neck_bone = _skeleton.find_bone("neck")
	if _neck_bone >= 0:
		_remember_base_pose(_neck_bone)
		_neck_pose = _base_bone_rotations[_neck_bone]
	if _head_bone >= 0:
		_remember_base_pose(_head_bone)
		_head_pose = _base_bone_rotations[_head_bone]
	_snap_head_to_player()


func _process(delta: float) -> void:
	if _skeleton == null or _spine_bones.is_empty():
		return
	_elapsed += delta
	_animate_breathing()
	_animate_ornament_eyes()
	_animate_head_tracking(delta)


func _animate_breathing() -> void:
	var breath := sin(_elapsed * 1.45)
	for index in range(_spine_bones.size()):
		var influence := float(index + 1) / float(_spine_bones.size())
		var bone := _spine_bones[index]
		var expansion := breath * 0.006 * influence
		var base_scale: Vector3 = _base_bone_scales[bone]
		_skeleton.set_bone_pose_scale(
			bone,
			base_scale * Vector3(1.0 + expansion, 1.0 + expansion * 0.35, 1.0 + expansion)
		)


func _animate_ornament_eyes() -> void:
	for index in range(_ornament_eye_bones.size()):
		var cycle := fmod(_elapsed + float(index % 8) * 0.19 + float(index / 8) * 0.71, 4.6)
		var blink := pow(sin(clampf(cycle / 0.30, 0.0, 1.0) * PI), 8.0) if cycle < 0.30 else 0.0
		var bone := _ornament_eye_bones[index]
		var base_scale: Vector3 = _base_bone_scales[bone]
		_skeleton.set_bone_pose_scale(bone, base_scale * Vector3(1.0, 1.0, lerpf(1.0, 0.08, blink)))


func _animate_head_tracking(delta: float) -> void:
	if _head_bone < 0 or _neck_bone < 0 or not is_instance_valid(_player):
		return
	var yaw := _target_yaw()
	var neck_base: Quaternion = _base_bone_rotations[_neck_bone]
	var head_base: Quaternion = _base_bone_rotations[_head_bone]
	var desired_neck := neck_base * Quaternion(Vector3.UP, yaw * 0.46)
	var desired_head := head_base * Quaternion(Vector3.UP, yaw * 0.54)
	var weight := 1.0 - exp(-HEAD_TRACK_SPEED * delta)
	_neck_pose = _neck_pose.slerp(desired_neck, weight)
	_head_pose = _head_pose.slerp(desired_head, weight)
	_skeleton.set_bone_pose_rotation(_neck_bone, _neck_pose)
	_skeleton.set_bone_pose_rotation(_head_bone, _head_pose)


func _snap_head_to_player() -> void:
	if _head_bone < 0 or _neck_bone < 0 or not is_instance_valid(_player):
		return
	var yaw := _target_yaw()
	var neck_base: Quaternion = _base_bone_rotations[_neck_bone]
	var head_base: Quaternion = _base_bone_rotations[_head_bone]
	_neck_pose = neck_base * Quaternion(Vector3.UP, yaw * 0.46)
	_head_pose = head_base * Quaternion(Vector3.UP, yaw * 0.54)
	_skeleton.set_bone_pose_rotation(_neck_bone, _neck_pose)
	_skeleton.set_bone_pose_rotation(_head_bone, _head_pose)


func _target_yaw() -> float:
	var local_direction := global_transform.basis.inverse() * (_player.global_position - global_position)
	var player_yaw := clampf(atan2(local_direction.x, local_direction.z), -PLAYER_YAW_LIMIT, PLAYER_YAW_LIMIT)
	return HEAD_CENTER_YAW + player_yaw


func _remember_base_pose(bone: int) -> void:
	_base_bone_rotations[bone] = _skeleton.get_bone_pose_rotation(bone)
	_base_bone_scales[bone] = _skeleton.get_bone_pose_scale(bone)
