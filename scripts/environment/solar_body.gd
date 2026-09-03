class_name SolarBody
extends Node3D

const SURFACE_SHADER = preload("res://shaders/solar_planet.gdshader")
const LUNAR_SHADER = preload("res://shaders/lunar_surface.gdshader")
const RING_SHADER = preload("res://shaders/solar_rings.gdshader")
const ACCRETION_SHADER = preload("res://shaders/black_hole_accretion.gdshader")

var body_radius := 1.0
var spin_axis := Vector3.UP
var spin_speed := 0.5
var ring_speed := 0.22
var model: Node3D
var sun_position := Vector3.ZERO
var emitter := false
var accretion := false
var rings: Array[MeshInstance3D] = []
var surfaces: Array[MeshInstance3D] = []

func configure(asset: PackedScene, radius: float, sunlight_position: Vector3, axis: Vector3, speed: float) -> void:
	body_radius = radius
	sun_position = sunlight_position
	spin_axis = axis.normalized()
	spin_speed = speed
	model = asset.instantiate() as Node3D
	model.name = "Model"
	model.scale = Vector3.ONE * radius
	add_child(model)
	var direction := (sun_position - global_position).normalized()
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = 4
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mesh.name == "Rings":
			rings.append(mesh)
		else:
			surfaces.append(mesh)
		for index in mesh.mesh.get_surface_count():
			var imported := mesh.get_active_material(index) as StandardMaterial3D
			if imported == null:
				continue
			if accretion:
				if mesh.name == "Surface":
					mesh.scale = Vector3.ONE * 2.1
					var horizon := StandardMaterial3D.new()
					horizon.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					horizon.albedo_color = Color.BLACK
					mesh.set_surface_override_material(index, horizon)
				else:
					# Material de acreção com transparência suave.
					var disk := ShaderMaterial.new()
					disk.shader = ACCRETION_SHADER
					disk.set_shader_parameter("intensity", 0.4 if "ring" in String(mesh.name) else 0.75)
					mesh.set_surface_override_material(index, disk)
				continue
			var material := ShaderMaterial.new()
			if mesh.name == "Rings":
				material.shader = RING_SHADER
				material.set_shader_parameter("ring_map", imported.albedo_texture)
				material.set_shader_parameter("planet_center", global_position)
				material.set_shader_parameter("planet_radius", radius)
				material.set_shader_parameter("opacity", 0.025 if name == "Jupiter" else (0.20 if name == "Neptune" else 0.48))
			else:
				material.shader = LUNAR_SHADER if name == "Moon" else SURFACE_SHADER
				material.set_shader_parameter("surface_map", imported.albedo_texture)
				material.set_shader_parameter("surface_tint", imported.albedo_color)
				if name != "Moon":
					material.set_shader_parameter("solar_emitter", emitter)
				material.set_shader_parameter("has_relief", imported.normal_texture != null)
				if imported.normal_texture != null:
					material.set_shader_parameter("relief_map", imported.normal_texture)
			material.set_shader_parameter("sun_direction", direction)
			mesh.set_surface_override_material(index, material)

func set_axial_rotation(world_axis: Vector3, degrees_per_second: float) -> void:
	var current_axis := (model.basis * spin_axis).normalized()
	var target_axis := (global_basis.orthonormalized().inverse() * world_axis).normalized()
	var correction_axis := current_axis.cross(target_axis)
	if correction_axis.length_squared() > 0.000000000001:
		var angle := atan2(correction_axis.length(), current_axis.dot(target_axis))
		model.basis = Basis(Quaternion(correction_axis.normalized(), angle)) * model.basis
	spin_speed = degrees_per_second
	# Os anéis acompanham o plano equatorial e o sentido de rotação do planeta.
	ring_speed = degrees_per_second * 0.60

func _process(delta: float) -> void:
	# Rotação em torno do eixo local do modelo.
	for surface in surfaces:
		surface.rotate(spin_axis, deg_to_rad(spin_speed) * delta)
	for ring in rings:
		ring.rotate(spin_axis, deg_to_rad(ring_speed) * delta)

func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE:
		return
	# Liberação dos materiais antes da destruição das instâncias de renderização.
	for mesh in surfaces + rings:
		if is_instance_valid(mesh) and mesh.mesh != null:
			for index in mesh.mesh.get_surface_count():
				mesh.set_surface_override_material(index, null)
