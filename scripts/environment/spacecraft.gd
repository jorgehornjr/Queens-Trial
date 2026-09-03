class_name AmbientSpacecraft
extends Node3D

var is_station := false
var model: Node3D
var habitat_ring: Node3D
var hull: Node3D
var anchor := Vector3.ZERO
var elapsed := 0.0
var drift_radius := 9.0
var phase_offset := 0.0
var ring_degrees_per_second := 1.8
var _model_rest := Basis.IDENTITY
var _materials: Array[MeshInstance3D] = []

func configure(asset: PackedScene, size: float, sunlight_position: Vector3, layer: int) -> void:
	anchor = position
	model = asset.instantiate() as Node3D
	model.name = "Model"
	model.scale = Vector3.ONE * size
	add_child(model)
	_model_rest = model.basis
	habitat_ring = model.find_child("HabitatRing", true, false) as Node3D
	hull = model.find_child("Hull", true, false) as Node3D
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		_materials.append(mesh)
		mesh.layers = layer
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for index in mesh.mesh.get_surface_count():
			var imported := mesh.get_active_material(index) as StandardMaterial3D
			if imported == null:
				continue
			var material := imported.duplicate() as StandardMaterial3D
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			# Rugosidade mínima para reduzir aliasing especular à distância.
			material.roughness = maxf(material.roughness, 0.68)
			material.roughness_texture = null
			material.metallic = minf(material.metallic, 0.45)
			material.metallic_specular = 0.3
			material.normal_scale = minf(material.normal_scale, 0.4)
			material.emission_energy_multiplier = minf(material.emission_energy_multiplier, 1.2)
			mesh.set_surface_override_material(index, material)
	var key := DirectionalLight3D.new()
	key.name = "SolarLight"
	key.light_cull_mask = layer
	key.light_energy = 1.8
	key.light_color = Color(1.0, 0.95, 0.88)
	key.shadow_enabled = false
	add_child(key)
	key.look_at(global_position - (sunlight_position - global_position).normalized())

func _process(delta: float) -> void:
	elapsed += delta
	if is_station:
		if habitat_ring != null:
			habitat_ring.rotate_x(deg_to_rad(ring_degrees_per_second) * delta)
		return
	# Deriva limitada ao entorno do ponto de ancoragem.
	var phase := elapsed * 0.065 + phase_offset
	position = anchor + Vector3(sin(phase) - sin(phase_offset),
		0.35 * (sin(phase * 0.7) - sin(phase_offset * 0.7)),
		cos(phase) - cos(phase_offset)) * drift_radius
	model.basis = _model_rest * Basis.from_euler(Vector3(
		deg_to_rad(2.0) * sin(elapsed * 0.11), deg_to_rad(elapsed * 0.18),
		deg_to_rad(3.0) * sin(elapsed * 0.08)))

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for mesh in _materials:
			if is_instance_valid(mesh) and mesh.mesh != null:
				for index in mesh.mesh.get_surface_count():
					mesh.set_surface_override_material(index, null)
