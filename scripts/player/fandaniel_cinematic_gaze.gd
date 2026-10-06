extends SkeletonModifier3D
## A small chin lift layered after the native slow walk, including the hood.

var lift := 0.0

func _process_modification_with_delta(_delta: float) -> void:
	if lift <= 0.0001: return
	var skeleton := get_skeleton()
	for item in [["j_kubi", 4.0], ["j_kao", 8.0]]:
		var bone := skeleton.find_bone(item[0])
		if bone < 0: continue
		var pose := skeleton.get_bone_global_pose(bone)
		var parent := skeleton.get_bone_parent(bone)
		var parent_basis := skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
		# +Z is the model's facing axis; a negative X rotation lifts the chin.
		var raised := Basis(Vector3.RIGHT, -deg_to_rad(float(item[1])) * lift) * pose.basis
		# Godot poses are parent-relative transforms, not deltas from rest.
		var local := parent_basis.inverse() * raised
		skeleton.set_bone_pose_rotation(bone, local.orthonormalized().get_rotation_quaternion())
