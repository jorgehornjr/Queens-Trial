class_name MainMenuMoonWorld
extends Node3D


signal intro_finished

const INTRO_DURATION := 11.5
const ORBIT_OFFSET := Vector3(0, 18, 48)
const ORBIT_AXIS := Vector3(0, -48, 18)
const EARTH_START_SCALE := 6.8
const EARTH_END_SCALE := 10.4

const SPACE = preload("res://scenes/environment/celestial_space.tscn")
const BOARD = preload("res://scenes/board/PaintedBoard.tscn")
const MOON = preload("res://assets/environment/solar_system/moon.glb")
const Body = preload("res://scripts/environment/solar_body.gd")
const Rotation = preload("res://scripts/environment/planet_rotation.gd")

var moon: SolarBody
var earth: CinematicEarth
var board: Node3D
var camera: Camera3D
var environment: Environment
var _sky_material: ShaderMaterial
var effect_time := 0.0
var intro_time := 0.0
var intro_complete := false
var light_uv := Vector2.ZERO
var light_strength := 0.0
var _moon_materials: Array[ShaderMaterial] = []
var _earth_materials: Array[ShaderMaterial] = []
var _atmosphere: ShaderMaterial
var _board_light: DirectionalLight3D


func _ready() -> void:

	var source := SPACE.instantiate()
	environment = (source.get_node("WorldEnvironment") as WorldEnvironment).environment.duplicate() as Environment
	environment.sky = environment.sky.duplicate() as Sky
	_sky_material = environment.sky.sky_material.duplicate() as ShaderMaterial
	environment.sky.sky_material = _sky_material
	environment.background_energy_multiplier = 0.36
	earth = source.get_node("DistantEarth") as CinematicEarth
	source.remove_child(earth)
	source.free()
	var sky := WorldEnvironment.new()
	sky.name = "GameSky"
	sky.environment = environment
	add_child(sky)
	board = BOARD.instantiate() as Node3D
	board.name = "BoardFloor"
	add_child(board)
	_board_light = DirectionalLight3D.new()
	_board_light.name = "BoardLight"
	_board_light.rotation_degrees = Vector3(-28, -38, 0)
	_board_light.light_color = Color(0.65, 0.76, 1.0)
	_board_light.light_cull_mask = 1
	_board_light.shadow_enabled = false
	add_child(_board_light)
	camera = Camera3D.new()
	camera.name = "OrbitalCamera"
	camera.near = 0.1
	camera.far = 5000.0
	add_child(camera)
	camera.current = true
	earth.position = Vector3(0, 31, -64)
	earth.scale = Vector3.ONE * EARTH_START_SCALE
	earth.sun_direction = Vector3(0.93, 0.25, 0.28)
	earth.city_energy = 0.35
	earth.get_node("Atmosphere").show()
	add_child(earth)
	earth.set_axial_rotation(Rotation.axis_for("Earth"), 1.5)
	_atmosphere = earth.get_node("Atmosphere").material_override as ShaderMaterial
	for mesh: MeshInstance3D in earth.get_node("Model").find_children("*", "MeshInstance3D", true, false):
		for index in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(index) as ShaderMaterial
			if material != null and material.shader == CinematicEarth.SURFACE_SHADER:
				_earth_materials.append(material)
				material.set_shader_parameter("specular_strength", 0.04)
	moon = Body.new() as SolarBody
	moon.name = "Moon"
	moon.position = Vector3(0, -5, -160)
	add_child(moon)
	moon.configure(MOON, 34.0, Vector3(800, 500, -700), Vector3.UP, Rotation.speed_for("Earth", 240.0, false))
	moon.model.rotation_degrees = Vector3(0, 240, 0)
	for mesh in moon.surfaces:
		for index in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(index) as ShaderMaterial
			if material != null: _moon_materials.append(material)
	_apply_shot()
	_update_sky()


