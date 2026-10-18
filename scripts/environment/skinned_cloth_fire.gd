class_name SkinnedClothFire
extends Node3D
## Internal embers on the actual fabric, with ash emitted from its skinned surface.
const SURFACE = preload("res://shaders/savage_cloth_embers.gdshader")
const ASH = preload("res://shaders/savage_cloth_ash.gdshader")
const SAMPLE_COUNT := 192
const HEM_BELOW_WAIST := 32.0
const SHOULDER_ABOVE_NECK := 2.5
var _skeleton: Skeleton3D
var _dress: MeshInstance3D
var _skin: Skin
var _samples: Array[Dictionary] = []
var _bind_bones: Array[int] = []
var _transforms: Array[Transform3D] = []
var _points: Image
var _point_texture: ImageTexture
var _materials: Array[ShaderMaterial] = []
var _previous_materials: Array[Material] = []
var _lights: Array[OmniLight3D] = []
var _time := 0.0

func configure(dress: MeshInstance3D, skeleton: Skeleton3D) -> void:
	_dress = dress
	_skeleton = skeleton
	_skin = dress.skin
	for index in range(_skin.get_bind_count()):
		var bone := _skin.get_bind_bone(index)
		if bone < 0: bone = skeleton.find_bone(_skin.get_bind_name(index))
		_bind_bones.append(bone)
		_transforms.append(Transform3D.IDENTITY)
	_update_bind_transforms()
	_collect_surface_points()
	if _samples.is_empty():
		push_error("Não foi possível localizar tecido para as brasas da rainha.")
		return
	_points = Image.create(_samples.size(),1,false,Image.FORMAT_RGBAF)
	_fill_point_image()
	_point_texture = ImageTexture.create_from_image(_points)
	for surface in range(dress.mesh.get_surface_count()):
		var fabric := dress.get_active_material(surface) as StandardMaterial3D
		_previous_materials.append(dress.get_surface_override_material(surface))
		var embers := ShaderMaterial.new()
		embers.shader = SURFACE
		if fabric != null:
			embers.set_shader_parameter("fabric_color",fabric.albedo_color)
			embers.set_shader_parameter("fabric_roughness",fabric.roughness)
			embers.set_shader_parameter("fabric_metallic",fabric.metallic)
			embers.set_shader_parameter("has_fabric_texture",fabric.albedo_texture != null)
			embers.set_shader_parameter("fabric_texture",fabric.albedo_texture)
			embers.set_shader_parameter("has_normal_texture",fabric.normal_enabled and fabric.normal_texture != null)
			embers.set_shader_parameter("normal_texture",fabric.normal_texture)
			embers.set_shader_parameter("normal_strength",fabric.normal_scale)
			embers.set_shader_parameter("uv_scale",Vector2(fabric.uv1_scale.x,fabric.uv1_scale.y))
			embers.set_shader_parameter("uv_offset",Vector2(fabric.uv1_offset.x,fabric.uv1_offset.y))
		dress.set_surface_override_material(surface,embers)
		_materials.append(embers)
	_spawn_embers()
	for index in range(2):
		var light := OmniLight3D.new()
		light.light_color = Color(1.0,0.23,0.024)
		light.light_energy = 0.45
		light.light_cull_mask = 65
		light.omni_range = 11.0
		add_child(light)
		_lights.append(light)
	_process(0.0)

func _update_bind_transforms() -> void:
	for index in range(_bind_bones.size()):
		_transforms[index] = _skeleton.get_bone_global_pose(_bind_bones[index])*_skin.get_bind_pose(index)

func _deformed(sample: Dictionary) -> Vector3:
	var point := Vector3.ZERO
	for index in range(4):
		point += (_transforms[int(sample.bones[index])]*Vector3(sample.vertex))*float(sample.weights[index])
	return _skeleton.to_global(point)

func _collect_surface_points() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 14102026
	var lower := _skeleton.to_global(_skeleton.get_bone_global_pose(_skeleton.find_bone("spine")).origin).y-HEM_BELOW_WAIST
	var upper := _skeleton.to_global(_skeleton.get_bone_global_pose(_skeleton.find_bone("neck")).origin).y+SHOULDER_ABOVE_NECK
	var visible_torso := _skeleton.to_global(_skeleton.get_bone_global_pose(_skeleton.find_bone("spine1")).origin).y-2.0
	for surface in range(_dress.mesh.get_surface_count()):
		var arrays := _dress.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var selected := {}
		for attempt in range(6000):
			if _samples.size() >= SAMPLE_COUNT: break
			var index := rng.randi_range(0,vertices.size()-1)
			if selected.has(index): continue
			selected[index] = true
			var sample := {"vertex":vertices[index],"bones":bones.slice(index*4,index*4+4),"weights":weights.slice(index*4,index*4+4)}
			var world := _deformed(sample)
			# Dress mesh only: include the hem and shoulders, keeping face/crown separate.
			if world.y < lower or world.y > upper or world.z < _skeleton.global_position.z+3.5: continue
			# Keep most sparks above the board, with the remaining samples on the skirt.
			if _samples.size() < SAMPLE_COUNT*3/4 and world.y < visible_torso: continue
			_samples.append(sample)

func _fill_point_image() -> void:
	for index in range(_samples.size()):
		var point := to_local(_deformed(_samples[index]))
		_points.set_pixel(index,0,Color(point.x,point.y,point.z,1.0))

func _point_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINTS
	material.emission_point_texture = _point_texture
	material.emission_point_count = _samples.size()
	material.direction = Vector3.UP
	material.spread = 32.0
	material.scale_min = 0.6
	material.scale_max = 1.15
	return material

func _spawn_embers() -> void:
	var particles := GPUParticles3D.new()
	particles.name = "ClothEmbers"
	particles.amount = 128
	particles.lifetime = 3.8
	particles.preprocess = 2.0
	particles.local_coords = false
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visibility_aabb = AABB(Vector3(-25,-70,-60),Vector3(50,100,60))
	var process := _point_material()
	process.initial_velocity_min = 1.0
	process.initial_velocity_max = 2.2
	process.gravity = Vector3(0.12,0.26,0.10)
	process.angle_min = -180.0
	process.angle_max = 180.0
	process.angular_velocity_min = -95.0
	process.angular_velocity_max = 95.0
	particles.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.26,0.34)
	var material := ShaderMaterial.new()
	material.shader = ASH
	quad.material = material
	particles.draw_pass_1 = quad
	add_child(particles)

func _process(delta: float) -> void:
	if _points == null: return
	_time += delta
	_update_bind_transforms()
	_fill_point_image()
	_point_texture.update(_points)
	var waist := _skeleton.to_global(_skeleton.get_bone_global_pose(_skeleton.find_bone("spine")).origin)
	var collar := _skeleton.to_global(_skeleton.get_bone_global_pose(_skeleton.find_bone("neck")).origin)
	for material in _materials:
		material.set_shader_parameter("effect_time",_time)
		if material.shader == SURFACE:
			material.set_shader_parameter("lower_height",waist.y-HEM_BELOW_WAIST)
			material.set_shader_parameter("upper_height",collar.y+SHOULDER_ABOVE_NECK)
	for index in range(_lights.size()):
		_lights[index].global_position = waist+Vector3(-4 if index==0 else 4,5,8)
		_lights[index].light_energy = 0.45+sin(_time*2.3+index)*0.05

func _exit_tree() -> void:
	if not is_instance_valid(_dress): return
	for surface in range(_previous_materials.size()):
		_dress.set_surface_override_material(surface,_previous_materials[surface])
