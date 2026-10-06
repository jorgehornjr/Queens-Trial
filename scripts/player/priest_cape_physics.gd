extends Node3D
## World-space XPBD cloth cage. Pinning follows the animated shoulder mantle.
## Structural/shear/bending constraints preserve length while allowing folds.

const CAGE_PATH := "res://assets/models/characters/fallen_priest/cape_cage.json"
const STEP := 1.0 / 120.0
const ITERATIONS := 12
var skeleton: Skeleton3D
var points := PackedVector3Array()
var previous := PackedVector3Array()
var rest := PackedVector3Array()
var bone_ids := PackedInt32Array()
var constraints: Array[Vector4] = []
var lambdas := PackedFloat32Array()
var wind := Vector3.ZERO
var floor_enabled := true
var floor_transform := Transform3D.IDENTITY
var floor_half_extent := 19.0
var floor_height := 0.0
var _columns := 9
var _rows := 13
var _chest := -1
var _scale := 1.0
var _accumulator := 0.0
var _time := 0.0
var _last_anchor := Vector3.ZERO
var _chest_rest := Transform3D.IDENTITY
var _colliders: Array[Vector4] = []
var _rest_frames: Array[Basis] = []
var _pinned_count := 18
var last_step_usec := 0
var _previous_pin := Transform3D.IDENTITY
var _floor_inverse := Transform3D.IDENTITY
var _collision_candidates: Array[PackedInt32Array] = []
var _collider_bones := PackedInt32Array()
var _collider_ends := PackedInt32Array()
var _collider_radii := PackedFloat32Array()
var _bone_rests: Array[Transform3D] = []
var _frame_inverses: Array[Basis] = []
var _constraint_a := PackedInt32Array()
var _constraint_b := PackedInt32Array()
var _constraint_rest := PackedFloat32Array()
var _constraint_alpha := PackedFloat32Array()
var _constraint_mass_a := PackedFloat32Array()
var _constraint_mass_b := PackedFloat32Array()
var _native_solver: RefCounted
var _native_state := PackedByteArray()


func configure(target: Skeleton3D) -> void:
	skeleton = target
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CAGE_PATH))
	_columns = int(data.columns)
	_rows = int(data.rows)
	_pinned_count = _columns * 2
	_scale = skeleton.global_basis.get_scale().x
	_chest = skeleton.find_bone("Chest")
	_chest_rest = skeleton.get_bone_global_rest(_chest)
	for index in range(data.points.size()):
		var p: Array = data.points[index]
		rest.append(Vector3(float(p[0]), float(p[1]), float(p[2])))
		bone_ids.append(skeleton.find_bone(data.bones[index]))
	for index in range(rest.size()):
		var frame := _surface_frame(rest, index)
		_rest_frames.append(frame)
		_frame_inverses.append(frame.inverse())
		_bone_rests.append(skeleton.get_bone_global_rest(bone_ids[index]))
		_collision_candidates.append(PackedInt32Array())
	for def in [["Pelvis", 0.11], ["Spine", 0.12], ["Chest", 0.12], ["Neck", 0.11], ["Head", 0.14], ["UpperArm_L", 0.09], ["UpperArm_R", 0.09], ["Thigh_L", 0.095], ["Thigh_R", 0.095], ["Shin_L", 0.075], ["Shin_R", 0.075]]:
		var id := skeleton.find_bone(def[0])
		_collider_bones.append(id)
		var children := skeleton.get_bone_children(id)
		_collider_ends.append(children[0] if not children.is_empty() else -1)
		_collider_radii.append(float(def[1]) * _scale)
	for r in range(_rows):
		for c in range(_columns):
			var i := r * _columns + c
			if c + 1 < _columns: _link(i, i + 1, 0.00000005)
			if r + 1 < _rows: _link(i, i + _columns, 0.00000005)
			if c + 1 < _columns and r + 1 < _rows:
				_link(i, i + _columns + 1, 0.0000005)
				_link(i + 1, i + _columns, 0.0000005)
			if c + 2 < _columns: _link(i, i + 2, 0.002)
			if r + 2 < _rows: _link(i, i + _columns * 2, 0.002)
	lambdas.resize(constraints.size())
	if ClassDB.class_exists("PriestCapeSolver") and not "--cape-script" in OS.get_cmdline_user_args():
		_native_solver = ClassDB.instantiate("PriestCapeSolver")
	reset_cloth()
	# Run after AnimationPlayer and the player's platform transform.
	process_priority = 50


