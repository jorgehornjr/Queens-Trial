class_name QueenDeparture
extends Node3D


const SURFACE := preload("res://shaders/queen_aether_surface.gdshader")
const MOTES := preload("res://shaders/queen_aether_motes.gdshader")
const NEBULA := preload("res://shaders/queen_reflection_nebula.gdshader")
const FRAGMENT := preload("res://shaders/queen_orb_fragment.gdshader")
const RELEASE := preload("res://shaders/orb_release.gdshader")
const FLOW := preload("res://assets/effects/queen_departure/ysayle_flow.png")
const GLOW := preload("res://assets/effects/queen_departure/ysayle_glow.png")
const STARS := preload("res://assets/effects/queen_departure/ysayle_stars.png")
const FILAMENTS := preload("res://assets/effects/queen_departure/ysayle_filaments.png")
const DISSOLVE_LENGTH := 20.0
var _queen: Node3D
var _previous: Array[Dictionary] = []
var _surfaces: Array[ShaderMaterial] = []
var _motes: Array[ShaderMaterial] = []
var _fragments: Array[Dictionary] = []
var _waves: Array[MeshInstance3D] = []
var _core: MeshInstance3D
var _light: OmniLight3D
var _nebula: MeshInstance3D
var _cluster: MultiMeshInstance3D
var _nebula_material: ShaderMaterial
var _cluster_material: ShaderMaterial
var _burst_origin := Vector3.ZERO
var _bottom := -20.0
var _height := 50.0
var _center := Vector3.ZERO
var _fractured := false
var prepared := false

func configure(queen: Node3D) -> void:
	_queen = queen
	_build_release()
	prepare_dissolve()
	set_burst_age(-1.0)
	set_dissolve_age(-1.0)

func prepare_dissolve() -> void:
	if prepared: return
	prepared = true
	var points: Array[Vector3] = []
	var triangles: Array[Dictionary] = []
	var total_area := 0.0
	var orb := _queen.get_node("Model/Seraph/Skeleton3D/OrbAttachment/AstraiaOrb")
	var skeleton: Skeleton3D = _queen._skeleton
	var rng := RandomNumberGenerator.new()
	rng.seed = 18102026
	for mesh: MeshInstance3D in _queen.get_node("Model").find_children("*","MeshInstance3D",true,false):
		if not mesh.is_visible_in_tree() or orb.is_ancestor_of(mesh): continue
		var binds: Array[Transform3D] = []
		if mesh.skin != null:
			for index in range(mesh.skin.get_bind_count()):
				var bone := mesh.skin.get_bind_bone(index)
				if bone < 0: bone = skeleton.find_bone(mesh.skin.get_bind_name(index))
				binds.append(skeleton.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(index))
		for surface in range(mesh.mesh.get_surface_count()):
			var original := mesh.get_active_material(surface) as StandardMaterial3D
			if original == null: continue
			_previous.append({"mesh":mesh,"surface":surface,"material":mesh.get_surface_override_material(surface)})
			var material := _surface_material(original)
			mesh.set_surface_override_material(surface,material)
			_surfaces.append(material)
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES] if arrays[Mesh.ARRAY_BONES] != null else PackedInt32Array()
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS] if arrays[Mesh.ARRAY_WEIGHTS] != null else PackedFloat32Array()
			var stride := bones.size()/maxi(vertices.size(),1)
			var world_vertices := PackedVector3Array()
			world_vertices.resize(vertices.size())
			for index in range(vertices.size()):
				var point := mesh.to_global(vertices[index])
				if not binds.is_empty() and stride > 0:
					var deformed := Vector3.ZERO
					for influence in range(stride):
						deformed += (binds[bones[index*stride+influence]]*vertices[index])*weights[index*stride+influence]
					point = skeleton.to_global(deformed)
				world_vertices[index] = point
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				for index in range(vertices.size()): indices.append(index)
			var alpha: Image
			if original.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and original.albedo_texture != null:
				alpha = original.albedo_texture.get_image()
				if alpha.is_compressed(): alpha.decompress()
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			for face in range(0,indices.size(),3):
				var a := world_vertices[indices[face]]
				var b := world_vertices[indices[face+1]]
				var c := world_vertices[indices[face+2]]
				var area := (b-a).cross(c-a).length()*0.5
				if area<0.00001: continue
				total_area += area
				triangles.append({"a":a,"b":b,"c":c,"end":total_area,"alpha":alpha,
					"uv_a":uvs[indices[face]] if not uvs.is_empty() else Vector2.ZERO,
					"uv_b":uvs[indices[face+1]] if not uvs.is_empty() else Vector2.ZERO,
					"uv_c":uvs[indices[face+2]] if not uvs.is_empty() else Vector2.ZERO,
					"uv_scale":Vector2(original.uv1_scale.x,original.uv1_scale.y),
					"uv_offset":Vector2(original.uv1_offset.x,original.uv1_offset.y)})
	# Amostras por área evitam concentrar partículas nos vértices mais densos.

	if triangles.is_empty(): return
	for sample in range(38000):
		var area := rng.randf()*total_area
		var lower := 0
		var upper := triangles.size()-1
		while lower<upper:
			var middle := (lower+upper)/2
			if float(triangles[middle].end)<area: lower=middle+1
			else: upper=middle
		var triangle := triangles[lower]
		var u := sqrt(rng.randf())
		var v := rng.randf()
		var weights := Vector3(1.0-u,u*(1.0-v),u*v)
		if triangle.alpha != null:
			var uv: Vector2 = (Vector2(triangle.uv_a)*weights.x+Vector2(triangle.uv_b)*weights.y+Vector2(triangle.uv_c)*weights.z)*Vector2(triangle.uv_scale)+Vector2(triangle.uv_offset)
			var mask: Image = triangle.alpha
			if mask.get_pixel(posmod(int(uv.x*mask.get_width()),mask.get_width()),posmod(int(uv.y*mask.get_height()),mask.get_height())).a<0.45: continue
		points.append(Vector3(triangle.a)*weights.x+Vector3(triangle.b)*weights.y+Vector3(triangle.c)*weights.z)
	if points.is_empty(): return
	_bottom = points[0].y
	var top := _bottom
	for point in points:
		_bottom = minf(_bottom,point.y)
		top = maxf(top,point.y)
	_height = maxf(1.0,top-_bottom)
	_center = Vector3(_queen.global_position.x,_bottom+_height*0.68,_queen.global_position.z+1.0)
	for material in _surfaces:
		material.set_shader_parameter("bottom",_bottom)
		material.set_shader_parameter("height",_height)
	_build_motes(points,false,rng)
	_build_motes(points,true,rng)
	_build_remnant(rng)

