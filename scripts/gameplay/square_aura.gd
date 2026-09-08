extends Node3D
## A neon perimeter and four upright, flowing veils. The marble stays visible.

const AURA_SHADER = preload("res://shaders/square_aura.gdshader")
const INTERIOR_MIST_SHADER = preload("res://shaders/interior_mist.gdshader")
const CLOUD_FIELD = preload("res://assets/textures/guidance_mist.tres")

var _materials: Array[ShaderMaterial] = []
var reveal := 1.0:
	set(value):
		reveal = clampf(value, 0.0, 1.0)
		for material in _materials:
			material.set_shader_parameter("reveal", reveal)


func configure(size: float, color: Color, height: float, phase := 0.0, interior_mist := false, core_color := Color(0.60, 0.85, 0.74)) -> void:
	var floor_material := _material(color, false, phase, core_color)
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2.ONE * size
	_add_mesh("NeonPerimeter", floor_mesh, floor_material)
	var wall_material := _material(color, true, phase, core_color)
	var half := size * 0.455
	for index in range(4):
		var veil := QuadMesh.new()
		veil.size = Vector2(half * 2.0, height)
		var mesh := _add_mesh("RisingVeil%d" % index, veil, wall_material)
		mesh.rotation.y = float(index) * PI * 0.5
		mesh.position = Vector3(sin(mesh.rotation.y) * half, height * 0.5, cos(mesh.rotation.y) * half)
	# Opt-in only: attack markers retain their approved materials and geometry.
	if interior_mist:
		_add_interior_mist(size, color, height, phase)


func _add_interior_mist(size: float, color: Color, height: float, phase: float) -> void:
	for index in range(3):
		var material := ShaderMaterial.new()
		material.shader = INTERIOR_MIST_SHADER
		material.set_shader_parameter("cloud_field", CLOUD_FIELD)
		material.set_shader_parameter("tint", color)
		material.set_shader_parameter("phase", phase + float(index) * 2.37)
		material.set_shader_parameter("layer_strength", 0.16 - float(index) * 0.045)
		material.set_shader_parameter("reveal", reveal)
		_materials.append(material)
		var plane := PlaneMesh.new()
		plane.size = Vector2.ONE * size
		var mist := _add_mesh("InteriorMist%d" % index, plane, material)
		mist.position.y = height * (0.08 + float(index) * 0.10)


func _material(color: Color, wall: bool, phase: float, core_color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = AURA_SHADER
	material.set_shader_parameter("tint", color)
	material.set_shader_parameter("core_tint", core_color)
	material.set_shader_parameter("wall", wall)
	material.set_shader_parameter("phase", phase)
	material.set_shader_parameter("reveal", reveal)
	_materials.append(material)
	return material


func _add_mesh(mesh_name: String, mesh: Mesh, material: ShaderMaterial) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance
