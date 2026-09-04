class_name CelestialSpace
extends Node3D

@export_category("Panorama Motion")
@export var sky_drift_enabled := true
@export_range(-0.5, 0.5, 0.005) var sky_degrees_per_second := 0.04

@export_category("Cinematic Nebula")
@export var nebula_motion_enabled := true
@export_range(0.0, 0.02, 0.001) var nebula_motion_strength := 0.007
@export_range(0.0, 3.0, 0.1) var nebula_motion_speed := 1.0
@export_range(0.0, 3.0, 0.1) var core_glow_strength := 1.2
@export var sparkles_enabled := true
@export_range(0.0, 20.0, 0.1) var sparkle_intensity := 10.0
@export_range(0.0, 1.0, 0.005) var sparkle_density := 0.42

@export_category("Celestial Motion")
@export_range(-2.0, 2.0, 0.01) var earth_degrees_per_second := 0.18
@export_range(-2.0, 2.0, 0.01) var cloud_degrees_per_second := 0.27
@export_range(-1.0, 1.0, 0.001) var star_field_degrees_per_second := 0.006

@export_category("Star Field")
@export var star_texture: Texture2D
@export_range(64, 1200, 1) var star_count := 520
@export var star_seed := 240831

@onready var earth_surface: MeshInstance3D = $Earth/EarthSurface
@onready var earth_clouds: MeshInstance3D = $Earth/EarthClouds
@onready var star_field: MultiMeshInstance3D = $StarField
@onready var world_environment: WorldEnvironment = $WorldEnvironment

var _environment: Environment
var _sky_material: ShaderMaterial
var _effect_time := 0.0


func _ready() -> void:
	# O movimento deve pertencer a esta instância, não ao recurso compartilhado.
	_environment = world_environment.environment.duplicate() as Environment
	world_environment.environment = _environment
	_environment.sky = _environment.sky.duplicate() as Sky
	_sky_material = _environment.sky.sky_material.duplicate() as ShaderMaterial
	_environment.sky.sky_material = _sky_material
	set_effect_time(0.0)
	if star_field.visible:
		_build_star_field()


func _process(delta: float) -> void:
	_advance_sky(delta)
	set_effect_time(_effect_time + delta)
	if earth_surface.is_visible_in_tree():
		earth_surface.rotate_y(deg_to_rad(earth_degrees_per_second) * delta)
	if earth_clouds.is_visible_in_tree():
		earth_clouds.rotate_y(deg_to_rad(cloud_degrees_per_second) * delta)
	if star_field.visible:
		star_field.rotate_y(deg_to_rad(star_field_degrees_per_second) * delta)


func _advance_sky(delta: float) -> void:
	if not sky_drift_enabled or _environment == null:
		return
	# Deriva rígida do panorama: não deforma as estrelas gravadas no HDR.
	var orientation := _environment.sky_rotation
	orientation.y = wrapf(orientation.y + deg_to_rad(sky_degrees_per_second) * delta, -PI, PI)
	_environment.sky_rotation = orientation


func set_effect_time(seconds: float) -> void:
	_effect_time = maxf(seconds, 0.0)
	if _sky_material == null:
		return
	_sky_material.set_shader_parameter("effect_time", _effect_time)
	_sky_material.set_shader_parameter("motion_enabled", nebula_motion_enabled)
	_sky_material.set_shader_parameter("motion_strength", nebula_motion_strength)
	_sky_material.set_shader_parameter("motion_speed", nebula_motion_speed)
	_sky_material.set_shader_parameter("core_glow_strength", core_glow_strength)
	_sky_material.set_shader_parameter("sparkles_enabled", sparkles_enabled)
	_sky_material.set_shader_parameter("sparkle_intensity", sparkle_intensity)
	_sky_material.set_shader_parameter("sparkle_density", sparkle_density)


func _build_star_field() -> void:
	if star_texture == null:
		push_warning("O campo estelar está sem a textura de brilho.")
		return
	if star_field == null:
		star_field = get_node_or_null("StarField") as MultiMeshInstance3D
	if star_field == null:
		push_warning("O campo estelar não encontrou o nó StarField.")
		return

	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_texture = star_texture
	material.albedo_color = Color(0.78, 0.88, 1.0, 0.82)
	material.emission_enabled = true
	material.emission_texture = star_texture
	material.emission = Color(0.56, 0.72, 1.0)
	material.emission_energy_multiplier = 2.4
	quad.material = material

	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = quad
	instances.instance_count = star_count

	var random := RandomNumberGenerator.new()
	random.seed = star_seed
	for index in star_count:
		var vertical := random.randf_range(-0.88, 0.92)
		var angle := random.randf_range(0.0, TAU)
		var horizontal := sqrt(maxf(0.0, 1.0 - vertical * vertical))
		var direction := Vector3(
			horizontal * cos(angle),
			vertical,
			horizontal * sin(angle)
		)
		var radius := random.randf_range(72.0, 138.0)
		var scale_value := random.randf_range(0.18, 0.72)
		if random.randf() < 0.06:
			scale_value *= random.randf_range(1.8, 2.8)
		instances.set_instance_transform(
			index,
			Transform3D(
				Basis.IDENTITY.scaled(Vector3.ONE * scale_value),
				direction * radius + Vector3(0.0, -12.0, 0.0)
			)
		)
		var warmth := random.randf()
		var star_color := Color(0.48, 0.66, 1.0, 0.72).lerp(
			Color(1.0, 0.72, 0.94, 0.88),
			warmth * 0.34
		)
		instances.set_instance_color(index, star_color)

	star_field.multimesh = instances
	star_field.custom_aabb = AABB(Vector3.ONE * -150.0, Vector3.ONE * 300.0)