func _process(delta: float) -> void:
	effect_time += delta
	if not intro_complete:
		intro_time = minf(intro_time + delta, INTRO_DURATION)
		if intro_time >= INTRO_DURATION:
			intro_complete = true
			intro_finished.emit()
	_apply_shot()
	var pose := environment.sky_rotation
	pose.y = wrapf(pose.y + deg_to_rad(0.04) * delta, -PI, PI)
	environment.sky_rotation = pose
	_update_sky()


func skip_intro() -> void:
	if intro_complete: return
	intro_time = INTRO_DURATION
	intro_complete = true
	_apply_shot()
	intro_finished.emit()


func _apply_shot() -> void:
	var arrival := smoothstep(0.8, 8.5, intro_time)
	var light_reveal := smoothstep(5.8, 9.2, intro_time)
	camera.position = Vector3(0, 5.0, 16.0).lerp(Vector3(0, 9.0, 24.0), arrival)
	camera.fov = lerpf(52.0, 48.0, arrival)
	camera.look_at(Vector3(0, 25, -88))

	var pivot := Vector3(0, 13, -112).lerp(Vector3(0, 13, -136), arrival)
	var orbit := Basis(ORBIT_AXIS.normalized(), lerpf(-PI, 0.0, arrival)) * ORBIT_OFFSET
	earth.position = pivot - orbit
	moon.position = pivot + orbit

	earth.position.x += 60.0 * smoothstep(6.2, 8.5, intro_time)
	earth.scale = Vector3.ONE * lerpf(EARTH_START_SCALE, EARTH_END_SCALE, arrival)
	var earth_sun := Vector3(0.93, 0.25, 0.28).lerp(Vector3(0.84, 0.28, -0.46), arrival).normalized()
	earth.illuminate_from(earth.position + earth_sun * 1000.0)
	_atmosphere.set_shader_parameter("sun_direction", earth_sun)
	(earth.get_node("PlanetSun") as DirectionalLight3D).light_energy = lerpf(1.4, 0.48, arrival)
	for material in _earth_materials:
		material.set_shader_parameter("city_energy", lerpf(0.35, 0.06, arrival))
	var moon_sun := Vector3(0.90, 0.25, -0.32).lerp(Vector3(0.32, 0.24, 0.916), light_reveal).normalized()
	for material in _moon_materials:
		material.set_shader_parameter("sun_direction", moon_sun)
		material.set_shader_parameter("exposure", lerpf(0.65, 1.20, light_reveal))
		material.set_shader_parameter("highlight_strength", 1.8)
		material.set_shader_parameter("light_tint", Color(0.82, 0.89, 1.0))
		material.set_shader_parameter("rim_strength", light_reveal * 2.2)
	_board_light.light_energy = lerpf(0.23, 0.44, light_reveal)

	var view_size := get_viewport().get_visible_rect().size
	var earth_limb := camera.unproject_position(earth.position + Vector3(earth.scale.x * 5.4, 10, -6)) / view_size
	var moon_limb := camera.unproject_position(moon.position + Vector3(38, 12, -6)) / view_size
	light_uv = earth_limb.lerp(moon_limb, arrival)

	light_uv.x = lerpf(maxf(earth_limb.x, moon_limb.x), moon_limb.x, smoothstep(7.6, 8.5, intro_time))
	light_strength = (1.15 + sin(smoothstep(0.6, 9.0, intro_time) * PI) * 1.15) * smoothstep(0.2, 1.7, intro_time)


func _update_sky() -> void:
	_sky_material.set_shader_parameter("effect_time", effect_time)
	_sky_material.set_shader_parameter("motion_enabled", true)
	_sky_material.set_shader_parameter("motion_strength", 0.007)
	_sky_material.set_shader_parameter("motion_speed", 1.0)
	_sky_material.set_shader_parameter("core_glow_strength", 1.2)
	_sky_material.set_shader_parameter("sparkles_enabled", true)
	_sky_material.set_shader_parameter("sparkle_intensity", 10.0)
	_sky_material.set_shader_parameter("sparkle_density", 0.42)