func _link(a: int, b: int, compliance: float) -> void:
	constraints.append(Vector4(a, b, rest[a].distance_to(rest[b]) * _scale, compliance))
	_constraint_a.append(a)
	_constraint_b.append(b)
	_constraint_rest.append(rest[a].distance_to(rest[b]) * _scale)
	_constraint_alpha.append(compliance / (STEP * STEP))
	_constraint_mass_a.append(0.0 if a < _pinned_count else 1.0)
	_constraint_mass_b.append(0.0 if b < _pinned_count else 1.0)


func reset_cloth() -> void:
	if skeleton == null: return
	skeleton.clear_bones_global_pose_override()
	points.clear()
	for p in rest: points.append(skeleton.to_global(p))
	previous = points.duplicate()
	if _native_solver != null:
		_native_state.resize(12)
		_native_state.encode_u32(0, points.size())
		_native_state.encode_u32(4, _pinned_count)
		_native_state.encode_u32(8, constraints.size())
		_native_state.append_array(PackedVector4Array(constraints).to_byte_array())
		_native_state.append_array(points.to_byte_array())
		_native_state.append_array(previous.to_byte_array())
	_last_anchor = skeleton.global_position
	_previous_pin = skeleton.global_transform * skeleton.get_bone_global_pose_no_override(_chest) * _chest_rest.affine_inverse()
	_accumulator = 0.0
	wind = Vector3.ZERO


func _physics_process(delta: float) -> void:
	if skeleton == null or points.is_empty(): return
	var begin := Time.get_ticks_usec()
	if skeleton.global_position.distance_to(_last_anchor) > 10.0 * _scale:
		reset_cloth()
	_last_anchor = skeleton.global_position
	_time += delta
	_accumulator += minf(delta, 1.0 / 30.0)
	_floor_inverse = floor_transform.affine_inverse()
	_update_colliders()
	var pin_transform := skeleton.global_transform * skeleton.get_bone_global_pose_no_override(_chest) * _chest_rest.affine_inverse()
	var count := maxi(1, int(_accumulator / STEP))
	var step_index := 0
	while _accumulator >= STEP:
		step_index += 1
		_substep(_previous_pin.interpolate_with(pin_transform, float(step_index) / count))
		_accumulator -= STEP
	_previous_pin = pin_transform
	if _native_solver != null:
		var offset := 12 + constraints.size() * 16
		var coordinates := _native_state.slice(offset).to_float32_array()
		for i in range(points.size()):
			points[i] = Vector3(coordinates[i*3], coordinates[i*3+1], coordinates[i*3+2])
			var pi := (i+points.size())*3
			previous[i] = Vector3(coordinates[pi], coordinates[pi+1], coordinates[pi+2])
	_apply_skin(pin_transform)
	last_step_usec = Time.get_ticks_usec() - begin


func _substep(pin_transform: Transform3D) -> void:
	# Damped Verlet plus air drag: movement creates relative wind automatically.
	var gust := Vector3(sin(_time * 1.7) * 0.23, 0.05, cos(_time * 1.13) * 0.30) * _scale
	if _native_solver != null:
		var air := wind + gust
		var params := PackedFloat32Array([air.x, air.y, air.z, 16.0*_scale, _scale, 1.0 if floor_enabled else 0.0, floor_half_extent, floor_height])
		for transform in [floor_transform, _floor_inverse]:
			for vector in [transform.basis.x, transform.basis.y, transform.basis.z, transform.origin]:
				params.append_array(PackedFloat32Array([vector.x,vector.y,vector.z]))
		var anchors := PackedVector3Array()
		for i in range(_pinned_count): anchors.append(pin_transform * rest[i])
		var frame := PackedByteArray()
		frame.resize(4)
		frame.encode_u32(0,_colliders.size())
		frame.append_array(params.to_byte_array())
		frame.append_array(anchors.to_byte_array())
		frame.append_array(PackedVector4Array(_colliders).to_byte_array())
		_native_state = _native_solver.call("advance",_native_state,frame)
		return
	for i in range(points.size()):
		if i < _pinned_count:
			points[i] = pin_transform * rest[i]
			previous[i] = points[i]
			continue
		var old := points[i]
		var velocity := (points[i] - previous[i]) / STEP
		var air := (wind + gust - velocity) * 0.65
		# The encounter uses 32 world units/s² and this model has scale 2.
		var acceleration := Vector3.DOWN * 16.0 * _scale + air
		points[i] += (points[i] - previous[i]) * 0.997 + acceleration * STEP * STEP
		previous[i] = old
	# Candidate spheres are selected once per substep, with padding for the
	# subsequent constraint corrections. Distant limbs do not need 12 retests.
	for i in range(_pinned_count, points.size()):
		var candidates := PackedInt32Array()
		var point := points[i]
		for ci in range(_colliders.size()):
			var sphere := _colliders[ci]
			var extent := sphere.w + .45 * _scale
			if absf(point.x-sphere.x) <= extent and absf(point.y-sphere.y) <= extent and absf(point.z-sphere.z) <= extent:
				candidates.append(ci)
		_collision_candidates[i] = candidates
	lambdas.fill(0.0)
	for iteration in range(ITERATIONS):
		for ci in range(constraints.size()):
			var a := _constraint_a[ci]
			var b := _constraint_b[ci]
			var wa := _constraint_mass_a[ci]
			var wb := _constraint_mass_b[ci]
			if wa + wb == 0.0: continue
			var diff := points[a] - points[b]
			var length := diff.length()
			if length < 0.000001: continue
			var alpha := _constraint_alpha[ci]
			var correction := (-(length - _constraint_rest[ci]) - alpha * lambdas[ci]) / (wa + wb + alpha)
			lambdas[ci] += correction
			var normal := diff / length
			points[a] += normal * correction * wa
			points[b] -= normal * correction * wb
		if iteration % 2 == 1:
			for i in range(_pinned_count, points.size()): _collide(i)


