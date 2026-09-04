class_name CinematicEarth
extends Node3D

const SURFACE_SHADER = preload("res://shaders/earth_cinematic_surface.gdshader")
const CLOUD_SHADER = preload("res://shaders/earth_cinematic_clouds.gdshader")
@export var sun_direction := Vector3(-0.97, 0.12, -0.2)
@export_range(0.0, 5.0, 0.1) var city_energy := 1.0
@export_range(-5.0, 5.0, 0.05) var rotation_degrees_per_second := 0.65
var spin_axis := Vector3.UP

func _process(delta: float) -> void:
	# O limite entre dia e noite depende do Sol, independentemente do giro do globo.
	$Model.rotate(spin_axis, deg_to_rad(rotation_degrees_per_second) * delta)

func set_axial_rotation(world_axis: Vector3, degrees_per_second: float) -> void:
	spin_axis = (global_basis.orthonormalized().inverse() * world_axis).normalized()
	var current_axis: Vector3 = ($Model.basis * Vector3.UP).normalized()
	$Model.basis = Basis(Quaternion(current_axis, spin_axis)) * $Model.basis
	rotation_degrees_per_second = degrees_per_second

func _ready() -> void:
	var direction := sun_direction.normalized()
	var sunlight := $PlanetSun as DirectionalLight3D
	sunlight.look_at_from_position(global_position, global_position - direction)
	# Materiais por instância para os parâmetros de iluminação da Terra.
	for mesh: MeshInstance3D in $Model.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = 2
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in mesh.mesh.get_surface_count():
			var imported := mesh.get_active_material(surface) as StandardMaterial3D
			if imported == null:
				continue
			if imported.normal_texture != null and imported.emission_texture != null:
				var material := ShaderMaterial.new()
				material.shader = SURFACE_SHADER
				material.set_shader_parameter("surface_map", imported.albedo_texture)
				material.set_shader_parameter("relief_map", imported.normal_texture)
				material.set_shader_parameter("roughness_map", imported.roughness_texture)
				material.set_shader_parameter("city_map", imported.emission_texture)
				material.set_shader_parameter("sun_direction", direction)
				material.set_shader_parameter("city_energy", city_energy)
				mesh.set_surface_override_material(surface, material)
			else:
				var clouds := ShaderMaterial.new()
				clouds.shader = CLOUD_SHADER
				clouds.set_shader_parameter("cloud_map", imported.albedo_texture)
				mesh.set_surface_override_material(surface, clouds)
	var atmosphere := $Atmosphere as MeshInstance3D
	atmosphere.material_override = atmosphere.mesh.material.duplicate()
	(atmosphere.material_override as ShaderMaterial).set_shader_parameter("sun_direction", direction)

func illuminate_from(solar_position: Vector3) -> void:
	sun_direction = (solar_position - global_position).normalized()
	$PlanetSun.look_at_from_position(global_position, global_position - sun_direction)
	for mesh: MeshInstance3D in $Model.find_children("*", "MeshInstance3D", true, false):
		for index in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(index) as ShaderMaterial
			if material != null and material.shader == SURFACE_SHADER:
				material.set_shader_parameter("sun_direction", sun_direction)