func _surface_material(source: StandardMaterial3D) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SURFACE
	if source.albedo_texture != null: material.set_shader_parameter("base_texture",source.albedo_texture)
	material.set_shader_parameter("tint",source.albedo_color)
	material.set_shader_parameter("surface_roughness",source.roughness)
	material.set_shader_parameter("surface_metallic",source.metallic)
	if source.metallic_texture != null: material.set_shader_parameter("metallic_texture",source.metallic_texture)
	if source.roughness_texture != null: material.set_shader_parameter("roughness_texture",source.roughness_texture)
	var channels := [Vector4(1,0,0,0),Vector4(0,1,0,0),Vector4(0,0,1,0),Vector4(0,0,0,1),Vector4(0.333,0.333,0.333,0)]
	material.set_shader_parameter("metallic_channel",channels[source.metallic_texture_channel])
	material.set_shader_parameter("roughness_channel",channels[source.roughness_texture_channel])
	if source.emission_enabled:
		material.set_shader_parameter("source_emission",Vector3(source.emission.r,source.emission.g,source.emission.b)*source.emission_energy_multiplier)
		if source.emission_texture != null: material.set_shader_parameter("emission_texture",source.emission_texture)
	material.set_shader_parameter("use_normal",source.normal_enabled and source.normal_texture != null)
	if source.normal_texture != null: material.set_shader_parameter("normal_texture",source.normal_texture)
	material.set_shader_parameter("normal_strength",source.normal_scale)
	material.set_shader_parameter("uv_scale",Vector2(source.uv1_scale.x,source.uv1_scale.y))
	material.set_shader_parameter("uv_offset",Vector2(source.uv1_offset.x,source.uv1_offset.y))
	material.set_shader_parameter("cutout",source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED)
	return material