func _update_colliders() -> void:
	_colliders.clear()
	for ci in range(_collider_bones.size()):
		var id := _collider_bones[ci]
		var transform := skeleton.global_transform * skeleton.get_bone_global_pose_no_override(id)
		var center := transform.origin
		# Multiple samples approximate animated capsules along each limb.
		var end := center
		if _collider_ends[ci] >= 0:
			end = skeleton.to_global(skeleton.get_bone_global_pose_no_override(_collider_ends[ci]).origin)
		elif id == skeleton.find_bone("Head"):
			end = center + skeleton.global_basis.y * 0.24
		var samples := [0.0] if center.is_equal_approx(end) else [0.0, 0.33, 0.66]
		for t in samples:
			var p := center.lerp(end, t)
			_colliders.append(Vector4(p.x, p.y, p.z, _collider_radii[ci]))


func _collide(i: int) -> void:
	for ci in _collision_candidates[i]:
		var sphere := _colliders[ci]
		var center := Vector3(sphere.x, sphere.y, sphere.z)
		var diff := points[i] - center
		var squared := diff.length_squared()
		if squared < sphere.w * sphere.w and squared > 0.000000001:
			var distance := sqrt(squared)
			points[i] = center + diff / distance * sphere.w
	if floor_enabled:
		var local := _floor_inverse * points[i]
		if absf(local.x) < floor_half_extent and absf(local.z) < floor_half_extent and local.y < floor_height + 0.018 * _scale:
			local.y = floor_height + 0.018 * _scale
			points[i] = floor_transform * local


func _apply_skin(pin_transform: Transform3D) -> void:
	var inverse := skeleton.global_transform.affine_inverse()
	var chest_motion := (inverse * pin_transform).basis
	var local_points := PackedVector3Array()
	for point in points: local_points.append(inverse * point)
	for i in range(points.size()):
		var pose := _bone_rests[i]
		if i < _pinned_count:
			pose.basis = chest_motion * pose.basis
		else:
			pose.basis = _surface_frame(local_points, i) * _frame_inverses[i] * pose.basis
		pose.origin = inverse * points[i]
		skeleton.set_bone_global_pose_override(bone_ids[i], pose, 1.0, true)


func _surface_frame(vertices: PackedVector3Array, index: int) -> Basis:
	var row := index / _columns
	var col := index % _columns
	var left := row * _columns + maxi(0, col - 1)
	var right := row * _columns + mini(_columns - 1, col + 1)
	var up := maxi(0, row - 1) * _columns + col
	var down := mini(_rows - 1, row + 1) * _columns + col
	var x := (vertices[right] - vertices[left]).normalized()
	var y := (vertices[up] - vertices[down]).normalized()
	var z := x.cross(y).normalized()
	if z.length_squared() < 0.01: return Basis.IDENTITY
	y = z.cross(x).normalized()
	return Basis(x, y, z)


func max_stretch_ratio() -> float:
	var maximum := 1.0
	for link in constraints:
		if link.w < 0.001:
			maximum = maxf(maximum, points[int(link.x)].distance_to(points[int(link.y)]) / link.z)
	return maximum