func _mote_instance(count: int, material: ShaderMaterial, node_name: String) -> MultiMeshInstance3D:
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	quad.material = material
	multi.mesh = quad
	multi.instance_count = count
	multi.custom_aabb = AABB(Vector3(-60,-70,-85),Vector3(120,170,150))
	instance.multimesh = multi
	add_child(instance)
	return instance

func _build_motes(points: Array[Vector3], trails: bool, rng: RandomNumberGenerator) -> void:
	var material := ShaderMaterial.new()
	material.shader = MOTES
	material.set_shader_parameter("source_texture",STARS)
	material.set_shader_parameter("trails",trails)
	material.set_shader_parameter("bottom",_bottom)
	material.set_shader_parameter("height",_height)
	material.set_shader_parameter("dissolve_length",DISSOLVE_LENGTH)
	var instance := _mote_instance(points.size()/10 if trails else points.size(),material,"AetherTraces" if trails else "AetherLights")
	for index in range(instance.multimesh.instance_count):
		var point := points[(index*10 if trails else index)%points.size()]
		instance.multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY,point))
		instance.multimesh.set_instance_custom_data(index,Color(rng.randf(),0,rng.randf_range(3.2,6.8),rng.randf_range(0.15,0.32) if trails else rng.randf_range(0.10,0.25)))
	_motes.append(material)

func _build_remnant(rng: RandomNumberGenerator) -> void:
	_nebula = MeshInstance3D.new()
	_nebula.name = "ReflectionNebula"
	var box := BoxMesh.new()
	box.size = Vector3(30,28,18)
	_nebula.mesh = box
	_nebula.position = _center+Vector3.UP*4.0
	_nebula.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_nebula_material = ShaderMaterial.new()
	_nebula_material.shader = NEBULA
	var mist := _queen.get_parent().get_node("Board/LevitationMist")
	_nebula_material.set_shader_parameter("cloud_noise",mist._nebula_material.get_shader_parameter("cloud_noise"))
	_nebula.material_override = _nebula_material
	add_child(_nebula)
	_cluster_material = ShaderMaterial.new()
	_cluster_material.shader = MOTES
	_cluster_material.set_shader_parameter("source_texture",STARS)
	_cluster_material.set_shader_parameter("remnant",true)
	_cluster = _mote_instance(87,_cluster_material,"QueenStarCluster")
	var crown := [Vector3(-7,3,0),Vector3(-4,8,2),Vector3(0,10,0),Vector3(4,8,1),Vector3(7,3,-1),Vector3(-2,-1,2),Vector3(2,-2,0)]
	for index in range(87):
		var point := Vector3(rng.randfn(0,4.2),rng.randfn(2,5.0),rng.randfn(0,2.8))
		if index<crown.size(): point = crown[index]
		_cluster.multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY,_center+point))
		_cluster.multimesh.set_instance_custom_data(index,Color(rng.randf(),0,1000,rng.randf_range(2.0,3.2) if index<7 else rng.randf_range(0.25,0.85)))

func set_dissolve_age(age: float) -> void:
	for material in _surfaces: material.set_shader_parameter("dissolve",clampf(age/DISSOLVE_LENGTH,0.0,1.0))
	for material in _motes: material.set_shader_parameter("effect_time",age)
	if _nebula_material != null:
		var presence := smoothstep(11.0,23.5,age)
		_nebula.visible = presence>0.001
		_cluster.visible = presence>0.001
		_nebula_material.set_shader_parameter("envelope",presence)
		_nebula_material.set_shader_parameter("effect_time",age)
		_cluster_material.set_shader_parameter("effect_time",age-13.0)
		_cluster_material.set_shader_parameter("envelope",presence)

func _release_material(wave: bool, delay := 0.0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = RELEASE
	material.set_shader_parameter("glow_texture",GLOW)
	material.set_shader_parameter("flow_texture",FLOW)
	material.set_shader_parameter("filament_texture",FILAMENTS)
	material.set_shader_parameter("wave",wave)
	material.set_shader_parameter("delay",delay)
	return material

func _build_release() -> void:
	_core = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(8,8)
	_core.mesh = quad
	_core.material_override = _release_material(false)
	_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_core)
	for index in range(2):
		var mesh := MeshInstance3D.new()
		var plane := QuadMesh.new()
		plane.size = Vector2.ONE*38.0
		mesh.mesh = plane
		mesh.material_override = _release_material(true,float(index)*0.22)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mesh)
		_waves.append(mesh)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0,0.86,0.63)
	_light.omni_range = 28
	_light.light_cull_mask = 65
	add_child(_light)

func set_burst_origin(point: Vector3) -> void:
	_burst_origin = point
	if _fractured: return
	_fractured = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 601
	var orb := _queen.get_node("Model/Seraph/Skeleton3D/OrbAttachment/AstraiaOrb")
	for source: MeshInstance3D in orb.find_children("*","MeshInstance3D",true,false):
		for surface in range(source.mesh.get_surface_count()):
			var arrays := source.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				for index in range(vertices.size()): indices.append(index)
			var groups: Array[Array] = [[],[],[],[],[],[],[],[]]
			for index in range(0,indices.size(),3):
				var center := (vertices[indices[index]]+vertices[indices[index+1]]+vertices[indices[index+2]])/3.0
				var sector := posmod(int(floor((atan2(center.y,center.x)+PI)/TAU*8.0)),8)
				groups[sector].append_array([indices[index],indices[index+1],indices[index+2]])
			for group in groups:
				if group.is_empty(): continue
				var center := Vector3.ZERO
				for index: int in group: center += vertices[index]
				center /= float(group.size())
				var builder := SurfaceTool.new()
				builder.begin(Mesh.PRIMITIVE_TRIANGLES)
				for index: int in group:
					if not normals.is_empty(): builder.set_normal(normals[index])
					if not uvs.is_empty(): builder.set_uv(uvs[index])
					builder.add_vertex(vertices[index]-center)
				if normals.is_empty(): builder.generate_normals()
				if not uvs.is_empty(): builder.generate_tangents()
				var fragment := MeshInstance3D.new()
				fragment.mesh = builder.commit()
				fragment.layers = source.layers
				fragment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var material := ShaderMaterial.new()
				material.shader = FRAGMENT
				var original := source.get_active_material(surface) as ShaderMaterial
				if original != null:
					for parameter in ["base_color","metallic_map","roughness_map","normal_map","opacity_map"]:
						material.set_shader_parameter(parameter,original.get_shader_parameter(parameter))
				fragment.material_override = material
				add_child(fragment)
				var position := source.to_global(center)
				var direction := (position-_burst_origin).normalized()
				if direction.length_squared()<0.1: direction = Vector3(rng.randf_range(-1,1),rng.randf(),rng.randf_range(-1,1)).normalized()
				_fragments.append({"mesh":fragment,"material":material,"position":position,"basis":source.global_basis,"velocity":direction*rng.randf_range(2.5,5.0)+Vector3.UP*0.4,"axis":Vector3(rng.randf(),rng.randf(),rng.randf()).normalized(),"spin":rng.randf_range(-2.0,2.0)})

func set_burst_age(age: float) -> void:
	var active := age>=0 and age<6.0
	_core.visible = active and age<0.8
	_light.visible = active
	_core.position = _burst_origin
	(_core.material_override as ShaderMaterial).set_shader_parameter("age",age)
	_core.scale = Vector3.ONE*(1.0+maxf(age,0.0)*0.7)
	for wave in _waves:
		wave.visible = active
		wave.position = _burst_origin
		(wave.material_override as ShaderMaterial).set_shader_parameter("age",age)
	_light.position = _burst_origin
	_light.light_energy = (1.0-smoothstep(0.0,0.6,maxf(age,0)))*1.0
	for piece in _fragments:
		piece.mesh.visible = active
		if not active: continue
		piece.material.set_shader_parameter("fragment_age",age)
		var travel := age*(1.0-age*0.045)
		var basis: Basis = Basis(piece.axis,age*float(piece.spin))*Basis(piece.basis)
		piece.mesh.global_transform = Transform3D(basis,Vector3(piece.position)+Vector3(piece.velocity)*travel)

func restore() -> void:
	for entry in _previous:
		if is_instance_valid(entry.mesh): entry.mesh.set_surface_override_material(entry.surface,entry.material)
	_previous.clear()

func _exit_tree() -> void:
	restore()
